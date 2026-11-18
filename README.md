# Herd Around the World

The phone app for **The Herd’s Companions**: tiny handmade clay travelers that people find, carry,
and pass on. Each Companion has a number and a QR code on their bottom. Scan one to see their story,
where they’ve been, and their wish.

Built with **Flutter**, so the same app runs on **Android and iPhone**.

This is the **testing version**, built from the Page 4 designs. Nothing is for sale: passing a
Companion on and granting a wish earn stamps in your Passport.

## Try it on an Android phone

Every change is built automatically on GitHub. On your Android phone:

1. Open **[Releases → Test build](https://github.com/armada4team-prog/herdaroundtheworld/releases/tag/test-build)**.
2. Tap **herd-around-the-world.apk** to download it.
3. Open the download. If your phone asks, allow installs from your browser or Files app.

Direct download link:
`https://github.com/armada4team-prog/herdaroundtheworld/releases/download/test-build/herd-around-the-world.apk`

To update, download and open the newest file the same way. Your phone keeps the app and replaces it.

## What’s in the app

| Tab | What it does |
|---|---|
| **The Herd** | Greeting, your numbers, Companions you follow, the Originals, latest sightings, Instagram |
| **Map** | Every Companion as a dot on a world map, with filters (Originals, Moved this week, Waiting to be found, Quiet lately, Adopted, Retired, Wishes granted). Tap a dot to zoom to their journey. Most active top 10 |
| **Scan** | Point the camera at the code on a Companion’s bottom, or type their number |
| **Passport** | Your travels, stamps and herd, with optional email sign-in |
| **Activity** | News about your Companions, the one-month reminder, and notification settings |

Plus each Companion’s page (with the hello card a finder sees after scanning), *I found them*,
*Pass them on*, *Wish granted*, the postcard screen, *Something happened*, the traveler chat,
their story, *How it works*, and the language picker.

## For developers

You need [Flutter](https://docs.flutter.dev/get-started/install) 3.50.

```bash
flutter pub get
flutter run            # on a connected phone or emulator
flutter test           # unit and widget tests
flutter build apk      # Android app
```

The iPhone version needs a Mac with Xcode: `flutter build ios`.

```
lib/
  main.dart          App start, the five tabs, routes
  app_state.dart     App state (AppModel) and navigation (AppRouter)
  models.dart        Companion, Stop, Stamp, map filters…
  sample_data.dart   52 sample Companions with real city coordinates
  services.dart      Location, photos, links
  theme.dart         The Herd’s colours, fonts and buttons
  widgets/           The Companion figure, blobs, stamps, maps, shared pieces
  screens/           One file per screen
assets/              Fonts and the app icon
```

GitHub Actions builds the Android app (and publishes it to the Test build release) and checks
that the iPhone version compiles, on every push to `main`.

The earlier iPhone-only SwiftUI version is kept on the `swiftui-version` branch.

## Test data vs. real data

Right now the app runs on **sample data** (the journeys from the designs) and keeps anything you
do in memory until the app closes. That’s enough to try every screen and show people the idea.

To make it live, everything goes through `AppModel`: replace `sampleCompanions()` with data loaded
from The Herd’s database, and send `logFind`, `passOn`, `setNextWish`, `sendChat` and
`reportBroken` to it. The website and the app should share that one database so they stay in sync.

## Maps

The maps use OpenStreetMap’s free tiles (credited on the map), with no account or key needed.
That’s fine for testing. OpenStreetMap’s servers are meant for light use, so before a big public
launch switch to a tile provider with a free account tier (for example MapTiler or Stadia Maps).

## Scanning a Companion

Each Companion’s QR code should point to `https://theherdstudio.com/c/<number>` (for example
`/c/07`). The website opens for anyone with a phone camera, and the app reads the same codes.

## Fonts

Fira Sans, Baloo 2 and Shadows Into Light Two, all under the SIL Open Font License
(see `Licenses/`).
