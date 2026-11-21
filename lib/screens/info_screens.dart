import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../services.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';

/// How it works, where to pass one on, places to avoid, wishes and stamps, Instagram.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _steps = [
    ('Find one', Icons.search, Herd.pink, 'Spot a little clay Companion on a shelf, a windowsill or a café table.'),
    ('Meet them', Icons.qr_code_scanner, Herd.mintSoft, 'Scan the code on their bottom to see their number, wish and journey.'),
    ('Travel together', Icons.place_outlined, Herd.butter, 'Carry them a while, help their wish come true, and add your chapter.'),
    ('Pass them on', Icons.redo, Herd.sageBackground, 'Hand them to a fellow traveler or leave them somewhere new, then log the spot.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: herdAppBar(title: 'How it works', actions: [
        IconButton(tooltip: 'Language', icon: const Icon(Icons.language), onPressed: () => showLanguagePicker(context)),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Eyebrow('Art in Transit · Children of the clay'),
        const SizedBox(height: 6),
        Text(tr('Find one. Carry one. Watch them go.'), style: HerdText.script(38)),
        Text(tr('Companions are tiny travelers handmade by The Herd. Every traveler they meet becomes part of their story.'), style: HerdText.body(16)),
        const SizedBox(height: 20),
        for (final (title, icon, color, body) in _steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Blob(color: color, width: 52, height: 52, variant: title.length, child: Icon(icon, color: Herd.ink)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr(title), style: HerdText.chunky(18, extraBold: false, color: Herd.sageDark)),
                  Text(tr(body), style: HerdText.body(15, color: Herd.ink)),
                ]),
              ),
            ]),
          ),
        const ScriptHeading('How to pass one on', size: 32),
        const SizedBox(height: 10),
        HerdCard(children: [
          Text(tr('Best of all: hand them on'), style: HerdText.chunky(18, extraBold: false)),
          Text(tr('Give your Companion to a fellow traveler: a new friend, a host, someone heading somewhere fun.'), style: HerdText.body(15)),
        ]),
        const SizedBox(height: 10),
        HerdCard(color: Herd.mintSoft, children: [
          Text(tr('Or leave them somewhere'), style: HerdText.chunky(18, extraBold: false, color: Herd.mintInk)),
          Text(tr('Cafés, hostels, hotel lobbies, bookstores, libraries, or near a monument.'), style: HerdText.body(15, color: Herd.mintInk)),
        ]),
        const SizedBox(height: 10),
        HerdCard(color: Herd.pinkSoft, children: [
          Text(tr('Please don’t'), style: HerdText.chunky(18, extraBold: false, color: Herd.pinkInk)),
          Text(tr('Airport security areas, trails and parks (leave no trace), private property, or anywhere they could fall or block a path.'),
              style: HerdText.body(15, color: Herd.pinkInk)),
        ]),
        const SizedBox(height: 10),
        HerdCard(color: Herd.butter, children: [
          Text(tr('Wishes and stamps'), style: HerdText.chunky(18, extraBold: false, color: Herd.butterInk)),
          Text(
              tr('Every Companion carries a wish. Pass one on to earn a stamp in your Passport, and grant their wish to earn a special Wish Granted stamp. Stamps are yours to keep.'),
              style: HerdText.body(15, color: Herd.butterInk)),
        ]),
        const SizedBox(height: 20),
        const ScriptHeading('Share on Instagram'),
        const SizedBox(height: 8),
        Text(tr('Add @growtheherdstudio as a collaborator on your post, or mention us in your story, and use #TheHerdCompanions.'),
            style: HerdText.body(15, color: Herd.ink)),
        const SizedBox(height: 10),
        HerdButton('Follow @growtheherdstudio', kind: HerdButtonKind.soft, onPressed: () => Services.open('https://www.instagram.com/growtheherdstudio/')),
        const SizedBox(height: 14),
        Text(tr('No app needed to take part. Anyone can scan a Companion with their phone camera.'), style: HerdText.body(14)),
      ]),
    );
  }
}

/// Save your Passport: optional "Sign up or sign in" with an emailed 6-digit code, no password.
/// The first code creates the account. Nothing in the app needs it.
Future<void> showSignIn(BuildContext context, {bool confirmDelete = false}) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Herd.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AppScope(model: context.model, router: context.router, child: _SignInSheet(confirmDelete: confirmDelete)),
    );

