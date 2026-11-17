import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
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

  @override
  void dispose() {
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void select(Companion c) {
    setState(() {
      selected = c.number;
      filter = MapFilter.all;
    });
    final points = [for (final s in c.stops) s.point];
    if (points.length > 1) {
      mapController.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(50, 190, 50, 260), maxZoom: 7));
    } else if (points.isNotEmpty) {
      mapController.move(points.first, 6);
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
      body: ModelBuilder(builder: (context, model) {
        final visible = model.companions.where((c) => model.matches(c, filter)).toList();
        final sel = selected == null ? null : model.companion(selected!);
        return Stack(children: [
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
              MarkerLayer(markers: [
                if (sel != null)
                  for (final s in sel.stops.take(sel.stops.length - 1))
                    Marker(point: s.point, width: 10, height: 10, child: MapDot(color: sel.accentColor, size: 10, faded: true)),
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
                          child: Center(child: MapDot(color: c.accentColor, size: c.number == selected ? 18 : 12)),
                        ),
                      ),
                    ),
              ]),
            ],
          ),
          SafeArea(child: herdAttribution(alignment: Alignment.topRight, margin: const EdgeInsets.fromLTRB(0, 116, 16, 0))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
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
                      return FilterPill(filter: f, selected: filter == f, onTap: () => setState(() {
                        filter = f;
                        selected = null;
                      }));
                    },
                  ),
                ),
                Row(children: [
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
                          child: Row(children: [
                            const Icon(Icons.zoom_out_map, size: 16, color: Herd.ink),
                            const SizedBox(width: 6),
                            Text('Whole world', style: HerdText.body(14, color: Herd.ink)),
                          ]),
                        ),
                      ),
                    ),
                  const Spacer(),
                  InfoPill('${visible.length} Companions'),
                ]),
              ]),
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: sel != null ? _selectedCard(context, sel) : _mostActive(model)),
        ]);
      }),
    );
  }

  Widget _searchBar(AppModel model) => Material(
        color: Herd.cream,
        shape: const StadiumBorder(),
        elevation: 3,
        shadowColor: Herd.ink.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
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
              TextButton(onPressed: () => find(model), child: Text('Go', style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark))),
          ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
          Row(children: [
            CompanionBadge(companion: c, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                Text(c.label, style: HerdText.chunky(18, extraBold: false, color: Herd.sageDark)),
                Text('${c.current?.city ?? ''} · ${c.lastMoved}', style: HerdText.body(13)),
                Text('Wish: ${c.wish}', style: HerdText.body(13, color: Herd.butterInk)),
              ]),
            ),
          ]),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _legend(c.accentColor.withValues(alpha: 0.6), 'Where they’ve been'),
            _legend(c.accentColor, 'Where #${c.number} is now'),
          ]),
          HerdButton('Open their page', onPressed: () => context.router.push(CompanionRoute(c.number))),
        ]),
      );

  Widget _legend(Color color, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: HerdText.body(12, color: Herd.ink)),
      ]);

  Widget _mostActive(AppModel model) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Herd.cream,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Herd.ink.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: hex('DCDDD6'), borderRadius: BorderRadius.circular(999))),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            const ScriptHeading('Most active', size: 26),
            const Spacer(),
            Text('${model.companions.length} Companions', style: HerdText.body(12)),
          ]),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: model.mostActive.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: Herd.line),
              itemBuilder: (context, i) {
                final c = model.mostActive[i];
                return InkWell(
                  onTap: () => select(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      SizedBox(width: 22, child: Text('${i + 1}', style: HerdText.chunky(13, extraBold: false, color: Herd.sage))),
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: c.accentColor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text('#${c.number}', style: HerdText.chunky(14, extraBold: false, color: Herd.sageDark)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.current?.city ?? '', overflow: TextOverflow.ellipsis, style: HerdText.body(14, color: Herd.ink))),
                      Text('${c.stopCount} stops', style: HerdText.body(12)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
}
