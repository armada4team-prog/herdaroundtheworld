import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'l10n.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/activity_screen.dart';
import 'screens/broke_screen.dart';
import 'screens/chat_story_screens.dart';
import 'screens/companion_screen.dart';
import 'screens/found_screen.dart';
import 'screens/home_screen.dart';
import 'screens/info_screens.dart';
import 'screens/map_screen.dart';
import 'screens/pass_on_screen.dart';
import 'screens/passport_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/sent_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wish_screen.dart';
import 'services.dart';
import 'storage.dart';
import 'theme.dart';
import 'wix_api.dart';

/// Opens straight to one screen when built with `--dart-define=SCREEN=map`, or on the web with `?screen=map`
/// (used for automatic screenshots).
final startScreen = const String.fromEnvironment('SCREEN').isNotEmpty
    ? const String.fromEnvironment('SCREEN')
    : (kIsWeb ? (Uri.base.queryParameters['screen'] ?? '') : '');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The real app connects to The Herd's Wix site (or uses the sample data until it's published)
  // and keeps what's yours on the phone. Screenshot runs (SCREEN=…) always use the sample data.
  final model = startScreen.isEmpty ? (AppModel(api: WixApi(), store: PrefsStore())..start()) : AppModel();
  runApp(HerdApp(model: model));
}

Widget pageFor(AppRoute route) => switch (route) {
  CompanionRoute(:final number, :final showHello) => CompanionScreen(number: number, startWithHello: showHello),
  FoundRoute(:final number) => FoundScreen(number: number),
      PassOnRoute(:final number) => PassOnScreen(number: number),
  WishRoute(:final number) => WishScreen(number: number),
  SentRoute(:final number) => SentScreen(number: number),
  BrokeRoute(:final number) => BrokeScreen(number: number),
  ChatRoute(:final number) => ChatScreen(number: number),
  StoryRoute(:final number) => StoryScreen(number: number),
  LearnRoute() => const LearnScreen(),
  NotificationSettingsRoute() => const NotificationSettingsScreen(),
};

class HerdApp extends StatefulWidget {
  const HerdApp({super.key, this.model});

  /// Without one, the app uses the sample data in memory.
  final AppModel? model;

  @override
  State<HerdApp> createState() => _HerdAppState();
}

class _HerdAppState extends State<HerdApp> {
  late final AppModel model = widget.model ?? AppModel();
  String _language = 'en';
  late final router = AppRouter(pageFor: pageFor);
  bool showSplash = startScreen.isEmpty || startScreen == 'splash';

  @override
  void initState() {
    super.initState();
    // Switching language redraws every screen in the new language, keeping your place.
    model.addListener(() {
      if (model.language != _language) {
        _language = model.language;
        Lang.code = _language;
        if (mounted) rebuildAllText(context);
      }
    });
    if (startScreen.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _openStartScreen());
    // Testing aid on the web: ?lang=es opens the app in Spanish.
    if (kIsWeb && startScreen.isNotEmpty) Services.previewHere = const HerePlace('Aurora, CO', LatLng(39.7294, -104.8319));
    final startLang = kIsWeb ? Uri.base.queryParameters['lang'] : null;
    if (startLang != null) model.setLanguage(startLang);
  }

  void _openStartScreen() {
    final ctx = router.navigators[AppTab.home]!.currentContext;
    switch (startScreen) {
      case 'map':
        router.select(AppTab.map);
      case 'scan':
        router.select(AppTab.scan);
      case 'passport':
        router.select(AppTab.passport);
      case 'activity':
        router.select(AppTab.activity);
      case 'companion':
        router.open(const CompanionRoute('07'), inTab: AppTab.home);
      case 'hello':
        router.open(const CompanionRoute('07', showHello: true), inTab: AppTab.home);
      case 'found':
        model.unlocked.add('07'); // preview as someone who scanned #07
        router.open(const FoundRoute('07'), inTab: AppTab.home);
      case 'passon-near': // preview the 5-mile rule: found #07 right here
        model.holding.add('07');
        model.foundAt['07'] = const LatLng(39.74, -104.84);
        router.open(const PassOnRoute('07'), inTab: AppTab.home);
      case 'passon':
        model.holding.add('07'); // preview as someone who has found #07
        router.open(const PassOnRoute('07'), inTab: AppTab.home);
      case 'wish':
        router.open(const WishRoute('07'), inTab: AppTab.home);
      case 'sent':
        router.open(const SentRoute('07'), inTab: AppTab.home);
      case 'broke':
        router.open(const BrokeRoute('07'), inTab: AppTab.home);
      case 'chat':
        router.open(const ChatRoute('07'), inTab: AppTab.home);
      case 'story':
        router.open(const StoryRoute('07'), inTab: AppTab.home);
      case 'learn':
        router.open(const LearnRoute(), inTab: AppTab.home);
      case 'settings':
        router.open(const NotificationSettingsRoute(), inTab: AppTab.activity);
      case 'signin':
        router.select(AppTab.passport);
        if (ctx != null) showSignIn(ctx);
      case 'language':
        if (ctx != null) showLanguagePicker(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: model,
      router: router,
      child: MaterialApp(
        title: 'Herd Around the World',
        debugShowCheckedModeBanner: false,
        theme: herdTheme(),
        home: Stack(
          children: [
            const MainShell(),
            if (showSplash) Positioned.fill(child: SplashScreen(onEnter: () => setState(() => showSplash = false))),
            // First launch only: waiting for The Herd's Companions (the welcome screen usually covers it).
            if (!showSplash)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: model,
                  builder: (context, _) => model.ready ? const SizedBox.shrink() : const _Loading(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Five tabs, like the designs: The Herd · Map · Scan · Passport · Activity.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _tabs = [
    (AppTab.home, 'The Herd', Icons.home_outlined, Icons.home),
    (AppTab.map, 'Map', Icons.map_outlined, Icons.map),
    (AppTab.scan, 'Scan', Icons.qr_code_scanner, Icons.qr_code_scanner),
    (AppTab.passport, 'Passport', Icons.menu_book_outlined, Icons.menu_book),
    (AppTab.activity, 'Activity', Icons.notifications_none, Icons.notifications),
  ];

  Widget _root(AppTab tab) => switch (tab) {
    AppTab.home => const HomeScreen(),
    AppTab.map => const MapScreen(),
    AppTab.scan => const ScanScreen(),
    AppTab.passport => const PassportScreen(),
    AppTab.activity => const ActivityScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final router = context.router;
    return ListenableBuilder(
      listenable: router,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (!router.handleBack()) SystemNavigator.pop();
        },
        child: Scaffold(
          body: IndexedStack(
            index: router.tab.index,
            children: [
              for (final (tab, _, _, _) in _tabs)
                Navigator(
                  key: router.navigators[tab],
                  onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => _root(tab)),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: router.tab.index,
            onDestinationSelected: (i) => router.select(AppTab.values[i]),
            destinations: [
              for (final (_, label, icon, selectedIcon) in _tabs)
                NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selectedIcon), label: tr(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Material(
    color: Herd.cream,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 14,
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Herd.sageDark)),
          Text(tr('Loading the herd…'), style: HerdText.body(16, color: Herd.sageDark)),
        ],
      ),
    ),
  );
}