enum _SignInStep { email, code, signedIn, confirm }

class _SignInSheet extends StatefulWidget {
  const _SignInSheet({this.confirmDelete = false});
  final bool confirmDelete;

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final email = TextEditingController();
  final code = TextEditingController();
  _SignInStep? step;
  String? emailError;
  String? codeError;
  String? deleteError;
  String? previewCode;
  String? note;
  bool busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    step ??= context.model.signedIn ? (widget.confirmDelete ? _SignInStep.confirm : _SignInStep.signedIn) : _SignInStep.email;
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    if (!isEmail(email.text)) {
      setState(() => emailError = 'Please enter a valid email.');
      return;
    }
    setState(() {
      busy = true;
      emailError = null;
      codeError = null;
    });
    final result = await context.model.signInStart(email.text.trim());
    if (!mounted) return;
    setState(() {
      busy = false;
      if (!result.ok) {
        emailError = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
        step = _SignInStep.email;
      } else {
        previewCode = result.previewCode;
        code.clear();
        step = _SignInStep.code;
      }
    });
  }

  Future<void> verify() async {
    final typed = code.text.replaceAll(RegExp(r'\D'), '');
    if (typed.length != 6) {
      setState(() => codeError = 'Please enter the 6-digit code from the email.');
      return;
    }
    setState(() {
      busy = true;
      codeError = null;
    });
    final result = await context.model.signInVerify(email.text.trim(), typed);
    if (!mounted) return;
    setState(() {
      busy = false;
      if (!result.ok) {
        codeError = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
      } else {
        note = 'You’re signed in. Companions on this device have chosen to join you on your journey.';
        step = _SignInStep.signedIn;
      }
    });
  }

  Future<void> signOut() async {
    setState(() => busy = true);
    await context.model.signOut();
    if (!mounted) return;
    setState(() {
      busy = false;
      note = 'You’re signed out. Everything still works on this device.';
      previewCode = null;
      step = _SignInStep.email;
    });
  }

  Future<void> deleteData() async {
    setState(() {
      busy = true;
      deleteError = null;
    });
    final result = await context.model.forgetMe();
    if (!mounted) return;
    setState(() {
      busy = false;
      if (!result.ok) {
        deleteError = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
      } else {
        note = 'Your email and sign-in are deleted. Everything still works without signing in.';
        previewCode = null;
        step = _SignInStep.email;
      }
    });
  }

  Widget _link(String label, VoidCallback? onPressed, {Color color = Herd.sageDark}) =>
      TextButton(onPressed: onPressed, child: Text(tr(label), style: HerdText.body(15, color: color)));

  Widget _note() => HerdCard(color: Herd.mintSoft, children: [Text(tr(note!), style: HerdText.body(14, color: Herd.mintInk))]);

  @override
  Widget build(BuildContext context) {
    final model = context.model;
    final children = switch (step!) {
      _SignInStep.email => [
          Text(tr('Save your Passport'), style: HerdText.chunky(17, extraBold: false)),
          const Blob(color: Herd.mintSoft, width: 120, height: 110, child: Icon(Icons.menu_book_outlined, size: 40, color: Herd.ink)),
          Text(tr('Keep your stamps safe'), textAlign: TextAlign.center, style: HerdText.script(38)),
          Text(tr('Right now your Passport and stamps live only on this phone. Add your email to keep them if you change phones, and to see them on the website too.'),
              textAlign: TextAlign.center, style: HerdText.body(16)),
          if (note != null) _note(),
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            const FieldLabel('Your email'),
            HerdField(
              fieldKey: const Key('signInEmail'),
              controller: email,
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              errorText: emailError,
              onChanged: (_) => setState(() => emailError = null),
            ),
          ]),
          HerdButton(busy ? 'Sending…' : 'Email me a sign-in code', onPressed: busy || email.text.trim().isEmpty ? null : sendCode),
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            for (final line in const ['No password to remember, ever', 'Never shown publicly or shared', 'Optional: finding and passing on never need it'])
              Row(children: [
                const Icon(Icons.check, size: 18, color: Herd.sageDark),
                const SizedBox(width: 10),
                Expanded(child: Text(tr(line), style: HerdText.body(14, color: Herd.ink))),
              ]),
          ]),
          _link('Not now', () => Navigator.of(context).pop()),
        ],
      _SignInStep.code => [
          Text(tr('Save your Passport'), style: HerdText.chunky(17, extraBold: false)),
          const Blob(color: Herd.butter, width: 120, height: 110, child: Icon(Icons.mail_outline, size: 40, color: Herd.butterInk)),
          Text(tr('Check your email'), textAlign: TextAlign.center, style: HerdText.script(38)),
          Text(tr('We sent a 6-digit code to ${email.text.trim()}. It works for 15 minutes.'), textAlign: TextAlign.center, style: HerdText.body(16)),
          if (previewCode != null)
            HerdCard(color: Herd.butter, children: [
              Text(tr('Preview: your code is $previewCode. On the real site it’s emailed.'), style: HerdText.body(14, color: Herd.butterInk)),
            ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            const FieldLabel('Your 6-digit code'),
            HerdField(
              fieldKey: const Key('signInCode'),
              controller: code,
              hint: '123456',
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              errorText: codeError,
              onChanged: (_) => setState(() => codeError = null),
            ),
          ]),
          HerdButton('Sign in', onPressed: busy ? null : verify),
          Wrap(alignment: WrapAlignment.center, children: [
            _link(
              'Use a different email',
              busy
                  ? null
                  : () => setState(() {
                        step = _SignInStep.email;
                        previewCode = null;
                        codeError = null;
                      }),
            ),
            _link('Send a new code', busy ? null : sendCode),
          ]),
        ],
      _SignInStep.signedIn => [
          Text(tr('Your sign-in'), style: HerdText.chunky(17, extraBold: false)),
          const Blob(color: Herd.mintSoft, width: 120, height: 110, child: Icon(Icons.verified_outlined, size: 40, color: Herd.ink)),
          Text(tr('Your stamps are safe'), textAlign: TextAlign.center, style: HerdText.script(38)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check, size: 18, color: Herd.sageDark),
            const SizedBox(width: 8),
            Flexible(child: Text(tr('Signed in as ${model.account?.email ?? ''}'), style: HerdText.body(16, weight: FontWeight.w600, color: Herd.ink))),
          ]),
          Text(tr('Your Passport, the Companions in your care and the ones you follow are saved with your email, on every device.'),
              textAlign: TextAlign.center, style: HerdText.body(16)),
          if (note != null) _note(),
          HerdButton('Done', onPressed: () => Navigator.of(context).pop()),
          HerdButton('Sign out', kind: HerdButtonKind.outline, onPressed: busy ? null : signOut),
          _link(
            'Delete my data',
            busy
                ? null
                : () => setState(() {
                      deleteError = null;
                      step = _SignInStep.confirm;
                    }),
            color: Herd.error,
          ),
        ],
      _SignInStep.confirm => [
          Text(tr('Your sign-in'), style: HerdText.chunky(17, extraBold: false)),
          Text(tr('Delete your email and sign-in from The Herd?'), textAlign: TextAlign.center, style: HerdText.chunky(20, color: Herd.error)),
          Text(tr('Your chapters stay on the Companions’ pages. Everything keeps working without signing in.'),
              textAlign: TextAlign.center, style: HerdText.body(16)),
          if (deleteError != null) ErrorNote(deleteError!),
          HerdButton('Yes, delete my data', onPressed: busy ? null : deleteData),
          HerdButton('Keep it', kind: HerdButtonKind.outline, onPressed: busy ? null : () => setState(() => step = _SignInStep.signedIn)),
        ],
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 16, children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: hex('DCDDD6'), borderRadius: BorderRadius.circular(999))),
          ...children,
        ]),
      ),
    );
  }
}

