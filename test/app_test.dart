import 'package:flutter_test/flutter_test.dart';
import 'package:herd_around_the_world/app_state.dart';
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
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.appAlert);
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: true, chapter: 'Hi', nickname: 'Sam', grantedWish: true);
    expect(c.stops.length, stopsBefore + 2);
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
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(model.canLogFind('07'), isFalse);
    model.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none);
    expect(c.stops.length, stopsBefore + 1, reason: 'cannot find twice in a row');
    model.passOn('07', city: 'Boulder, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false);
    model.passOn('07', city: 'Golden, CO', handedToSomeone: false, chapter: '', nickname: 'Sam', grantedWish: false);
    expect(c.stops.length, stopsBefore + 2, reason: 'cannot leave twice in a row');
    expect(model.canLogFind('07'), isTrue);
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
