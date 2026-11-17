import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../theme.dart';

/// Free map tiles (CARTO Voyager, built on OpenStreetMap). Light and soft, to sit with The Herd's colours.
/// Before a big public launch, check CARTO's terms or switch to a free-tier provider with an account.
TileLayer herdTiles() => TileLayer(
      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      retinaMode: true,
      userAgentPackageName: 'com.theherdstudio.herd_around_the_world',
      maxZoom: 18,
    );

/// The map credit both map providers ask for. Tapping it opens OpenStreetMap's copyright page.
Widget herdAttribution({Alignment alignment = Alignment.bottomRight, EdgeInsets margin = EdgeInsets.zero}) => Align(
      alignment: alignment,
      child: Padding(
        padding: margin,
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Herd.cream.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(6)),
            child: Text('© OpenStreetMap contributors © CARTO', style: HerdText.body(10, color: Herd.body)),
          ),
        ),
      ),
    );

/// A dot for a Companion on the map.
class MapDot extends StatelessWidget {
  const MapDot({super.key, required this.color, this.size = 12, this.faded = false});
  final Color color;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: faded ? color.withValues(alpha: 0.6) : color,
          shape: BoxShape.circle,
          border: Border.all(color: Herd.cream, width: 2),
          boxShadow: [BoxShadow(color: Herd.ink.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(0, 1))],
        ),
      );
}

/// The dotted line of a Companion's journey.
Polyline journeyLine(Companion c) => Polyline(
      points: [for (final s in c.stops) s.point],
      color: c.accentColor,
      strokeWidth: 3,
      pattern: const StrokePattern.dotted(spacingFactor: 2.2),
    );

/// A small, still map of one Companion's journey.
class JourneyMap extends StatelessWidget {
  const JourneyMap({super.key, required this.companion, this.height = 190});
  final Companion companion;
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = [for (final s in companion.stops) s.point];
    final single = points.length < 2;
    return Semantics(
      label: 'Map of #${companion.number}’s journey, now in ${companion.current?.city ?? ''}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: points.isEmpty ? const LatLng(30, -40) : points.last,
              initialZoom: single ? 6 : 3,
              initialCameraFit: single ? null : CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(28)),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              herdTiles(),
              PolylineLayer(polylines: [journeyLine(companion)]),
              MarkerLayer(markers: [
                for (var i = 0; i < companion.stops.length; i++)
                  Marker(
                    point: companion.stops[i].point,
                    width: i == companion.stops.length - 1 ? 18 : 10,
                    height: i == companion.stops.length - 1 ? 18 : 10,
                    child: MapDot(color: companion.accentColor, size: i == companion.stops.length - 1 ? 18 : 10, faded: i != companion.stops.length - 1),
                  ),
              ]),
              herdAttribution(),
            ],
          ),
        ),
      ),
    );
  }
}
