import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n.dart';

import '../models.dart';
import '../theme.dart';

/// A Passport stamp: round, slightly tilted, with a big word and a small word.
class StampView extends StatelessWidget {
  const StampView({super.key, required this.stamp, this.size = 92});
  final Stamp stamp;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = hex(stamp.ink);
    return Semantics(
      label: tr(stamp.isEmpty ? 'Empty stamp: ${stamp.label}' : 'Stamp: ${stamp.label}'),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: stamp.tilt * math.pi / 180,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: hex(stamp.background),
                shape: BoxShape.circle,
                border: stamp.isEmpty ? null : Border.all(color: hex(stamp.ring), width: 3),
              ),
              foregroundDecoration: stamp.isEmpty ? _DashedCircleDecoration(hex(stamp.ring)) : null,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr(stamp.big), style: HerdText.chunky(size * 0.24, color: ink)),
                  Text(tr(stamp.small).toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HerdText.body(size * 0.1, color: ink).copyWith(letterSpacing: 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(tr(stamp.label), textAlign: TextAlign.center, style: HerdText.body(13, color: Herd.ink)),
        ],
      ),
    );
  }
}

class _DashedCircleDecoration extends Decoration {
  const _DashedCircleDecoration(this.color);
  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _DashedCirclePainter(color);
}

class _DashedCirclePainter extends BoxPainter {
  _DashedCirclePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final center = offset + Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const dashes = 22;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.pi / dashes, false, paint);
    }
  }
}

/// Filter pill on the map (same colours as the website map).
class FilterPill extends StatelessWidget {
  const FilterPill({super.key, required this.filter, required this.selected, required this.onTap});
  final MapFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : hex(filter.foreground);
    return Semantics(
      button: true,
      selected: selected,
      label: tr(filter.label),
      excludeSemantics: true,
      child: Material(
        color: selected ? Herd.sageDark : hex(filter.background),
        shape: const StadiumBorder(),
        elevation: 1,
        shadowColor: Herd.ink.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (filter.dot != null) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: hex(filter.dot!), shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(tr(filter.label), style: HerdText.body(14, color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Wish card: yellow card with a star and the wish in handwriting.
class WishCard extends StatelessWidget {
  const WishCard({super.key, required this.wish, this.granted = false, this.note});
  final String wish;
  final bool granted;
  final String? note;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Herd.butter, borderRadius: BorderRadius.circular(20)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.star_rounded, color: Herd.gold, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Eyebrow(granted ? 'Their wish · granted!' : 'Their wish · not granted yet', color: Herd.butterInk),
              Text(tr('“$wish”'), style: HerdText.script(26, color: Herd.wishInk)),
              if (note != null) Text(tr(note!), style: HerdText.body(14, color: Herd.butterInk)),
            ]),
          ),
        ]),
      );
}

/// Numbered step row ("1  Take me along for a while…").
class NumberedRow extends StatelessWidget {
  const NumberedRow(this.number, this.text, {super.key});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ExcludeSemantics(
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Herd.stepDot, shape: BoxShape.circle),
            child: Text(number, style: HerdText.chunky(14, extraBold: false, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(tr(text), style: HerdText.body(15, color: Herd.ink))),
      ]);
}

/// Segmented choice (App alert / Email / No thanks).
class PillPicker<T> extends StatelessWidget {
  const PillPicker({super.key, required this.options, required this.selected, required this.onChanged});
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Herd.field, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            for (final (value, label) in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: value == selected,
                  label: tr(label),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onChanged(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: value == selected ? Herd.sageDark : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                      child: Text(tr(label), style: HerdText.body(14, weight: FontWeight.w500, color: value == selected ? Colors.white : Herd.ink)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Radio-style option card (Handing them to someone / Leaving them somewhere).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({super.key, required this.title, required this.detail, this.badge, required this.selected, required this.onTap});
  final String title;
  final String detail;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${tr(title)}. ${tr(detail)}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? Herd.sageDark : Herd.border, width: 2),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: Herd.sageDark, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(tr(title), style: HerdText.body(16, weight: FontWeight.w500, color: Herd.ink)),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                        decoration: BoxDecoration(color: Herd.mintSoft, borderRadius: BorderRadius.circular(999)),
                        child: Text(tr(badge!), style: HerdText.body(12, color: Herd.mintInk)),
                      ),
                  ]),
                  Text(tr(detail), style: HerdText.body(14)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

/// Placeholder for traveler photos (until real photos come from the server).
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key, this.label = 'Traveler’s photo', this.color = Herd.sageBackground, this.height = 120});
  final String label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.photo_camera_outlined, color: Herd.body),
            const SizedBox(height: 6),
            Text(tr(label), style: HerdText.body(13)),
          ]),
        ),
      );
}

/// Toggle row with a label.
class LabeledSwitch extends StatelessWidget {
  const LabeledSwitch({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Row(children: [
          Expanded(child: Text(tr(label), style: HerdText.body(15, color: Herd.ink))),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

/// Section heading in handwriting.
class ScriptHeading extends StatelessWidget {
  const ScriptHeading(this.text, {super.key, this.size = 30});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(header: true, child: Text(tr(text), style: HerdText.script(size)));
}

/// A row in a list that opens something (chevron on the right).
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.title, required this.subtitle, required this.onTap, this.leading});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Material(
        color: Herd.beige,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(tr(title), style: HerdText.chunky(16, extraBold: false)),
                  Text(tr(subtitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: HerdText.body(13)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Herd.sageDark),
            ]),
          ),
        ),
      );
}

/// Soft mint chip button ("Use my city").
Widget softChip(String label, IconData icon, VoidCallback? onTap) => Material(
      color: Herd.mintSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: Herd.mintInk),
            const SizedBox(width: 8),
            Text(tr(label), style: HerdText.body(15, color: Herd.mintInk)),
          ]),
        ),
      ),
    );
