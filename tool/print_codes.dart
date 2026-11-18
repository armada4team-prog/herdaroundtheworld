// Lists every Companion's find code and QR address, for printing their bottom labels.
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
