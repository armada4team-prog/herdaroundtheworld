import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../services.dart';
import '../theme.dart';
import 'pieces.dart';

/// "Where are you?" for finding and passing on a Companion. It uses the phone's location (city
/// level) instead of a typed place, so a Companion can only be logged where the traveler really is.
class HereCard extends StatefulWidget {
  const HereCard({super.key, required this.onChanged, this.errorText});

  /// Called with the city once it's found (or null while finding / if it can't be found).
  final ValueChanged<HerePlace?> onChanged;
  final String? errorText;

  @override
  State<HereCard> createState() => _HereCardState();
}

class _HereCardState extends State<HereCard> {
  HerePlace? here;
  HereProblem? problem;
  bool locating = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => locate());
  }

  Future<void> locate() async {
    setState(() {
      locating = true;
      problem = null;
    });
    widget.onChanged(null);
    final result = await Services.whereAmI();
    if (!mounted) return;
    setState(() {
      locating = false;
      here = result.place;
      problem = result.problem;
    });
    widget.onChanged(result.place);
  }

  String get problemText => switch (problem) {
    HereProblem.off => 'Location is turned off. Turn it on so we can log where you are.',
    HereProblem.notAllowed => 'Please allow location so we can log where you are. We only use your city.',
    HereProblem.blocked => 'Location is blocked for this app. Open Settings and allow location.',
    HereProblem.faked => 'Your location looks like it’s coming from a location-changing app. Please turn it off and try again.',
    _ => 'We couldn’t find where you are. Check your signal and try again.',
  };

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null ? Herd.error : Colors.transparent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.errorText != null ? Herd.errorField : Herd.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: locating
              ? Row(
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Herd.sageDark)),
                    const SizedBox(width: 12),
                    Text(tr('Finding where you are…'), style: HerdText.body(16, color: Herd.ink)),
                  ],
                )
              : here != null
              ? Row(
                  children: [
                    const Icon(Icons.place, color: Herd.sageDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        label: tr('You’re in {0}').replaceAll('{0}', here!.city),
                        excludeSemantics: true,
                        child: Text(here!.city, style: HerdText.chunky(18, extraBold: false, color: Herd.sageDark)),
                      ),
                    ),
                    TextButton(
                      onPressed: locate,
                      child: Text(tr('Refresh'), style: HerdText.body(14, color: Herd.sageDark)),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(tr(problemText), style: HerdText.body(15, color: Herd.ink)),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        softChip('Try again', Icons.refresh, locate),
                        if (problem == HereProblem.off)
                          softChip('Location settings', Icons.settings_outlined, Geolocator.openLocationSettings),
                        if (problem == HereProblem.blocked) softChip('App settings', Icons.settings_outlined, Geolocator.openAppSettings),
                      ],
                    ),
                  ],
                ),
        ),
        Text(
          tr('We use your phone’s location so travelers know where to look. A street address is never shown.'),
          style: HerdText.body(13),
        ),
        if (widget.errorText != null) ErrorNote(widget.errorText!),
      ],
    );
  }
}
