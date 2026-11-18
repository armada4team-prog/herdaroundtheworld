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
    final photo = Uint8List.fromList([1, 2, 3]);
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: true, chapter: 'Hi', nickname: 'Sam', grantedWish: true, photo: photo);
    expect(c.stops.length, stopsBefore + 2);
    expect(c.current!.photo, photo, reason: 'the photo is saved with the chapter');
    expect(c.current!.note, 'Hi');
    expect(c.current!.city, 'Boulder, CO');
    expect(model.stamps.length, stampsBefore + 2);
    model.setNextWish('07', 'I want to meet a dog.');
    expect(c.wish, 'meet a dog');
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

  test('map dots are blurred: about the city, or near a public place', () {
    const here = HerePlace('Aurora, CO', LatLng(39.72946, -104.83191));
    expect(here.blurred(exactish: false), const LatLng(39.7, -104.8));
    expect(here.blurred(exactish: true), const LatLng(39.729, -104.832));
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
