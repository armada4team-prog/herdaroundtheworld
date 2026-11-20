import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'find_codes.dart';
import 'models.dart';
import 'sample_data.dart';
import 'storage.dart';
import 'validation.dart';
import 'wix_api.dart';

/// Where the app's data comes from.
///
/// LIVE: The Herd's Wix site, the same data as the website. Used only when The Herd's checker
/// answers (wix/backend/handlers.src.js), so the app never writes to a checker that isn't there.
/// SAMPLE: the bundled sample Companions, with every rule checked right here in the app (the way
/// the app worked before it was connected). Used until the Wix site is published, or offline.
enum DataMode { sample, live }

/// A Companion in your care (found and not passed on yet).
class HoldInfo {
  HoldInfo({this.token, this.city = '', this.date, this.claimed = false});

  /// Proof for the checker that you're the one holding them.
  final String? token;
  final String city;
  final DateTime? date;

  /// True when the hold is linked to your sign-in.
  bool claimed;

  Map<String, dynamic> toJson() => {'token': token, 'city': city, 'date': date?.toIso8601String(), 'claimed': claimed};
  static HoldInfo fromJson(Map<String, dynamic> j) => HoldInfo(
    token: j['token'] as String?,
    city: (j['city'] as String?) ?? '',
    date: j['date'] is String ? DateTime.tryParse(j['date'] as String) : null,
    claimed: j['claimed'] == true,
  );
}

/// One line of your Passport history: found, passedOn, left or wish.
class JournalEntry {
  JournalEntry({required this.type, required this.number, this.city = '', required this.date, this.wish, this.miles = 0});
  final String type;
  final String number;
  final String city;
  final DateTime date;
  final String? wish;
  final int miles;

  Map<String, dynamic> toJson() => {'type': type, 'number': number, 'city': city, 'date': date.toIso8601String(), 'wish': wish, 'miles': miles};
  static JournalEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final date = j['date'] is String ? DateTime.tryParse(j['date'] as String) : null;
    final type = j['type'] ?? j['kind'];
    if (type is! String || j['number'] == null) return null;
    return JournalEntry(
      type: type,
      number: wixNumber(j['number']),
      city: '${j['city'] ?? ''}',
      date: date ?? DateTime.fromMillisecondsSinceEpoch(0),
      wish: j['wish'] as String?,
      miles: j['miles'] is num ? (j['miles'] as num).round() : 0,
    );
  }
}

/// Signed in with an emailed code (optional).
class Account {
  const Account({required this.session, required this.email});
  final String session;
  final String email;
}

/// The answer to a find, pass-on, wish, report, chat message or sign-in. When it isn't [ok],
/// [field] says which box to mark in red and [message] says what to fix.
class WriteResult {
  const WriteResult.ok({this.previewCode}) : ok = true, field = null, message = null;
  const WriteResult.problem(this.message, {this.field}) : ok = false, previewCode = null;
  final bool ok;
  final String? field;
  final String? message;

  /// Preview only: the sign-in code, shown on screen instead of emailed.
  final String? previewCode;

  static WriteResult from(CheckerReply r) => r.ok ? const WriteResult.ok() : WriteResult.problem(r.message, field: r.field);
}

class CodeResult {
  const CodeResult(this.check, [this.message]);
  final CodeCheck check;
  final String? message;
}

const _mineKey = 'herd.mine.';
const _previewLogKey = 'herd.preview.log';
const _previewTravelersKey = 'herd.preview.travelers';
const _cacheKey = 'herd.cache.live';
const _lastModeKey = 'herd.lastMode';

/// Everything the app knows. `AppModel()` is the sample data, kept in memory (tests and screenshots).
/// The app itself uses `AppModel(api: WixApi(), store: PrefsStore())` and calls [start], which
/// picks LIVE or SAMPLE and loads what was saved on this phone.
class AppModel extends ChangeNotifier {
  AppModel({this.api, this.store}) : ready = api == null && store == null;

  final WixApi? api;
  final KeyValueStore? store;
  DataMode mode = DataMode.sample;

  /// False while starting up (checking for The Herd's site and loading what's saved).
  bool ready;

  /// LIVE, but showing the copy saved on this phone because The Herd couldn't be reached.
  bool offline = false;

  bool get isLive => mode == DataMode.live;

  List<Companion> companions = sampleCompanions();
  final Set<String> following = {'07', '2'};
  final Set<String> holding = {}; // found and not passed on yet
  final Set<String> unlocked = {}; // find code checked, find not logged yet
  /// LIVE: the find code that was checked, sent again with the find.
  final Map<String, String> unlockedCodes = {};
  /// Hold tokens and details for the Companions in [holding].
  final Map<String, HoldInfo> holdInfo = {};
  /// After granting a wish: proof for choosing the next one.
  final Map<String, String> wishTokens = {};
  final Set<String> _remoteWishKeys = {};
  final List<JournalEntry> journal = [];
  final List<JournalEntry> _remoteJournal = [];
  Account? account;

  /// Exactly where each Companion was found. Private: only used to check the 5-mile rule, never shown.
  final Map<String, LatLng> foundAt = {};
  static const minMilesToPassOn = 5;
  int _wrongCodes = 0;
  DateTime? _codesLockedUntil;
  String nickname = '';
  String? email;
  String language = 'en';
  final NotificationPrefs notificationPrefs = NotificationPrefs();
  final Map<String, List<ChatMessage>> chats = {
    '07': [
      ChatMessage(
        who: 'The Herd · made them in Aurora, CO',
        text: 'Welcome to #07’s chat! Everyone who carries them can talk here. Say hi to the travelers before you.',
        kind: ChatKind.herd,
      ),
      ChatMessage(
        who: '[TRAVELER 2] · Traveler 4 · Boise, ID',
        text: 'I miss this little one already! Where are they headed next?',
        kind: ChatKind.traveler,
      ),
      ChatMessage(
        who: 'Sam R. · Traveler 5 · Moab, UT',
        text: 'They loved the arches. Somewhere with mountains, please!',
        kind: ChatKind.traveler,
      ),
    ],
  };
  final Set<String> _chatsLoading = {};
  final Set<String> _chatsLoaded = {};

  /// Photos taken on this phone, shown on the postcard right away (LIVE photos wait for The Herd's look).
  final Map<String, (String city, Uint8List bytes)> _localPhotos = {};

  /// SAMPLE: what was done on this phone, replayed onto the sample data at start-up.
  final List<Map<String, dynamic>> _previewLog = [];
  Map<String, dynamic> _previewTravelers = {};

