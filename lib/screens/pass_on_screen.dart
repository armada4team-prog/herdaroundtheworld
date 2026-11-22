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
  bool exactSpot = true; // show the exact spot on the map, or only the general area
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
  String? formError; // from The Herd's checker, when it isn't about one box
  bool triedToSend = false; // after a send with problems, the list of fixes shows above the button
  final kWhere = GlobalKey(), kPlace = GlobalKey(), kPhoto = GlobalKey(), kChapter = GlobalKey();
  final kWish = GlobalKey(), kNickname = GlobalKey(), kEmail = GlobalKey();

  /// Every problem still on the form, in the order they appear.
  List<String> get problems =>
      [whereError, placeError, photoError, chapterError, wishPhotoError, nicknameError, emailError, formError].whereType<String>().toList();
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
      formError = null;
    });
    if (problems.isNotEmpty) {
      setState(() => triedToSend = true);
      scrollToFirstProblem([
        kWhere,
        kPlace,
        kPhoto,
        kChapter,
        kWish,
        kNickname,
        kEmail,
      ], [whereError, placeError, photoError, chapterError, wishPhotoError, nicknameError, emailError].map((e) => e != null).toList());
      return;
    }
    if (where == null) return;
    setState(() => saving = true);
    final city = where.city;
    // The dot shows the exact spot (unless they chose the general area). Left somewhere, it comes
    // with their hint, so the next person can find them.
    final point = where.blurred(exactish: exactSpot);
    final place = handToSomeone ? null : description;
    final model = context.model;
    final result = await model.submitPassOn(
      widget.number,
      city: city,
      place: place,
      handedToSomeone: handToSomeone,
      chapter: chapter.text.trim(),
      nickname: nickname.text.trim(),
      grantedWish: grantedWish,
      photo: photo,
      wishPhoto: grantedWish ? wishPhoto : null,
      point: point,
      exactPoint: where.point,
      exactSpot: exactSpot,
      shrink: Services.shrinkPhoto,
    );
    if (!mounted) return;
    if (!result.ok) {
      // The checker said what to fix: mark that box in red.
      final message = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
      setState(() {
        saving = false;
        triedToSend = true;
        switch (result.field) {
          case 'where':
            whereError = message;
          case 'hint':
            placeError = message;
          case 'photo':
            photoError = message;
          case 'chapter':
            chapterError = message;
          case 'wishPhoto':
            wishPhotoError = message;
          case 'nickname':
            nicknameError = message;
          default:
            formError = message;
        }
      });
      scrollToFirstProblem(
        [kWhere, kPlace, kPhoto, kChapter, kWish, kNickname],
        ['where', 'hint', 'photo', 'chapter', 'wishPhoto', 'nickname'].map((f) => f == result.field).toList(),
      );
      return;
    }
    if (alertMe && !model.following.contains(widget.number)) model.toggleFollow(widget.number);
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
                    scrollCacheExtent: const ScrollCacheExtent.pixels(10000), // keep the whole form built, so we can scroll to any problem
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
                      FieldLabel('Where are you? *', key: kWhere),
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
                        tr('Please never use a home address. A street address is never written out.'),
                        style: HerdText.body(13),
                      ),
                      const SizedBox(height: 12),
                      LabeledSwitch(label: 'Show my exact spot on the map', value: exactSpot, onChanged: (v) => setState(() => exactSpot = v)),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                        const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.place_outlined, size: 18, color: Herd.sageDark)),
                        Expanded(
                          child: Text(
                            tr(!exactSpot ? 'Only the general area (within about 3 miles) will be shown on their map.' : handToSomeone ? 'Heads up: the exact spot where you hand them on will be shown on their map.' : 'The exact spot where you leave them will be shown on their map, so the next traveler can find them.'),
                            style: HerdText.body(14, color: Herd.ink),
                          ),
                        ),
                      ]),
                      if (!handToSomeone) ...[
                        const SizedBox(height: 20),
                        FieldLabel('Where in the city? *', key: kPlace),
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
                      FieldLabel('Add a photo *', key: kPhoto),
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
                      if (photoError != null) ...[const SizedBox(height: 6), ErrorNote(photoError!)],
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
                      FieldLabel('Add your chapter to their story', key: kChapter),
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
                      if (c != null && !c.wishGranted) ...[const SizedBox(height: 20), KeyedSubtree(key: kWish, child: _wishSection(c))],
                      const SizedBox(height: 20),
                      FieldLabel('Your name or nickname *', key: kNickname),
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
                      FieldLabel('Email (optional)', key: kEmail),
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
                      if (triedToSend && problems.isNotEmpty) ...[FixList(problems), const SizedBox(height: 12)],
                      HerdButton(saving ? 'Sending…' : 'Send them on their way →', onPressed: saving ? null : submit),
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
        if (wishPhotoError != null) ErrorNote(wishPhotoError!),
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
