import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'sample_data.dart';

/// Everything the app knows. For testing it starts with the sample data from the designs and keeps
/// changes in memory. Swap the sample data for The Herd's database when it's ready (see README).
class AppModel extends ChangeNotifier {
  final List<Companion> companions = sampleCompanions();
  final Set<String> following = {'07', '2'};
  final Set<String> holding = {}; // found and not passed on yet
  String nickname = '';
  String? email;
  String language = 'en';
  final NotificationPrefs notificationPrefs = NotificationPrefs();
  final Map<String, List<ChatMessage>> chats = {
    '07': [
      ChatMessage(
          who: 'The Herd · made them in Aurora, CO',
          text: 'Welcome to #07’s chat! Everyone who carries them can talk here. Say hi to the travelers before you.',
          kind: ChatKind.herd),
      ChatMessage(who: '[TRAVELER 2] · Traveler 4 · Boise, ID', text: 'I miss this little one already! Where are they headed next?', kind: ChatKind.traveler),
      ChatMessage(who: 'Sam R. · Traveler 5 · Moab, UT', text: 'They loved the arches. Somewhere with mountains, please!', kind: ChatKind.traveler),
    ],
  };

  final List<Stamp> stamps = [
    const Stamp(big: '#07', small: 'Santa Fe', label: 'Carried #07 · Oct', background: 'DDF0E8', ring: '5B7869', ink: '2F4A3D', tilt: -6),
    const Stamp(big: '#3', small: 'Tokyo', label: 'Carried #3 · Aug', background: 'FBE4E2', ring: 'D98C86', ink: '6B3F3A', tilt: 5),
    const Stamp(big: 'Wish', small: 'Granted', label: 'Helped #2 see the ocean', background: 'F9EBB5', ring: 'E0B94A', ink: '5A4C1E', tilt: -3),
    const Stamp(big: '1st', small: 'Hand-off', label: 'Handed one to a stranger', background: 'E7ECE5', ring: '6E8B7D', ink: '3F5A4C', tilt: 4),
  ];

  final List<ActivityItem> activity = [
    ActivityItem(
        title: '#07 just arrived in Santa Fe, NM!',
        meta: 'Left by [TRAVELER] · 2 hours ago',
        icon: Icons.place_outlined,
        background: 'DDF0E8',
        foreground: '2F4A3D',
        route: const CompanionRoute('07'),
        isToday: true),
    ActivityItem(
        title: '[TRAVELER 2] replied in #07’s traveler chat',
        meta: '“Somewhere with mountains, please!” · 4 hours ago',
        icon: Icons.chat_bubble_outline,
        background: 'F6EFE7',
        foreground: '3F5A4C',
        route: const ChatRoute('07'),
        isToday: true),
    ActivityItem(
        title: 'Two new stamps: Passed on #3 and Wish granted',
        meta: 'Added to your Passport after a quick look',
        icon: Icons.star_outline,
        background: 'FBE4E2',
        foreground: '6B3F3A',
        isToday: true),
    ActivityItem(
        title: '#2’s wish came true: they saw the ocean!',
        meta: 'Lisbon, Portugal · 5 days ago',
        icon: Icons.star_outline,
        background: 'F9EBB5',
        foreground: '5A4C1E',
        route: const CompanionRoute('2'),
        isToday: false),
    ActivityItem(
        title: '#07 passed 1,000 miles',
        meta: 'A new milestone for the herd · 6 days ago',
        icon: Icons.flag_outlined,
        background: 'E7ECE5',
        foreground: '3F5A4C',
        route: const CompanionRoute('07'),
        isToday: false),
  ];

  /// The one gentle reminder from a Companion you're holding, shown at the top of Activity.
  String? reminderFrom = '07';

  // Lookups

  Companion? companion(String number) {
    final clean = cleanNumber(number);
    for (final c in companions) {
      if (cleanNumber(c.number) == clean) return c;
    }
    return null;
  }

  List<Companion> get originals =>
      companions.where((c) => c.isOriginal).toList()..sort((a, b) => int.parse(a.number).compareTo(int.parse(b.number)));
  List<Companion> get followed => companions.where((c) => following.contains(c.number)).toList();

  /// The 10 Companions with the most stops, most recently moved first when tied.
  List<Companion> get mostActive {
    final sorted = [...companions]..sort((a, b) {
        if (a.stopCount != b.stopCount) return b.stopCount.compareTo(a.stopCount);
        return daysAgo(a.lastMoved).compareTo(daysAgo(b.lastMoved));
      });
    return sorted.take(10).toList();
  }

