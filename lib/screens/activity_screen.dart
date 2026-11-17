import 'package:material_ui/material_ui.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

/// Activity tab: news about your Companions, plus the one gentle reminder.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return Scaffold(
      body: SafeArea(
        child: ModelBuilder(builder: (context, model) {
          final reminder = model.reminderFrom == null ? null : model.companion(model.reminderFrom!);
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              const Wordmark(),
              const Spacer(),
              CircleIconButton(icon: Icons.tune, label: 'Notification settings', onTap: () => router.push(const NotificationSettingsRoute())),
            ]),
            const SizedBox(height: 12),
            Text('Activity', style: HerdText.script(40)),
            const SizedBox(height: 12),
            if (reminder != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Herd.pinkSoft, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Herd.pinkInk, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('From ${reminder.displayName}', style: HerdText.body(12, color: Herd.pinkInk)),
                  ]),
                  Text('Hi again! You found me in ${reminder.current?.city ?? 'your city'} about a month ago. Ready to send me on my next adventure?',
                      style: HerdText.body(15, color: Herd.ink)),
                  Row(spacing: 10, children: [
                    Expanded(child: HerdButton('Pass me on', onPressed: () => router.push(PassOnRoute(reminder.number)))),
                    Expanded(child: HerdButton('Still traveling', kind: HerdButtonKind.outline, onPressed: model.dismissReminder)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            ..._section(context, 'Today', model.activity.where((a) => a.isToday).toList()),
            ..._section(context, 'This week', model.activity.where((a) => !a.isToday).toList()),
          ]);
        }),
      ),
    );
  }

  List<Widget> _section(BuildContext context, String title, List<ActivityItem> items) {
    if (items.isEmpty) return [];
    return [
      Eyebrow(title),
      const SizedBox(height: 8),
      for (final item in items)
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => item.route != null ? context.router.push(item.route!) : context.router.select(AppTab.passport),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: hex(item.background), shape: BoxShape.circle),
                child: Icon(item.icon, size: 20, color: hex(item.foreground)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                  Text(item.title, style: HerdText.body(15, weight: FontWeight.w500, color: Herd.ink)),
                  Text(item.meta, style: HerdText.body(13)),
                ]),
              ),
            ]),
          ),
        ),
      const SizedBox(height: 12),
    ];
  }
}
