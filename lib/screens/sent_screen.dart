import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';

/// "Thank you! They're on their way." — postcard, Instagram tips and the new stamp.
class SentScreen extends StatefulWidget {
  const SentScreen({super.key, required this.number});
  final String number;

  @override
  State<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends State<SentScreen> {
  final postcardKey = GlobalKey();
  bool copied = false;

  Future<void> savePostcard(Companion c) async {
    final boundary = postcardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png', name: 'companion-${c.number}-postcard.png')],
        text: 'Greetings from ${c.current?.city ?? 'the road'}!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.model;
    final router = context.router;
    final c = model.companion(widget.number);
    final city = c?.current?.city ?? '';
    final caption = 'Companion #${widget.number} is in $city! Thanks for traveling with me. @growtheherdstudio #TheHerdCompanions';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('Sent on their way'), style: HerdText.chunky(17, extraBold: false)),
        actions: [
          TextButton(
            onPressed: router.popToRoot,
            child: Text(
              tr('Done'),
              style: HerdText.body(16, weight: FontWeight.w500, color: Herd.sageDark),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr('Thank you! They’re on their way.'), textAlign: TextAlign.center, style: HerdText.script(40)),
          const SizedBox(height: 6),
          Text(
            tr('Your chapter is on their map now. Photos appear after a quick look, usually within a few days.'),
            textAlign: TextAlign.center,
            style: HerdText.body(16),
          ),
          if (c != null && c.miles > 0) ...[
            const SizedBox(height: 10),
            Center(
              child: InfoPill(
                '★ Milestone: #${widget.number} has traveled ${formatThousands(c.miles)} miles!',
                background: Herd.butter,
                foreground: Herd.butterInk,
              ),
            ),
          ],
          if (c != null) ...[
            const SizedBox(height: 16),
            RepaintBoundary(
              key: postcardKey,
              child: Postcard(companion: c),
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: HerdButton(
                    copied ? 'Copied!' : 'Copy caption',
                    kind: HerdButtonKind.soft,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: caption));
                      if (mounted) setState(() => copied = true);
                    },
                  ),
                ),
                Expanded(child: HerdButton('Save postcard', onPressed: () => savePostcard(c))),
              ],
            ),
          ],
          const SizedBox(height: 16),
          HerdCard(
            padding: 18,
            spacing: 12,
            children: [
              Text(tr('Share it on Instagram'), style: HerdText.chunky(22, extraBold: false)),
              const NumberedRow(
                '1',
                'Posting? Tap Tag people → Invite collaborator → @growtheherdstudio. It shows on both our pages, and it stays yours.',
              ),
              const NumberedRow('2', 'Story? Mention @growtheherdstudio and we’ll reshare it.'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text(caption, style: HerdText.body(14, color: Herd.ink)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          HerdCard(
            color: Herd.pinkSoft,
            children: [
              Text(tr('New stamp: Passed on #${widget.number}'), style: HerdText.chunky(22, color: Herd.pinkInk)),
              Text(tr('Added to your Passport after a quick review.'), style: HerdText.body(15, color: Herd.pinkInk)),
            ],
          ),
          const SizedBox(height: 16),
          HerdButton('See their journey', onPressed: () => router.replaceTop(CompanionRoute(widget.number))),
          Center(
            child: TextButton(
              onPressed: () {
                router.popToRoot();
                router.select(AppTab.passport);
              },
              child: Text(tr('See my Passport'), style: HerdText.body(15, color: Herd.sageDark)),
            ),
          ),
        ],
      ),
    );
  }
}

class Postcard extends StatelessWidget {
  const Postcard({super.key, required this.companion});
  final Companion companion;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Herd.sage, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Container(
          height: 200,
          color: Herd.sageBackground,
          child: Stack(
            children: [
              if (companion.current?.photo != null)
                Positioned.fill(child: Image.memory(companion.current!.photo!, fit: BoxFit.cover))
              else if (companion.current?.photoUrl != null)
                Positioned.fill(
                  child: Image.network(companion.current!.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                )
              else
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CompanionFigure(glaze: companion.glazeColor, waving: true, happy: true, showsShadow: false, height: 110),
                  ),
                ),
              if (companion.current?.photo == null && companion.current?.photoUrl == null)
                const Positioned(left: 12, top: 12, child: InfoPill('Your photo')),
              Positioned(
                right: 12,
                top: 12,
                child: Transform.rotate(
                  angle: 0.1,
                  child: Container(
                    width: 60,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: Herd.stepDot, width: 2)),
                    child: Text(tr('#${companion.number}'), style: HerdText.chunky(18, color: Herd.sageDark)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(tr('Greetings from ${companion.current?.city ?? 'the road'}!'), style: HerdText.script(28)),
        Text(
          tr(
            '${companion.name != null ? '${companion.name} · ' : ''}Companion #${companion.number} · Stop ${companion.stops.length} · theherdstudio.com/c/${companion.number}',
          ),
          style: HerdText.body(13),
        ),
      ],
    ),
  );
}
