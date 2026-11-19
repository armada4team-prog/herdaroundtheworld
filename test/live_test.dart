// The app connected to The Herd's Wix site, with a pretend Wix site (no real internet).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:herd_around_the_world/app_state.dart';
import 'package:herd_around_the_world/main.dart';
import 'package:herd_around_the_world/models.dart';
import 'package:herd_around_the_world/storage.dart';
import 'package:herd_around_the_world/wix_api.dart';

/// A pretend Wix site: the CMS lists and the checker. [checker] false = not published yet (404).
class FakeWix {
  FakeWix({this.checker = true});
  bool checker;
  final List<(String, Map<String, dynamic>)> calls = [];

  final companions = <Map<String, dynamic>>[
    {'number': '07', 'status': 'waiting', 'wish': 'I want to see the ocean.', 'glaze': 'A8DCC9', 'accent': 'D98C86', 'blob': 'DDF0E8', 'blurb': 'Loves cafés.'},
    {'number': 3, 'status': 'moving', 'isOriginal': true, 'wish': 'meet a dog', 'name': 'Juniper'},
  ];
  final stops = <Map<String, dynamic>>[
    {
      'companionNumber': '07',
      'kind': 'left',
      'city': 'Moab, UT',
      'place': 'Bookstore on Main Street',
      'latitude': 38.57,
      'longitude': -109.55,
      'byName': 'Sam R.',
      'chapter': 'Carried them through the arches.',
      'photo': 'wix:image://v1/abc123~mv2.jpg/moab.jpg#originWidth=800',
      'photoApproved': true,
      '_createdDate': {r'$date': '2026-11-01T10:00:00Z'},
    },
    {'companionNumber': '07', 'kind': 'made', 'city': 'Aurora, CO', 'latitude': 39.73, 'longitude': -104.83, 'byName': 'The Herd', 'whenText': 'Where they were made', '_createdDate': {r'$date': '2026-12-01T10:00:00Z'}},
    {
      'companionNumber': '07',
      'kind': 'found',
      'city': 'Santa Fe, NM',
      'latitude': 35.69,
      'longitude': -105.94,
      'byName': 'Robin',
      'photo': 'wix:image://v1/notyet~mv2.jpg/x.jpg',
      'photoApproved': false,
      '_createdDate': {r'$date': '2026-11-10T10:00:00Z'},
    },
  ];
  final chat = <Map<String, dynamic>>[
    {'companionNumber': '07', 'author': 'Sam R.', 'message': 'Hello!', 'hidden': false, '_createdDate': {r'$date': '2026-11-02T10:00:00Z'}},
    {'companionNumber': '07', 'author': 'Troll', 'message': 'Hidden one', 'hidden': true, '_createdDate': {r'$date': '2026-11-03T10:00:00Z'}},
  ];

  http.Response _json(int status, Object body) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
  http.Response _problem(String message, String field) => _json(400, {'ok': false, 'field': field, 'message': message});

