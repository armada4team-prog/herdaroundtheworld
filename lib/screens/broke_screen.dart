import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../validation.dart';
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
  bool saving = false;
  String? whereError;
  String? chapterError;
  String? nicknameError;
  String? formError; // from The Herd's checker, when it isn't about one box

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

  bool get canSubmit => whereText.text.trim().isNotEmpty && nickname.text.trim().isNotEmpty && !saving;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final place = whereText.text.trim();
    setState(() {
      formError = null;
      whereError = checkPlaceFormat(place);
      chapterError = checkPublicText(chapter.text, maxLength: 500);
      nicknameError = checkNickname(nickname.text);
    });
    if (whereError != null || chapterError != null || nicknameError != null) return;
    setState(() => saving = true);
    final lookup = await Services.lookUpPlace(place);
    if (!mounted) return;
    if (lookup.status == PlaceStatus.notFound) {
      setState(() {
        saving = false;
        whereError = 'We couldn’t find that place. Check the spelling, like Lisbon, Portugal.';
      });
      return;
    }
    final result = await context.model.submitReport(
      widget.number,
      what: what.name,
      city: place,
      note: chapter.text.trim(),
      byName: nickname.text.trim(),
      sendPieces: what == _What.broke && sendHome,
    );
    if (!mounted) return;
    if (!result.ok) {
      final message = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
      setState(() {
        saving = false;
        switch (result.field) {
          case 'where':
            whereError = message;
          case 'note':
            chapterError = message;
          case 'nickname':
            nicknameError = message;
          default:
            formError = message;
        }
      });
      return;
    }
    setState(() {
      saving = false;
      sent = true;
    });
  }

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
        Text(tr('Thank you for telling us'), textAlign: TextAlign.center, style: HerdText.script(36)),
        const SizedBox(height: 6),
        Text(
          tr(what == _What.chipped
              ? 'We’ve noted the chip. $name can keep traveling.'
              : 'Everyone who followed $name will get a note, and their journey is kept safe on their page.'),
          textAlign: TextAlign.center,
          style: HerdText.body(16),
        ),
        const SizedBox(height: 18),
        HerdButton('Back to their page', onPressed: () => context.router.replaceTop(CompanionRoute(widget.number))),
      ];

  List<Widget> _form(String name) => [
        Eyebrow('Companion #${widget.number}'),
        const SizedBox(height: 4),
        Text(tr('Oh no, did something happen to $name?'), style: HerdText.script(36)),
        Text(tr('Clay is fragile, and accidents happen on the road. Thank you for letting everyone know. Every journey deserves an ending.'),
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
        HerdField(
            controller: whereText,
            hint: 'City, State or Country, like Lisbon, Portugal',
            errorText: whereError,
            onChanged: (_) => setState(() => whereError = null)),
        const SizedBox(height: 20),
        FieldLabel(what == _What.chipped ? 'Add a note (optional)' : 'Write their last chapter'),
        const SizedBox(height: 8),
        HerdField(
            controller: chapter,
            hint: 'What happened, and what did they mean to you?',
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            showCounter: true,
            errorText: chapterError,
            onChanged: (_) => setState(() => chapterError = null)),
        if (what == _What.broke) ...[
          const SizedBox(height: 20),
          HerdCard(color: Herd.mintSoft, children: [
            Text(tr('Want to send the pieces home?'), style: HerdText.chunky(18, extraBold: false, color: Herd.mintInk)),
            Text(tr('If you can, The Herd would love to have them back in the studio. We’ll email you how.'), style: HerdText.body(14, color: Herd.mintInk)),
            LabeledSwitch(label: 'Yes, tell me how', value: sendHome, onChanged: (v) => setState(() => sendHome = v)),
          ]),
        ],
        const SizedBox(height: 20),
        const FieldLabel('Your name or nickname *'),
        const SizedBox(height: 8),
        HerdField(
            controller: nickname,
            hint: 'Shown on their page',
            maxLength: 30,
            errorText: nicknameError,
            onChanged: (_) => setState(() => nicknameError = null)),
        if (what != _What.chipped) ...[
          const SizedBox(height: 12),
          Text(tr('Everyone who followed $name will get a note, and their page will show a Retired badge with their whole journey kept safe.'),
              style: HerdText.body(14)),
        ],
        const SizedBox(height: 18),
        if (formError != null) ...[ErrorNote(formError!), const SizedBox(height: 12)],
        HerdButton(
          what == _What.chipped ? 'Send the note' : 'Share their last chapter',
          onPressed: canSubmit ? submit : null,
        ),
      ];
}
