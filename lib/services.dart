import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Location, photos and links, working the same way on Android and iPhone.
class Services {
  /// "Use my city": asks once for location, then turns it into a city name only (never a street address).
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
      final city = <String?>[p.locality, p.subAdministrativeArea, p.name].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => '') ?? '';
      final region = p.isoCountryCode == 'US' ? (p.administrativeArea ?? '') : (p.country ?? '');
      return [city, region].where((s) => s.isNotEmpty).join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Finds the map position of a typed city ("Boulder, CO"), so the dot lands in the right place.
  static Future<LatLng?> pointFor(String city) async {
    if (kIsWeb || city.trim().isEmpty) return null;
    try {
      final found = await Geocoding().locationFromAddress(city);
      if (found.isEmpty) return null;
      return LatLng(found.first.latitude, found.first.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Picks a photo from the phone's library.
  static Future<Uint8List?> pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      return file == null ? null : await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