  int get companionsCarried => stamps.where((s) => s.big.startsWith('#')).length;
  int get wishesGranted => stamps.where((s) => s.big == 'Wish').length;
  int get milesCarried => 640;
  int get herdSize => 14;

  bool matches(Companion c, MapFilter filter) => switch (filter) {
        MapFilter.all || MapFilter.nearMe => true,
        MapFilter.following => following.contains(c.number),
        MapFilter.originals => c.isOriginal,
        MapFilter.movedThisWeek => c.movedThisWeek,
        MapFilter.waiting => c.status == CompanionStatus.waiting,
        MapFilter.quiet => c.status == CompanionStatus.quiet,
        MapFilter.adopted => c.status == CompanionStatus.adopted,
        MapFilter.retired => c.status == CompanionStatus.retired,
        MapFilter.wishesGranted => c.wishGranted,
      };

  // Actions

  void toggleFollow(String number) {
    following.contains(number) ? following.remove(number) : following.add(number);
    notifyListeners();
  }

  void setNickname(String value) {
    nickname = value;
    notifyListeners();
  }

  void setEmail(String? value) {
    email = (value == null || value.isEmpty) ? null : value;
    notifyListeners();
  }

  void setLanguage(String code) {
    language = code;
    notifyListeners();
  }

  void changed() => notifyListeners();

  /// A Companion's journey always goes found → left → found → left. You can only log a find
  /// for a Companion you aren't already holding, and only pass on one you've logged finding.
  bool canLogFind(String number) => !holding.contains(number);
  bool canPassOn(String number) => holding.contains(number);

  void logFind(String number, {required String city, required String nickname, required CheckIn checkIn, String? email, LatLng? point}) {
    if (!canLogFind(number)) return;
    this.nickname = nickname;
    if (email != null && email.isNotEmpty) this.email = email;
    holding.add(number);
    following.add(number);
    final c = companion(number);
    if (c != null) {
      final last = c.current;
      c.status = CompanionStatus.moving;
      c.stops.add(Stop(
        city: city.isEmpty ? (last?.city ?? '') : city,
        latitude: point?.latitude ?? last?.latitude ?? 0,
        longitude: point?.longitude ?? last?.longitude ?? 0,
        leftBy: nickname,
        when: 'Just now',
        note: 'Found by $nickname.',
      ));
      c.lastMoved = 'Just now';
      c.movedThisWeek = true;
      activity.insert(
          0,
          ActivityItem(
              title: 'You found #$number!',
              meta: '$city · just now',
              icon: Icons.place_outlined,
              background: 'DDF0E8',
              foreground: '2F4A3D',
              route: CompanionRoute(number),
              isToday: true));
    }
    notifyListeners();
  }

  void passOn(String number,
      {required String city,
      String? place,
      required bool handedToSomeone,
      required String chapter,
      required String nickname,
      required bool grantedWish,
      LatLng? point}) {
    if (!canPassOn(number)) return;
    if (nickname.isNotEmpty) this.nickname = nickname;
    holding.remove(number);
    final c = companion(number);
    if (c != null) {
      final last = c.current;
      c.stops.add(Stop(
        city: city,
        place: handedToSomeone ? null : place,
        latitude: point?.latitude ?? last?.latitude ?? 0,
        longitude: point?.longitude ?? last?.longitude ?? 0,
        leftBy: nickname,
        when: 'Just now',
        note: chapter.isEmpty ? null : chapter,
      ));
      c.status = handedToSomeone ? CompanionStatus.moving : CompanionStatus.waiting;
      c.lastMoved = 'Just now';
      c.movedThisWeek = true;
      c.travelers += 1;
      stamps.insert(0, Stamp(big: '#$number', small: city, label: 'Passed on #$number', background: 'DDF0E8', ring: '5B7869', ink: '2F4A3D', tilt: -4));
      if (grantedWish) {
        c.wishGranted = true;
        stamps.insert(0, Stamp(big: 'Wish', small: 'Granted', label: 'Helped #$number ${c.wish}', background: 'F9EBB5', ring: 'E0B94A', ink: '5A4C1E', tilt: 3));
      }
    }
    if (reminderFrom == number) reminderFrom = null;
    notifyListeners();
  }

