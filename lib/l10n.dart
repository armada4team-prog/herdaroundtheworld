/// Translations: English is written in the code; Spanish, French and Japanese come from
/// `translations.dart`. Every piece of app text goes through [tr]. Sentences with names or
/// numbers in them ("You found #07!") are matched by pattern ("You found {0}!").
///
/// Travelers' own chapters and chat messages are never translated: they stay in the language
/// they were written in.
library;

import 'package:material_ui/material_ui.dart';

import 'translations.dart';

class Lang {
  static String code = 'en';
}

final Map<String, List<(RegExp, String)>> _patternCache = {};

List<(RegExp, String)> _patterns(String code) => _patternCache.putIfAbsent(code, () {
      final table = translations[code] ?? const {};
      // Most specific patterns first, so "Want {0} to check in with you?" wins over "{0} in {1}".
      final keys = table.keys.where((k) => k.contains('{0}')).toList()
        ..sort((a, b) => b.replaceAll(RegExp(r'\{\d\}'), '').length.compareTo(a.replaceAll(RegExp(r'\{\d\}'), '').length));
      return [
        for (final key in keys)
          (
            RegExp('^${RegExp.escape(key).replaceAllMapped(RegExp(r'\\\{(\d)\\\}'), (_) => '(.+?)')}\$', dotAll: true),
            table[key]!,
          ),
      ];
    });

/// Translates one piece of app text into the current language.
String tr(String english) {
  if (Lang.code == 'en' || english.isEmpty) return english;
  final table = translations[Lang.code];
  if (table == null) return english;
  final exact = table[english];
  if (exact != null) return exact;
  for (final (pattern, translated) in _patterns(Lang.code)) {
    final match = pattern.firstMatch(english);
    if (match != null) {
      var out = translated;
      for (var i = 1; i <= match.groupCount; i++) {
        out = out.replaceAll('{${i - 1}}', tr(match.group(i)!));
      }
      return out;
    }
  }
  return english;
}

/// Redraws every screen after the language changes (keeps your place in the app).
void rebuildAllText(BuildContext context) {
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