  final List<Stamp> _sampleStamps = [
    const Stamp(big: '#07', small: 'Santa Fe', label: 'Carried #07 · Oct', background: 'DDF0E8', ring: '5B7869', ink: '2F4A3D', tilt: -6),
    const Stamp(big: '#3', small: 'Tokyo', label: 'Carried #3 · Aug', background: 'FBE4E2', ring: 'D98C86', ink: '6B3F3A', tilt: 5),
    const Stamp(
      big: 'Wish',
      small: 'Granted',
      label: 'Helped #2 see the ocean',
      background: 'F9EBB5',
      ring: 'E0B94A',
      ink: '5A4C1E',
      tilt: -3,
    ),
    const Stamp(
      big: '1st',
      small: 'Hand-off',
      label: 'Handed one to a stranger',
      background: 'E7ECE5',
      ring: '6E8B7D',
      ink: '3F5A4C',
      tilt: 4,
    ),
  ];

  /// Your stamps, newest first. LIVE: made from your Passport history.
  List<Stamp> get stamps => isLive ? _liveStamps() : _sampleStamps;

  final List<ActivityItem> _activity = [
    ActivityItem(
      title: '#07 just arrived in Santa Fe, NM!',
      meta: 'Left by [TRAVELER] · 2 hours ago',
      icon: Icons.place_outlined,
      background: 'DDF0E8',
      foreground: '2F4A3D',
      route: const CompanionRoute('07'),
      isToday: true,
    ),
    ActivityItem(
      title: '[TRAVELER 2] replied in #07’s traveler chat',
      meta: '“Somewhere with mountains, please!” · 4 hours ago',
      icon: Icons.chat_bubble_outline,
      background: 'F6EFE7',
      foreground: '3F5A4C',
      route: const ChatRoute('07'),
      isToday: true,
    ),
    ActivityItem(
      title: 'Two new stamps: Passed on #3 and Wish granted',
      meta: 'Added to your Passport after a quick look',
      icon: Icons.star_outline,
      background: 'FBE4E2',
      foreground: '6B3F3A',
      isToday: true,
    ),
    ActivityItem(
      title: '#2’s wish came true: they saw the ocean!',
      meta: 'Lisbon, Portugal · 5 days ago',
      icon: Icons.star_outline,
      background: 'F9EBB5',
      foreground: '5A4C1E',
      route: const CompanionRoute('2'),
      isToday: false,
    ),
    ActivityItem(
      title: '#07 passed 1,000 miles',
      meta: 'A new milestone for the herd · 6 days ago',
      icon: Icons.flag_outlined,
      background: 'E7ECE5',
      foreground: '3F5A4C',
      route: const CompanionRoute('07'),
      isToday: false,
    ),
  ];

  /// What's new. LIVE: what you did, then the latest moves of Companions you follow.
  List<ActivityItem> get activity => isLive ? [..._activity, ..._followedMoves()] : _activity;

  /// The one gentle reminder from a Companion you're holding, shown at the top of Activity.
  String? reminderFrom = '07';

  // Starting up

  /// Decides LIVE or SAMPLE, then loads the data and what's saved on this phone.
  /// LIVE only when The Herd's checker answers; otherwise SAMPLE (nothing changes until launch).
  Future<void> start() async {
    try {
      final api = this.api;
      final lastMode = await store?.read(_lastModeKey);
      final probe = api == null ? CheckerProbe.notThere : await api.probeChecker();
      if (api != null && (probe == CheckerProbe.live || (probe == CheckerProbe.unreachable && lastMode == DataMode.live.name))) {
        final cached = WixLists.fromJson(await store?.readJson(_cacheKey));
        if (probe == CheckerProbe.live && (cached == null || cached.companions.isEmpty)) {
          // First launch: wait for The Herd's lists (the loading screen shows).
          try {
            final lists = await api.loadLists();
            if (lists.companions.isNotEmpty) {
              _useLive(lists, offline: false);
              unawaited(store?.writeJson(_cacheKey, lists.toJson()));
            }
          } catch (_) {
            // Can't read the lists: stay on the sample data.
          }
        } else if (cached != null && cached.companions.isNotEmpty) {
          // Show the saved copy right away, then refresh it.
          _useLive(cached, offline: true);
          if (probe == CheckerProbe.live) unawaited(refreshLive());
        }
      }
      await _loadMine();
      if (!isLive) await _replayPreview();
      await store?.write(_lastModeKey, mode.name);
    } catch (_) {
      // Anything unexpected: the sample data still works.
    }
    ready = true;
    notifyListeners();
    if (isLive && account != null) unawaited(syncAccount());
  }

  void _useLive(WixLists lists, {required bool offline}) {
    mode = DataMode.live;
    this.offline = offline;
    companions = companionsFromWix(lists);
    _applyLocalPhotos();
    chats.clear();
    _activity.clear();
    reminderFrom = null;
  }

  /// Reads The Herd's lists again (after a change, or on start-up). Keeps what we have if offline.
  Future<void> refreshLive() async {
    final api = this.api;
    if (api == null || !isLive) return;
    try {
      final lists = await api.loadLists();
      if (lists.companions.isEmpty) return;
      companions = companionsFromWix(lists);
      offline = false;
      _applyLocalPhotos();
      unawaited(store?.writeJson(_cacheKey, lists.toJson()));
      notifyListeners();
    } catch (_) {
      // Keep the copy we have.
    }
  }

  void _applyLocalPhotos() {
    for (final MapEntry(key: number, value: (city, bytes)) in _localPhotos.entries) {
      final c = companion(number);
      if (c == null || c.stops.isEmpty) continue;
      final last = c.stops.last;
      if (last.kind != 'found' && last.city == city && last.photo == null && last.photoUrl == null) {
        c.stops[c.stops.length - 1] = last.withPhoto(bytes);
      }
    }
  }

  // Saving on this phone

  String get _mineStoreKey => '$_mineKey${mode.name}';

  Map<String, dynamic> _mineJson() => {
    'nickname': nickname,
    'email': email,
    'language': language,
    'following': following.toList(),
    'holding': holding.toList(),
    'holds': {for (final e in holdInfo.entries) e.key: e.value.toJson()},
    'foundAt': {
      for (final e in foundAt.entries) e.key: [e.value.latitude, e.value.longitude],
    },
    'wishTokens': wishTokens,
    'remoteWishKeys': _remoteWishKeys.toList(),
    'journal': [for (final j in journal) j.toJson()],
    'remoteJournal': [for (final j in _remoteJournal) j.toJson()],
    'account': account == null ? null : {'session': account!.session, 'email': account!.email},
    'reminderFrom': reminderFrom,
  };