  late final client = MockClient((request) async {
    final path = request.url.path;
    if (request.url.host == 'www.wixapis.com' && path == '/oauth2/token') {
      return _json(200, {'access_token': 'visitor-token', 'refresh_token': 'refresh', 'expires_in': 14400});
    }
    if (request.url.host == 'www.wixapis.com' && path == '/wix-data/v2/items/query') {
      expect(request.headers['Authorization'], 'visitor-token');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final items = switch (body['dataCollectionId']) {
        'Companions' => companions,
        'CompanionStops' => stops,
        'CompanionChat' => chat.where((m) => m['companionNumber'] == (body['query']['filter'] as Map)['companionNumber']).toList(),
        _ => <Map<String, dynamic>>[],
      };
      return _json(200, {
        'dataItems': [for (final i in items) {'data': i}],
      });
    }
    if (request.url.host == 'www.theherdstudio.com' && path.startsWith('/_functions/')) {
      if (!checker) return http.Response('<html>Not found</html>', 404);
      final name = path.substring('/_functions/'.length);
      final b = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.headers['Content-Type'], startsWith('text/plain'));
      calls.add((name, b));
      switch (name) {
        case 'herdMine':
          if (b['session'] != 'session-1') return _problem('Please sign in again.', 'session');
          return _json(200, {'ok': true, 'profile': _profile});
        case 'herdFind':
          if (b['code'] != 'GOOD') return _problem('That code doesn’t match #07. Check the letters under their number.', 'code');
          if ((b['nickname'] ?? '') == '') return _problem('Please add a name or nickname.', 'nickname');
          return _json(200, {'ok': true, 'number': '07', 'holdToken': 'hold-07'});
        case 'herdPassOn':
          if (b['holdToken'] != 'hold-07') return _problem('Log that you found #07 before you pass them on.', 'number');
          if (b['handedOn'] != true && (b['hint'] ?? '') == '') return _problem('Please add a hint so the next person can find them.', 'hint');
          return _json(200, {'ok': true, 'number': '07', 'wishToken': b['wishGranted'] == true ? 'wish-07' : null});
        case 'herdWish':
          if (b['wishToken'] != 'wish-07') return _problem('Only the traveler who granted their wish can choose the next one.', 'wish');
          return _json(200, {'ok': true});
        case 'herdChat':
          return _json(200, {'ok': true, 'id': 'c1', 'message': b['message']});
        case 'herdSignInStart':
          return _json(200, {'ok': true});
        case 'herdSignInVerify':
          if (b['code'] != '123456') return _problem('That code isn’t right. Check the email and try again.', 'code');
          return _json(200, {'ok': true, 'session': 'session-1', 'profile': _profile});
        case 'herdFollow':
          return _json(200, {'ok': true, 'following': ['07', '3']});
        default:
          return _json(200, {'ok': true});
      }
    }
    return http.Response('?', 404);
  });

  static final _profile = {
    'email': 'robin@example.com',
    'nickname': 'Robin',
    'following': ['3'],
    'holds': [
      {'number': '3', 'token': 'hold-3', 'city': 'Tokyo', 'date': {r'$date': '2026-11-05T10:00:00Z'}},
    ],
    'wishTokens': {'07': 'wish-07'},
    'journal': [
      {'number': '07', 'kind': 'left', 'city': 'Moab, UT', 'date': {r'$date': '2026-10-01T10:00:00Z'}, 'wishGranted': true},
    ],
  };
}

Future<AppModel> started(FakeWix wix, {KeyValueStore? store}) async {
  final model = AppModel(api: WixApi(client: wix.client), store: store ?? MemoryStore());
  await model.start();
  return model;
}

const _here = LatLng(39.7294, -104.8319);
const _farAway = LatLng(40.0150, -105.2705);