/// Choose a language. Travelers' own chapters and chat stay in the language they were written in.
Future<void> showLanguagePicker(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Herd.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AppScope(model: context.model, router: context.router, child: const _LanguageSheet()),
    );

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  static const _languages = [('en', 'English', 'English'), ('es', 'Español', 'Spanish'), ('fr', 'Français', 'French'), ('ja', '日本語', 'Japanese')];

  @override
  Widget build(BuildContext context) {
    return ModelBuilder(
      builder: (context, model) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: hex('DCDDD6'), borderRadius: BorderRadius.circular(999)))),
          Center(child: Text(tr('Language'), style: HerdText.chunky(17, extraBold: false))),
          Text(tr('Choose your language'), style: HerdText.script(32)),
          for (final (code, name, english) in _languages)
            Semantics(
              button: true,
              selected: model.language == code,
              label: '$name, $english',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  model.setLanguage(code);
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: model.language == code ? Herd.sageDark : Herd.border, width: 2),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                        Text(name, style: HerdText.body(17, weight: FontWeight.w500, color: Herd.ink)),
                        Text(tr(english), style: HerdText.body(13)),
                      ]),
                    ),
                    Icon(model.language == code ? Icons.check_circle : Icons.circle_outlined, color: model.language == code ? Herd.sageDark : Herd.border),
                  ]),
                ),
              ),
            ),
          Text(tr('Travelers’ chapters and chat messages stay in the language they were written in.'), style: HerdText.body(13)),
        ]),
      ),
    );
  }
}

