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

The app shares The Herd's Wix site with the website (`lib/wix_api.dart`, the same calls as
`website/js/data.js`). When it opens, it asks The Herd's checker (`herdMine`) whether it's there:

- **LIVE** (the checker answers): Companions, stops and chat come from the Wix CMS lists, every
  find, pass-on, wish, chat message and report goes to the checker, and find codes are checked
  there. A copy of the lists is kept on the phone for when it's offline.
- **SAMPLE** (the Wix site isn't published yet, or no internet on a first launch): the sample
  journeys from the designs, with the same rules checked in the app. The Passport says
  "Preview: using sample Companions".

Either way, what's yours (nickname, follows, the Companions in your care, your Passport, your
optional sign-in) is saved on the phone, so nothing resets when the app closes.

## Maps

The maps use OpenStreetMap’s free tiles (credited on the map), with no account or key needed.
That’s fine for testing. OpenStreetMap’s servers are meant for light use, so before a big public
launch switch to a tile provider with a free account tier (for example MapTiler or Stadia Maps).

## Scanning a Companion

Each Companion’s QR code points to the Herd Around the World page on The Herd’s Wix site:
`https://www.theherdstudio.com/herd-around-the-world?c=<number>&k=<code>` (for example
`?c=07&k=KCVT`). It opens for anyone with a phone camera, and the app reads the same codes (older
`/c/07?k=KCVT` codes still work). Share links are `https://www.theherdstudio.com/herd-around-the-world#/c/<number>`.

## Fonts

Fira Sans, Baloo 2 and Shadows Into Light Two, all under the SIL Open Font License
(see `Licenses/`).

## Find codes (stops fake finds)

Logging a find needs the Companion's secret 4-letter code. It's hidden in the QR code on their
bottom (`https://www.theherdstudio.com/herd-around-the-world?c=07&k=KCVT`) and printed small under their number, for when the
camera won't scan. Typing a number alone only shows the Companion's page.

List every code and QR address for printing labels (keep this list private):

```bash
dart run tool/print_codes.dart 52
```

In SAMPLE mode the codes are worked out inside the app. In LIVE mode they're checked by The
Herd's checker on the Wix site, so nobody can dig them out of the app.
