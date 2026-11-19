import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';
import 'info_screens.dart';

/// Passport tab: your travels, stamps and herd.
class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      body: SafeArea(
        child: ModelBuilder(
          builder: (context, model) => ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              const Wordmark(),
              const Spacer(),
              CircleIconButton(
                icon: Icons.share_outlined,
                label: 'Share',
                size: 40,
                onTap: () => SharePlus.instance.share(ShareParams(
                  text: 'I’m part of The Herd’s Companions project! Find one, carry one, watch them go. https://theherdstudio.com',
                )),
              ),
            ]),
            const SizedBox(height: 16),
            if (!model.signedIn) ...[
              Material(
                color: Herd.butter,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => showSignIn(context),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      const Icon(Icons.mail_outline, color: Herd.butterInk),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
                          Text(tr('Save your Passport'), style: HerdText.body(15, weight: FontWeight.w600, color: Herd.butterInk)),
                          Text(tr('Add your email so your stamps are never lost'), style: HerdText.body(13, color: Herd.butterInk)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Herd.butterInk),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _cover(model),
            const SizedBox(height: 14),
            Row(spacing: 10, children: [
              _tile('Map', 'Where everyone is', Herd.mintSoft, Herd.mintInk, () => router.select(AppTab.map)),
              _tile('Found one?', 'Scan a Companion', Herd.pinkSoft, Herd.pinkInk, () => router.select(AppTab.scan)),
            ]),
            const SizedBox(height: 18),
            const ScriptHeading('Stamps', size: 32),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              final width = (constraints.maxWidth - 24) / 3;
              return Wrap(spacing: 12, runSpacing: 18, children: [
                for (final s in [
                  ...model.stamps,
                  const Stamp(big: '?', small: 'Next', label: 'Your next Companion', background: 'FDF8F3', ring: 'B9C9BF', ink: '566E62', tilt: 0, isEmpty: true),
                  const Stamp(big: '?', small: 'Next', label: 'Grant another wish', background: 'FDF8F3', ring: 'B9C9BF', ink: '566E62', tilt: 0, isEmpty: true),
                ])
                  SizedBox(width: width, child: StampView(stamp: s, size: width.clamp(70, 100).toDouble())),
              ]);
            }),
            const SizedBox(height: 18),
            HerdCard(children: [
              Text(tr('Your herd: ${model.herdSize} travelers in 5 countries'), style: HerdText.chunky(18, extraBold: false)),
              Text(tr('Everyone who carried the same Companions as you. You’re connected, even if you’ve never met.'), style: HerdText.body(14)),
            ]),
            if (!model.isLive) ...[
              const SizedBox(height: 14),
              Center(child: Text(tr('Preview: using sample Companions'), style: HerdText.body(12))),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _cover(AppModel model) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Herd.sageDark, borderRadius: BorderRadius.circular(24)),
        child: Stack(children: [
          Positioned(right: -30, top: -30, child: Blob(color: Colors.white.withValues(alpha: 0.12), width: 130, height: 110, variant: 1)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
              const Eyebrow('Herd Around the World · Passport', color: Herd.mintSoft),
              Text(tr(model.nickname.isEmpty ? 'Your travels' : '${model.nickname}’s travels'), style: HerdText.script(36, color: Colors.white)),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _coverStat('${model.companionsCarried}', 'Companions carried'),
                _coverStat('${model.milesCarried}', 'Miles carried'),
                _coverStat('${model.herdSize}', 'Travelers in your herd'),
              ]),
            ]),
          ),
        ]),
      );

  Widget _coverStat(String n, String label) => Expanded(
        child: MergeSemantics(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n, style: HerdText.chunky(24, color: Colors.white)),
            Text(tr(label), style: HerdText.body(12, color: Herd.mintSoft)),
          ]),
        ),
      );

  Widget _tile(String title, String detail, Color bg, Color fg, VoidCallback onTap) => Expanded(
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                Text(tr(title), style: HerdText.chunky(16, extraBold: false, color: fg)),
                Text(tr(detail), style: HerdText.body(12, color: fg)),
              ]),
            ),
          ),
        ),
      );
}
