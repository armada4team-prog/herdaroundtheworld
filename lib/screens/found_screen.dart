import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/companion_figure.dart';
import '../widgets/here_card.dart';
import '../widgets/pieces.dart';

/// Step 1 of 2: "I found them" — a quick log so everyone knows the Companion is safe.
class FoundScreen extends StatefulWidget {
  const FoundScreen({super.key, required this.number});
  final String number;

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  HerePlace? here; // from the phone's location
  final nickname = TextEditingController();
  final email = TextEditingController();
  CheckIn checkIn = CheckIn.appAlert;
  bool alsoTellMe = true;
  bool done = false;
  bool? alreadyHolding; // checked once when the screen opens
  bool? needsCode;
  bool saving = false;
  String? cityError;
  String? nicknameError;
  String? emailError;
  bool triedToSend = false;
  final kWhere = GlobalKey(), kNickname = GlobalKey(), kCheckIn = GlobalKey();

  List<String> get problems => [cityError, nicknameError, emailError].whereType<String>().toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nickname.text.isEmpty) nickname.text = context.model.nickname;
    alreadyHolding ??= !context.model.canLogFind(widget.number);
    needsCode ??= !context.model.hasFindCode(widget.number);
  }

  @override
  void dispose() {
    nickname.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final where = here;
    setState(() {
      cityError = where == null ? 'We need your location to log a find.' : null;
      nicknameError = checkNickname(nickname.text);
      emailError = checkIn == CheckIn.email && !isEmail(email.text) ? 'Please enter a valid email, or choose another option.' : null;
    });
    if (where == null || nicknameError != null || emailError != null) {
      setState(() => triedToSend = true);
      scrollToFirstProblem([kWhere, kNickname, kCheckIn], [cityError != null, nicknameError != null, emailError != null]);
      return;
    }
    context.model.logFind(
      widget.number,
      city: where.city,
      nickname: nickname.text.trim(),
      checkIn: checkIn,
      email: checkIn == CheckIn.email ? email.text.trim() : null,
      point: where.blurred(exactish: false),
      exactPoint: where.point,
    );
    setState(() {
      saving = false;
      done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.model.companion(widget.number);
    final name = c?.displayName ?? '#${widget.number}';
    return Scaffold(
      appBar: herdAppBar(title: 'I found them'),
      body: needsCode == true && alreadyHolding != true && !done
          ? OutOfOrderView(
              companion: c,
              title: 'Scan {0}’s code first'.replaceAll('{0}', name),
              message: 'To log a find, scan the code on {0}’s bottom, or type their number and the 4-letter code printed under it. That’s how we know they’re really with you.'
                  .replaceAll('{0}', name),
              buttonLabel: 'Go to Scan →',
              onPressed: () {
                context.router.popToRoot();
                context.router.select(AppTab.scan);
              },
            )
          : alreadyHolding == true && !done
          ? OutOfOrderView(
              companion: c,
              title: '{0} is already with you'.replaceAll('{0}', name),
              message: 'You’ve already logged finding {0}. When you’re ready, pass them on so the next traveler can find them.'.replaceAll(
                '{0}',
                name,
              ),
              buttonLabel: 'Pass them on →',
              onPressed: () => context.router.replaceTop(PassOnRoute(widget.number)),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                scrollCacheExtent: const ScrollCacheExtent.pixels(10000), // keep the whole form built, so we can scroll to any problem
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                children: done ? _doneView(c, name) : _form(name),
              ),
            ),
    );
  }

  List<Widget> _form(String name) => [
    Eyebrow('Step 1 of 2 · Companion #${widget.number}'),
    const SizedBox(height: 4),
    Text(tr('You found $name!'), style: HerdText.script(40)),
    Text(
      tr('Let everyone know $name is safe with you. It takes a few seconds. You’ll log where they go next when you pass them on.'),
      style: HerdText.body(16),
    ),
    const SizedBox(height: 20),
    FieldLabel('Where are you? *', key: kWhere),
    const SizedBox(height: 8),
    HereCard(
      errorText: cityError,
      onChanged: (place) => setState(() {
        here = place;
        if (place != null) cityError = null;
      }),
    ),
    const SizedBox(height: 20),
    FieldLabel('Your name or nickname *', key: kNickname),
    const SizedBox(height: 8),
    HerdField(
      fieldKey: const Key('foundNickname'),
      controller: nickname,
      hint: 'Shown on their page',
      maxLength: 30,
      errorText: nicknameError,
      onChanged: (_) => setState(() => nicknameError = null),
      autofillHints: const [AutofillHints.nickname],
    ),
    const SizedBox(height: 20),
    FieldLabel('Want $name to check in with you?', key: kCheckIn),
    const SizedBox(height: 6),
    Text(tr('In about a month, $name will send one friendly nudge to help you pass them on. Totally optional.'), style: HerdText.body(14)),
    const SizedBox(height: 10),
    PillPicker<CheckIn>(
      options: const [(CheckIn.appAlert, 'App alert'), (CheckIn.email, 'Email'), (CheckIn.none, 'No thanks')],
      selected: checkIn,
      onChanged: (v) => setState(() => checkIn = v),
    ),
    const SizedBox(height: 10),
    if (checkIn == CheckIn.appAlert) Text(tr('We’ll send one gentle app alert in about a month. Nothing else.'), style: HerdText.body(13)),
    if (checkIn == CheckIn.email)
      HerdField(
        controller: email,
        hint: 'you@email.com',
        keyboardType: TextInputType.emailAddress,
        errorText: emailError,
        onChanged: (_) => setState(() => emailError = null),
      ),
    if (checkIn != CheckIn.none) ...[
      LabeledSwitch(
        label: 'Also tell me where #${widget.number} goes after me',
        value: alsoTellMe,
        onChanged: (v) => setState(() => alsoTellMe = v),
      ),
      Text(tr('Never shown publicly. Never shared.'), style: HerdText.body(13)),
    ],
    const SizedBox(height: 20),
    if (triedToSend && problems.isNotEmpty) ...[FixList(problems), const SizedBox(height: 12)],
    HerdButton(saving ? 'Logging…' : 'Log my find →', onPressed: saving ? null : submit),
  ];

  List<Widget> _doneView(Companion? c, String name) => [
    if (c != null) Center(child: CompanionBadge(companion: c, size: 120, waving: true, happy: true)),
    const SizedBox(height: 10),
    Text(tr('Logged! Enjoy your time together.'), textAlign: TextAlign.center, style: HerdText.script(36)),
    const SizedBox(height: 6),
    Text(
      tr('Take $name along for your trip. When you’re ready, scan them again and tap “I’m passing them on.”'),
      textAlign: TextAlign.center,
      style: HerdText.body(16),
    ),
    const SizedBox(height: 8),
    Text(
      tr('Leaving them somewhere? Take them at least 5 miles from here first. Handing them to someone is fine anywhere.'),
      textAlign: TextAlign.center,
      style: HerdText.body(16),
    ),
    const SizedBox(height: 18),
    HerdCard(
      spacing: 10,
      children: [
        Text(tr('Travel tips from $name'), style: HerdText.chunky(18, extraBold: false)),
        const NumberedRow('1', 'Snap a photo of me somewhere fun. It makes a great chapter.'),
        const NumberedRow('2', 'Keep me a little while, then send me on. A week or two is perfect.'),
      ],
    ),
    const SizedBox(height: 18),
    HerdButton('I’m passing them on now', onPressed: () => context.router.replaceTop(PassOnRoute(widget.number))),
    const SizedBox(height: 10),
    HerdButton('See their full story', kind: HerdButtonKind.outline, onPressed: () => context.router.replaceTop(StoryRoute(widget.number))),
  ];
}
