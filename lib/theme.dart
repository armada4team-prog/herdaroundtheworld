import 'package:material_ui/material_ui.dart';

/// The Herd's colours, taken from the designs (cream + sage, pastel blobs).
class Herd {
  static const cream = Color(0xFFFDF8F3);
  static const beige = Color(0xFFF6EFE7);
  static const field = Color(0xFFF1EAE3);
  static const sageBackground = Color(0xFFE7ECE5);
  static const sage = Color(0xFF6E8B7D);
  static const sageDark = Color(0xFF5B7869);
  static const ink = Color(0xFF3F5A4C);
  static const heading = Color(0xFF4F6B5D);
  static const body = Color(0xFF566E62);
  static const mint = Color(0xFFA8DCC9);
  static const mintSoft = Color(0xFFDDF0E8);
  static const mintInk = Color(0xFF2F4A3D);
  static const pink = Color(0xFFF6D3D3);
  static const pinkSoft = Color(0xFFFBE4E2);
  static const pinkInk = Color(0xFF6B3F3A);
  static const butter = Color(0xFFF9EBB5);
  static const butterInk = Color(0xFF5A4C1E);
  static const wishInk = Color(0xFF4F4320);
  static const rose = Color(0xFFD98C86);
  static const gold = Color(0xFFE0B94A);
  static const line = Color(0xFFEDE6DC);
  static const border = Color(0xFFE3DCD2);
  static const blush = Color(0xFFF2B4B0);
  static const stepDot = Color(0xFF8FAA9B);
}

Color hex(String value) => Color(int.parse('FF${value.replaceAll('#', '')}', radix: 16));

/// Fonts: Fira Sans (body), Shadows Into Light Two (handwritten headings), Baloo 2 (chunky labels).
class HerdText {
  static TextStyle script(double size, {Color color = Herd.heading}) =>
      TextStyle(fontFamily: 'ShadowsIntoLightTwo', fontSize: size, height: 1.25, color: color);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color color = Herd.body, double? height}) =>
      TextStyle(fontFamily: 'FiraSans', fontSize: size, fontWeight: weight, color: color, height: height ?? 1.4);

  static TextStyle chunky(double size, {bool extraBold = true, Color color = Herd.ink}) => TextStyle(
      fontFamily: 'Baloo2', fontSize: size, fontWeight: extraBold ? FontWeight.w800 : FontWeight.w700, color: color, height: 1.2);
}

ThemeData herdTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Herd.sageDark, surface: Herd.cream, primary: Herd.sageDark),
    scaffoldBackgroundColor: Herd.cream,
    fontFamily: 'FiraSans',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Herd.cream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Herd.ink,
      elevation: 0,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Herd.cream,
      indicatorColor: Herd.mintSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(HerdText.body(11, color: Herd.ink)),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: Herd.ink)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Herd.sageDark : Herd.border),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Herd.sageDark),
  );
}

/// Small uppercase label above headings ("ART IN TRANSIT · NO. 07").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Herd.sageDark});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: HerdText.body(13, color: color).copyWith(letterSpacing: 1));
}

/// "THE HERD" wordmark used in headers.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) =>
      Semantics(label: 'The Herd', child: ExcludeSemantics(child: Text('THE HERD', style: HerdText.chunky(22, color: Herd.sageDark))));
}

enum HerdButtonKind { primary, soft, outline }

/// Pill-shaped buttons from the designs.
class HerdButton extends StatelessWidget {
  const HerdButton(this.label, {super.key, required this.onPressed, this.kind = HerdButtonKind.primary, this.expand = true, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final HerdButtonKind kind;
  final bool expand;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = switch (kind) {
      HerdButtonKind.primary => Colors.white,
      HerdButtonKind.soft => Herd.mintInk,
      HerdButtonKind.outline => Herd.ink,
    };
    final bg = switch (kind) {
      HerdButtonKind.primary => Herd.sageDark,
      HerdButtonKind.soft => Herd.mint,
      HerdButtonKind.outline => Colors.transparent,
    };
    final enabled = onPressed != null;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 1,
        style: HerdText.body(15, weight: FontWeight.w500, color: fg).copyWith(letterSpacing: 0.6),
      ),
    );
    final button = Semantics(
      button: true,
      label: label,
      enabled: enabled,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: bg,
          shape: StadiumBorder(side: kind == HerdButtonKind.outline ? const BorderSide(color: Herd.sageDark, width: 2) : BorderSide.none),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                    Flexible(child: text),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return button;
  }
}

/// Rounded card used all over the designs.
class HerdCard extends StatelessWidget {
  const HerdCard({super.key, required this.children, this.color = Herd.beige, this.padding = 16, this.radius = 20, this.spacing = 8});
  final List<Widget> children;
  final Color color;
  final double padding;
  final double radius;
  final double spacing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: spacing, children: children),
      );
}

/// Field label and text field in the designs' style.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: HerdText.body(16, weight: FontWeight.w600, color: Herd.sageDark));
}

class HerdField extends StatelessWidget {
  const HerdField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.fieldKey,
    this.onChanged,
    this.maxLength,
    this.autofillHints,
    this.errorText,
    this.showCounter = false,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final bool showCounter;

  @override
  Widget build(BuildContext context) => TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        onChanged: onChanged,
        autofillHints: autofillHints,
        style: HerdText.body(16, color: Herd.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: HerdText.body(16, color: Herd.body.withValues(alpha: 0.7)),
          filled: true,
          fillColor: Herd.field,
          counterText: showCounter ? null : '',
          counterStyle: HerdText.body(12),
          errorText: errorText,
          errorMaxLines: 3,
          errorStyle: HerdText.body(13, color: const Color(0xFFB3261E)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );
}

/// Small rounded info pill ("6 stops", "Last seen in Santa Fe").
class InfoPill extends StatelessWidget {
  const InfoPill(this.text, {super.key, this.background = Herd.cream, this.foreground = Herd.ink});
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: HerdText.body(14, color: foreground)),
      );
}

/// Round icon button (mint circle) used in headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.label, required this.onTap, this.color = Herd.mintSoft, this.size = 44});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: size, height: size, child: Icon(icon, size: 20, color: Herd.mintInk)),
          ),
        ),
      );
}

/// App bar for pushed screens: back arrow and the wordmark (or a title) in the middle.
PreferredSizeWidget herdAppBar({String? title, List<Widget>? actions, bool showBack = true}) => AppBar(
      automaticallyImplyLeading: showBack,
      title: title == null ? const Wordmark() : Text(title, style: HerdText.chunky(17, extraBold: false)),
      actions: actions,
    );

/// 1453 → "1,453".
String formatThousands(int n) => n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