void main() {
  test('the checker answering 400 {field: session} means LIVE; a 404 means SAMPLE', () async {
    expect(await WixApi(client: FakeWix().client).probeChecker(), CheckerProbe.live);
    expect(await WixApi(client: FakeWix(checker: false).client).probeChecker(), CheckerProbe.notThere);
    final offline = MockClient((_) async => throw http.ClientException('no internet'));
    expect(await WixApi(client: offline).probeChecker(), CheckerProbe.unreachable);

    final live = await started(FakeWix());
    expect(live.isLive, isTrue);
    expect(live.ready, isTrue);
    expect(live.companions.length, 2);

    final sample = await started(FakeWix(checker: false));
    expect(sample.isLive, isFalse, reason: 'the site isn’t published yet: keep the sample data');
    expect(sample.companions.length, AppModel().companions.length);
  });

  test('reads Companions and their stops from the Wix lists', () async {
    final model = await started(FakeWix());
    final c = model.companion('7')!;
    expect(c.number, '07');
    expect(c.status, CompanionStatus.waiting);
    expect(c.wish, 'see the ocean', reason: '“I want to …” and the full stop are trimmed');
    expect(c.blurb, 'Loves cafés.');
    expect(c.stops.map((s) => s.kind), ['made', 'left', 'found'], reason: 'made first, then oldest to newest');
    expect(c.stops[1].photoUrl, 'https://static.wixstatic.com/media/abc123~mv2.jpg');
    expect(c.stops[1].byLine, 'Left by Sam R.');
    expect(c.stops[1].note, 'Carried them through the arches.');
    expect(c.stops[2].photoUrl, isNull, reason: 'photos wait for The Herd’s quick look');
    expect(c.travelers, 2);
    final juniper = model.companion('3')!;
    expect(juniper.number, '3', reason: 'a number field from Wix becomes "3"');
    expect(juniper.displayName, 'Juniper');
    expect(model.originals.map((x) => x.number), ['3']);

    model.ensureChat('07');
    await pumpEventQueue();
    expect(model.chats['07']!.map((m) => m.text), ['Hello!'], reason: 'hidden chat is never shown');
  });

  test('a find code is checked by the checker: field "code" is wrong, field "nickname" is right', () async {
    final wix = FakeWix();
    final model = await started(wix);
    final wrong = await model.checkFindCode('07', 'nope');
    expect(wrong.check, CodeCheck.wrong);
    expect(wrong.message, contains('doesn’t match'));
    expect(model.hasFindCode('07'), isFalse);

    final right = await model.checkFindCode('07', 'good');
    expect(right.check, CodeCheck.right);
    expect(model.hasFindCode('07'), isTrue);
    expect(wix.calls.last.$2.containsKey('nickname'), isFalse, reason: 'checking a code never logs a find');
  });

  test('a find stores the hold token; a pass-on problem is marked on the right box', () async {
    final wix = FakeWix();
    final store = MemoryStore();
    final model = await started(wix, store: store);
    await model.checkFindCode('07', 'GOOD');
    final found = await model.submitFind('07', city: 'Aurora, CO', nickname: 'Robin', checkIn: CheckIn.none, exactPoint: _here);
    expect(found.ok, isTrue);
    expect(model.holding, contains('07'));
    expect(model.holdInfo['07']!.token, 'hold-07');
    expect(model.following, contains('07'));
    expect(wix.calls.last.$2['code'], 'GOOD', reason: 'the checked code is sent with the find');
    await pumpEventQueue();
    expect(store.values['herd.mine.live'], contains('hold-07'), reason: 'saved on the phone');

    final photo = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
    final noHint = await model.submitPassOn(
      '07',
      city: 'Boulder, CO',
      handedToSomeone: false,
      chapter: '',
      nickname: 'Robin',
      grantedWish: false,
      photo: photo,
      exactPoint: _farAway,
    );
    expect(noHint.ok, isFalse);
    expect(noHint.field, 'hint');
    expect(noHint.message, 'Please add a hint so the next person can find them.');
    expect(model.holding, contains('07'), reason: 'nothing changes when the checker says no');

    final sent = await model.submitPassOn(
      '07',
      city: 'Boulder, CO',
      place: 'Library shelf',
      handedToSomeone: false,
      chapter: 'Hi',
      nickname: 'Robin',
      grantedWish: true,
      photo: photo,
      wishPhoto: photo,
      exactPoint: _farAway,
    );
    expect(sent.ok, isTrue);
    final body = wix.calls.last.$2;
    expect(body['holdToken'], 'hold-07');
    expect((body['photo'] as Map)['mimeType'], 'image/png');
    expect(base64Decode((body['photo'] as Map)['base64'] as String), photo);
    expect(model.holding, isNot(contains('07')));
    expect(model.wishTokens['07'], 'wish-07');
    expect(model.stamps.first.big, 'Wish');
    expect(model.milesCarried, greaterThan(20));

    final wish = await model.submitWish('07', 'I want to see snow.');
    expect(wish.ok, isTrue);
    expect(wix.calls.last.$2['wishToken'], 'wish-07');
    expect(model.wishTokens.containsKey('07'), isFalse);
  });

  test('signing in brings the traveler’s Passport, Companions in their care and follows', () async {
    final wix = FakeWix();
    final model = await started(wix);
    final start = await model.signInStart('robin@example.com');
    expect(start.ok, isTrue);
    expect(start.previewCode, isNull, reason: 'LIVE codes are emailed');
    final wrong = await model.signInVerify('robin@example.com', '000000');
    expect(wrong.field, 'code');
    expect(model.signedIn, isFalse);

    final ok = await model.signInVerify('robin@example.com', '123456');
    expect(ok.ok, isTrue);
    expect(model.signedIn, isTrue);
    expect(model.account!.email, 'robin@example.com');
    expect(model.holding, contains('3'));
    expect(model.holdInfo['3']!.token, 'hold-3');
    expect(model.following, {'3'});
    expect(model.wishTokens['07'], 'wish-07');
    expect(model.nickname, 'Robin');
    expect(model.stamps.map((s) => s.big), ['Wish', '#07'], reason: 'the Passport history comes along');

    // On the next start-up, herdMine refreshes it; signing out leaves what came only from the sign-in.
    await model.syncAccount();
    expect(wix.calls.last.$1, 'herdMine');
    await model.signOut();
    expect(model.signedIn, isFalse);
    expect(model.holding, isNot(contains('3')));
    expect(model.wishTokens.containsKey('07'), isFalse);
  });

  test('SAMPLE keeps changes on the phone between visits, and sign-in works as a preview', () async {
    final wix = FakeWix(checker: false);
    final store = MemoryStore();
    final first = await started(wix, store: store);
    first.toggleFollow('3');
    first.tryFindCode('07', 'KCVT');
    first.logFind('07', city: 'Denver, CO', nickname: 'Sam', checkIn: CheckIn.none, exactPoint: _here);
    final stops = first.companion('07')!.stops.length;
    await pumpEventQueue();

    final again = await started(wix, store: store);
    expect(again.isLive, isFalse);
    expect(again.following, containsAll(['07', '2', '3']));
    expect(again.holding, contains('07'));
    expect(again.nickname, 'Sam');
    expect(again.companion('07')!.stops.length, stops, reason: 'the find is still on their page');
    expect(again.companion('07')!.current!.byLine, 'Found by Sam');
    expect(again.farEnoughToPassOn('07', _here), isFalse, reason: 'the 5-mile rule remembers where they were found');

    final code = await again.signInStart('sam@example.com');
    expect(code.previewCode, matches(RegExp(r'^\d{6}$')), reason: 'the preview shows the code on screen');
    expect((await again.signInStart('sam@example.com')).field, 'email', reason: 'one code a minute');
    expect((await again.signInVerify('sam@example.com', '99999x')).field, 'code');
    expect((await again.signInVerify('sam@example.com', code.previewCode!)).ok, isTrue);
    expect(again.signedIn, isTrue);
    expect(again.holding, contains('07'), reason: 'finds on this phone come along');
    final gone = await again.forgetMe();
    expect(gone.ok, isTrue);
    expect(again.signedIn, isFalse);
    expect(again.holding, contains('07'));
  });

  testWidgets('Save your Passport: email, then the code (shown on screen in the preview)', (tester) async {
    final model = AppModel();
    await tester.pumpWidget(HerdApp(model: model));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.bySemanticsLabel('Say hi and come in'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Passport').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save your Passport'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('signInEmail')), 'sam@example.com');
    await tester.pump();
    await tester.tap(find.text('EMAIL ME A SIGN-IN CODE'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    final note = find.textContaining('Preview: your code is ');
    expect(note, findsOneWidget);
    final code = RegExp(r'\d{6}').firstMatch(tester.widget<Text>(note).data!)!.group(0)!;
    await tester.enterText(find.byKey(const Key('signInCode')), code);
    await tester.ensureVisible(find.text('SIGN IN'));
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in as sam@example.com'), findsOneWidget);
    expect(model.signedIn, isTrue);
  });
}
