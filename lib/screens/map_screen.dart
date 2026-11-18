import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets/companion_figure.dart';
import '../widgets/journey_map.dart';
import '../widgets/pieces.dart';

/// World map: one dot per Companion. Tap a dot (or a row in Most active) to zoom to their journey.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // A phone is too narrow for the whole flat world, so start over the Atlantic:
  // the Americas, Europe and Africa, where most Companions are.
  static const worldCenter = LatLng(38, -40);
  static const worldZoom = 1.4;

  final mapController = MapController();
  final search = TextEditingController();
  final searchFocus = FocusNode();
  MapFilter filter = MapFilter.all;
  String? selected;
  bool searching = false;
  bool listOpen = true; // the list at the bottom; tap or swipe its top to tuck it away
  LatLng? me; // for "Near me"
  bool locating = false;

  @override
  void dispose() {
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void select(Companion c) {
    setState(() => selected = c.number);
    final points = [for (final s in c.stops) s.point];
    if (points.length > 1) {
      mapController.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(50, 190, 50, 260), maxZoom: 7));
    } else if (points.isNotEmpty) {
      mapController.move(points.first, 6);
    }
  }

  /// Tapping a bubble at the top: those Companions light up on the map and fill the list.
  Future<void> chooseFilter(MapFilter f) async {
    setState(() {
      filter = f;
      selected = null;
      listOpen = true;
    });
    if (f != MapFilter.nearMe) {
      fitTo(context.model.companions.where((c) => context.model.matches(c, f)));
      return;
    }
    if (me == null) {
      setState(() => locating = true);
      final point = await Services.currentPoint();
      if (!mounted) return;
      setState(() {
        locating = false;
        me = point;
      });
    }
    if (me != null && filter == MapFilter.nearMe) mapController.move(me!, 4);
  }

  static const _distance = Distance();
  int milesAway(Companion c) => me == null || c.current == null ? 0 : (_distance.as(LengthUnit.Mile, me!, c.current!.point)).round();

  /// What the bottom list shows for the chosen bubble: a heading, the Companions, and a note per row.
  (String, List<Companion>, String Function(Companion)) listFor(AppModel model) {
    switch (filter) {
      case MapFilter.all:
        return ('Most active', model.mostActive, (c) => '${c.stopCount} stops');
      case MapFilter.nearMe:
        final near = [
          for (final c in model.companions)
            if (c.current != null) c,
        ]..sort((a, b) => milesAway(a).compareTo(milesAway(b)));
        return ('Near me', me == null ? <Companion>[] : near.take(15).toList(), (c) => '${formatThousands(milesAway(c))} mi away');
      default:
        final list = model.companions.where((c) => model.matches(c, filter)).toList()
          ..sort((a, b) => AppModel.daysAgo(a.lastMoved).compareTo(AppModel.daysAgo(b.lastMoved)));
        return (filter.label, list, (c) => c.lastMoved);
    }
  }

  /// Zooms the map so every highlighted Companion shows above the list.
  void fitTo(Iterable<Companion> companions) {
    final points = [
      for (final c in companions)
        if (c.current != null) c.current!.point,
    ];
    if (filter == MapFilter.all || points.isEmpty) {
      mapController.move(worldCenter, worldZoom);
    } else if (points.length == 1) {
      mapController.move(points.first, 4);
    } else {
      mapController.fitCamera(
        CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(40, 190, 40, 330), maxZoom: 5, minZoom: 1),
      );
    }
  }

  void wholeWorld() {
    setState(() => selected = null);
    mapController.move(worldCenter, worldZoom);
  }

  void find(AppModel model) {
    final c = model.companion(search.text);
    if (c == null) return;
    searchFocus.unfocus();
    search.clear();
    setState(() => searching = false);
    select(c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModelBuilder(
        builder: (context, model) {
          final visible = model.companions.where((c) => model.matches(c, filter)).toList();
          final others = filter == MapFilter.all || filter == MapFilter.nearMe
              ? <Companion>[]
              : model.companions.where((c) => !model.matches(c, filter)).toList();
          final sel = selected == null ? null : model.companion(selected!);
          return Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: worldCenter,
                  initialZoom: worldZoom,
                  minZoom: 1,
                  maxZoom: 12,
                  backgroundColor: Herd.sageBackground,
                  onTap: (_, _) => searchFocus.unfocus(),
                ),
                children: [
                  herdTiles(),
                  if (sel != null) PolylineLayer(polylines: [journeyLine(sel)]),
                  MarkerLayer(
                    markers: [
                      if (sel != null)
                        for (final s in sel.stops.take(sel.stops.length - 1))
                          Marker(
                            point: s.point,
                            width: 10,
                            height: 10,
                            child: MapDot(color: sel.accentColor, size: 10, faded: true),
                          ),
                      // The ones that don't match the chosen bubble stay as small, pale dots underneath.
                      for (final c in others)
                        if (c.current != null)
                          Marker(
                            point: c.current!.point,
                            width: 12,
                            height: 12,
                            child: IgnorePointer(
                              child: Center(
                                child: Opacity(opacity: 0.35, child: MapDot(color: Herd.stepDot, size: 8)),
                              ),
                            ),
                          ),
                      if (me != null && filter == MapFilter.nearMe)
                        Marker(
                          point: me!,
                          width: 22,
                          height: 22,
                          child: Semantics(
                            label: 'You are here',
                            child: const Icon(Icons.my_location, color: Herd.ink, size: 20),
                          ),
                        ),
                      for (final c in visible)
                        if (c.current != null)
                          Marker(
                            point: c.current!.point,
                            width: 30,
                            height: 30,
                            child: Semantics(
                              button: true,
                              label: 'Companion #${c.number}, ${c.current!.city}',
                              excludeSemantics: true,
                              child: GestureDetector(
                                onTap: () => select(c),
                                child: Center(
                                  child: MapDot(color: c.accentColor, size: c.number == selected ? 18 : (others.isEmpty ? 12 : 15)),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: herdAttribution(alignment: Alignment.topRight, margin: const EdgeInsets.fromLTRB(0, 116, 16, 0)),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      _searchBar(model),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: MapFilter.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final f = MapFilter.values[i];
                            return FilterPill(filter: f, selected: filter == f, onTap: () => chooseFilter(f));
                          },
                        ),
                      ),
                      Row(
                        children: [
                          if (sel != null)
                            Material(
                              color: Herd.cream,
                              shape: const StadiumBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: wholeWorld,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.zoom_out_map, size: 16, color: Herd.ink),
                                      const SizedBox(width: 6),
                                      Text(tr('Whole world'), style: HerdText.body(14, color: Herd.ink)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const Spacer(),
                          InfoPill('${visible.length} Companions'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Align(alignment: Alignment.bottomCenter, child: sel != null ? _selectedCard(context, sel) : _mostActive(model)),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBar(AppModel model) => Material(
    color: Herd.cream,
    shape: const StadiumBorder(),
    elevation: 3,
    shadowColor: Herd.ink.withValues(alpha: 0.3),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Herd.sageDark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: const Key('mapSearch'),
              controller: search,
              focusNode: searchFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => searching = v.isNotEmpty),
              onSubmitted: (_) => find(model),
              style: HerdText.body(16, color: Herd.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Find a Companion: #07',
                hintStyle: HerdText.body(16, color: Herd.body.withValues(alpha: 0.7)),
              ),
            ),
          ),
          if (searching)
            TextButton(
              onPressed: () => find(model),
              child: Text(
                tr('Go'),
                style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _selectedCard(BuildContext context, Companion c) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Herd.cream,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [BoxShadow(color: Herd.ink.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Row(
          children: [
            CompanionBadge(companion: c, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(c.label, style: HerdText.chunky(18, extraBold: false, color: Herd.sageDark)),
                  Text(tr('${c.current?.city ?? ''} · ${c.lastMoved}'), style: HerdText.body(13)),
                  Text(tr('Wish: ${c.wish}'), style: HerdText.body(13, color: Herd.butterInk)),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _legend(c.accentColor.withValues(alpha: 0.6), 'Where they’ve been'),
            _legend(c.accentColor, 'Where #${c.number} is now'),
          ],
        ),
        HerdButton('Open their page', onPressed: () => context.router.push(CompanionRoute(c.number))),
      ],
    ),
  );

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(tr(text), style: HerdText.body(12, color: Herd.ink)),
    ],
  );

  Widget _mostActive(AppModel model) {
    final (title, items, note) = listFor(model);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Herd.cream,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Herd.ink.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The top of the list: tap it, or swipe down/up, to tuck the list away or bring it back.
          Semantics(
            button: true,
            label: listOpen ? 'Hide the list to see the whole map' : 'Show the list',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => listOpen = !listOpen),
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 100 && listOpen) setState(() => listOpen = false);
                if (v < -100 && !listOpen) setState(() => listOpen = true);
              },
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: hex('DCDDD6'), borderRadius: BorderRadius.circular(999)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            ScriptHeading(title, size: 26),
                            Text(
                              tr('${filter == MapFilter.all ? model.companions.length : items.length} Companions'),
                              style: HerdText.body(12),
                            ),
                          ],
                        ),
                      ),
                      Icon(listOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Herd.sageDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (listOpen && items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                tr(
                  filter != MapFilter.nearMe
                      ? 'None right now.'
                      : locating
                      ? 'Finding your location…'
                      : 'Turn on location to see the Companions nearest you.',
                ),
                style: HerdText.body(14),
              ),
            ),
          if (listOpen && items.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Herd.line),
                itemBuilder: (context, i) {
                  final c = items[i];
                  return InkWell(
                    onTap: () => select(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(tr('${i + 1}'), style: HerdText.chunky(13, extraBold: false, color: Herd.sage)),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: c.accentColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Text(tr('#${c.number}'), style: HerdText.chunky(14, extraBold: false, color: Herd.sageDark)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.current?.city ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: HerdText.body(14, color: Herd.ink),
                            ),
                          ),
                          Text(tr(note(c)), style: HerdText.body(12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
