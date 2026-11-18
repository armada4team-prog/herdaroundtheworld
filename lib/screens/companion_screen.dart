import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/companion_figure.dart';
import '../widgets/journey_map.dart';
import '../widgets/pieces.dart';

/// One page per Companion. A scan opens it with the hello card on top.
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key, required this.number, this.startWithHello = false});
  final String number;
  final bool startWithHello;

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  late bool showHello = widget.startWithHello;

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      appBar: herdAppBar(),
      body: ModelBuilder(
        builder: (context, model) {
          final c = model.companion(widget.number);
          if (c == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('We couldn’t find #${widget.number}. Check the number on their bottom and try again.'),
                  textAlign: TextAlign.center,
                  style: HerdText.body(16),
                ),
              ),
            );
          }
          final retired = c.status == CompanionStatus.retired;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      CompanionBadge(companion: c, size: 104, waving: true),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Eyebrow('Art in Transit · No. ${c.number}'),
                            Text(c.displayName, style: HerdText.script(40)),
                            InfoPill(c.status.label, background: retired ? hex('F8DCC8') : Herd.mintSoft),
                          ],
                        ),
                      ),
                      Column(
                        spacing: 8,
                        children: [
                          CircleIconButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            size: 40,
                            onTap: () => SharePlus.instance.share(
                              ShareParams(
                                text: 'Follow Companion #${c.number} around the world with The Herd: ${c.shareUrl}',
                                subject: 'Companion #${c.number}',
                              ),
                            ),
                          ),
                          CircleIconButton(
                            icon: Icons.info_outline,
                            label: 'About #${c.number}',
                            size: 40,
                            onTap: () => setState(() => showHello = true),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      InfoPill('${c.stopCount} stops', background: Herd.beige),
                      InfoPill('${formatThousands(c.miles)} miles', background: Herd.butter, foreground: Herd.butterInk),
                      InfoPill('${c.travelers} travelers', background: Herd.beige),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WishCard(wish: c.wishSentence, granted: c.wishGranted),
                  const SizedBox(height: 16),
                  JourneyMap(companion: c),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text(tr('Live · updated ${c.lastMoved}'), style: HerdText.body(13))),
                      TextButton(
                        onPressed: () => router.select(AppTab.map),
                        child: Text(
                          tr('World map →'),
                          style: HerdText.body(13, weight: FontWeight.w500, color: Herd.sageDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!retired) ...[
                    // Logging a find needs their secret code (scanned, or typed on the Scan tab).
                    if (model.hasFindCode(c.number))
                      HerdButton('I just found them', onPressed: () => router.push(FoundRoute(c.number)))
                    else if (!model.holding.contains(c.number))
                      HerdButton('Found them? Scan their code', onPressed: () => router.select(AppTab.scan)),
                    if (model.holding.contains(c.number)) ...[
                      const SizedBox(height: 10),
                      HerdButton('Pass them on', kind: HerdButtonKind.soft, onPressed: () => router.push(PassOnRoute(c.number))),
                    ],
                    const SizedBox(height: 6),
                  ],
                  LabeledSwitch(
                    label: 'Following · notify me when they move',
                    value: model.following.contains(c.number),
                    onChanged: (_) => model.toggleFollow(c.number),
                  ),
                  const SizedBox(height: 14),
                  const ScriptHeading('Where they’ve been'),
                  const SizedBox(height: 10),
                  for (var i = c.stops.length - 1; i >= 0; i--) _stopRow(c.stops[i], i + 1, i == c.stops.length - 1),
                  const SizedBox(height: 16),
                  LinkRow(
                    title: 'Their story · ${c.stops.where((s) => s.note != null).length + 1} chapters',
                    subtitle: 'Read every traveler’s chapter and the chat',
                    onTap: () => router.push(StoryRoute(c.number)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => showHello = true),
                        child: Text(tr('About #${c.number}'), style: HerdText.body(14, color: Herd.sageDark)),
                      ),
                      const Spacer(),
                      if (!retired)
                        TextButton(
                          onPressed: () => router.push(BrokeRoute(c.number)),
                          child: Text(tr('Something happened to them?'), style: HerdText.body(14, color: Herd.sageDark)),
                        ),
                    ],
                  ),
                ],
              ),
              if (showHello) HelloCard(companion: c, onClose: () => setState(() => showHello = false)),
            ],
          );
        },
      ),
    );
  }

  Widget _stopRow(Stop stop, int number, bool isNow) {
    final parts = [
      if (isNow) 'Now',
      if (stop.place != null) stop.place!,
      if (stop.leftBy != null) 'left by ${stop.leftBy}',
      if (stop.when.isNotEmpty) stop.when,
    ];
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isNow ? Herd.rose : Herd.mintSoft, shape: BoxShape.circle),
              child: Text(tr('$number'), style: HerdText.chunky(14, extraBold: false, color: isNow ? Colors.white : Herd.ink)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    stop.city,
                    style: HerdText.body(16, weight: FontWeight.w500, color: Herd.ink),
                  ),
                  Text(parts.join(' · '), style: HerdText.body(13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card a finder sees right after scanning.
class HelloCard extends StatelessWidget {
  const HelloCard({super.key, required this.companion, required this.onClose});
  final Companion companion;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = companion;
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: Herd.ink.withValues(alpha: 0.35)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Herd.cream, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  spacing: 12,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: CircleIconButton(icon: Icons.close, label: 'Close', color: Herd.field, size: 36, onTap: onClose),
                    ),
                    CompanionBadge(companion: c, size: 104, waving: true, happy: true),
                    Eyebrow('Art in Transit · No. ${c.number}'),
                    Text(tr('Hi, I’m ${c.displayName}!'), textAlign: TextAlign.center, style: HerdText.script(38)),
                    Text(c.blurb, textAlign: TextAlign.center, style: HerdText.body(15)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Herd.butter, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          const Eyebrow('My wish', color: Herd.butterInk),
                          Text(tr('“${c.wishSentence}”'), style: HerdText.script(22, color: Herd.wishInk)),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        InfoPill('${c.stopCount} stops', background: Herd.beige),
                        InfoPill('Last seen in ${c.current?.city ?? ''}', background: Herd.beige),
                      ],
                    ),
                    HerdCard(
                      spacing: 10,
                      children: [
                        const Eyebrow('How this works'),
                        const NumberedRow('1', 'Take me along for a while, and help my wish come true if you can!'),
                        const NumberedRow('2', 'Leave me somewhere new for someone else to find.'),
                        const NumberedRow('3', 'Log the spot and add your chapter to my story.'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Herd.pinkSoft, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            tr('Log where you leave me and earn a stamp in your Passport.'),
                            style: HerdText.body(14, color: Herd.pinkInk),
                          ),
                        ),
                      ],
                    ),
                    HerdButton('See where I’ve been ↓', onPressed: onClose),
                    Text.rich(
                      TextSpan(
                        style: HerdText.body(13),
                        children: [
                          TextSpan(text: tr('You’ve found a piece of ')),
                          TextSpan(
                            text: tr('Art in Transit'),
                            style: HerdText.body(13, weight: FontWeight.w600),
                          ),
                          TextSpan(text: tr(', a traveling art project by The Herd. No app, no sign-up, no cost.')),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
