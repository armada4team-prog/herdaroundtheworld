# Herd Around the World

The iPhone app for **The Herd’s Companions**: tiny handmade clay travelers that people find, carry,
and pass on. Each Companion has a number and a QR code on their bottom. Scan one to see their story,
where they’ve been, and their wish.

This is the **testing version**, built from the Page 4 designs. Nothing is for sale: passing a
Companion on and granting a wish earn stamps in your Passport.

## What’s in the app

| Tab | What it does |
|---|---|
| **The Herd** | Greeting, your numbers, Companions you follow, the Originals, latest sightings, Instagram |
| **Map** | Every Companion as a dot on a world map. Filters (Originals, Moved this week, Waiting to be found, Quiet lately, Adopted, Retired, Wishes granted), tap a dot to zoom to their journey, and the Most active top 10 |
| **Scan** | Point the camera at the code on a Companion’s bottom, or type their number |
| **Passport** | Your travels, stamps and herd, with optional email sign-in |
| **Activity** | News about your Companions, the one-month reminder, and notification settings |

Plus each Companion’s page (with the hello card a finder sees after scanning), *I found them*,
*Pass them on*, *Wish granted*, the postcard screen, *Something happened*, the traveler chat,
their story, *How it works*, and the language picker.

## Open it on a Mac

You need a Mac with **Xcode 16** (free from the Mac App Store).

1. Install XcodeGen (it builds the Xcode project from `project.yml`):
   ```bash
   brew install xcodegen
   ```
2. In this folder, generate the project:
   ```bash
   xcodegen generate
   ```
3. Open it:
   ```bash
   open HerdAroundTheWorld.xcodeproj
   ```
4. Pick an iPhone simulator at the top of Xcode and press **Run** (▶).

To run it on your own iPhone, select the **HerdAroundTheWorld** target → **Signing & Capabilities**
→ choose your Apple ID team. The camera scanner only works on a real iPhone (the simulator shows
the “type their number” option instead).

Every push to `main` is also built automatically on GitHub (see the **Actions** tab).

## How it’s organised

```
HerdAroundTheWorld/
  App/          App entry, tabs, navigation, app state (AppModel), location helper
  Models/       Companion, Stop, Stamp, map filters… and SampleData (52 Companions)
  Theme/        The Herd’s colours, fonts and button styles
  Components/   The Companion figure, blobs, stamps, chips, cards
  Views/        One file per screen
  Resources/    Fonts and the asset catalog (app icon, colours)
```

## Test data vs. real data

Right now the app runs on **sample data** (the journeys from the designs) and keeps anything you do
in memory until the app closes. That’s enough to try every screen and show people the idea.

To make it live, everything goes through `AppModel`: replace `SampleData.companions` with data
loaded from The Herd’s database, and send `logFind`, `passOn`, `setNextWish`, `sendChat` and
`reportBroken` to it. The website and the app should share that one database so they stay in sync.
Good options are Wix’s own database (the site already runs on Wix) or Firebase.

Still to connect for a live launch: the real database, email sign-in links, push notifications,
photo upload with location data removed, and review/approval of photos and custom wishes.

## Scanning a Companion

Each Companion’s QR code should point to `https://theherdstudio.com/c/<number>` (for example
`/c/07`). The website opens for anyone with a phone camera. The app reads the same codes, and it
can open those links directly once Universal Links are set up for theherdstudio.com.

## Fonts

Fira Sans, Baloo 2 and Shadows Into Light Two, all under the SIL Open Font License
(see `Licenses/`).
