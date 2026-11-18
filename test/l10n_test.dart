import 'package:flutter_test/flutter_test.dart';
import 'package:herd_around_the_world/l10n.dart';

void main() {
  tearDown(() => Lang.code = 'en');

  test('English stays as written', () {
    expect(tr('Map'), 'Map');
  });

  test('Spanish, French and Japanese translate, including names and numbers', () {
    Lang.code = 'es';
    expect(tr('Map'), 'Mapa');
    expect(tr('You found #07!'), '¡Encontraste a #07!');
    Lang.code = 'fr';
    expect(tr('Send'), 'Envoyer');
    Lang.code = 'ja';
    expect(tr('Please keep it under 500 characters.'), '500文字以内にしてください。');
  });

  test('The most specific sentence wins', () {
    Lang.code = 'fr';
    expect(tr('Want #07 to check in with you?'), 'Tu veux que #07 te donne des nouvelles ?');
  });

  test('Unknown text falls back to English', () {
    Lang.code = 'es';
    expect(tr('Moab, UT'), 'Moab, UT');
  });
}
