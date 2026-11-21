import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';
import 'info_screens.dart';

/// The Herd tab: greeting, your numbers, who you follow, the Originals, latest sightings and Instagram.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      body: SafeArea(
        child: ModelBuilder(
          builder: (context, model) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Row(children: [
                const Wordmark(),
                const Spacer(),
                CircleIconButton(icon: Icons.question_mark, label: 'How it works', onTap: () => router.push(const LearnRoute()), size: 40),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Language',
                  excludeSemantics: true,
                  child: Material(
                    color: Herd.field,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => showLanguagePicker(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(children: [
                          const Icon(Icons.language, size: 18, color: Herd.mintInk),
                          const SizedBox(width: 6),
                          Text(model.language.toUpperCase(), style: HerdText.body(14, color: Herd.mintInk)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Text(tr(model.nickname.isEmpty ? 'Hi there!' : 'Hi, ${model.nickname}!'), style: HerdText.script(40)),
              const SizedBox(height: 4),
              Text(tr(_movedSentence(model)), style: HerdText.body(16)),
              const SizedBox(height: 18),
              Row(spacing: 10, children: [
                _stat('${model.companionsCarried}', 'Companions carried', Herd.mintSoft, Herd.mintInk),
                _stat('${model.wishesGranted}', model.wishesGranted == 1 ? 'Wish granted' : 'Wishes granted', Herd.butter, Herd.butterInk),
                _stat('${model.herdSize}', 'Travelers in your herd', Herd.pinkSoft, Herd.pinkInk),
              ]),
              const SizedBox(height: 22),
              Row(children: [
                const ScriptHeading('Following'),
                const Spacer(),
                TextButton(onPressed: () => router.select(AppTab.map), child: Text(tr('See map'), style: HerdText.body(14, color: Herd.sageDark))),
              ]),
              if (model.followed.isEmpty) Text(tr('Follow a Companion from their page to see their news here.'), style: HerdText.body(14)),
              for (final c in model.followed) ...[_followedCard(context, c), const SizedBox(height: 10)],
              const SizedBox(height: 12),
              const ScriptHeading('Meet the Originals'),
              const SizedBox(height: 10),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: model.originals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _originalCard(context, model.originals[i]),
                ),
              ),
              const SizedBox(height: 22),
              const ScriptHeading('Latest sightings'),
              const SizedBox(height: 10),
              Builder(builder: (context) {
                final sightings = _latestSightings(model.companions);
                if (sightings.isEmpty) {
                  return Text(tr('No sightings yet. Be the first to find a Companion!'), style: HerdText.body(14));
                }
                return SizedBox(
                  height: 225,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sightings.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _sighting(context, sightings[i].$1, sightings[i].$2),
                  ),
                );
              }),
              const SizedBox(height: 22),
              LinkRow(
                title: 'How it works & where to pass one on',
                subtitle: 'Wishes, stamps, good spots and places to avoid',
                onTap: () => router.push(const LearnRoute()),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Herd.mintSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.place_outlined, color: Herd.mintInk),
                ),
              ),
              const SizedBox(height: 22),
              _stampsCard(model, router),
              const SizedBox(height: 22),
              const ScriptHeading('Companions on Instagram'),
              const SizedBox(height: 6),
              Text.rich(TextSpan(style: HerdText.body(14, color: Herd.ink), children: [
                TextSpan(text: tr('Mention ')),
                TextSpan(text: tr('@growtheherdstudio'), style: HerdText.body(14, weight: FontWeight.w600, color: Herd.ink)),
                TextSpan(text: tr(' in your story and we’ll reshare it.')),
              ])),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                onPressed: () => Services.open('https://www.instagram.com/growtheherdstudio/'),
                child: Text(tr('Follow @growtheherdstudio'), style: HerdText.body(14, weight: FontWeight.w500, color: Herd.sageDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _movedSentence(AppModel model) {
    final n = model.followed.where((c) => c.movedThisWeek).length;
    const words = ['No', 'One', 'Two', 'Three', 'Four', 'Five'];
    final count = n < words.length ? words[n] : '$n';
    return 'Your herd is on the move. $count Companion${n == 1 ? '' : 's'} you follow moved this week.';
  }

  Widget _stat(String number, String label, Color bg, Color fg) => Expanded(
        child: MergeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(number, style: HerdText.chunky(26, color: fg)),
              Text(tr(label), style: HerdText.body(12, color: fg)),
            ]),
          ),
        ),
      );

  Widget _followedCard(BuildContext context, Companion c) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Herd.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.router.push(CompanionRoute(c.number)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CompanionBadge(companion: c, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(c.label, style: HerdText.chunky(17, extraBold: false, color: Herd.sageDark)),
                  Text(tr(c.wishGranted ? 'Wish granted!' : 'Just arrived in ${c.current?.city ?? 'somewhere new'}'), style: HerdText.body(14, color: Herd.ink)),
                  Text(tr('${c.lastMoved} · ${c.stopCount} stops'), style: HerdText.body(12)),
                ]),
              ),
              if (c.movedThisWeek)
                Semantics(label: tr('New'), child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Herd.rose, shape: BoxShape.circle))),
            ]),
          ),
        ),
      );

  Widget _originalCard(BuildContext context, Companion c) => GestureDetector(
        onTap: () => context.router.push(CompanionRoute(c.number)),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Herd.sage, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
            Container(
              height: 90,
              width: double.infinity,
              color: c.blobColor,
              alignment: c.profilePhoto == null ? Alignment.bottomCenter : Alignment.center,
              padding: EdgeInsets.only(bottom: c.profilePhoto == null ? 6 : 0),
              child: c.profilePhoto == null
                  ? CompanionFigure(glaze: c.glazeColor, showsShadow: false, height: 62)
                  : Image.network(c.profilePhoto!, width: double.infinity, height: 90, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => CompanionFigure(glaze: c.glazeColor, showsShadow: false, height: 62)),
            ),
            Text(c.label, style: HerdText.chunky(15, extraBold: false, color: Herd.sageDark)),
            Text(c.current?.city ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: HerdText.body(12)),
          ]),
        ),
      );

  /// Your stamps so far: what you've earned, or how to earn your first one.
  Widget _stampsCard(AppModel model, dynamic router) {
    final passed = <String>[];
    for (final st in model.stamps.reversed) {
      if (st.big.startsWith('#') && !passed.contains(st.big)) passed.add(st.big);
    }
    final wishes = model.wishesGranted;
    final total = model.stamps.length;
    final String title;
    final String body;
    if (total == 0) {
      title = 'Earn stamps';
      body = 'Pass a Companion on or help a wish come true, and your stamps will be added to your Passport.';
    } else {
      title = total == 1 ? '1 stamp in your Passport!' : '$total stamps in your Passport!';
      final who = passed.join(' & ');
      final one = total == 1;
      if (passed.isNotEmpty && wishes > 0) {
        body = wishes == 1
            ? 'You passed $who on and granted 1 wish. They’re in your Passport now.'
            : 'You passed $who on and granted $wishes wishes. They’re in your Passport now.';
      } else if (passed.isNotEmpty) {
        body = one ? 'You passed $who on. It’s in your Passport now.' : 'You passed $who on. They’re in your Passport now.';
      } else {
        body = wishes == 1 ? 'You granted 1 wish. It’s in your Passport now.' : 'You granted $wishes wishes. They’re in your Passport now.';
      }
    }
    return HerdCard(color: Herd.pinkSoft, children: [
      Text(tr(title), style: HerdText.chunky(22, color: Herd.pinkInk)),
      Text(tr(body), style: HerdText.body(14, color: Herd.pinkInk)),
      HerdButton('See my Passport', expand: false, onPressed: () => router.select(AppTab.passport)),
    ]);
  }

  /// The newest finds and stops across every Companion (newest first), from the live lists.
  static List<(Companion, Stop)> _latestSightings(List<Companion> companions, {int max = 8}) {
    final all = <(Companion, Stop, int)>[];
    for (final c in companions) {
      for (var i = 0; i < c.stops.length; i++) {
        if (c.stops[i].kind != 'made') all.add((c, c.stops[i], i));
      }
    }
    all.sort((a, b) {
      final da = a.$2.date, db = b.$2.date;
      if (da != null && db != null) return db.compareTo(da);
      if (da != null) return -1;
      if (db != null) return 1;
      return b.$3.compareTo(a.$3); // no dates (sample data): later stops first
    });
    return all.take(max).map((e) => (e.$1, e.$2)).toList();
  }

  Widget _sighting(BuildContext context, Companion c, Stop stop) {
    final title = stop.kind == 'found' ? '${c.label} was found in ${stop.city}' : '${c.label} arrived in ${stop.city}';
    final text = stop.note != null && stop.note!.trim().isNotEmpty
        ? '“${stop.note!.trim()}”'
        : [stop.byLine, stop.when].whereType<String>().where((x) => x.isNotEmpty).map(tr).join(' · ');
    final photo = stop.photoUrl;
    final drawing = Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(color: c.blobColor, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: CompanionFigure(glaze: c.glazeColor, showsShadow: false, height: 78),
    );
    return Semantics(
      button: true,
      label: tr(title),
      child: GestureDetector(
        onTap: () => context.router.push(CompanionRoute(c.number)),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Herd.sage, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            photo == null
                ? drawing
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(photo, height: 110, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => drawing),
                  ),
            Text(tr(title), maxLines: 1, overflow: TextOverflow.ellipsis, style: HerdText.chunky(15, extraBold: false, color: Herd.sageDark)),
            Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: HerdText.body(13, color: Herd.ink)),
          ]),
        ),
      ),
    );
  }
}
