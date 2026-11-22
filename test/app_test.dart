import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:herd_around_the_world/services.dart';
import 'package:herd_around_the_world/app_state.dart';
import 'package:herd_around_the_world/find_codes.dart';
import 'package:herd_around_the_world/main.dart';
import 'package:herd_around_the_world/models.dart';

void main() {
  test('reads scanned codes and typed numbers', () {
    expect(AppModel.numberFromScan('https://theherdstudio.com/c/07'), '07');
    expect(AppModel.numberFromScan('https://www.theherdstudio.com/herd-around-the-world?c=3&k=MHE6'), '3');
    expect(AppModel.numberFromScan('https://www.theherdstudio.com/herd-around-the-world#/c/12'), '12');
    expect(codeFromScan('https://www.theherdstudio.com/herd-around-the-world?c=3&k=MHE6'), 'MHE6');
    expect(codeFromScan('https://companions.theherdstudio.com/c/07?k=KCVT'), 'KCVT');
    expect(AppModel.numberFromScan('https://companions.theherdstudio.com/c/07?k=KCVT'), '07');
    expect(AppModel.numberFromScan('https://companions.theherdstudio.com/#/c/12'), '12');
    expect(AppModel.numberFromScan('07'), '07');
    expect(AppModel.numberFromScan('hello'), isNull);
    expect(AppModel.cleanNumber('007'), '7');
  });

  test('hides phone numbers and emails in chat', () {
    expect(AppModel.hideContactDetails('call me on +1 303 555 0100'), 'call me on [hidden]');
    expect(AppModel.hideContactDetails('mail sam@example.com'), 'mail [hidden]');
  });

  test('finding and passing on adds stops and stamps', () {
    final model = AppModel();
    final stampsBefore = model.stamps.length;
    final c = model.companion('07')!;
    final stopsBefore = c.stops.length;
    model.tryFindCode('07', findCodeFor('07'));
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.appAlert);
    expect(c.current!.byLine, 'Found by Sam', reason: 'a find shows as Found by');
    final photo = Uint8List.fromList([1, 2, 3]);
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: true, chapter: 'Hi', nickname: 'Sam', grantedWish: true, photo: photo);
    expect(c.stops.length, stopsBefore + 2);
    expect(c.current!.photo, photo, reason: 'the photo is saved with the chapter');
    expect(c.current!.note, 'Hi');
    expect(c.current!.byLine, 'Passed on by Sam', reason: 'handed to someone');
    expect(model.activity.first.meta, 'Passed on by Sam · Just now');
    expect(c.current!.city, 'Boulder, CO');
    expect(model.stamps.length, stampsBefore + 2);
    model.setNextWish('07', 'I want to meet a dog.');
    expect(c.wish, 'meet a dog');
    model.setNextWish('07', 'I want to see the northern lights.');
    expect(c.wish, 'see the northern lights', reason: 'a typed wish is kept as typed');
  });

  test('a Companion goes found, left, found, left: never left twice in a row', () {
    final model = AppModel();
    final c = model.companion('07')!;
    final stopsBefore = c.stops.length;
    expect(model.canPassOn('07'), isFalse);
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false);
    expect(c.stops.length, stopsBefore, reason: 'cannot leave before finding');
    model.tryFindCode('07', findCodeFor('07'));
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(model.canLogFind('07'), isFalse);
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(c.stops.length, stopsBefore + 1, reason: 'cannot find twice in a row');
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false);
    model.passOn('07', city: 'Golden, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false);
    expect(c.stops.length, stopsBefore + 2, reason: 'cannot leave twice in a row');
    expect(model.canLogFind('07'), isTrue);
  });

  test('a find needs the secret code from their bottom', () {
    final model = AppModel();
    final c = model.companion('07')!;
    final stopsBefore = c.stops.length;
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(c.stops.length, stopsBefore, reason: 'typing the number alone is not enough');
    expect(model.tryFindCode('07', 'AAAA' == findCodeFor('07') ? 'CCCC' : 'AAAA'), CodeCheck.wrong);
    expect(model.hasFindCode('07'), isFalse);
    final code = findCodeFor('07');
    expect(code, 'KCVT', reason: 'the code the studio was given for #07');
    expect(model.companion('7')!.number, '07', reason: 'typing 7 finds #07');
    expect(findCodeFor('7'), code, reason: '07 and 7 are the same Companion');
    expect(findCodeFor('08'), isNot(code));
    expect(model.tryFindCode('07', ' ${code.toLowerCase()} '), CodeCheck.right);
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(c.stops.length, stopsBefore + 1);
    expect(codeFromScan(qrAddressFor('07')), code);
    expect(AppModel.numberFromScan(qrAddressFor('07')), '07');
    expect(qrAddressFor('07'), startsWith('https://companions.theherdstudio.com/c/07?k='));
  });

  test('guessing codes pauses after 5 wrong tries', () {
    final model = AppModel();
    final wrong = findCodeFor('07') == 'AAAA' ? 'CCCC' : 'AAAA';
    for (var i = 0; i < 4; i++) {
      expect(model.tryFindCode('07', wrong), CodeCheck.wrong);
    }
    expect(model.tryFindCode('07', wrong), CodeCheck.tooManyTries);
    expect(model.tryFindCode('07', findCodeFor('07')), CodeCheck.tooManyTries);
  });

  test('map dots: the exact spot, or the general area (within about 3 miles)', () {
    const here = HerePlace('Aurora, CO', LatLng(39.72946, -104.83191));
    expect(here.blurred(exactish: false), const LatLng(39.75, -104.85));
    expect(here.blurred(exactish: true), const LatLng(39.72946, -104.83191));
  });

  test('a Companion must travel 5 miles before it is left somewhere (gifts are fine anywhere)', () {
    final model = AppModel();
    final c = model.companion('3')!;
    const aurora = LatLng(39.7294, -104.8319);
    const stillAurora = LatLng(39.72, -104.79); // about 2 miles away
    const boulder = LatLng(40.0150, -105.2705); // about 30 miles away
    model.tryFindCode('3', findCodeFor('3'));
    model.logFind('3', city: 'Aurora, CO', nickname: 'Sam', checkIn: CheckIn.none, exactPoint: aurora);
    final stops = c.stops.length;
    expect(model.farEnoughToPassOn('3', stillAurora), isFalse);
    model.passOn(
      '3',
      city: 'Aurora, CO',
      handedToSomeone: false,
      chapter: '',
      nickname: 'Sam',
      grantedWish: false,
      exactPoint: stillAurora,
    );
    expect(c.stops.length, stops, reason: 'only about 2 miles: cannot be left somewhere yet');
    expect(model.farEnoughToPassOn('3', boulder), isTrue);
    model.passOn('3', city: 'Boulder, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false, exactPoint: boulder);
    expect(c.stops.length, stops + 1);
    expect(c.current!.byLine, 'Left by Sam', reason: 'left somewhere');
    expect(model.activity.first.meta, 'Left by Sam · Just now');

    // Handing a Companion to someone is a gift: fine right where it was found.
    model.tryFindCode('3', findCodeFor('3'));
    model.logFind('3', city: 'Boulder, CO', nickname: 'Sam', checkIn: CheckIn.none, exactPoint: boulder);
    model.passOn('3', city: 'Boulder, CO', handedToSomeone: true, chapter: '', nickname: 'Sam', grantedWish: false, exactPoint: boulder);
    expect(c.stops.length, stops + 3);
  });

  testWidgets('opens on the welcome screen and comes in', (tester) async {
    await tester.pumpWidget(const HerdApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tap me to say hi!'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Say hi and come in'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hi there!'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });
}
