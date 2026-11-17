import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/companion_figure.dart';

/// Welcome: a bouncing, twirling Companion. Tap them to come in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onEnter});
  final VoidCallback onEnter;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..repeat(reverse: true);
  late final spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      bounce.stop();
      spin.stop();
    }
  }

  @override
  void dispose() {
    bounce.dispose();
    spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Herd.cream,
      child: Stack(children: [
        const Positioned(left: -60, top: 120, child: Blob(color: Herd.pink, width: 150, height: 170, variant: 1)),
        const Positioned(right: -50, top: 200, child: Blob(color: Herd.butter, width: 140, height: 140, variant: 2)),
        const Positioned(right: -40, bottom: 60, child: Blob(color: Herd.mintSoft, width: 200, height: 160, variant: 3)),
        SafeArea(
          child: Column(children: [
            const SizedBox(height: 12),
            const Wordmark(),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Say hi and come in',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: widget.onEnter,
                child: Column(children: [
                  SizedBox(
                    width: 240,
                    height: 230,
                    child: Stack(alignment: Alignment.bottomCenter, children: [
                      const Blob(color: Herd.mintSoft, width: 230, height: 220),
                      AnimatedBuilder(
                        animation: Listenable.merge([bounce, spin]),
                        builder: (context, child) {
                          final lift = Curves.easeInOut.transform(bounce.value) * -26;
                          // Twirl: squash horizontally like a turn, using cos of the spin angle.
                          final cos = math.cos(spin.value * 2 * math.pi);
                          final turn = (cos < 0 ? -1 : 1) * (0.35 + 0.65 * cos.abs());
                          return Transform.translate(
                            offset: Offset(0, lift - 18),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(turn, 1, 1),
                              child: child,
                            ),
                          );
                        },
                        child: const CompanionFigure(glaze: Herd.mint, waving: true, happy: true, height: 170),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text('Tap me to say hi!', style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark)),
                ]),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text('Herd Around the World', textAlign: TextAlign.center, style: HerdText.script(40))),
            ),
            const SizedBox(height: 6),
            Text('Children of the clay, on the move', style: HerdText.body(16)),
            const SizedBox(height: 36),
          ]),
        ),
      ]),
    );
  }
}
