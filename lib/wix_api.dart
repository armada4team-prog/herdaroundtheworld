/// The Herd's Wix site: the same data the website uses.
///
/// READING: the Companions, CompanionStops and CompanionChat lists in The Herd's Wix CMS, with a
/// Wix Headless visitor token (the same as website/js/data.js).
/// WRITING: every find, pass-on, wish, chat message, report and sign-in goes to The Herd's checker
/// (wix/backend/handlers.src.js, run as the Cloudflare Worker in worker/), which checks the rules,
/// saves to the same Wix lists and keeps the find codes secret.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

const wixClientId = '492b0619-e1c9-49e2-958c-b24c49fc5771';
const wixApi = 'https://www.wixapis.com';
/// ▶ THE CHECKER ADDRESS (the Cloudflare Worker in worker/). Change it here once the Worker is
/// deployed; the website has the same address in website/js/data.js (CHECKER). Until it answers,
/// the app stays in sample mode.
const checkerBase = 'https://herd-checker.growtheherd.workers.dev/';

/// What the checker answered. [status] is 0 when The Herd couldn't be reached at all.
class CheckerReply {
  const CheckerReply({required this.ok, required this.status, this.field, this.message, this.data = const {}});
  final bool ok;
  final int status;
  final String? field;
  final String? message;
  final Map<String, dynamic> data;

  static const serverProblem = 'Something went wrong on our side. Please try again in a minute.';
  static const unreachable = 'We couldn’t reach The Herd. Check your connection and try again.';
}

/// Whether the checker is there: [live] (it answered), [notThere] (the site answered, but there's
/// no checker yet: before the Wix site is published), or [unreachable] (no internet or no answer).
enum CheckerProbe { live, notThere, unreachable }

/// Raw Wix lists, kept as a cached copy for when the phone is offline.
class WixLists {
  const WixLists({required this.companions, required this.stops});
  final List<Map<String, dynamic>> companions;
  final List<Map<String, dynamic>> stops;

  Map<String, dynamic> toJson() => {'companions': companions, 'stops': stops};
  static WixLists? fromJson(Object? json) {
    if (json is! Map) return null;
    List<Map<String, dynamic>> list(Object? v) =>
        v is List ? [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)] : <Map<String, dynamic>>[];
    return WixLists(companions: list(json['companions']), stops: list(json['stops']));
  }
}

class WixApi {
  WixApi({http.Client? client, this.timeout = const Duration(seconds: 20)}) : client = client ?? http.Client();

  final http.Client client;
  final Duration timeout;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  static const _json = {'Content-Type': 'application/json'};

  // ── Is the checker there? ───────────────────────────────────────────────────────────────
  /// herdMine with no session answers 400 {field: 'session'} when the checker is live.
  Future<CheckerProbe> probeChecker({Duration within = const Duration(seconds: 6)}) async {
    try {
      final res = await client
          .post(Uri.parse('${checkerBase}herdMine'), headers: const {'Content-Type': 'text/plain'}, body: '{}')
          .timeout(within);
      if (res.statusCode == 400) {
        final json = _decode(res.body);
        if (json['field'] == 'session') return CheckerProbe.live;
      }
      return CheckerProbe.notThere;
    } catch (_) {
      return CheckerProbe.unreachable;
    }
  }

  // ── Reading ─────────────────────────────────────────────────────────────────────────────
  Future<String> _token({bool forceNew = false}) async {
    final saved = _accessToken;
    final expires = _expiresAt;
    if (!forceNew && saved != null && expires != null && expires.isAfter(DateTime.now().add(const Duration(minutes: 1)))) return saved;
    final url = Uri.parse('$wixApi/oauth2/token');
    final refresh = _refreshToken;
    http.Response res;
    if (refresh != null) {
      res = await client
          .post(url, headers: _json, body: jsonEncode({'clientId': wixClientId, 'grantType': 'refresh_token', 'refresh_token': refresh}))
          .timeout(timeout);
      if (res.statusCode != 200) res = await _anonymous(url);
    } else {
      res = await _anonymous(url);
    }
    if (res.statusCode != 200) throw Exception('token ${res.statusCode}');
    final json = _decode(res.body);
    final access = json['access_token'];
    if (access is! String || access.isEmpty) throw Exception('no token');
    _accessToken = access;
    _refreshToken = json['refresh_token'] is String ? json['refresh_token'] as String : null;
    final seconds = json['expires_in'] is num ? (json['expires_in'] as num).toInt() : 14400;
    _expiresAt = DateTime.now().add(Duration(seconds: seconds));
    return access;
  }

