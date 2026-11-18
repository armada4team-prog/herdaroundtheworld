import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
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

/// Turned on for the automated walkthrough, which can't open the photo library.
const _samplePhotoForTests = bool.fromEnvironment('SAMPLE_PHOTO');

/// Step 2 of 2: send them on their way (hand to someone or leave somewhere), with an optional photo and chapter.
class PassOnScreen extends StatefulWidget {
  const PassOnScreen({super.key, required this.number});
  final String number;

  @override
  State<PassOnScreen> createState() => _PassOnScreenState();
}

class _PassOnScreenState extends State<PassOnScreen> {
  HerePlace? here; // from the phone's location
  final placeText = TextEditingController();
  final chapter = TextEditingController();
  final nickname = TextEditingController();
  final email = TextEditingController();
  final sampleKey = GlobalKey();
  bool handToSomeone = true;
  bool shareOK = true;
  bool grantedWish = false;
  bool alertMe = true;
  bool saving = false;
  Uint8List? photo;
  Uint8List? wishPhoto;
  String? whereError;
  String? placeError;
  String? chapterError;
  String? nicknameError;
  String? emailError;
  String? wishPhotoError;
  String? photoError;
  bool? needsFindFirst; // checked once when the screen opens

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (nickname.text.isEmpty) nickname.text = context.model.nickname;
    needsFindFirst ??= !context.model.canPassOn(widget.number);
  }

  @override
  void dispose() {
    placeText.dispose();
    chapter.dispose();
    nickname.dispose();
    email.dispose();
    super.dispose();
  }

  /// The 5-mile rule: a message if they're still too close to where they found this Companion.
  String? tooCloseMessage(HerePlace place) {
    final model = context.model;
    // Handing them to someone is a gift: no minimum distance.
    if (handToSomeone || model.farEnoughToPassOn(widget.number, place.point)) return null;
    final miles = model.milesFromFind(widget.number, place.point)!;
    if (miles < 1) {
      return 'To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re still close to where you found them. (Handing them to someone is fine anywhere.)';
    }
    return 'To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re about {0} miles away. (Handing them to someone is fine anywhere.)'
        .replaceAll('{0}', miles.toStringAsFixed(0));
  }

  bool get canSubmit => nickname.text.trim().isNotEmpty && !saving;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    final where = here;
    final description = placeText.text.trim();
    setState(() {
      whereError = where == null ? 'We need your location to pass them on.' : tooCloseMessage(where);
      placeError = handToSomeone
          ? null
          : (description.isEmpty ? 'Please add a hint so the next person can find them.' : checkPlaceDescription(description));
      chapterError = checkPublicText(chapter.text, maxLength: 500);
      nicknameError = checkNickname(nickname.text);
      emailError = email.text.trim().isNotEmpty && !isEmail(email.text) ? 'Please enter a valid email, or leave it empty.' : null;
      wishPhotoError = grantedWish && wishPhoto == null ? 'Please add a photo of the wish coming true.' : null;
      photoError = photo == null ? 'Please add a photo.' : null;
    });
    if ([whereError, placeError, chapterError, nicknameError, emailError, wishPhotoError, photoError].any((e) => e != null)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('A few things need a quick fix. They’re marked in red.'))));
      return;
    }
    if (where == null) return;
    setState(() => saving = true);
    final city = where.city;
    // A public place shows close to the spot (about 100 m); otherwise only roughly the city.
    // Left somewhere: the dot shows close to the spot (about 100 m), with their hint, so the next
    // person can find them. Handed to someone: only roughly the city.
    final point = where.blurred(exactish: !handToSomeone);
    final place = handToSomeone ? null : description;
    final model = context.model;
    model.passOn(
      widget.number,
      city: city,
      place: place,
      handedToSomeone: handToSomeone,
      chapter: chapter.text.trim(),
      nickname: nickname.text.trim(),
      grantedWish: grantedWish,
      photo: photo ?? (grantedWish ? wishPhoto : null),
      point: point,
      exactPoint: where.point,
    );
    if (alertMe) model.following.add(widget.number);
    if (email.text.trim().isNotEmpty) model.setEmail(email.text.trim());
    context.router.replaceTop(grantedWish ? WishRoute(widget.number) : SentRoute(widget.number));
  }

  /// A sample "photo" for the automated walkthrough: a Companion on a sunny background.
  Future<Uint8List?> _renderSamplePhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final boundary = sampleKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.model;
    final c = model.companion(widget.number);
    final name = c?.displayName ?? '#${widget.number}';
    return Scaffold(
      appBar: herdAppBar(title: 'Pass them on'),
      body: needsFindFirst == true
          ? OutOfOrderView(
              companion: c,
              title: 'Find {0} first'.replaceAll('{0}', name),
              message: 'Every Companion’s journey goes found, then left, then found again. Log that you found {0} before you pass them on.'
                  .replaceAll('{0}', name),
              buttonLabel: 'I found them →',
              onPressed: () => context.router.replaceTop(FoundRoute(widget.number)),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  if (_samplePhotoForTests)
                    Positioned(
                      left: -1000,
                      child: RepaintBoundary(
                        key: sampleKey,
                        child: Container(
                          width: 360,
                          height: 260,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Herd.butter, Herd.mintSoft],
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 16),
                          child: const CompanionFigure(glaze: Herd.mint, waving: true, happy: true, height: 150),
                        ),
                      ),
                    ),
                  ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Eyebrow('Step 2 of 2 · Companion #${widget.number}'),
                      const SizedBox(height: 4),
                      Text(tr('Send $name on their way'), style: HerdText.script(40)),
                      Text(tr('Thanks for traveling together. Tell us where they’re headed next.'), style: HerdText.body(16)),
                      const SizedBox(height: 18),
                      if (model.nickname.isNotEmpty && model.holding.contains(widget.number)) ...[
                        HerdCard(
                          color: Herd.mintSoft,
                          children: [
                            Text(
                              tr('Welcome back, ${model.nickname}! We filled in your details from last time.'),
                              style: HerdText.body(15, color: Herd.mintInk),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      const FieldLabel('How are you passing them on? *'),
                      const SizedBox(height: 10),
                      ChoiceCard(
                        title: 'Handing them to someone',
                        detail: 'Give them to a fellow traveler: a new friend, a host, someone heading somewhere fun. Works anywhere, no distance needed.',
                        badge: 'Most personal',
                        selected: handToSomeone,
                        onTap: () => setState(() {
                          handToSomeone = true;
                          if (here != null) whereError = tooCloseMessage(here!);
                        }),
                      ),
                      const SizedBox(height: 10),
                      ChoiceCard(
                        title: 'Leaving them somewhere',
                        detail: 'A café shelf, a hostel lobby, a little free library. Somewhere they’ll be found, at least 5 miles from where you found them.',
                        selected: !handToSomeone,
                        onTap: () => setState(() {
                          handToSomeone = false;
                          if (here != null) whereError = tooCloseMessage(here!);
                        }),
                      ),
                      const SizedBox(height: 20),
                      const FieldLabel('Where are you? *'),
                      const SizedBox(height: 8),
                      HereCard(
                        errorText: whereError,
                        onChanged: (place) => setState(() {
                          here = place;
                          whereError = place == null ? null : tooCloseMessage(place);
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('Please never use a home address. We only ever show a place name and city, never a street address.'),
                        style: HerdText.body(13),
                      ),
                      if (!handToSomeone) ...[
                        const SizedBox(height: 20),
                        const FieldLabel('Where in the city? *'),
                        const SizedBox(height: 8),
                        HerdField(
                          fieldKey: const Key('passPlace'),
                          controller: placeText,
                          hint: 'Like a café on the plaza, or a hostel lobby',
                          maxLength: 120,
                          errorText: placeError,
                          onChanged: (_) => setState(() => placeError = null),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(
                            'This is the hint the next traveler uses to find them, and their dot on the map shows close to this spot. Be specific, like “bookshelf by the window at Bean Café.”',
                          ),
                          style: HerdText.body(13),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const FieldLabel('Add a photo *'),
                      const SizedBox(height: 8),
                      _photoBox(
                        photo,
                        handToSomeone
                            ? 'A photo from your time together, or their new spot'
                            : 'A photo of the spot helps the next traveler find them',
                        Herd.stepDot,
                        () async {
                          final p = await Services.choosePhoto(context);
                          if (p != null && mounted) {
                            setState(() {
                              photo = p;
                              photoError = null;
                            });
                          }
                        },
                      ),
                      if (photoError != null) ...[
                        const SizedBox(height: 6),
                        Text(tr(photoError!), style: HerdText.body(14, color: Herd.pinkInk)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, size: 16, color: Herd.sageDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('We remove the hidden location data from photos, so only the spot you choose above is shared.'),
                              style: HerdText.body(13),
                            ),
                          ),
                        ],
                      ),
                      LabeledSwitch(
                        label: 'It’s OK for The Herd to share my photo on their website and Instagram, with credit.',
                        value: shareOK,
                        onChanged: (v) => setState(() => shareOK = v),
                      ),
                      const SizedBox(height: 16),
                      const FieldLabel('Add your chapter to their story'),
                      const SizedBox(height: 8),
                      HerdField(
                        fieldKey: const Key('passChapter'),
                        controller: chapter,
                        hint: 'Where did you go together? Who are you passing them to, and why?',
                        minLines: 4,
                        maxLines: 8,
                        maxLength: 500,
                        showCounter: true,
                        errorText: chapterError,
                        onChanged: (_) => setState(() => chapterError = null),
                      ),
                      Text(
                        tr('Keep it kind and family-friendly. Chapters are checked, and The Herd takes a quick look.'),
                        style: HerdText.body(13),
                      ),
                      if (c != null && !c.wishGranted) ...[const SizedBox(height: 20), _wishSection(c)],
                      const SizedBox(height: 20),
                      const FieldLabel('Your name or nickname *'),
                      const SizedBox(height: 8),
                      HerdField(
                        fieldKey: const Key('passNickname'),
                        controller: nickname,
                        hint: 'Shown on their page',
                        maxLength: 30,
                        errorText: nicknameError,
                        onChanged: (_) => setState(() => nicknameError = null),
                      ),
                      const SizedBox(height: 20),
                      const FieldLabel('Email (optional)'),
                      const SizedBox(height: 8),
                      HerdField(
                        controller: email,
                        hint: 'you@email.com',
                        keyboardType: TextInputType.emailAddress,
                        errorText: emailError,
                        onChanged: (_) => setState(() => emailError = null),
                      ),
                      const SizedBox(height: 6),
                      Text(tr('Optional. Your stamps are always saved in the app. Never shown publicly.'), style: HerdText.body(13)),
                      LabeledSwitch(
                        label: 'Alert me each time #${widget.number} moves',
                        value: alertMe,
                        onChanged: (v) => setState(() => alertMe = v),
                      ),
                      const SizedBox(height: 12),
                      HerdCard(
                        color: Herd.pinkSoft,
                        children: [
                          Text(
                            tr(
                              'Your sighting shows up right away. Photos and new wishes appear after a quick look, usually within a few days. Your new stamps appear in your Passport after that review.',
                            ),
                            style: HerdText.body(14, color: Herd.pinkInk),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      HerdButton(saving ? 'Sending…' : 'Send them on their way →', onPressed: canSubmit ? submit : null),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _wishSection(Companion c) => HerdCard(
    color: Herd.butter,
    padding: 16,
    radius: 18,
    spacing: 10,
    children: [
      Row(
        children: [
          const Icon(Icons.star_rounded, color: Herd.gold),
          const SizedBox(width: 8),
          Text(
            tr('Did you grant their wish?'),
            style: HerdText.body(16, weight: FontWeight.w600, color: Herd.wishInk),
          ),
        ],
      ),
      Text(tr('“${c.wishSentence}”'), style: HerdText.script(24, color: Herd.wishInk)),
      ChoiceCard(
        title: 'Yes, we did it!',
        detail: 'Add a photo of the moment below. You’ll choose their next wish and earn a Wish Granted stamp.',
        selected: grantedWish,
        onTap: () async {
          setState(() => grantedWish = true);
          if (_samplePhotoForTests && wishPhoto == null) {
            final sample = await _renderSamplePhoto();
            if (mounted) setState(() => wishPhoto = sample);
          }
        },
      ),
      ChoiceCard(
        title: 'Not this time',
        detail: 'That’s okay. The next traveler can try.',
        selected: !grantedWish,
        onTap: () => setState(() => grantedWish = false),
      ),
      if (grantedWish) ...[
        Text(
          tr('A photo of the wish coming true *'),
          style: HerdText.body(15, weight: FontWeight.w600, color: Herd.wishInk),
        ),
        _photoBox(wishPhoto, 'Add the photo', Herd.gold, () async {
          final p = await Services.choosePhoto(context);
          if (p != null && mounted) {
            setState(() {
              wishPhoto = p;
              wishPhotoError = null;
            });
          }
        }),
        if (wishPhotoError != null) Text(tr(wishPhotoError!), style: HerdText.body(13, color: const Color(0xFFB3261E))),
        Text(
          tr('Required for the Wish Granted stamp. It’s added once we see your photo.'),
          style: HerdText.body(13, color: Herd.butterInk),
        ),
      ],
    ],
  );

  Widget _photoBox(Uint8List? bytes, String prompt, Color tint, VoidCallback onTap) => Semantics(
    button: true,
    label: tr(bytes == null ? prompt : 'Photo added. Tap to change it.'),
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: bytes == null ? 120 : 200,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Herd.beige,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint, width: 2),
        ),
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_outlined, color: Herd.ink, size: 26),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      tr(prompt),
                      textAlign: TextAlign.center,
                      style: HerdText.body(14, color: Herd.ink),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
