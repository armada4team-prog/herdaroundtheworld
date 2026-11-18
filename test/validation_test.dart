import 'package:flutter_test/flutter_test.dart';
import 'package:herd_around_the_world/validation.dart';

void main() {
  group('word filter', () {
    test('blocks swearing, including disguised spellings', () {
      for (final bad in ['what the fuck', 'sh1t', 'FUUUUCK this', 'f u c k', 'f.u.c.k', 'you b!tch', r'a$$hole', 'kill yourself', 'go die']) {
        expect(containsBlockedLanguage(bad), isTrue, reason: bad);
      }
    });

    test('allows normal travel writing', () {
      for (final ok in [
        'We watched the sunrise over the Flatirons together.',
        'Left them at a café in Sussex near the class assignment board',
        'Hello from Scunthorpe! They loved the bass player.',
        'A really cocky seagull tried to steal them in Essex',
        'They saw the Dead Sea and a grasshopper',
      ]) {
        expect(containsBlockedLanguage(ok), isFalse, reason: ok);
      }
    });

    test('blocks links and contact details', () {
      expect(checkPublicText('visit www.example.com'), isNotNull);
      expect(checkPublicText('call 303 555 0100'), isNotNull);
      expect(checkPublicText('mail me at sam@example.com'), isNotNull);
      expect(checkPublicText('A lovely day in Lisbon'), isNull);
    });

    test('limits length', () {
      expect(checkPublicText('a' * 501, maxLength: 500), isNotNull);
    });
  });

  group('places', () {
    test('accepts City, State and City, Country', () {
      for (final ok in ['Santa Fe, NM', 'Boulder, Colorado', 'Lisbon, Portugal', 'São Paulo, Brazil', "St. John's, Newfoundland", 'Kyoto, Japan']) {
        expect(checkPlaceFormat(ok), isNull, reason: ok);
      }
    });

    test('rejects anything else', () {
      for (final bad in ['', 'Denver', 'my house', '123 Main St, Denver', 'asdf', 'fuck, shit', 'Denver, CO, USA, Earth']) {
        expect(checkPlaceFormat(bad), isNotNull, reason: bad);
      }
    });
  });

  test('nicknames', () {
    expect(checkNickname('Sam'), isNull);
    expect(checkNickname(''), isNotNull);
    expect(checkNickname('x'), isNotNull);
    expect(checkNickname('12345'), isNotNull);
    expect(checkNickname('Sh1thead'), isNotNull);
  });
}