  Future<http.Response> _anonymous(Uri url) =>
      client.post(url, headers: _json, body: jsonEncode({'clientId': wixClientId, 'grantType': 'anonymous'})).timeout(timeout);

  /// Every item in one CMS list (100 at a time).
  Future<List<Map<String, dynamic>>> queryAll(String collection, [Map<String, dynamic> filter = const {}]) async {
    final items = <Map<String, dynamic>>[];
    for (var offset = 0; offset < 20000; offset += 100) {
      Future<http.Response> call(String auth) => client
          .post(
            Uri.parse('$wixApi/wix-data/v2/items/query'),
            headers: {..._json, 'Authorization': auth},
            body: jsonEncode({
              'dataCollectionId': collection,
              'query': {
                'filter': filter,
                'paging': {'limit': 100, 'offset': offset},
              },
            }),
          )
          .timeout(timeout);
      var res = await call(await _token());
      if (res.statusCode == 401 || res.statusCode == 403) res = await call(await _token(forceNew: true));
      if (res.statusCode != 200) throw Exception('$collection ${res.statusCode}');
      final json = _decode(res.body);
      final page = [
        for (final d in (json['dataItems'] as List? ?? const []))
          if (d is Map) Map<String, dynamic>.from((d['data'] as Map?) ?? const {}),
      ];
      items.addAll(page);
      if (page.length < 100) break;
    }
    return items;
  }

  Future<WixLists> loadLists() async {
    final results = await Future.wait([queryAll('Companions'), queryAll('CompanionStops')]);
    return WixLists(companions: results[0], stops: results[1]);
  }

  /// Traveler chat for one Companion, oldest first. Hidden messages are never shown.
  Future<List<ChatMessage>> loadChat(String number, {String? myName}) async {
    final items = await queryAll('CompanionChat', {'companionNumber': number});
    final visible = items.where((m) => m['hidden'] != true).toList()
      ..sort((a, b) => (dateOf(a['_createdDate'])?.millisecondsSinceEpoch ?? 0).compareTo(dateOf(b['_createdDate'])?.millisecondsSinceEpoch ?? 0));
    return [
      for (final m in visible)
        ChatMessage(
          who: '${m['author'] ?? ''}',
          text: '${m['message'] ?? ''}',
          kind: '${m['author']}'.startsWith('The Herd') ? ChatKind.herd : ChatKind.traveler,
        ),
    ];
  }

