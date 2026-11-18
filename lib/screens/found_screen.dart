import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../services.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';

/// Step 1 of 2: "I found them" — a quick log so everyone knows the Companion is safe.
class FoundScreen extends StatefulWidget {
  const FoundScreen({super.key, required this.number});
  final String number;

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  final city = TextEditingController();
  final nickname = TextEditingController();
  final email = TextEditingController();
  CheckIn checkIn = CheckIn.appAlert;
  bool alsoTellMe = true;
  bool done = false;
  bool? alreadyHolding; // checked once when the screen opens
  bool locating = false;
  bool saving = false;
  String? cityError;
  String? nicknameError;
  String? emailError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nickname.text.isEmpty) nickname.text = context.model.nickname;
    alreadyHolding ??= !context.model.canLogFind(widget.number);
  }

  @override
  void dispose() {
    city.dispose();
    nickname.dispose();
    email.dispose();
    super.dispose();
  }

  bool get canSubmit => city.text.trim().isNotEmpty && nickname.text.trim().isNotEmpty && !saving;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final place = city.text.trim();
    setState(() {
      cityError = checkPlaceFormat(place);
      nicknameError = checkNickname(nickname.text);
      emailError = checkIn == CheckIn.email && !isEmail(email.text) ? 'Please enter a valid email, or choose another option.' : null;
    });
    if (cityError != null || nicknameError != null || emailError != null) return;
    setState(() => saving = true);
    final lookup = await Services.lookUpPlace(place);
    if (!mounted) return;
    if (lookup.status == PlaceStatus.notFound) {
      setState(() {
        saving = false;
        cityError = 'We couldn’t find that place. Check the spelling, like Santa Fe, NM.';
      });
      return;
    }
    context.model.logFind(
      widget.number,
      city: place,
      nickname: nickname.text.trim(),
      checkIn: checkIn,
      email: checkIn == CheckIn.email ? email.text.trim() : null,
      point: lookup.point,
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
      body: alreadyHolding == true && !done
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
    const FieldLabel('Where are you? *'),
    const SizedBox(height: 8),
    HerdField(
      fieldKey: const Key('foundCity'),
      controller: city,
      hint: 'City, State or Country, like Santa Fe, NM',
      errorText: cityError,
      onChanged: (_) => setState(() => cityError = null),
      autofillHints: const [AutofillHints.addressCity],
    ),
    const SizedBox(height: 8),
    Align(
      alignment: Alignment.centerLeft,
      child: softChip(
        locating ? 'Finding your city…' : 'Use my city',
        Icons.near_me_outlined,
        locating
            ? null
            : () async {
                setState(() => locating = true);
                final found = await Services.currentCity();
                if (!mounted) return;
                setState(() {
                  if (found != null) city.text = found;
                  locating = false;
                });
              },
      ),
    ),
    const SizedBox(height: 20),
    const FieldLabel('Your name or nickname *'),
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
    FieldLabel('Want $name to check in with you?'),
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
    HerdButton(saving ? 'Logging…' : 'Log my find →', onPressed: canSubmit ? submit : null),
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
