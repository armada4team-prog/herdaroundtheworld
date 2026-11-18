import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app_state.dart';
import '../find_codes.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';

/// Scan tab: point the camera at the code on a Companion's bottom, or type their number.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Phones get the camera first; elsewhere (and if the camera fails) the number box shows.
  bool typing = kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool cameraFailed = false;
  bool notFound = false;
  Companion? found;
  String? codeError;
  final number = TextEditingController();
  final code = TextEditingController();
  final numberFocus = FocusNode();

  @override
  void dispose() {
    number.dispose();
    code.dispose();
    numberFocus.dispose();
    super.dispose();
  }

  void openCompanion(Companion c) {
    numberFocus.unfocus();
    context.router.push(CompanionRoute(c.number, showHello: true));
  }

  void onScan(BarcodeCapture capture) {
    if (found != null) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null) continue;
      final n = AppModel.numberFromScan(raw);
      final c = n == null ? null : context.model.companion(n);
      if (c != null) {
        // The code hidden in the QR address proves they're holding this Companion.
        final hidden = codeFromScan(raw);
        if (hidden != null) context.model.tryFindCode(c.number, hidden);
        setState(() => found = c);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          openCompanion(c);
          setState(() => found = null);
        });
        return;
      }
    }
  }

  void findTyped() {
    final c = context.model.companion(number.text);
    if (c == null) {
      setState(() => notFound = true);
      return;
    }
    // No code: just looking at their page. With a code: unlocks logging a find.
    if (code.text.trim().isNotEmpty) {
      final check = context.model.tryFindCode(c.number, code.text);
      if (check != CodeCheck.right) {
        setState(() {
          notFound = false;
          codeError = check == CodeCheck.tooManyTries
              ? 'Too many tries. Please wait 10 minutes and try again.'
              : 'That code doesn’t match #{0}. Check the letters under their number.'.replaceAll('{0}', c.number);
        });
        return;
      }
    }
    setState(() {
      notFound = false;
      codeError = null;
    });
    number.clear();
    code.clear();
    openCompanion(c);
  }

  @override
  Widget build(BuildContext context) {
    final showTyping = typing || cameraFailed;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Align(alignment: Alignment.centerLeft, child: Wordmark()),
            const SizedBox(height: 18),
            Text(tr('Found a Companion?'), textAlign: TextAlign.center, style: HerdText.script(38)),
            const SizedBox(height: 6),
            Text(
              tr('Flip them over and point your camera at the code on their bottom.'),
              textAlign: TextAlign.center,
              style: HerdText.body(16),
            ),
            const SizedBox(height: 18),
            if (showTyping)
              _typePanel()
            else ...[
              _camera(),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => typing = true);
                    numberFocus.requestFocus();
                  },
                  child: Text(
                    tr('Or type their number instead'),
                    style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _camera() => Semantics(
    label: 'Camera viewfinder. Point it at the code on the Companion’s bottom.',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 380,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(
              onDetect: onScan,
              errorBuilder: (context, error) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !cameraFailed) setState(() => cameraFailed = true);
                });
                return const ColoredBox(color: Herd.sageBackground);
              },
            ),
            IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Herd.cream, width: 4),
                ),
              ),
            ),
            if (found != null)
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(color: Herd.mintSoft, borderRadius: BorderRadius.circular(999)),
                  child: Column(
                    children: [
                      Text(
                        tr('Hi! It’s #${found!.number}, ${found!.displayName}'),
                        style: HerdText.chunky(17, extraBold: false, color: Herd.mintInk),
                      ),
                      Text(tr('Opening their page…'), style: HerdText.body(13, color: Herd.mintInk)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _typePanel() => HerdCard(
    radius: 24,
    padding: 18,
    spacing: 12,
    children: [
      Text(tr('Type their number'), style: HerdText.chunky(20, extraBold: false)),
      Text(tr('It’s printed on their bottom, under the code: “No. 07”.'), style: HerdText.body(14)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Herd.field, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Text(tr('No.'), style: HerdText.chunky(24, color: Herd.sageDark)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('scanNumber'),
                controller: number,
                focusNode: numberFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => findTyped(),
                onChanged: (_) => setState(() {}),
                style: HerdText.chunky(24, extraBold: false),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '07',
                  hintStyle: HerdText.chunky(24, extraBold: false, color: Herd.body.withValues(alpha: 0.5)),
                  semanticCounterText: 'Companion number',
                ),
              ),
            ),
          ],
        ),
      ),
      Text(tr('Their find code'), style: HerdText.chunky(16, extraBold: false)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Herd.field, borderRadius: BorderRadius.circular(14)),
        child: TextField(
          key: const Key('scanCode'),
          controller: code,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 6,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => findTyped(),
          onChanged: (_) => setState(() => codeError = null),
          style: HerdText.chunky(22, extraBold: false),
          decoration: InputDecoration(
            border: InputBorder.none,
            counterText: '',
            hintText: 'KX4P',
            hintStyle: HerdText.chunky(22, extraBold: false, color: Herd.body.withValues(alpha: 0.5)),
            semanticCounterText: 'Find code',
          ),
        ),
      ),
      Text(
        tr('The 4 letters printed under their number. You need it to log a find. Leave it empty to just look at their page.'),
        style: HerdText.body(13),
      ),
      if (codeError != null) Text(tr(codeError!), style: HerdText.body(14, color: Herd.pinkInk)),
      if (notFound)
        Text(tr('We couldn’t find that number. Check their bottom and try again.'), style: HerdText.body(14, color: Herd.pinkInk)),
      HerdButton('Find them →', onPressed: number.text.isEmpty ? null : findTyped),
      if (!cameraFailed && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) && !kIsWeb)
        Center(
          child: TextButton(
            onPressed: () {
              numberFocus.unfocus();
              setState(() {
                typing = false;
                notFound = false;
              });
            },
            child: Text(tr('Back to the camera'), style: HerdText.body(15, color: Herd.sageDark)),
          ),
        )
      else
        Text(tr('The camera isn’t available here, so type their number instead.'), style: HerdText.body(13)),
    ],
  );
}