  // ── Writing ─────────────────────────────────────────────────────────────────────────────
  /// Sends one request to the checker. Never throws.
  Future<CheckerReply> send(String name, Map<String, dynamic> body) async {
    try {
      final res = await client
          .post(Uri.parse('$checkerBase$name'), headers: const {'Content-Type': 'text/plain'}, body: jsonEncode(body))
          .timeout(timeout);
      final json = _decode(res.body);
      if (res.statusCode == 200 && json['ok'] != false) return CheckerReply(ok: true, status: 200, data: json);
      if (res.statusCode == 400) {
        return CheckerReply(
          ok: false,
          status: 400,
          field: json['field'] is String ? json['field'] as String : null,
          message: json['message'] is String ? json['message'] as String : 'Something was missing. Please try again.',
          data: json,
        );
      }
      return CheckerReply(ok: false, status: res.statusCode, message: CheckerReply.serverProblem, data: json);
    } catch (_) {
      return const CheckerReply(ok: false, status: 0, message: CheckerReply.unreachable);
    }
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

// ── Turning Wix items into Companions (the same rules as website/js/data.js) ────────────────

/// `wix:image://v1/<id>/<name>#...` → `https://static.wixstatic.com/media/<id>`
String? wixImageUrl(Object? value) {
  if (value is! String || value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  final m = RegExp(r'^wix:image://v1/([^/#]+)').firstMatch(value);
  return m == null ? null : 'https://static.wixstatic.com/media/${m.group(1)}';
}

/// Wix dates come as {"$date": "2026-01-02T…Z"} or a plain string.
DateTime? dateOf(Object? v) {
  if (v == null) return null;
  final s = v is Map ? v[r'$date'] : v;
  return s is String ? DateTime.tryParse(s)?.toLocal() : null;
}

/// A date → "Just now", "5 hours ago", "3 days ago", "2 weeks ago", "4 months ago".
String relativeTime(DateTime date, [DateTime? now]) {
  final hours = (now ?? DateTime.now()).difference(date).inMinutes / 60;
  if (hours < 1) return 'Just now';
  if (hours < 24) {
    final h = hours.floor();
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  final days = (hours / 24).floor();
  if (days < 7) return days == 1 ? '1 day ago' : '$days days ago';
  if (days < 30) {
    final w = (days / 7).floor();
    return w == 1 ? '1 week ago' : '$w weeks ago';
  }
  final m = (days / 30).floor().clamp(1, 1 << 30);
  return m == 1 ? '1 month ago' : '$m months ago';
}

/// A Wix number field can be text ("07") or a number (7).
String wixNumber(Object? v) => v is num ? v.toInt().toString() : '${v ?? ''}';

String _cleanNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
  return trimmed.isEmpty ? (digits.isEmpty ? '' : '0') : trimmed;
}

double _double(Object? v) => v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);

String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

/// Builds the Companions from the Wix lists.
List<Companion> companionsFromWix(WixLists lists, {DateTime? now}) {
  final byNumber = <String, List<Map<String, dynamic>>>{};
  for (final s in lists.stops) {
    byNumber.putIfAbsent(_cleanNumber(wixNumber(s['companionNumber'])), () => []).add(s);
  }
  return [
    for (final c in lists.companions)
      if (wixNumber(c['number']).isNotEmpty) companionFromWix(c, byNumber[_cleanNumber(wixNumber(c['number']))] ?? const [], now: now),
  ];
}

Companion companionFromWix(Map<String, dynamic> c, List<Map<String, dynamic>> stops, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  int time(Map<String, dynamic> s) => dateOf(s['_createdDate'])?.millisecondsSinceEpoch ?? 0;
  final sorted = [...stops]
    ..sort((a, b) {
      final am = a['kind'] == 'made', bm = b['kind'] == 'made';
      if (am != bm) return am ? -1 : 1;
      return time(a).compareTo(time(b));
    });
  String whenFor(Map<String, dynamic> s) {
    final text = _text(s['whenText']);
    if (text != null) return text;
    if (s['sample'] == true) return '';
    final d = dateOf(s['_createdDate']);
    return d == null ? '' : relativeTime(d, clock);
  }

  final mapped = [
    for (final s in sorted)
      Stop(
        city: '${s['city'] ?? ''}',
        place: _text(s['place']),
        latitude: _double(s['latitude']),
        longitude: _double(s['longitude']),
        leftBy: _text(s['byName']),
        when: whenFor(s),
        note: _text(s['chapter']),
        // Only photos The Herd has approved are shown.
        photoUrl: s['photoApproved'] == true ? wixImageUrl(s['photo']) : null,
        found: s['kind'] == 'found',
        handedOn: s['kind'] == 'passedOn',
        kind: '${s['kind'] ?? 'left'}',
        date: dateOf(s['_createdDate']),
      ),
  ];
  final moves = mapped.where((s) => s.kind != 'made').toList();
  final lastMove = moves.isEmpty ? null : moves.last;
  final status = CompanionStatus.values.firstWhere((v) => v.name == c['status'], orElse: () => CompanionStatus.moving);
  final travelers = moves.map((s) => s.leftBy).whereType<String>().toSet().length;
  final lastDate = lastMove?.date;
  final companion = Companion(
    number: wixNumber(c['number']),
    name: _text(c['name']),
    glaze: _text(c['glaze']) ?? 'A8DCC9',
    accent: _text(c['accent']) ?? 'D98C86',
    blob: _text(c['blob']) ?? 'DDF0E8',
    isOriginal: c['isOriginal'] == true,
    status: status,
    wish: '${c['wish'] ?? ''}'.replaceFirst(RegExp(r'^i want to ', caseSensitive: false), '').replaceFirst(RegExp(r'\.$'), ''),
    wishGranted: c['wishGranted'] == true,
    lastMoved: status == CompanionStatus.waiting && lastMove == null ? 'Waiting to be found' : (mapped.isEmpty ? '' : mapped.last.when),
    movedThisWeek: lastMove != null &&
        (lastDate != null ? clock.difference(lastDate) < const Duration(days: 7) : _daysAgo(lastMove.when) <= 7),
    stops: mapped,
    travelers: travelers < 1 ? 1 : travelers,
  );
  final blurb = _text(c['blurb']);
  final origin = _text(c['originStory']);
  if (blurb != null) companion.blurb = blurb;
  if (origin != null) companion.originStory = origin;
  return companion;
}

int _daysAgo(String text) {
  final n = int.tryParse(text.split(' ').first);
  if (n == null) return text == 'Just now' ? 0 : 999;
  if (text.contains('hour') || text.contains('minute')) return 0;
  if (text.contains('week')) return n * 7;
  if (text.contains('month')) return n * 30;
  return n;
}