/// Notification settings (the slider button on Activity).
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: herdAppBar(title: 'Notifications'),
      body: ModelBuilder(builder: (context, model) {
        final p = model.notificationPrefs;
        void set(void Function() change) {
          change();
          model.changed();
        }

        return ListView(padding: const EdgeInsets.all(20), children: [
          const Eyebrow('Tell me when'),
          const SizedBox(height: 8),
          HerdCard(color: Colors.white, spacing: 2, children: [
            LabeledSwitch(label: 'A Companion I’ve carried moves', value: p.carriedMoves, onChanged: (v) => set(() => p.carriedMoves = v)),
            LabeledSwitch(label: 'A Companion I follow moves', value: p.followedMoves, onChanged: (v) => set(() => p.followedMoves = v)),
            LabeledSwitch(label: 'A wish is granted', value: p.wishesGranted, onChanged: (v) => set(() => p.wishesGranted = v)),
            LabeledSwitch(label: 'Someone replies to me in a chat', value: p.chatReplies, onChanged: (v) => set(() => p.chatReplies = v)),
            LabeledSwitch(label: 'New stamps in my Passport', value: p.newStamps, onChanged: (v) => set(() => p.newStamps = v)),
            LabeledSwitch(label: 'The one-month reminder to pass a Companion on', value: p.monthlyReminder, onChanged: (v) => set(() => p.monthlyReminder = v)),
          ]),
          const SizedBox(height: 20),
          const Eyebrow('How'),
          const SizedBox(height: 8),
          HerdCard(color: Colors.white, spacing: 2, children: [
            LabeledSwitch(
              label: 'Also send these by email',
              value: p.byEmail && model.email != null,
              onChanged: (v) => model.email == null ? showSignIn(context) : set(() => p.byEmail = v),
            ),
            LabeledSwitch(label: 'Quiet hours (10pm – 8am)', value: p.quietHours, onChanged: (v) => set(() => p.quietHours = v)),
          ]),
          const SizedBox(height: 6),
          Text(tr(model.email == null ? 'Add your email in Passport to get emails too.' : 'Emails go to ${model.email}.'), style: HerdText.body(13)),
          const SizedBox(height: 20),
          HerdCard(color: Colors.white, children: [
            // Optional sign-in (opens the same sheet as the Passport's "Save your Passport").
            TextButton(
              key: const Key('settingsSignIn'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              onPressed: () => showSignIn(context),
              child: Text(
                tr(model.signedIn ? 'Signed in as ${model.account!.email}' : 'Sign up or sign in'),
                style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          HerdCard(color: Colors.white, children: [
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              // Signed in: confirm first, then remove the email and sign-in from The Herd too.
              onPressed: model.signedIn ? () => showSignIn(context, confirmDelete: true) : model.deleteMyData,
              child: Text(tr('Delete my data'), style: HerdText.body(15, weight: FontWeight.w500, color: const Color(0xFFC0392B))),
            ),
          ]),
          const SizedBox(height: 6),
          Text(tr('Removes your email and nickname from The Herd. Your chapters stay on the Companions’ pages without your name.'), style: HerdText.body(13)),
        ]);
      }),
    );
  }
}
