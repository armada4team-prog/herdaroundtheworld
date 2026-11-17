import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
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
              Text(model.nickname.isEmpty ? 'Hi there!' : 'Hi, ${model.nickname}!', style: HerdText.script(40)),
              const SizedBox(height: 4),
              Text(_movedSentence(model), style: HerdText.body(16)),
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
                TextButton(onPressed: () => router.select(AppTab.map), child: Text('See map', style: HerdText.body(14, color: Herd.sageDark))),
              ]),
              if (model.followed.isEmpty) Text('Follow a Companion from their page to see their news here.', style: HerdText.body(14)),
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
              SizedBox(
                height: 225,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _sighting(context, '#07 arrived in Santa Fe', '“On a café windowsill, watching the street.”', Herd.mintSoft, '07'),
                  const SizedBox(width: 12),
                  _sighting(context, '#2’s wish came true!', 'They saw the ocean in Lisbon.', Herd.butter, '2'),
                ]),
              ),
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
              HerdCard(color: Herd.pinkSoft, children: [
                Text('Two new stamps!', style: HerdText.chunky(22, color: Herd.pinkInk)),
                Text('You passed #3 on and granted their wish. Both stamps are in your Passport now.', style: HerdText.body(14, color: Herd.pinkInk)),
                HerdButton('See my Passport', expand: false, onPressed: () => router.select(AppTab.passport)),
              ]),
              const SizedBox(height: 22),
              const ScriptHeading('Companions on Instagram'),
              const SizedBox(height: 10),
              Row(spacing: 8, children: [
                _tile('#07 in Santa Fe', Herd.mintSoft),
                _tile('#3 in Tokyo', Herd.pinkSoft),
                _tile('#2 in Lisbon', Herd.butter),
              ]),
              const SizedBox(height: 10),
              Text.rich(TextSpan(style: HerdText.body(14, color: Herd.ink), children: [
                const TextSpan(text: 'Mention '),
                TextSpan(text: '@growtheherdstudio', style: HerdText.body(14, weight: FontWeight.w600, color: Herd.ink)),
                const TextSpan(text: ' in your story and we’ll reshare it.'),
              ])),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                onPressed: () => Services.open('https://www.instagram.com/growtheherdstudio/'),
                child: Text('Follow @growtheherdstudio', style: HerdText.body(14, weight: FontWeight.w500, color: Herd.sageDark)),
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
              Text(label, style: HerdText.body(12, color: fg)),
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
                  Text(c.wishGranted ? 'Wish granted!' : 'Just arrived in ${c.current?.city ?? 'somewhere new'}', style: HerdText.body(14, color: Herd.ink)),
                  Text('${c.lastMoved} · ${c.stopCount} stops', style: HerdText.body(12)),
                ]),
              ),
              if (c.movedThisWeek)
                Semantics(label: 'New', child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Herd.rose, shape: BoxShape.circle))),
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
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 6),
              child: CompanionFigure(glaze: c.glazeColor, showsShadow: false, height: 62),
            ),
            Text(c.label, style: HerdText.chunky(15, extraBold: false, color: Herd.sageDark)),
            Text(c.current?.city ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: HerdText.body(12)),
          ]),
        ),
      );

  Widget _sighting(BuildContext context, String title, String text, Color color, String number) => GestureDetector(
        onTap: () => context.router.push(CompanionRoute(number)),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Herd.sage, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            PhotoPlaceholder(color: color, height: 110),
            Text(title, style: HerdText.chunky(15, extraBold: false, color: Herd.sageDark)),
            Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: HerdText.body(13, color: Herd.ink)),
          ]),
        ),
      );

  Widget _tile(String text, Color color) => Expanded(
        child: Container(
          height: 100,
          color: color,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Text(text, textAlign: TextAlign.center, style: HerdText.body(12, color: Herd.ink)),
        ),
      );
}
