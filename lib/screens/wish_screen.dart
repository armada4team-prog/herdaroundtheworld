import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/companion_figure.dart';

/// "You made my wish come true!" — the traveler picks the next wish.
class WishScreen extends StatefulWidget {
  const WishScreen({super.key, required this.number});
  final String number;

  @override
  State<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  static const ideas = [
    'I want to ride a train.',
    'I want to meet a dog.',
    'I want to see snow.',
    'I want to go to a concert.',
    'I want to visit a library.',
    'I want to watch a sunrise.',
  ];
  String pick = ideas.first;
  final custom = TextEditingController();
  String? grantedWish;
  String? customError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    grantedWish ??= context.model.companion(widget.number)?.wish;
  }

  @override
  void dispose() {
    custom.dispose();
    super.dispose();
  }

  String get chosen => custom.text.trim().isEmpty ? pick : 'I want to ${custom.text.trim()}.';

  @override
  Widget build(BuildContext context) {
    final model = context.model;
    final c = model.companion(widget.number);
    final name = c?.displayName ?? '#${widget.number}';
    return Scaffold(
      appBar: herdAppBar(title: 'Wish granted'),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(color: Herd.butter, borderRadius: BorderRadius.circular(26)),
            child: Column(spacing: 10, children: [
              if (c != null) CompanionBadge(companion: c, size: 130, waving: true, happy: true),
              InfoPill('★ Wish granted · Companion #${widget.number}', foreground: Herd.butterInk),
              Text(tr('You made my wish come true!'), textAlign: TextAlign.center, style: HerdText.script(40)),
              Text(tr('“I wanted to $grantedWish.” Thanks to you, $name finally did. Everyone following them will hear the news.'),
                  textAlign: TextAlign.center, style: HerdText.body(16, color: Herd.ink)),
            ]),
          ),
          const SizedBox(height: 18),
          HerdCard(color: Herd.pinkSoft, children: [
            const Eyebrow('Your new stamp', color: Herd.pinkInk),
            Text(tr('Wish Granted'), style: HerdText.chunky(26, color: Herd.pinkInk)),
            Text(tr('A special stamp for your Passport, added after a quick look at your photo. Everyone following $name will see you made it happen.'),
                style: HerdText.body(15, color: Herd.pinkInk)),
          ]),
          const SizedBox(height: 20),
          Text(tr('You get to choose their next wish'), style: HerdText.chunky(22, extraBold: false, color: Herd.sageDark)),
          Text(tr('It goes on their page for the next traveler to try.'), style: HerdText.body(15)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final idea in ideas)
              Semantics(
                button: true,
                selected: pick == idea && custom.text.isEmpty,
                label: idea,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => setState(() {
                    pick = idea;
                    custom.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                    decoration: BoxDecoration(
                      color: pick == idea && custom.text.isEmpty ? Herd.mintSoft : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: pick == idea && custom.text.isEmpty ? Herd.sageDark : Herd.border, width: 2),
                    ),
                    child: Text(tr(idea), style: HerdText.body(15, color: Herd.ink)),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          const FieldLabel('Or write your own'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Herd.field, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text(tr('I want to'), style: HerdText.body(16, color: Herd.ink)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: custom,
                  maxLength: 50,
                  onChanged: (_) => setState(() => customError = null),
                  style: HerdText.body(16, color: Herd.ink),
                  decoration: const InputDecoration(border: InputBorder.none, counterText: '', hintText: '…'),
                ),
              ),
              Text(tr('${custom.text.length}/50'), style: HerdText.body(13)),
            ]),
          ),
          if (customError != null) ...[
            const SizedBox(height: 6),
            Text(tr(customError!), style: HerdText.body(13, color: const Color(0xFFB3261E))),
          ],
          const SizedBox(height: 6),
          Text(tr('Keep it kind, safe and doable. Wishes are checked automatically, then The Herd gives them a quick look. Until it’s approved, their page shows a wish from the list.'),
              style: HerdText.body(13)),
          const SizedBox(height: 16),
          HerdCard(children: [
            const Eyebrow('On their page'),
            Text(tr('Next wish: “$chosen”'), style: HerdText.script(24)),
            Text(tr('Wish chosen by ${model.nickname.isEmpty ? 'you' : model.nickname}, who granted their last one.'), style: HerdText.body(14)),
          ]),
          const SizedBox(height: 18),
          HerdButton('Set their next wish →', onPressed: () {
            if (custom.text.trim().isNotEmpty) {
              final error = checkPublicText(custom.text, maxLength: 50);
              if (error != null) {
                setState(() => customError = error);
                return;
              }
            }
            // List wishes go live right away. A custom wish waits for The Herd's approval,
            // so the selected list wish shows on their page until then.
            model.setNextWish(widget.number, pick);
            context.router.replaceTop(SentRoute(widget.number));
          }),
        ],
      ),
    );
  }
}
