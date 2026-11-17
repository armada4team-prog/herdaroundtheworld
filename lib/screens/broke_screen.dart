import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/pieces.dart';

enum _What { broke, chipped, lost }

/// "Something happened" — broke, chipped or lost. Every journey deserves an ending.
class BrokeScreen extends StatefulWidget {
  const BrokeScreen({super.key, required this.number});
  final String number;

  @override
  State<BrokeScreen> createState() => _BrokeScreenState();
}

class _BrokeScreenState extends State<BrokeScreen> {
  _What what = _What.broke;
  final whereText = TextEditingController();
  final chapter = TextEditingController();
  final nickname = TextEditingController();
  bool sendHome = true;
  bool sent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nickname.text.isEmpty) nickname.text = context.model.nickname;
  }

  @override
  void dispose() {
    whereText.dispose();
    chapter.dispose();
    nickname.dispose();
    super.dispose();
  }

  bool get canSubmit => whereText.text.trim().isNotEmpty && nickname.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.model.companion(widget.number);
    final name = c?.displayName ?? '#${widget.number}';
    return Scaffold(
      appBar: herdAppBar(title: 'Something happened'),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        children: sent ? _thanks(name) : _form(name),
      ),
    );
  }

  List<Widget> _thanks(String name) => [
        const SizedBox(height: 20),
        const Icon(Icons.favorite, size: 36, color: Herd.rose),
        const SizedBox(height: 10),
        Text('Thank you for telling us', textAlign: TextAlign.center, style: HerdText.script(36)),
        const SizedBox(height: 6),
        Text(
          what == _What.chipped
              ? 'We’ve noted the chip. $name can keep traveling.'
              : 'Everyone who followed $name will get a note, and their journey is kept safe on their page.',
          textAlign: TextAlign.center,
          style: HerdText.body(16),
        ),
        const SizedBox(height: 18),
        HerdButton('Back to their page', onPressed: () => context.router.replaceTop(CompanionRoute(widget.number))),
      ];

  List<Widget> _form(String name) => [
        Eyebrow('Companion #${widget.number}'),
        const SizedBox(height: 4),
        Text('Oh no, did something happen to $name?', style: HerdText.script(36)),
        Text('Clay is fragile, and accidents happen on the road. Thank you for letting everyone know. Every journey deserves an ending.',
            style: HerdText.body(16)),
        const SizedBox(height: 20),
        const FieldLabel('What happened? *'),
        const SizedBox(height: 10),
        ChoiceCard(title: 'They broke', detail: 'Their journey ends here.', selected: what == _What.broke, onTap: () => setState(() => what = _What.broke)),
        const SizedBox(height: 10),
        ChoiceCard(
            title: 'They got chipped, but can keep traveling',
            detail: 'Their journey continues.',
            selected: what == _What.chipped,
            onTap: () => setState(() => what = _What.chipped)),
        const SizedBox(height: 10),
        ChoiceCard(
            title: 'They got lost', detail: 'Their journey ends where they were last seen.', selected: what == _What.lost, onTap: () => setState(() => what = _What.lost)),
        const SizedBox(height: 20),
        const FieldLabel('Where? *'),
        const SizedBox(height: 8),
        HerdField(controller: whereText, hint: 'A city, like Lisbon, Portugal', onChanged: (_) => setState(() {})),
        const SizedBox(height: 20),
        FieldLabel(what == _What.chipped ? 'Add a note (optional)' : 'Write their last chapter'),
        const SizedBox(height: 8),
        HerdField(controller: chapter, hint: 'What happened, and what did they mean to you?', minLines: 3, maxLines: 6),
        if (what == _What.broke) ...[
          const SizedBox(height: 20),
          HerdCard(color: Herd.mintSoft, children: [
            Text('Want to send the pieces home?', style: HerdText.chunky(18, extraBold: false, color: Herd.mintInk)),
            Text('If you can, The Herd would love to have them back in the studio. We’ll email you how.', style: HerdText.body(14, color: Herd.mintInk)),
            LabeledSwitch(label: 'Yes, tell me how', value: sendHome, onChanged: (v) => setState(() => sendHome = v)),
          ]),
        ],
        const SizedBox(height: 20),
        const FieldLabel('Your name or nickname *'),
        const SizedBox(height: 8),
        HerdField(controller: nickname, hint: 'Shown on their page', onChanged: (_) => setState(() {})),
        if (what != _What.chipped) ...[
          const SizedBox(height: 12),
          Text('Everyone who followed $name will get a note, and their page will show a Retired badge with their whole journey kept safe.',
              style: HerdText.body(14)),
        ],
        const SizedBox(height: 18),
        HerdButton(
          what == _What.chipped ? 'Send the note' : 'Share their last chapter',
          onPressed: canSubmit
              ? () {
                  context.model.reportBroken(widget.number, chipped: what == _What.chipped);
                  setState(() => sent = true);
                }
              : null,
        ),
      ];
}
