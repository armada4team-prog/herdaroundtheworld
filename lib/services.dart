import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n.dart';
import 'theme.dart';

/// Location, photos and links, working the same way on Android and iPhone.
class Services {
  /// "Use my city": asks once for location, then turns it into a city name only (never a street address).
  /// Where the phone is, roughly (city level). Null if location is off or not allowed.
  static Future<LatLng?> currentPoint() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> currentCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
      if (kIsWeb) return null;
      final places = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isEmpty) return null;
      final p = places.first;
      final city =
          <String?>[p.locality, p.subAdministrativeArea, p.name].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => '') ?? '';
      final region = p.isoCountryCode == 'US' ? (p.administrativeArea ?? '') : (p.country ?? '');
      return [city, region].where((s) => s.isNotEmpty).join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Looks up a typed place ("Boulder, CO") on the phone's map service: confirms it's a real place
  /// and finds where to put its dot. If the phone can't check right now (no internet), it says so
  /// rather than blocking the traveler.
  static Future<PlaceLookup> lookUpPlace(String place) async {
    if (kIsWeb || place.trim().isEmpty) return const PlaceLookup(PlaceStatus.unavailable);
    try {
      final found = await Geocoding().locationFromAddress(place).timeout(const Duration(seconds: 8));
      if (found.isEmpty) return const PlaceLookup(PlaceStatus.notFound);
      return PlaceLookup(PlaceStatus.found, LatLng(found.first.latitude, found.first.longitude));
    } on PlatformException catch (e) {
      final text = '${e.code} ${e.message}'.toLowerCase();
      final notFound = text.contains('not_found') || text.contains('not found') || text.contains('no result') || text.contains('no_result');
      return PlaceLookup(notFound ? PlaceStatus.notFound : PlaceStatus.unavailable);
    } catch (e) {
      final text = e.toString().toLowerCase();
      return PlaceLookup(text.contains('noresult') || text.contains('no result') ? PlaceStatus.notFound : PlaceStatus.unavailable);
    }
  }

  /// Picks a photo from the phone's library.
  /// Asks "Take a photo" or "Choose from your photos", then gets the photo.
  static Future<Uint8List?> choosePhoto(BuildContext context) async {
    final canUseCamera = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    if (!canUseCamera) return pickPhoto();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Herd.cream,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: Herd.sageDark),
              title: Text(tr('Take a photo'), style: HerdText.body(16, color: Herd.ink)),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Herd.sageDark),
              title: Text(tr('Choose from your photos'), style: HerdText.body(16, color: Herd.ink)),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    return source == null ? null : pickPhoto(source: source);
  }

  /// Gets a photo, shrunk and re-saved (which also drops the hidden location data).
  static Future<Uint8List?> pickPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return null;
      return await withoutHiddenData(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  /// Redraws a photo into a fresh picture, so none of the hidden data inside the original
  /// (GPS location, phone model, date) comes along.
  static Future<Uint8List?> withoutHiddenData(Uint8List original) async {
    try {
      final codec = await ui.instantiateImageCodec(original, targetWidth: 1200);
      final frame = await codec.getNextFrame();
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      return png?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<void> open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

enum PlaceStatus { found, notFound, unavailable }

class PlaceLookup {
  const PlaceLookup(this.status, [this.point]);
  final PlaceStatus status;
  final LatLng? point;
}
