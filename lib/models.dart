import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// One place a Companion has been. Only a city or a public place is ever stored, never a street address.
class Stop {
  Stop({
    required this.city,
    this.place,
    required this.latitude,
    required this.longitude,
    this.leftBy,
    this.when = '',
    this.note,
    this.photo,
    this.photoUrl,
    this.found = false,
    this.handedOn = false,
    String? kind,
    this.date,
  }) : kind = kind ?? (found ? 'found' : (handedOn ? 'passedOn' : 'left'));

  final String city;
  final String? place;
  final double latitude;
  final double longitude;
  final String? leftBy;
  final String when;
  final String? note;

  /// The traveler's photo. Waits for The Herd's quick look before others see it.
  final Uint8List? photo;

  /// An approved photo on The Herd's website (live data only).
  final String? photoUrl;

  /// made, found, passedOn or left (as on the website).
  final String kind;

  /// When it happened, if known (live data).
  final DateTime? date;

  /// True for "Found by …" stops.
  final bool found;

  /// True when they were handed to someone ("Passed on by …"); false when left somewhere ("Left by …").
  final bool handedOn;

  /// "Found by Sam", "Passed on by Sam" or "Left by Sam".
  String? get byLine => leftBy == null
      ? null
      : found
      ? 'Found by $leftBy'
      : handedOn
      ? 'Passed on by $leftBy'
      : 'Left by $leftBy';

  LatLng get point => LatLng(latitude, longitude);

  /// The same stop with the traveler's just-taken photo (shown on this phone until it's approved).
  Stop withPhoto(Uint8List? bytes) => Stop(
    city: city,
    place: place,
    latitude: latitude,
    longitude: longitude,
    leftBy: leftBy,
    when: when,
    note: note,
    photo: bytes,
    photoUrl: photoUrl,
    found: found,
    handedOn: handedOn,
    kind: kind,
    date: date,
  );
}

enum CompanionStatus {
  moving('On the move'),
  waiting('Waiting to be found'),
  quiet('Quiet lately'),
  adopted('Adopted'),
  retired('Retired');

  const CompanionStatus(this.label);
  final String label;
}

class Companion {
  Companion({
    required this.number,
    this.name,
    required this.glaze,
    required this.accent,
    required this.blob,
    this.isOriginal = false,
    this.status = CompanionStatus.moving,
    required this.wish,
    this.wishGranted = false,
    required this.lastMoved,
    this.movedThisWeek = false,
    required this.stops,
    required this.travelers,
  });

  final String number;
  String? name; // written by The Herd; shown as "#07" until set
  final String glaze;
  final String accent;
  final String blob;
  final bool isOriginal;
  CompanionStatus status;
  String wish; // "see the ocean"
  bool wishGranted;
  String lastMoved;
  bool movedThisWeek;
  final List<Stop> stops;
  int travelers;
  String blurb = 'A short blurb about this Companion, written by The Herd.';
  String originStory = 'Their origin story, written by The Herd.';

  String get displayName => name ?? '#$number';
  String get label => name == null ? '#$number' : '#$number · $name';
  Color get glazeColor => hex(glaze);
  Color get accentColor => hex(accent);
  Color get blobColor => hex(blob);
  Stop? get current => stops.isEmpty ? null : stops.last;
  String get wishSentence => 'I want to $wish.';
  Uri get shareUrl => Uri.parse('https://companions.theherdstudio.com/#/c/$number');

  /// The first entry is the studio in Aurora, so it isn't counted as a stop.
  int get stopCount => math.max(stops.length - 1, 0);

  int get miles {
    const distance = Distance();
    double meters = 0;
    for (var i = 1; i < stops.length; i++) {
      meters += distance(stops[i - 1].point, stops[i].point);
    }
    return (meters / 1609.34).round();
  }
}

/// Filters on the map, with the same colours as the website map.
enum MapFilter {
  all('All', 'FDF8F3', '3F5A4C', null),
  following('Following', 'FDF8F3', '3F5A4C', null),
  nearMe('Near me', 'FDF8F3', '3F5A4C', null),
  originals('Originals #0–5', 'FBE4E2', '6B3F3A', 'D98C86'),
  movedThisWeek('Moved this week', 'DDF0E8', '2F4A3D', '6BBFA3'),
  waiting('Waiting to be found', 'DCEAF5', '2D4A63', '6A9BC3'),
  quiet('Quiet lately', 'EDE6DC', '4A4440', 'A69C90'),
  adopted('Adopted', 'E6DDF5', '4A3D63', '9C86C9'),
  retired('Retired', 'F8DCC8', '6B4430', 'D08A5E'),
  wishesGranted('Wishes granted', 'F9EBB5', '5A4C1E', 'E0B94A');

  const MapFilter(this.label, this.background, this.foreground, this.dot);
  final String label;
  final String background;
  final String foreground;
  final String? dot;
}

class Stamp {
  const Stamp({
    required this.big,
    required this.small,
    required this.label,
    required this.background,
    required this.ring,
    required this.ink,
    required this.tilt,
    this.isEmpty = false,
  });

  final String big;
  final String small;
  final String label;
  final String background;
  final String ring;
  final String ink;
  final double tilt; // degrees
  final bool isEmpty;
}

/// Everywhere the app can navigate to.
sealed class AppRoute {
  const AppRoute();
}

class CompanionRoute extends AppRoute {
  const CompanionRoute(this.number, {this.showHello = false});
  final String number;
  final bool showHello;
}

class FoundRoute extends AppRoute {
  const FoundRoute(this.number);
  final String number;
}

class PassOnRoute extends AppRoute {
  const PassOnRoute(this.number);
  final String number;
}

class WishRoute extends AppRoute {
  const WishRoute(this.number);
  final String number;
}

class SentRoute extends AppRoute {
  const SentRoute(this.number);
  final String number;
}

class BrokeRoute extends AppRoute {
  const BrokeRoute(this.number);
  final String number;
}

class ChatRoute extends AppRoute {
  const ChatRoute(this.number);
  final String number;
}

class StoryRoute extends AppRoute {
  const StoryRoute(this.number);
  final String number;
}

class LearnRoute extends AppRoute {
  const LearnRoute();
}

class NotificationSettingsRoute extends AppRoute {
  const NotificationSettingsRoute();
}

class ActivityItem {
  ActivityItem({
    required this.title,
    required this.meta,
    required this.icon,
    required this.background,
    required this.foreground,
    this.route,
    required this.isToday,
  });

  final String title;
  final String meta;
  final IconData icon;
  final String background;
  final String foreground;
  final AppRoute? route;
  final bool isToday;
}

enum ChatKind { herd, traveler, me }

class ChatMessage {
  ChatMessage({required this.who, required this.text, required this.kind});
  final String who;
  final String text;
  final ChatKind kind;
}

enum CheckIn { appAlert, email, none }

class NotificationPrefs {
  bool carriedMoves = true;
  bool followedMoves = true;
  bool wishesGranted = true;
  bool chatReplies = true;
  bool newStamps = true;
  bool monthlyReminder = true;
  bool byEmail = false;
  bool quietHours = true;
}
