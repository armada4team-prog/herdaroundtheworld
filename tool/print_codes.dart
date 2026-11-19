// Lists the TEST find codes the app and website use before launch (sample mode).
// The real Companions' codes are random and live only in the Wix dashboard list
// "Companion Find Codes (private)": print those on the real labels.
// Run from the project folder:  dart run tool/print_codes.dart
// Keep this list private: anyone with a code can log a find for that Companion.

// ignore_for_file: avoid_print

import 'package:herd_around_the_world/find_codes.dart';

void main(List<String> args) {
  final count = args.isEmpty ? 52 : int.parse(args.first);
  print('No.  Code  QR code address');
  for (var n = 0; n < count; n++) {
    final number = n.toString().padLeft(2, '0');
    print('${number.padRight(4)} ${findCodeFor(number)}  ${qrAddressFor(number)}');
  }
}
