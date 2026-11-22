import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';
import '../theme.dart';
import '../validation.dart';
import '../widgets/companion_figure.dart';
import '../widgets/pieces.dart';

/// Traveler chat: one conversation per Companion, for everyone who has carried them.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.number});
  final String number;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final draft = TextEditingController();
  final scroll = ScrollController();
  String? error;
  bool sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.model.ensureChat(widget.number); // LIVE: read the chat from The Herd's site
  }

  @override
  void dispose() {
    draft.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final problem = checkPublicText(draft.text, maxLength: 500);
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    setState(() => sending = true);
    final result = await context.model.submitChat(widget.number, draft.text);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        sending = false;
        error = result.message ?? 'Something went wrong on our side. Please try again in a minute.';
      });
      return;
    }
    draft.clear();
    setState(() => sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: herdAppBar(title: 'Travelers of #${widget.number}'),
      body: ModelBuilder(
        builder: (context, model) {
          final c = model.companion(widget.number);
          final messages = model.chats[widget.number] ?? [];
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      tr('${c?.travelers ?? 0} travelers · everyone who’s carried ${c?.displayName ?? '#${widget.number}'}'),
                      style: HerdText.body(14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Herd.beige, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outline, size: 16, color: Herd.body),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tr('Be kind. Phone numbers, emails and addresses are hidden automatically.'),
                              style: HerdText.body(13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final m in messages) _bubble(m),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Herd.cream,
                  border: Border(top: BorderSide(color: Herd.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: HerdField(
                          controller: draft,
                          hint: 'Message the travelers of #${widget.number}',
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 500,
                          errorText: error,
                          onChanged: (_) => setState(() => error = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        button: true,
                        label: 'Send',
                        excludeSemantics: true,
                        child: Material(
                          color: draft.text.trim().isEmpty ? Herd.border : Herd.sageDark,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: draft.text.trim().isEmpty || sending ? null : send,
                            child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_upward, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final mine = m.kind == ChatKind.me;
    final bg = mine ? Herd.sageDark : (m.kind == ChatKind.herd ? Herd.mintSoft : Colors.white);
    final fg = mine ? Colors.white : (m.kind == ChatKind.herd ? Herd.mintInk : Herd.ink);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(m.who, style: HerdText.body(12)),
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 300),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 18),
                ),
              ),
              child: Text(m.text, style: HerdText.body(15, color: fg)),
            ),
            if (!mine && m.id != null) ReportButton(number: widget.number, kind: 'chat', id: m.id!),
          ],
        ),
      ),
    );
  }
}

/// Their story: the origin story by The Herd, then every traveler's chapter.
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.number});
  final String number;

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      appBar: herdAppBar(),
      body: ModelBuilder(
        builder: (context, model) {
          final c = model.companion(number);
          if (c == null) return const SizedBox.shrink();
          model.ensureChat(number); // LIVE: read the chat from The Herd's site
          final lastText = model.chats[number]?.lastOrNull?.text ?? 'Say hi to the travelers before you.';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CompanionBadge(companion: c, size: 70),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(c.label),
                        Text(tr('Their story'), style: HerdText.script(40)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HerdCard(
                color: Herd.butter,
                children: [
                  const Eyebrow('Chapter 1 · Their origin story, by The Herd', color: Herd.butterInk),
                  Text(c.originStory, style: HerdText.body(15, color: Herd.butterInk)),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = c.stops.length - 1; i >= 1; i--) ...[
                _chapter(c.stops[i], i, i == c.stops.length - 1),
                const SizedBox(height: 14),
              ],
              LinkRow(
                title: 'Traveler chat · ${c.travelers} travelers',
                subtitle: '“$lastText”',
                onTap: () => router.push(ChatRoute(number)),
              ),
              if (c.status != CompanionStatus.retired)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => router.push(BrokeRoute(number)),
                    child: Text(tr('Something happened to them?'), style: HerdText.body(14, color: Herd.sageDark)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _chapter(Stop stop, int index, bool isNow) {
    final meta = [if (stop.byLine != null) stop.byLine!, if (stop.when.isNotEmpty) stop.when].map(tr).join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Herd.sage, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (stop.photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Image.memory(stop.photo!, height: 220, width: double.infinity, fit: BoxFit.cover, semanticLabel: tr('Traveler’s photo')),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: InfoPill('Waiting for The Herd’s quick look', background: Herd.cream, foreground: Herd.ink),
                  ),
                ],
              ),
            )
          else if (stop.photoUrl != null)
            // An approved photo on The Herd's website.
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                stop.photoUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: tr('Traveler’s photo'),
                errorBuilder: (_, _, _) => const PhotoPlaceholder(height: 140),
              ),
            )
          else if (stop.note != null)
            const PhotoPlaceholder(height: 140),
          Row(
            children: [
              Expanded(
                child: Text(stop.city, style: HerdText.chunky(18, extraBold: false, color: Herd.sageDark)),
              ),
              InfoPill(isNow ? 'Now' : 'Stop $index', background: Herd.mintSoft, foreground: Herd.mintInk),
            ],
          ),
          if (stop.place != null) Text(stop.place!, style: HerdText.body(14, color: Herd.ink)),
          if (meta.isNotEmpty) Text(meta, style: HerdText.body(13)),
          if (stop.note != null) Text('“${tr(stop.note!)}”', style: HerdText.body(15, color: Herd.ink)),
          if (stop.id != null && stop.kind != 'made') ReportButton(number: number, kind: 'stop', id: stop.id!),
        ],
      ),
    );
  }
}


/// "Report": flags a chat message or stop for The Herd to look at (it shows in their daily email).
class ReportButton extends StatefulWidget {
  const ReportButton({super.key, required this.number, required this.kind, required this.id});
  final String number;
  final String kind;
  final String id;

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  bool sending = false;
  bool done = false;

  Future<void> _report() async {
    final model = context.model;
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tr('Report this to The Herd? They’ll take a look and remove it if it breaks the rules.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Report'))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => sending = true);
    final ok = await model.reportItem(widget.number, kind: widget.kind, id: widget.id);
    if (!mounted) return;
    setState(() {
      sending = false;
      done = ok;
    });
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(tr('That didn’t go through. Please try again.'))));
  }

  @override
  Widget build(BuildContext context) {
    if (done) return Text(tr('Reported. Thank you!'), style: HerdText.body(13, color: Herd.sageDark));
    return TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 36), alignment: Alignment.centerLeft),
      onPressed: sending ? null : _report,
      child: Text(tr('Report'), style: HerdText.body(13).copyWith(decoration: TextDecoration.underline)),
    );
  }
}