  void _save() {
    final store = this.store;
    if (store == null || !ready) return;
    unawaited(store.writeJson(_mineStoreKey, _mineJson()));
    if (!isLive) {
      unawaited(store.writeJson(_previewLogKey, {'log': _previewLog}));
      unawaited(store.writeJson(_previewTravelersKey, _previewTravelers));
    }
  }

  Future<void> _loadMine() async {
    final store = this.store;
    if (store == null) return;
    if (isLive) following.clear();
    final m = await store.readJson(_mineStoreKey);
    if (m == null) return;
    nickname = (m['nickname'] as String?) ?? '';
    email = m['email'] as String?;
    if (m['language'] is String) language = m['language'] as String;
    if (m['following'] is List) {
      following
        ..clear()
        ..addAll([for (final n in m['following'] as List) '$n']);
    }
    holding
      ..clear()
      ..addAll([for (final n in (m['holding'] as List? ?? const [])) '$n']);
    holdInfo.clear();
    (m['holds'] as Map? ?? const {}).forEach((k, v) {
      if (v is Map) holdInfo['$k'] = HoldInfo.fromJson(Map<String, dynamic>.from(v));
    });
    foundAt.clear();
    (m['foundAt'] as Map? ?? const {}).forEach((k, v) {
      if (v is List && v.length == 2 && v[0] is num && v[1] is num) foundAt['$k'] = LatLng((v[0] as num).toDouble(), (v[1] as num).toDouble());
    });
    wishTokens
      ..clear()
      ..addAll({for (final e in (m['wishTokens'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'});
    _remoteWishKeys
      ..clear()
      ..addAll([for (final k in (m['remoteWishKeys'] as List? ?? const [])) '$k']);
    journal
      ..clear()
      ..addAll((m['journal'] as List? ?? const []).map(JournalEntry.fromJson).whereType<JournalEntry>());
    _remoteJournal
      ..clear()
      ..addAll((m['remoteJournal'] as List? ?? const []).map(JournalEntry.fromJson).whereType<JournalEntry>());
    final a = m['account'];
    account = a is Map && a['session'] is String ? Account(session: a['session'] as String, email: '${a['email'] ?? ''}') : null;
    if (m.containsKey('reminderFrom')) reminderFrom = m['reminderFrom'] as String?;
  }

  /// SAMPLE: puts back what was done on this phone (finds, pass-ons, wishes, reports, chat).
  /// Photos aren't kept between visits in the preview, like the website's preview.
  Future<void> _replayPreview() async {
    final store = this.store;
    if (store == null) return;
    final saved = await store.readJson(_previewLogKey);
    _previewTravelers = (await store.readJson(_previewTravelersKey)) ?? {};
    _previewLog.clear();
    for (final e in (saved?['log'] as List? ?? const [])) {
      if (e is! Map) continue;
      final entry = Map<String, dynamic>.from(e);
      _previewLog.add(entry);
      final number = '${entry['n']}';
      final date = DateTime.tryParse('${entry['date']}') ?? DateTime.now();
      LatLng? point() => entry['lat'] is num && entry['lng'] is num ? LatLng((entry['lat'] as num).toDouble(), (entry['lng'] as num).toDouble()) : null;
      switch (entry['t']) {
        case 'find':
          _applyFind(number, city: '${entry['city'] ?? ''}', nickname: '${entry['by'] ?? ''}', point: point(), date: date);
        case 'pass':
          _applyPass(
            number,
            city: '${entry['city'] ?? ''}',
            place: entry['place'] as String?,
            handedToSomeone: entry['handed'] == true,
            chapter: '${entry['chapter'] ?? ''}',
            nickname: '${entry['by'] ?? ''}',
            grantedWish: entry['wish'] == true,
            point: point(),
            date: date,
          );
        case 'wish':
          _applyWish(number, '${entry['wish'] ?? ''}');
        case 'report':
          final c = companion(number);
          if (c != null && entry['chipped'] != true) c.status = CompanionStatus.retired;
        case 'chat':
          chats.putIfAbsent(number, () => []).add(ChatMessage(who: '${entry['who'] ?? ''}', text: '${entry['text'] ?? ''}', kind: ChatKind.me));
      }
    }
  }

  void _log(Map<String, dynamic> entry) {
    if (store == null) return;
    _previewLog.add({...entry, 'date': DateTime.now().toIso8601String()});
  }

  // Lookups

  Companion? companion(String number) {
    final clean = cleanNumber(number);
    for (final c in companions) {
      if (cleanNumber(c.number) == clean) return c;
    }
    return null;
  }

  /// The Companion's number as it's written on their page ("7" → "07").
  String _key(String number) => companion(number)?.number ?? number;

  List<Companion> get originals =>
      companions.where((c) => c.isOriginal).toList()
        ..sort((a, b) => (int.tryParse(a.number) ?? 0).compareTo(int.tryParse(b.number) ?? 0));
  List<Companion> get followed => companions.where((c) => following.contains(c.number)).toList();

  /// The 10 Companions with the most stops, most recently moved first when tied.
  List<Companion> get mostActive {
    final sorted = [...companions]
      ..sort((a, b) {
        if (a.stopCount != b.stopCount) return b.stopCount.compareTo(a.stopCount);
        return daysAgo(a.lastMoved).compareTo(daysAgo(b.lastMoved));
      });
    return sorted.take(10).toList();
  }

  int get companionsCarried => stamps.where((s) => s.big.startsWith('#')).length;
  int get wishesGranted => stamps.where((s) => s.big == 'Wish').length;
  int get milesCarried => isLive ? journal.fold(0, (sum, j) => sum + j.miles) : 640;
  int get herdSize {
    if (!isLive) return 14;
    final names = <String>{};
    for (final n in fullJournal.map((j) => j.number).toSet()) {
      for (final s in companion(n)?.stops ?? const <Stop>[]) {
        if (s.leftBy != null && s.kind != 'made' && s.leftBy != nickname) names.add(s.leftBy!);
      }
    }
    return names.length;
  }

  /// Your Passport history: this phone's plus your sign-in's, without doubles, oldest first.
  List<JournalEntry> get fullJournal {
    final out = <JournalEntry>[];
    final seen = <String>{};
    String day(DateTime d) => d.toUtc().toIso8601String().substring(0, 10);
    void add(JournalEntry j) {
      final key = [cleanNumber(j.number), j.type, j.type == 'wish' ? '' : j.city.toLowerCase(), day(j.date)].join('|');
      if (seen.add(key)) out.add(j);
    }

    journal.forEach(add);
    _remoteJournal.forEach(add);
    // Oldest first, keeping the order they were added when the time is the same.
    final order = {for (var i = 0; i < out.length; i++) out[i]: i};
    return out..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : order[a]!.compareTo(order[b]!);
    });
  }

  static const _stampColors = [
    ('DDF0E8', '5B7869', '2F4A3D'),
    ('FBE4E2', 'D98C86', '6B3F3A'),
    ('E7ECE5', '6E8B7D', '3F5A4C'),
    ('DCEAF5', '6A9BC3', '2D4A63'),
    ('E6DDF5', '9C86C9', '4A3D63'),
  ];

  List<Stamp> _liveStamps() {
    final out = <Stamp>[];
    var i = 0;
    for (final j in fullJournal) {
      if (j.type == 'passedOn' || j.type == 'left') {
        final (bg, ring, ink) = _stampColors[i % _stampColors.length];
        out.insert(
          0,
          Stamp(big: '#${j.number}', small: j.city.split(',').first, label: 'Passed on #${j.number}', background: bg, ring: ring, ink: ink, tilt: i.isEven ? -4 : 4),
        );
        i++;
      } else if (j.type == 'wish') {
        final wish = j.wish ?? '';
        out.insert(
          0,
          Stamp(
            big: 'Wish',
            small: 'Granted',
            label: wish.isEmpty ? 'Wish granted' : 'Helped #${j.number} $wish',
            background: 'F9EBB5',
            ring: 'E0B94A',
            ink: '5A4C1E',
            tilt: 3,
          ),
        );
      }
    }
    return out;
  }

  List<ActivityItem> _followedMoves() {
    final now = DateTime.now();
    final moves = <(DateTime, Companion, Stop)>[];
    for (final c in followed) {
      final last = c.current;
      final date = last?.date;
      if (last == null || date == null || last.kind == 'made' || now.difference(date).inDays >= 7) continue;
      moves.add((date, c, last));
    }
    moves.sort((a, b) => b.$1.compareTo(a.$1));
    return [
      for (final (date, c, stop) in moves)
        ActivityItem(
          title: '#${c.number} just arrived in ${stop.city}!',
          meta: [if (stop.byLine != null) stop.byLine!, stop.when].where((s) => s.isNotEmpty).join(' · '),
          icon: Icons.place_outlined,
          background: 'DDF0E8',
          foreground: '2F4A3D',
          route: CompanionRoute(c.number),
          isToday: now.difference(date).inHours < 24,
        ),
    ];
  }

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
    final on = !following.contains(number);
    on ? following.add(number) : following.remove(number);
    notifyListeners();
    _save();
    _syncFollow(number, on);
  }

  /// Signed in (LIVE): the follow is kept with the sign-in too. It works on this phone either way.
  void _syncFollow(String number, bool on) {
    final api = this.api, acct = account;
    if (!isLive || api == null || acct == null) return;
    unawaited(
      api.send('herdFollow', {'session': acct.session, 'number': number, 'on': on}).then((res) {
        if (res.ok && res.data['following'] is List) {
          following
            ..clear()
            ..addAll([for (final n in res.data['following'] as List) _key(wixNumber(n))]);
          notifyListeners();
          _save();
        } else if (res.field == 'session') {
          _dropAccount();
        }
      }),
    );
  }

  void setNickname(String value) {
    nickname = value;
    notifyListeners();
    _save();
  }

  void setEmail(String? value) {
    email = (value == null || value.isEmpty) ? null : value;
    notifyListeners();
    _save();
  }

  void setLanguage(String code) {
    language = code;
    notifyListeners();
    _save();
  }

  void changed() => notifyListeners();

  /// A Companion's journey always goes found → left → found → left. You can only log a find
  /// for a Companion you aren't already holding, and only pass on one you've logged finding.
  bool canLogFind(String number) => !holding.contains(number);

  /// True once the Companion's secret find code has been scanned or typed (see find_codes.dart).
  bool hasFindCode(String number) => unlocked.contains(number);

  /// SAMPLE: checks a typed or scanned find code here in the app. After 5 wrong codes, typing
  /// codes pauses for 10 minutes, so nobody can guess their way in.
  CodeCheck tryFindCode(String number, String code) {
    final locked = _codesLockedUntil;
    if (locked != null && DateTime.now().isBefore(locked)) return CodeCheck.tooManyTries;
    if (isRightFindCode(number, code)) {
      _wrongCodes = 0;
      unlocked.add(number);
      notifyListeners();
      return CodeCheck.right;
    }
    return _wrongCode();
  }

  CodeCheck _wrongCode() {
    _wrongCodes++;
    if (_wrongCodes >= 5) {
      _wrongCodes = 0;
      _codesLockedUntil = DateTime.now().add(const Duration(minutes: 10));
      return CodeCheck.tooManyTries;
    }
    return CodeCheck.wrong;
  }

  /// Checks a find code: here in the app (SAMPLE), or with The Herd's checker (LIVE), which keeps
  /// the codes secret. The checker looks at the code before the nickname, so asking without a
  /// nickname tells us whether the code is right without logging anything (like the website).
  Future<CodeResult> checkFindCode(String number, String code) async {
    final api = this.api;
    if (!isLive || api == null) return CodeResult(tryFindCode(number, code));
    final locked = _codesLockedUntil;
    if (locked != null && DateTime.now().isBefore(locked)) return const CodeResult(CodeCheck.tooManyTries);
    final res = await api.send('herdFind', {
      'number': number,
      'code': cleanFindCode(code),
      if (holdInfo[number]?.token != null) 'holdToken': holdInfo[number]!.token,
    });
    if (!res.ok && res.field == 'code') return CodeResult(_wrongCode(), res.message);
    if (!res.ok && (res.field == 'nickname' || res.field == 'where')) {
      _wrongCodes = 0;
      unlocked.add(number);
      unlockedCodes[number] = cleanFindCode(code);
      notifyListeners();
      return const CodeResult(CodeCheck.right);
    }
    return CodeResult(CodeCheck.problem, res.message ?? CheckerReply.serverProblem);
  }

  bool canPassOn(String number) => holding.contains(number);

  /// How far (in miles) someone is from where they found this Companion, or null if unknown.
  double? milesFromFind(String number, LatLng here) {
    final found = foundAt[number];
    return found == null ? null : const Distance().as(LengthUnit.Meter, found, here) / 1609.344;
  }

  /// A Companion has to travel at least 5 miles from where it was found before it's left somewhere.
  bool farEnoughToPassOn(String number, LatLng here) => (milesFromFind(number, here) ?? minMilesToPassOn) >= minMilesToPassOn;

  /// Adds the signed-in session to a find or pass-on.
  Map<String, dynamic> _withSession(Map<String, dynamic> body) => account == null ? body : {...body, 'session': account!.session};

  /// SAMPLE: logs a find here in the app.
  void logFind(
    String number, {
    required String city,
    required String nickname,
    required CheckIn checkIn,
    String? email,
    LatLng? point,
    LatLng? exactPoint,
  }) {
    if (!canLogFind(number) || !hasFindCode(number)) return;
    _foundIt(number, token: 'preview-${_randomToken()}', city: city, nickname: nickname, email: email, exactPoint: exactPoint);
    _applyFind(number, city: city, nickname: nickname, point: point);
    _log({'t': 'find', 'n': number, 'city': city, 'by': nickname, 'lat': point?.latitude, 'lng': point?.longitude});
    notifyListeners();
    _save();
  }

  /// Your side of a find: holding them, following them, your Passport.
  void _foundIt(String number, {required String? token, required String city, required String nickname, String? email, LatLng? exactPoint}) {
    unlocked.remove(number); // each scan logs one find
    unlockedCodes.remove(number);
    if (exactPoint != null) foundAt[number] = exactPoint;
    this.nickname = nickname;
    if (email != null && email.isNotEmpty) this.email = email;
    holding.add(number);
    holdInfo[number] = HoldInfo(token: token, city: city, date: DateTime.now(), claimed: account != null);
    if (!following.contains(number)) {
      following.add(number);
      _syncFollow(number, true);
    }
    journal.add(JournalEntry(type: 'found', number: number, city: city, date: DateTime.now()));
  }

  /// The Companion's side of a find: a new "Found by" stop.
  void _applyFind(String number, {required String city, required String nickname, LatLng? point, DateTime? date}) {
    final c = companion(number);
    if (c == null) return;
    final when = date == null ? 'Just now' : relativeTime(date);
    final last = c.current;
    c.status = CompanionStatus.moving;
    c.stops.add(
      Stop(
        city: city.isEmpty ? (last?.city ?? '') : city,
        latitude: point?.latitude ?? last?.latitude ?? 0,
        longitude: point?.longitude ?? last?.longitude ?? 0,
        leftBy: nickname,
        when: when,
        found: true,
        date: date ?? DateTime.now(),
      ),
    );
    c.lastMoved = when;
    c.movedThisWeek = date == null || DateTime.now().difference(date).inDays < 7;
    _activity.insert(
      0,
      ActivityItem(
        title: 'You found #$number!',
        meta: when == 'Just now' ? '$city · just now' : '$city · $when',
        icon: Icons.place_outlined,
        background: 'DDF0E8',
        foreground: '2F4A3D',
        route: CompanionRoute(number),
        isToday: date == null || DateTime.now().difference(date).inHours < 24,
      ),
    );
  }

  /// Logs a find: here in the app (SAMPLE) or with The Herd's checker (LIVE).
  Future<WriteResult> submitFind(
    String number, {
    required String city,
    required String nickname,
    required CheckIn checkIn,
    String? email,
    LatLng? point,
    required LatLng exactPoint,
  }) async {
    final api = this.api;
    if (!isLive || api == null) {
      logFind(number, city: city, nickname: nickname, checkIn: checkIn, email: email, point: point, exactPoint: exactPoint);
      return const WriteResult.ok();
    }
    final res = await api.send(
      'herdFind',
      _withSession({
        'number': number,
        'code': unlockedCodes[number] ?? '',
        'nickname': nickname,
        'city': city,
        'latitude': exactPoint.latitude,
        'longitude': exactPoint.longitude,
      }),
    );
    if (!res.ok) {
      if (res.field == 'code') {
        unlocked.remove(number);
        unlockedCodes.remove(number);
        notifyListeners();
      }
      return WriteResult.from(res);
    }
    _foundIt(number, token: res.data['holdToken'] as String?, city: city, nickname: nickname, email: email, exactPoint: exactPoint);
    _applyFind(number, city: city, nickname: nickname, point: point);
    notifyListeners();
    _save();
    unawaited(refreshLive());
    return const WriteResult.ok();
  }

  /// SAMPLE: passes a Companion on here in the app.
  void passOn(
    String number, {
    required String city,
    String? place,
    required bool handedToSomeone,
    required String chapter,
    required String nickname,
    required bool grantedWish,
    Uint8List? photo,
    LatLng? point,
    LatLng? exactPoint,
  }) {
    if (!canPassOn(number)) return;
    // Leaving them somewhere needs 5+ miles from the find; handing them to someone doesn't.
    if (!handedToSomeone && exactPoint != null && !farEnoughToPassOn(number, exactPoint)) return;
    final wish = companion(number)?.wish;
    _passedIt(number, city: city, handedToSomeone: handedToSomeone, nickname: nickname, grantedWish: grantedWish, wish: wish, exactPoint: exactPoint);
    if (grantedWish) wishTokens[number] = 'preview-${_randomToken()}';
    _applyPass(
      number,
      city: city,
      place: place,
      handedToSomeone: handedToSomeone,
      chapter: chapter,
      nickname: nickname,
      grantedWish: grantedWish,
      photo: photo,
      point: point,
    );
    _log({
      't': 'pass',
      'n': number,
      'city': city,
      'place': handedToSomeone ? null : place,
      'handed': handedToSomeone,
      'chapter': chapter,
      'by': nickname,
      'wish': grantedWish,
      'lat': point?.latitude,
      'lng': point?.longitude,
    });
    notifyListeners();
    _save();
  }

  /// Your side of a pass-on: no longer holding them, and a new line in your Passport.
  void _passedIt(
    String number, {
    required String city,
    required bool handedToSomeone,
    required String nickname,
    required bool grantedWish,
    String? wish,
    LatLng? exactPoint,
  }) {
    final from = foundAt[number];
    final miles = from != null && exactPoint != null ? (const Distance().as(LengthUnit.Meter, from, exactPoint) / 1609.344).round() : 0;
    foundAt.remove(number);
    holdInfo.remove(number);
    if (nickname.isNotEmpty) this.nickname = nickname;
    holding.remove(number);
    final now = DateTime.now();
    journal.add(JournalEntry(type: handedToSomeone ? 'passedOn' : 'left', number: number, city: city, date: now, miles: miles));
    if (grantedWish) journal.add(JournalEntry(type: 'wish', number: number, city: city, date: now, wish: wish));
    if (reminderFrom == number) reminderFrom = null;
  }

  /// The Companion's side of a pass-on: a new stop with the chapter, and (SAMPLE) the new stamps.
  void _applyPass(
    String number, {
    required String city,
    String? place,
    required bool handedToSomeone,
    required String chapter,
    required String nickname,
    required bool grantedWish,
    Uint8List? photo,
    LatLng? point,
    DateTime? date,
  }) {
    final c = companion(number);
    if (c == null) return;
    final when = date == null ? 'Just now' : relativeTime(date);
    final last = c.current;
    c.stops.add(
      Stop(
        city: city,
        place: handedToSomeone ? null : place,
        latitude: point?.latitude ?? last?.latitude ?? 0,
        longitude: point?.longitude ?? last?.longitude ?? 0,
        leftBy: nickname,
        when: when,
        note: chapter.isEmpty ? null : chapter,
        photo: photo,
        handedOn: handedToSomeone,
        date: date ?? DateTime.now(),
      ),
    );
    _activity.insert(
      0,
      ActivityItem(
        title: '#$number just arrived in $city!',
        meta: '${c.current!.byLine} · $when',
        icon: Icons.place_outlined,
        background: 'DDF0E8',
        foreground: '2F4A3D',
        route: CompanionRoute(number),
        isToday: date == null || DateTime.now().difference(date).inHours < 24,
      ),
    );
    c.status = handedToSomeone ? CompanionStatus.moving : CompanionStatus.waiting;
    c.lastMoved = when;
    c.movedThisWeek = date == null || DateTime.now().difference(date).inDays < 7;
    c.travelers += 1;
    _sampleStamps.insert(
      0,
      Stamp(big: '#$number', small: city, label: 'Passed on #$number', background: 'DDF0E8', ring: '5B7869', ink: '2F4A3D', tilt: -4),
    );
    if (grantedWish) {
      c.wishGranted = true;
      _sampleStamps.insert(
        0,
        Stamp(
          big: 'Wish',
          small: 'Granted',
          label: 'Helped #$number ${c.wish}',
          background: 'F9EBB5',
          ring: 'E0B94A',
          ink: '5A4C1E',
          tilt: 3,
        ),
      );
    }
  }

  /// Passes a Companion on: here in the app (SAMPLE) or with The Herd's checker (LIVE).
  Future<WriteResult> submitPassOn(
    String number, {
    required String city,
    String? place,
    required bool handedToSomeone,
    required String chapter,
    required String nickname,
    required bool grantedWish,
    Uint8List? photo,
    Uint8List? wishPhoto,
    LatLng? point,
    required LatLng exactPoint,
    Future<Uint8List?> Function(Uint8List bytes)? shrink,
  }) async {
    final api = this.api;
    if (!isLive || api == null) {
      passOn(
        number,
        city: city,
        place: place,
        handedToSomeone: handedToSomeone,
        chapter: chapter,
        nickname: nickname,
        grantedWish: grantedWish,
        photo: photo ?? (grantedWish ? wishPhoto : null),
        point: point,
        exactPoint: exactPoint,
      );
      return const WriteResult.ok();
    }
    final photoJson = await photoForChecker(photo, shrink: shrink);
    final wishJson = grantedWish ? await photoForChecker(wishPhoto, shrink: shrink) : null;
    final res = await api.send(
      'herdPassOn',
      _withSession({
        'number': number,
        'holdToken': holdInfo[number]?.token,
        'handedOn': handedToSomeone,
        'city': city,
        'latitude': exactPoint.latitude,
        'longitude': exactPoint.longitude,
        'hint': handedToSomeone ? '' : (place ?? ''),
        'chapter': chapter,
        'nickname': nickname,
        'photo': photoJson,
        'wishGranted': grantedWish,
        if (grantedWish) 'wishPhoto': wishJson,
      }),
    );
    if (!res.ok) return WriteResult.from(res);
    final wish = companion(number)?.wish;
    _passedIt(number, city: city, handedToSomeone: handedToSomeone, nickname: nickname, grantedWish: grantedWish, wish: wish, exactPoint: exactPoint);
    final wishToken = res.data['wishToken'];
    if (wishToken is String && wishToken.isNotEmpty) wishTokens[number] = wishToken;
    if (photo != null) _localPhotos[number] = (city, photo);
    _applyPass(
      number,
      city: city,
      place: place,
      handedToSomeone: handedToSomeone,
      chapter: chapter,
      nickname: nickname,
      grantedWish: grantedWish,
      photo: photo,
      point: point,
    );
    notifyListeners();
    _save();
    unawaited(refreshLive());
    return const WriteResult.ok();
  }

  /// A photo for the checker: base64 with its type, under 8 MB (made smaller if needed).
  static Future<Map<String, String>?> photoForChecker(Uint8List? bytes, {Future<Uint8List?> Function(Uint8List bytes)? shrink}) async {
    if (bytes == null) return null;
    var data = bytes;
    if (data.length > 7 * 1024 * 1024 && shrink != null) data = await shrink(data) ?? data;
    final isPng = data.length > 4 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47;
    final isWebp = data.length > 12 && String.fromCharCodes(data.sublist(8, 12)) == 'WEBP';
    return {'base64': base64Encode(data), 'mimeType': isPng ? 'image/png' : (isWebp ? 'image/webp' : 'image/jpeg')};
  }

  /// Can this phone choose the next wish? (Only the traveler who granted the last one can.)
  bool canChooseWish(String number) => !isLive || wishTokens.containsKey(number);

  void setNextWish(String number, String wish) {
    _applyWish(number, wish);
    _log({'t': 'wish', 'n': number, 'wish': wish});
    wishTokens.remove(number);
    notifyListeners();
    _save();
  }

  void _applyWish(String number, String wish) {
    final c = companion(number);
    if (c == null) return;
    var text = wish.trim();
    if (text.toLowerCase().startsWith('i want to ')) text = text.substring(10);
    if (text.endsWith('.')) text = text.substring(0, text.length - 1);
    c.wish = text;
    c.wishGranted = false;
  }

  /// Sets the next wish: here in the app (SAMPLE) or with The Herd's checker (LIVE).
  Future<WriteResult> submitWish(String number, String wish) async {
    final api = this.api;
    if (!isLive || api == null) {
      setNextWish(number, wish);
      return const WriteResult.ok();
    }
    final res = await api.send('herdWish', {'number': number, 'wishToken': wishTokens[number], 'wish': wish});
    if (!res.ok) return WriteResult.from(res);
    _remoteWishKeys.remove(number);
    _applyWish(number, wish);
    wishTokens.remove(number);
    notifyListeners();
    _save();
    unawaited(refreshLive());
    return const WriteResult.ok();
  }

  void reportBroken(String number, {required bool chipped}) {
    final c = companion(number);
    if (c != null && !chipped) c.status = CompanionStatus.retired;
    holding.remove(number);
    holdInfo.remove(number);
    _log({'t': 'report', 'n': number, 'chipped': chipped});
    notifyListeners();
    _save();
  }

  /// "Something happened": here in the app (SAMPLE) or with The Herd's checker (LIVE).
  /// [what] is broke, chipped or lost.
  Future<WriteResult> submitReport(
    String number, {
    required String what,
    required String city,
    String note = '',
    String byName = '',
    bool sendPieces = false,
  }) async {
    final api = this.api;
    if (!isLive || api == null) {
      reportBroken(number, chipped: what == 'chipped');
      return const WriteResult.ok();
    }
    final res = await api.send('herdReport', {
      'number': number,
      'what': what,
      'city': city,
      'note': note,
      'byName': byName,
      'sendPieces': sendPieces,
      'email': sendPieces ? (email ?? '') : '',
    });
    if (!res.ok) return WriteResult.from(res);
    if (byName.isNotEmpty) nickname = byName;
    if (what != 'chipped') {
      holding.remove(number);
      holdInfo.remove(number);
      companion(number)?.status = CompanionStatus.retired;
    }
    notifyListeners();
    _save();
    unawaited(refreshLive());
    return const WriteResult.ok();
  }

  void dismissReminder() {
    reminderFrom = null;
    notifyListeners();
    _save();
  }

  /// Traveler chat for one Companion. LIVE: read from The Herd's site the first time it's opened.
  void ensureChat(String number) {
    final api = this.api;
    if (!isLive || api == null || _chatsLoaded.contains(number) || _chatsLoading.contains(number)) return;
    _chatsLoading.add(number);
    unawaited(
      api
          .loadChat(number)
          .then((list) {
            final mine = (chats[number] ?? const <ChatMessage>[]).where((m) => m.kind == ChatKind.me);
            chats[number] = [...list, ...mine];
            _chatsLoaded.add(number);
          })
          .catchError((Object _) {})
          .whenComplete(() {
            _chatsLoading.remove(number);
            notifyListeners();
          }),
    );
  }

  void sendChat(String number, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final who = nickname.isEmpty ? 'You' : nickname;
    final shown = hideContactDetails(trimmed);
    chats.putIfAbsent(number, () => []).add(ChatMessage(who: who, text: shown, kind: ChatKind.me));
    _log({'t': 'chat', 'n': number, 'who': who, 'text': shown});
    notifyListeners();
    _save();
  }

  /// Sends a chat message: here in the app (SAMPLE) or with The Herd's checker (LIVE).
  Future<WriteResult> submitChat(String number, String text) async {
    final api = this.api;
    if (!isLive || api == null) {
      sendChat(number, text);
      return const WriteResult.ok();
    }
    final author = nickname.isEmpty ? 'Traveler' : nickname;
    final res = await api.send('herdChat', {'number': number, 'author': author, 'message': text.trim()});
    if (!res.ok) return WriteResult.from(res);
    final message = res.data['message'] is String ? res.data['message'] as String : hideContactDetails(text.trim());
    chats.putIfAbsent(number, () => []).add(ChatMessage(who: author, text: message, kind: ChatKind.me));
    notifyListeners();
    return const WriteResult.ok();
  }

  void deleteMyData() {
    email = null;
    nickname = '';
    notifyListeners();
    _save();
  }

  // Optional sign-in: an emailed 6-digit code, no password. Nothing needs it. When signed in,
  // the Passport, the Companions in your care and the ones you follow are kept with your email.

  bool get signedIn => account != null;

  /// Asks for a sign-in code. SAMPLE: the code comes back to show on screen instead of an email.
  Future<WriteResult> signInStart(String rawEmail) async {
    final address = rawEmail.trim().toLowerCase();
    final api = this.api;
    if (isLive && api != null) return WriteResult.from(await api.send('herdSignInStart', {'email': rawEmail.trim()}));
    // SAMPLE: the same rules as the checker, here in the app.
    if (!isEmail(address)) return const WriteResult.problem('Please enter a valid email.', field: 'email');
    final now = DateTime.now().millisecondsSinceEpoch;
    final traveler = Map<String, dynamic>.from((_previewTravelers[address] as Map?) ?? {'following': <String>[], 'nickname': ''});
    final sentAt = traveler['codeSentAt'];
    if (sentAt is int && now - sentAt < 60 * 1000) {
      return const WriteResult.problem('We just sent you a code. Please wait a minute before asking for another one.', field: 'email');
    }
    final code = math.Random().nextInt(1000000).toString().padLeft(6, '0');
    traveler.addAll({'code': code, 'codeExpires': now + 15 * 60 * 1000, 'codeTries': 0, 'codeSentAt': now});
    _previewTravelers[address] = traveler;
    _save();
    return WriteResult.ok(previewCode: code);
  }

  /// Checks the code. Companions found on this phone, follows and your nickname come along.
  Future<WriteResult> signInVerify(String rawEmail, String code) async {
    final address = rawEmail.trim().toLowerCase();
    final holds = {
      for (final n in holding)
        if (holdInfo[n]?.token != null) n: holdInfo[n]!.token!,
    };
    final api = this.api;
    String session;
    Map<String, dynamic> profile;
    if (isLive && api != null) {
      final res = await api.send('herdSignInVerify', {
        'email': rawEmail.trim(),
        'code': code,
        'holds': holds,
        'following': following.toList(),
        'nickname': nickname,
      });
      if (!res.ok) return WriteResult.from(res);
      session = '${res.data['session'] ?? ''}';
      profile = Map<String, dynamic>.from((res.data['profile'] as Map?) ?? const {});
    } else {
      final saved = _previewTravelers[address];
      final traveler = saved is Map ? Map<String, dynamic>.from(saved) : null;
      if (traveler != null) _previewTravelers[address] = traveler;
      if (traveler == null || traveler['code'] == null) return const WriteResult.problem('Please ask for a sign-in code first.', field: 'code');
      if (DateTime.now().millisecondsSinceEpoch > (traveler['codeExpires'] as int? ?? 0)) {
        return const WriteResult.problem('That code has expired. Please ask for a new one.', field: 'code');
      }
      if ((traveler['codeTries'] as int? ?? 0) >= 5) return const WriteResult.problem('Too many tries. Please ask for a new code.', field: 'code');
      if (code.replaceAll(RegExp(r'\D'), '') != traveler['code']) {
        traveler['codeTries'] = (traveler['codeTries'] as int? ?? 0) + 1;
        _save();
        return const WriteResult.problem('That code isn’t right. Check the email and try again.', field: 'code');
      }
      session = 'preview-${_randomToken()}';
      final follows = {...[for (final n in (traveler['following'] as List? ?? const [])) '$n'], ...following};
      final nick = '${traveler['nickname'] ?? ''}'.isNotEmpty ? '${traveler['nickname']}' : (checkNickname(nickname) == null ? nickname : '');
      traveler.addAll({'code': null, 'codeExpires': null, 'codeTries': 0, 'session': session, 'following': follows.toList(), 'nickname': nick});
      profile = {
        'email': address,
        'nickname': nick,
        'following': follows.toList(),
        'holds': [
          for (final e in holds.entries) {'number': e.key, 'token': e.value, 'city': holdInfo[e.key]?.city ?? '', 'date': holdInfo[e.key]?.date?.toIso8601String()},
        ],
        'wishTokens': wishTokens,
        'journal': const [],
      };
    }
    account = Account(session: session, email: '${profile['email'] ?? address}');
    for (final n in holds.keys) {
      holdInfo[n]?.claimed = true;
    }
    _applyProfile(profile);
    notifyListeners();
    _save();
    return const WriteResult.ok();
  }

  /// What the signed-in traveler has, from The Herd. Companions in their care linked to the
  /// sign-in follow the server; ones found on this phone and never linked stay.
  void _applyProfile(Map<String, dynamic> profile) {
    for (final n in holdInfo.keys.toList()) {
      if (holdInfo[n]!.claimed) {
        holdInfo.remove(n);
        holding.remove(n);
      }
    }
    for (final h in (profile['holds'] as List? ?? const [])) {
      if (h is! Map) continue;
      final n = _key(wixNumber(h['number']));
      holding.add(n);
      holdInfo[n] = HoldInfo(token: h['token'] as String?, city: '${h['city'] ?? ''}', date: dateOf(h['date']), claimed: true);
    }
    foundAt.removeWhere((n, _) => !holding.contains(n));
    for (final k in _remoteWishKeys) {
      wishTokens.remove(k);
    }
    _remoteWishKeys.clear();
    (profile['wishTokens'] as Map? ?? const {}).forEach((k, v) {
      final n = _key(wixNumber(k));
      wishTokens[n] = '$v';
      _remoteWishKeys.add(n);
    });
    if (profile['following'] is List) {
      following
        ..clear()
        ..addAll([for (final n in profile['following'] as List) _key(wixNumber(n))]);
    }
    if (nickname.isEmpty && profile['nickname'] is String) nickname = profile['nickname'] as String;
    _remoteJournal
      ..clear()
      ..addAll([
        for (final j in (profile['journal'] as List? ?? const [])) ...[
          ?JournalEntry.fromJson(j is Map ? {...j, 'number': _key(wixNumber(j['number'])), 'date': dateOf(j['date'])?.toIso8601String()} : null),
          if (j is Map && j['wishGranted'] == true)
            ?JournalEntry.fromJson({...j, 'type': 'wish', 'number': _key(wixNumber(j['number'])), 'date': dateOf(j['date'])?.toIso8601String()}),
        ],
      ]);
  }

  /// Signed out (or the sign-in ended): what came only from the sign-in leaves; local finds stay.
  void _dropAccount() {
    account = null;
    for (final n in holdInfo.keys.toList()) {
      final h = holdInfo[n]!;
      if (!h.claimed) continue;
      if (foundAt.containsKey(n)) {
        h.claimed = false;
      } else {
        holdInfo.remove(n);
        holding.remove(n);
      }
    }
    for (final k in _remoteWishKeys) {
      wishTokens.remove(k);
    }
    _remoteWishKeys.clear();
    _remoteJournal.clear();
    notifyListeners();
    _save();
  }

  /// LIVE, on start-up: refreshes what the signed-in traveler has. Problems never block anything.
  Future<void> syncAccount() async {
    final api = this.api, acct = account;
    if (!isLive || api == null || acct == null) return;
    final res = await api.send('herdMine', {'session': acct.session}).timeout(
      const Duration(seconds: 6),
      onTimeout: () => const CheckerReply(ok: false, status: 0),
    );
    if (res.ok && res.data['profile'] is Map) {
      _applyProfile(Map<String, dynamic>.from(res.data['profile'] as Map));
      notifyListeners();
      _save();
    } else if (res.field == 'session') {
      _dropAccount();
    }
  }

  Future<void> signOut() async {
    final api = this.api, acct = account;
    if (isLive && api != null && acct != null) await api.send('herdSignOut', {'session': acct.session});
    if (!isLive && acct != null) {
      for (final t in _previewTravelers.values) {
        if (t is Map && t['session'] == acct.session) t['session'] = null;
      }
    }
    _dropAccount();
  }

  /// "Delete my data": removes your email and sign-in from The Herd. Chapters stay.
  Future<WriteResult> forgetMe() async {
    final api = this.api, acct = account;
    if (acct == null) return const WriteResult.ok();
    if (isLive && api != null) {
      final res = await api.send('herdForgetMe', {'session': acct.session});
      if (!res.ok && res.field != 'session') return WriteResult.from(res);
    } else {
      _previewTravelers.remove(acct.email);
    }
    email = null;
    _dropAccount();
    return const WriteResult.ok();
  }

  static String _randomToken() {
    const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
    final r = math.Random();
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // Helpers

  static String cleanNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    return trimmed.isEmpty ? (digits.isEmpty ? '' : '0') : trimmed;
  }

  /// Reads a scanned QR code ("https://companions.theherdstudio.com/c/07?k=KX4P", or the
  /// ".../herd-around-the-world?c=07&k=KX4P" and "#/c/07" forms) or a typed number ("07").
  static String? numberFromScan(String payload) {
    final query = RegExp(r'[?&#]c=(\d+)').firstMatch(payload);
    if (query != null) return query.group(1);
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

/// [problem]: the checker answered something else (like "already with you"), or couldn’t be reached.
enum CodeCheck { right, wrong, tooManyTries, problem }
