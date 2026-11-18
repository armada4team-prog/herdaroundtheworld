/// Rules for what people can type: places must be a real "City, State" (or "City, Country"),
/// and anything shown to others is checked for swearing, slurs, sexual or violent words,
/// links and contact details.
///
/// No word filter is perfect, so The Herd still reviews new chapters, and people can report
/// chat messages. Add words to the lists below as needed.
library;

/// Words that are blocked whenever they appear as a whole word (after cleaning up tricks like
/// "sh1t" or "fuuuck").
const _blockedWords = <String>{
  // Swearing
  'fuck', 'fucks', 'fucker', 'fuckers', 'fucking', 'fucked', 'fck', 'fuk', 'fuq', 'fking', 'fkn', 'wtf', 'stfu',
  'shit', 'shits', 'shitty', 'shite', 'bullshit', 'sht',
  'bitch', 'bitches', 'bitchy', 'btch',
  'cunt', 'cunts', 'twat', 'twats', 'prick', 'pricks', 'wanker', 'wankers', 'bollocks',
  'ass', 'asses', 'asshole', 'assholes', 'arse', 'arsehole', 'jackass', 'dumbass', 'badass',
  'dick', 'dicks', 'dickhead', 'cock', 'cocks', 'pussy', 'pussies', 'bastard', 'bastards',
  'motherfucker', 'motherfucking', 'mf', 'mofo', 'piss', 'pissed', 'crap', 'douche', 'douchebag',
  // Sexual or gross
  'sex', 'sexy', 'porn', 'porno', 'nude', 'nudes', 'naked', 'boob', 'boobs', 'tits', 'titties', 'penis', 'vagina',
  'dildo', 'cum', 'jizz', 'horny', 'blowjob', 'handjob', 'orgasm', 'masturbate', 'erection', 'anal', 'milf',
  'poop', 'vomit', 'puke', 'diarrhea', 'semen', 'genitals',
  // Hateful
  'nazi', 'nazis', 'hitler', 'heil', 'kkk',
  // Harm
  'kys', 'suicide', 'rape', 'raped', 'rapist', 'molest', 'pedo', 'pedophile', 'terrorist', 'gore', 'murder', 'murdered',
};

/// Word starts that are blocked (catches slurs and their variants).
const _blockedStarts = <String>[
  'fuck', 'shit', 'bitch', 'cunt', 'whore', 'slut', 'motherf', 'nigg', 'nigga', 'niga', 'fagg', 'faggot', 'retard',
  'spic', 'chink', 'kike', 'wetback', 'tranny', 'dyke', 'gook', 'beaner', 'raghead', 'towelhead', 'coon',
  'pornh', 'xxx', 'dickh', 'cocks', 'pussi', 'asshol',
];

/// Phrases that are blocked anywhere in the text.
const _blockedPhrases = <String>[
  'kill yourself', 'kill your self', 'kill myself', 'go die', 'hope you die', 'blow job', 'hand job', 'son of a bitch',
];

const _leet = {'0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '8': 'b', '@': 'a', r'$': 's', '!': 'i', '|': 'l', '+': 't'};

String _clean(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    buffer.write(_leet[ch] ?? ch);
  }
  return buffer.toString();
}

/// "fuuuuck" → "fuck" (so stretched-out words are still caught).
String _squash(String word) => word.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]!);

bool _isBlockedWord(String word) {
  if (word.isEmpty) return false;
  final forms = {word, _squash(word), word.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!)};
  for (final w in forms) {
    if (_blockedWords.contains(w)) return true;
    for (final start in _blockedStarts) {
      if (w.startsWith(start)) return true;
    }
  }
  return false;
}

/// True if the text contains a blocked word, phrase, or a spaced-out blocked word ("f u c k").
bool containsBlockedLanguage(String text) {
  final cleaned = _clean(text);
  final words = cleaned.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty).toList();
  if (words.any(_isBlockedWord)) return true;

  final spaced = cleaned.replaceAll(RegExp(r'[^a-z ]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');
  for (final phrase in _blockedPhrases) {
    if (spaced.contains(phrase)) return true;
  }

  // Runs of single letters joined together: "f u c k", "f.u.c.k", "s-h-i-t".
  final run = StringBuffer();
  for (final w in [...words, '']) {
    if (w.length == 1) {
      run.write(w);
    } else {
      if (run.length >= 3 && _isBlockedWord(run.toString())) return true;
      run.clear();
    }
  }
  return false;
}

final _link = RegExp(r'(https?://|www\.|\b[a-z0-9-]+\.(com|net|org|io|co|app|xyz|info|biz|ly|me|gg)\b)', caseSensitive: false);
final _email = RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
final _phone = RegExp(r'\+?\d[\d\s().-]{7,}\d');

/// Checks text that other people will see (chapters, chat, nicknames, wishes, place descriptions).
/// Returns a friendly message if it isn't allowed, or null if it's fine.
String? checkPublicText(String text, {int? maxLength}) {
  final t = text.trim();
  if (maxLength != null && t.length > maxLength) return 'Please keep it under $maxLength characters.';
  if (containsBlockedLanguage(t)) return 'Please keep it kind. Some words aren’t allowed here.';
  if (_link.hasMatch(t)) return 'Links can’t be added here.';
  if (_email.hasMatch(t) || _phone.hasMatch(t)) return 'Please don’t share phone numbers, emails or addresses.';
  return null;
}

/// A nickname: required, short, and kind.
String? checkNickname(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'Please add a name or nickname.';
  if (t.length < 2) return 'Please use at least 2 letters.';
  if (!RegExp(r'[A-Za-zÀ-ÿЀ-ӿ぀-ヿ一-鿿]').hasMatch(t)) return 'Please use letters in your nickname.';
  return checkPublicText(t, maxLength: 30);
}

final _placePart = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿĀ-žḀ-ỿ .'’-]{2,60}$");

/// A place must be "City, State" or "City, Country" (or "City, County"): letters only, no street
/// numbers, so it can't be a home address.
String? checkPlaceFormat(String text) {
  final t = text.trim();
  if (t.isEmpty) return 'Please add the city and state or country.';
  if (RegExp(r'\d').hasMatch(t)) return 'Just the city and state or country, please. No street addresses.';
  final parts = t.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return 'Please write it as City, State (or City, Country). For example: Santa Fe, NM';
  if (parts.length > 3) return 'Just the city and state or country, please.';
  if (!parts.every(_placePart.hasMatch)) return 'Please use only letters for the city and state or country.';
  if (containsBlockedLanguage(t)) return 'Please enter a real place.';
  return null;
}

/// A simple email check (something@something.something).
bool isEmail(String text) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(text.trim());

/// A short description of a public place ("café on the plaza"): optional, kind, and no street address.
String? checkPlaceDescription(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  if (RegExp(r'\d+\s+\w+\s+(st|street|ave|avenue|rd|road|blvd|boulevard|ln|lane|dr|drive|way|ct|court|pl|place)\b', caseSensitive: false).hasMatch(t)) {
    return 'Please describe the spot instead of giving a street address.';
  }
  return checkPublicText(t, maxLength: 60);
}
