/// Find codes: proof that someone is really holding a Companion.
///
/// Every Companion has a short secret code (like "KX4P"). It's hidden inside the QR code on
/// their bottom (https://companions.theherdstudio.com/c/07?k=KX4P) and printed small under their number,
/// for when the camera won't scan. Logging a find needs that code, so typing a number alone
/// only lets you look at a Companion's page.
///
/// These codes are only used in SAMPLE mode. In LIVE mode (The Herd's Wix site is published) the
/// codes live only on the Wix site and are checked there (AppModel.checkFindCode), so nobody can
/// dig them out of the app. Run `dart run tool/print_codes.dart` to list every code for printing.
library;

/// Letters and digits that can't be mixed up on a tiny label (no 0/O, 1/I/L, 2/Z, 5/S, 8/B).
const _alphabet = 'ACDEFGHJKMNPQRTUVWXY34679';
const _studioKey = 'the-herd-aurora-co-companions';

/// The secret code for one Companion, like "KX4P".
String findCodeFor(String number) {
  // FNV-1a hash of the studio key and the number, turned into 4 characters.
  var hash = 0x811c9dc5;
  for (final unit in '$_studioKey:${_cleanNumber(number)}'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final out = StringBuffer();
  for (var i = 0; i < 4; i++) {
    out.write(_alphabet[hash % _alphabet.length]);
    hash ~/= _alphabet.length;
    hash = (hash * 0x01000193 + i) & 0xffffffff;
  }
  return out.toString();
}

/// "07", "7" and "No. 7" are the same Companion (same as AppModel.cleanNumber).
String _cleanNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
  return trimmed.isEmpty ? (digits.isEmpty ? '' : '0') : trimmed;
}

/// Tidies what someone typed: "kx4p", "KX-4P" and " kx 4p " all become "KX4P".
String cleanFindCode(String typed) => typed.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool isRightFindCode(String number, String typed) => cleanFindCode(typed) == findCodeFor(number);

/// The web address to put in a Companion's QR code.
String qrAddressFor(String number) => 'https://companions.theherdstudio.com/c/$number?k=${findCodeFor(number)}';

/// Reads the code out of a scanned QR address ("...?k=KX4P"), if it has one.
String? codeFromScan(String payload) => RegExp(r'[?&]k=([A-Za-z0-9]+)').firstMatch(payload)?.group(1);
