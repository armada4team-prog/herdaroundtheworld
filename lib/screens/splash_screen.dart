import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n.dart';

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
  // One smooth loop drives everything: three gentle floats, then an eased twirl at the end.
  late final loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      loop.stop();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Herd.cream,
      child: Stack(
        children: [
          const Positioned(left: -60, top: 120, child: Blob(color: Herd.pink, width: 150, height: 170, variant: 1)),
          const Positioned(right: -50, top: 200, child: Blob(color: Herd.butter, width: 140, height: 140, variant: 2)),
          const Positioned(right: -40, bottom: 60, child: Blob(color: Herd.mintSoft, width: 200, height: 160, variant: 3)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Wordmark(),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Say hi and come in',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: widget.onEnter,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 240,
                          height: 230,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              const Blob(color: Herd.mintSoft, width: 230, height: 220),
                              AnimatedBuilder(
                                animation: loop,
                                builder: (context, child) {
                                  final t = loop.value;
                                  // Float up and down three times per loop, with no sudden stops (a smooth wave).
                                  final float = (1 - math.cos(t * 3 * 2 * math.pi)) / 2;
                                  final lift = -24 * float;
                                  // Twirl once in the last part of the loop, easing in and out.
                                  const twirlStart = 0.66;
                                  final twirl = t < twirlStart ? 0.0 : Curves.easeInOutCubic.transform((t - twirlStart) / (1 - twirlStart));
                                  final turn = Matrix4.identity()
                                    ..setEntry(3, 2, 0.0005) // a little perspective, so it looks like a real turn
                                    ..rotateY(twirl * 2 * math.pi);
                                  return Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Their shadow on the ground shrinks as they float up.
                                      Positioned(
                                        bottom: 12,
                                        child: Container(
                                          width: 96 - 30 * float,
                                          height: 14 - 4 * float,
                                          decoration: BoxDecoration(
                                            color: Herd.ink.withValues(alpha: 0.16 - 0.07 * float),
                                            borderRadius: const BorderRadius.all(Radius.elliptical(60, 10)),
                                          ),
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: Offset(0, lift - 18),
                                        child: Transform(alignment: Alignment.center, transform: turn, child: child),
                                      ),
                                    ],
                                  );
                                },
                                // Drawn once and reused every frame, so the motion stays smooth.
                                child: const RepaintBoundary(
                                  child: CompanionFigure(glaze: Herd.mint, waving: true, happy: true, showsShadow: false, height: 170),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          tr('Tap me to say hi!'),
                          style: HerdText.body(15, weight: FontWeight.w500, color: Herd.sageDark),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr('Herd Around the World'), textAlign: TextAlign.center, style: HerdText.script(40)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(tr('Children of the clay, on the move'), style: HerdText.body(16)),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
