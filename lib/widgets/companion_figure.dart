import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../theme.dart';

/// The little clay Companion: round head, rounded body, dot eyes, smile and blush.
/// Drawn on a 60 × 80 grid, like the SVG in the designs.
class CompanionFigure extends StatelessWidget {
  const CompanionFigure({
    super.key,
    this.glaze = Herd.mint,
    this.waving = false,
    this.happy = false,
    this.showsBlush = true,
    this.showsShadow = true,
    this.height = 80,
  });

  final Color glaze;
  final bool waving;
  final bool happy;
  final bool showsBlush;
  final bool showsShadow;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: height * 60 / 80,
          child: CustomPaint(painter: _FigurePainter(glaze, waving, happy, showsBlush, showsShadow)),
        ),
      );
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.glaze, this.waving, this.happy, this.blush, this.shadow);
  final Color glaze;
  final bool waving, happy, blush, shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 80;
    canvas.scale(s);
    final fill = Paint()..color = glaze;
    final ink = Paint()..color = Herd.ink;

    if (shadow) {
      canvas.drawOval(const Rect.fromLTWH(12, 74.5, 36, 5), Paint()..color = Herd.ink.withValues(alpha: 0.14));
    }

    final body = Path()
      ..moveTo(14, 46)
      ..quadraticBezierTo(14, 33, 30, 33)
      ..quadraticBezierTo(46, 33, 46, 46)
      ..lineTo(46, 70)
      ..quadraticBezierTo(46, 75, 41, 75)
      ..lineTo(19, 75)
      ..quadraticBezierTo(14, 75, 14, 70)
      ..close();
    canvas.drawPath(body, fill);

    if (waving) {
      final arm = Path()
        ..moveTo(14, 44)
        ..quadraticBezierTo(6, 36, 9, 27);
      canvas.drawPath(
          arm,
          Paint()
            ..color = glaze
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
    }

    canvas.drawCircle(const Offset(30, 20), 14, fill);

    final line = Paint()
      ..color = Herd.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (happy) {
      canvas.drawPath(
          Path()
            ..moveTo(23, 19)
            ..quadraticBezierTo(25, 16, 27, 19)
            ..moveTo(33, 19)
            ..quadraticBezierTo(35, 16, 37, 19),
          line);
      // Closed open-mouth smile, so it has a full outline.
      final mouth = Path()
        ..moveTo(24, 24)
        ..quadraticBezierTo(30, 31, 36, 24)
        ..close();
      canvas.drawPath(mouth, Paint()..color = Herd.blush);
      canvas.drawPath(mouth, line);
    } else {
      canvas.drawCircle(const Offset(25, 19), 1.8, ink);
      canvas.drawCircle(const Offset(35, 19), 1.8, ink);
      canvas.drawPath(
          Path()
            ..moveTo(26, 25)
            ..quadraticBezierTo(30, 28, 34, 25),
          line..strokeWidth = 1.5);
    }

    if (blush) {
      final b = Paint()..color = Herd.blush.withValues(alpha: 0.8);
      canvas.drawCircle(const Offset(21, 23.5), 2.2, b);
      canvas.drawCircle(const Offset(39, 23.5), 2.2, b);
    }
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.glaze != glaze || old.waving != waving || old.happy != happy || old.blush != blush || old.shadow != shadow;
}

/// Soft, lopsided "pebble" shape used behind figures and as decoration.
class BlobBorder extends OutlinedBorder {
  const BlobBorder({this.variant = 0, super.side});
  final int variant;

  static const _sets = [
    [0.42, 0.58, 0.38, 0.62, 0.52, 0.40, 0.60, 0.48],
    [0.55, 0.45, 0.50, 0.50, 0.50, 0.60, 0.40, 0.50],
    [0.60, 0.40, 0.55, 0.45, 0.50, 0.60, 0.40, 0.50],
    [0.45, 0.55, 0.40, 0.60, 0.55, 0.45, 0.60, 0.40],
  ];

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final v = _sets[variant.abs() % _sets.length];
    final w = rect.width, h = rect.height;
    return Path()
      ..addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.elliptical(v[0] * w, v[4] * h),
        topRight: Radius.elliptical(v[1] * w, v[5] * h),
        bottomRight: Radius.elliptical(v[2] * w, v[6] * h),
        bottomLeft: Radius.elliptical(v[3] * w, v[7] * h),
      ));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;

  @override
  OutlinedBorder copyWith({BorderSide? side}) => BlobBorder(variant: variant, side: side ?? this.side);
}

/// A filled blob.
class Blob extends StatelessWidget {
  const Blob({super.key, required this.color, this.width = 100, this.height = 100, this.variant = 0, this.child});
  final Color color;
  final double width, height;
  final int variant;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(color: color, shape: BlobBorder(variant: variant)),
        child: child,
      );
}

/// A Companion standing in a soft blob, used on cards and headers.
class CompanionBadge extends StatelessWidget {
  const CompanionBadge({super.key, required this.companion, this.size = 56, this.waving = false, this.happy = false});
  final Companion companion;
  final double size;
  final bool waving, happy;

  @override
  Widget build(BuildContext context) {
    final drawing = Center(
      child: CompanionFigure(glaze: companion.glazeColor, waving: waving, happy: happy, showsShadow: false, height: size * 0.66),
    );
    final photo = companion.profilePhoto;
    final shape = BlobBorder(variant: companion.number.length);
    return ExcludeSemantics(
      child: Blob(
        color: companion.blobColor,
        width: size,
        height: size,
        variant: companion.number.length,
        // A real photo from Wix when The Herd has added one; the drawing until then (or if it won't load).
        child: photo == null
            ? drawing
            : ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: Image.network(photo, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => drawing),
              ),
      ),
    );
  }
}