  void setNextWish(String number, String wish) {
    final c = companion(number);
    if (c == null) return;
    var text = wish.trim();
    if (text.toLowerCase().startsWith('i want to ')) text = text.substring(10);
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    c.wish = text;
    c.wishGranted = false;
    notifyListeners();
  }

  void reportBroken(String number, {required bool chipped}) {
    final c = companion(number);
    if (c != null && !chipped) c.status = CompanionStatus.retired;
    holding.remove(number);
    notifyListeners();
  }

  void dismissReminder() {
    reminderFrom = null;
    notifyListeners();
  }

  void sendChat(String number, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    chats.putIfAbsent(number, () => []).add(ChatMessage(who: nickname.isEmpty ? 'You' : nickname, text: hideContactDetails(trimmed), kind: ChatKind.me));
    notifyListeners();
  }

  void deleteMyData() {
    email = null;
    nickname = '';
    notifyListeners();
  }

  // Helpers

  static String cleanNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    return trimmed.isEmpty ? (digits.isEmpty ? '' : '0') : trimmed;
  }

  /// Reads a scanned QR code ("https://theherdstudio.com/c/07") or a typed number ("07").
  static String? numberFromScan(String payload) {
    final match = RegExp(r'/c/(\d+)').firstMatch(payload);
    if (match != null) return match.group(1);
    final digits = payload.replaceAll(RegExp(r'\D'), '');
    return (digits.isEmpty || digits.length > 4) ? null : digits;
  }

  static int daysAgo(String text) {
    final n = int.tryParse(text.split(' ').first);
    if (n == null) return text == 'Just now' ? 0 : 999;
    if (text.contains('week')) return n * 7;
    if (text.contains('month')) return n * 30;
    return n;
  }

  /// Phone numbers and email addresses typed into chat are hidden, as promised in the designs.
  static String hideContactDetails(String text) => text
      .replaceAll(RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false), '[hidden]')
      .replaceAll(RegExp(r'\+?\d[\d\s().-]{7,}\d'), '[hidden]');
}

enum AppTab { home, map, scan, passport, activity }

/// Which tab is showing, and the screen stack inside each tab.
class AppRouter extends ChangeNotifier {
  AppRouter({required this.pageFor});

  final Widget Function(AppRoute route) pageFor;
  AppTab tab = AppTab.home;
  final Map<AppTab, GlobalKey<NavigatorState>> navigators = {for (final t in AppTab.values) t: GlobalKey<NavigatorState>()};

  NavigatorState? get _nav => navigators[tab]!.currentState;

  void select(AppTab t) {
    if (t == tab) {
      navigators[t]!.currentState?.popUntil((r) => r.isFirst);
    }
    tab = t;
    notifyListeners();
  }

  void push(AppRoute route) => _nav?.push(MaterialPageRoute<void>(builder: (_) => pageFor(route)));

  /// Replace the top screen (when a form finishes and moves to its thank-you screen).
  void replaceTop(AppRoute route) => _nav?.pushReplacement(MaterialPageRoute<void>(builder: (_) => pageFor(route)));

  void popToRoot() => _nav?.popUntil((r) => r.isFirst);

  void open(AppRoute route, {required AppTab inTab}) {
    tab = inTab;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigators[inTab]!.currentState;
      nav?.popUntil((r) => r.isFirst);
      nav?.push(MaterialPageRoute<void>(builder: (_) => pageFor(route)));
    });
  }

  /// Android back button: go back inside the current tab first, then to Home.
  bool handleBack() {
    final nav = _nav;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return true;
    }
    if (tab != AppTab.home) {
      select(AppTab.home);
      return true;
    }
    return false;
  }
}

/// Makes the model and router available to every screen.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.model, required this.router, required super.child});
  final AppModel model;
  final AppRouter router;

  static AppScope _of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;
  static AppModel modelOf(BuildContext context) => _of(context).model;
  static AppRouter routerOf(BuildContext context) => _of(context).router;

  @override
  bool updateShouldNotify(AppScope oldWidget) => model != oldWidget.model || router != oldWidget.router;
}

extension AppContext on BuildContext {
  AppModel get model => AppScope.modelOf(this);
  AppRouter get router => AppScope.routerOf(this);
}

/// Rebuilds its child whenever the app model changes.
class ModelBuilder extends StatelessWidget {
  const ModelBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, AppModel model) builder;

  @override
  Widget build(BuildContext context) {
    final model = context.model;
    return ListenableBuilder(listenable: model, builder: (context, _) => builder(context, model));
  }
}
