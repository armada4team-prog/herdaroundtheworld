# Herd Around the World: handoff for the next agent

Read this first. It covers what exists, how the parts talk to each other, how to build, test and
ship each part, the owner's preferences, and what's still open.

**This repository is public.** Never commit secrets, the owner's email address or personal name,
or the Companions' real find codes. Real find codes live only in the Wix list
`CompanionFindCodes` (private).

---

## 1. What the project is

The Herd is a small handmade-ceramics studio in Aurora, Colorado (theherdstudio.com).
**Herd Around the World** is its community art project. Little clay **Companions** (each with a
number, a name, a wish, a blurb and an origin story) are left in public places. Whoever finds one
scans the QR code on its bottom, logs the find, carries it a while, then hands it on or leaves it
somewhere, adding a photo and a chapter to its story. Everyone can follow each Companion's journey
on a map.

There are **six real Companions, #0 to #5** (Stella, Wynter, Nimbus, Angel, Sprout, Bubba). All are
currently **waiting to be found** at the studio, with zero stops: the owner reset them after testing.

## 2. The parts and how they connect

```
 QR label ──► companions.theherdstudio.com/c/<n>?k=<code>
                     │
        ┌────────────┴─────────────┐
   Website (static JS)       Flutter app (Android, iPhone)
        │  reads lists              │  reads lists
        ├──── Wix Headless (visitor token, read-only) ────┐
        │  writes                   │  writes             │
        └────► Checker (Cloudflare Worker) ◄──────────────┘
                     │  Wix REST API with an API key
                     ▼
             Wix CMS lists on The Herd's Wix site
```

| Part | Where | Hosted | Deploys |
|---|---|---|---|
| Website | `website/` (+ `shared/rules.js`) | GitHub Pages at **companions.theherdstudio.com** (custom domain; CNAME in Wix DNS) | `.github/workflows/website.yml` on push to `main` |
| App | `lib/`, `android/`, `ios/`, `web/` (Flutter 3.50 / Dart 3.14, `material_ui`) | Android test build on GitHub Releases (`test-build`); Google Play pending | `.github/workflows/android.yml` (and `ios.yml` = build check only) |
| Checker | `wix/backend/handlers.src.js` + `shared/rules.js`, wrapped by `worker/` | Cloudflare Worker **herd-checker.growtheherd.workers.dev** | `.github/workflows/checker.yml` on push (tests, then `wrangler deploy`) |
| Data | Wix CMS on The Herd's Wix site (Wix **Harmony** editor, published) | Wix | Edited in the Wix dashboard or via the Wix MCP tools |

Why a Cloudflare Worker: the Wix Harmony editor can't run custom code (no Velo), so the checker that
used to be Velo `http-functions.js` runs on Cloudflare and talks to Wix over REST. The Velo file
(`wix/backend/http-functions.js`) is still generated and tested because the Worker is built from it.

## 3. The Wix CMS lists

| List | Public? | What |
|---|---|---|
| `Companions` | yes | number, name, status (waiting / moving / adopted / retired), wish, wishGranted, blurb, originStory, glaze/accent/blob colors, isOriginal, profilePhoto (optional; shown instead of the drawing) |
| `CompanionStops` | yes | companionNumber, kind (made / found / passedOn / left), city, latitude, longitude, byName, chapter, place (hint), photo, wishPhoto, **photoApproved** (photos hidden until true), approveToken, ownerNotifiedAt |
| `CompanionChat` | yes | companionNumber, author, message, hidden |
| `CompanionReports` | owner only | broke / chipped / lost / adopted / **flagged** (Report button), with note, email, flaggedId |
| `CompanionFindCodes` | owner only | the secret 4-letter code per Companion |
| `CompanionHolds` | owner only | who holds each Companion now: token, travelerId, exact foundLatitude/Longitude, nudgedAt, adoptedAt |
| `CompanionTravelers` | owner only | optional sign-in: email, hashed sessions, following, nickname |
| `CompanionSettings` | owner only | `signInEmailId` ("on" = emails on), `ownerEmail` (daily digest), `nudgeDays` (60), optional `nudges` = off |

Wix site ID: `84ee9f27-4b02-43aa-929d-1b05a51923a2`. Headless OAuth client ID is in `website/js/data.js`.
The Wix MCP tools (`CallWixSiteAPI` against `https://www.wixapis.com/wix-data/v2/items/...`) work
from a session for reading and fixing data. Confirm with the owner before changing data.

## 4. The checker (Cloudflare Worker)

Endpoints (POST, JSON body as text/plain): `herdFind`, `herdPassOn`, `herdWish`, `herdChat`,
`herdReport`, `herdFlag`, `herdSignInStart`, `herdSignInVerify`, `herdMine`, `herdFollow`,
`herdSignOut`, `herdForgetMe`. GET links from emails: `herdApprove?t=` (approve a photo),
`herdAdopted?t=` ("They're staying with me").

Rules: right find code; 5-mile rule only when *leaving* (not handing on); hint and photo required
when leaving; word filter; phone, email and address hiding; self-harm message points to 988.

**Location:** `blur(value, exact)` in `shared/rules.js`. Exact = 5 decimals; otherwise a 0.05° grid
(always within about 2.2 miles). Finds, hand-offs and leaves are **exact by default**; travelers can
switch to "general area" (`exactSpot: false`). The exact spot is also kept privately in the hold.

**Daily cron** (17:23 UTC, `worker/wrangler.toml`): `worker/src/nudge.js` (one reminder email after
`nudgeDays` to signed-in holders) and `worker/src/digest.js` (owner email: new photos with one-tap
Approve, new reports). Email goes out via Wix Email Transmissions (`worker/src/email.js`).

Secrets: `WIX_API_KEY` lives on the Worker in Cloudflare. GitHub repository secrets:
`CLOUDFLARE_API_TOKEN` (1 year, deploys the Worker), `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD` (Google Play upload key, alias `upload`). The owner holds the keystore
files; the session can't read or set GitHub secrets.

## 5. Building and testing

```bash
flutter analyze && flutter test                  # app (30 tests)
node wix/test/backend.test.mjs                   # checker logic (Velo version)
node worker/test/worker.test.mjs                 # Worker against a pretend Wix REST API
for t in website/test/*.mjs; do node $t; done    # website
python3 tool/build_wix_backend.py                # rebuild wix/backend/http-functions.js after editing handlers or rules
node website/tools/build-translations.mjs        # after editing lib/translations.dart
```

- **Translations:** English is in the code. Spanish, French and Japanese are in `lib/translations.dart`
  (app; it also generates `website/js/translations.js`) and `website/js/translations-web.js`
  (website only). Patterns use `{0}`, `{1}`. New user-facing text needs all three languages.
- **Sample vs live:** the app and website use bundled sample data when the checker can't be reached
  (preview banner on the website). Sample data has fake Companions (#07 etc.); never show it as real.
- **Screenshots of the app:** `flutter build web --release --no-web-resources-cdn` then `?screen=home`
  (also map, companion, hello, story, passport, found, passon, chat…). Add
  `--dart-define=STORE_SHOTS=true` to show the six real Companions as a new traveler sees them (all
  zeros). That's how the Google Play screenshots in `docs/play/` were made. Map tiles don't load in
  the sandbox.
- **Website locally:** `python3 -m http.server` at the repo root, then `/website/index.html?preview=1`.
- **Network in the sandbox:** wixapis.com, workers.dev, github.io and theherdstudio.com are blocked
  for curl. Use the Wix MCP tools for data, and the owner's screenshots or browser for live pages.
  GitHub works through `gh api` (REST only; GraphQL and Actions secrets are blocked).

## 6. Shipping

- **Website:** push to `main`, and Pages deploys in about 30 seconds. Browsers cache for up to 10 minutes.
- **Checker:** push to `main` touching `worker/`, `shared/`, `wix/backend/handlers.src.js`, and it deploys itself.
  For a one-off schedule test, temporarily add a cron in `wrangler.toml` and revert.
- **Android:** every push builds `herd-around-the-world.apk` and the signed `herd-around-the-world.aab`
  (version code = run number) on the `test-build` release. Phones with an older debug-signed install
  must uninstall before installing the new key-signed build.
- **Google Play:** a developer account ("The Herd Studio", personal) was created; identity verification
  is pending. Everything to paste is in `docs/google-play.md`; graphics are in `docs/play/`. Then:
  closed testing with 12+ testers for 14 days, then production. Target audience 13+ (not Families).
- **iPhone:** not published (Apple charges $99/year; the owner hasn't decided). Icons and the
  location text are ready.

## 7. The owner's preferences (important)

- **No spending without asking first.** Free options preferred. They chose to pay Google Play's one-time $25.
- **Never ask for or accept passwords.** Credentials go through the secure credential form or GitHub's
  secrets page, never into chat. If a token is pasted into chat, tell them to delete it afterwards.
- **Don't publish or change existing Wix pages** without being asked (only add menu items or new pages).
- **Don't change their wording without asking.** Suggest instead. Keep "1 stops" and "1 travelers"
  as they are (the numbers will grow).
- Real Companions have **no faces**, so copy must never mention smiles. The drawn icons with smiles
  are fine and liked. The **app icon** is the pin with a faceless Companion in The Herd's colors.
- They work from screenshots and aren't technical. Give short, plain, numbered steps naming the exact
  buttons, and say when something costs money or is optional.
- Design: header and footer match theherdstudio.com (logo from their SVGs, DM Sans nav, Kanit links,
  upright Playwrite AU QLD script); page tops are cream; colors: mint `#DDF0E8`/`#A8DCC9`,
  sage `#5B7869`, ink `#3F5A4C`, pink `#E07A93`, butter `#F9EBB5`, Herd beige `#F7F0E8`.
- Before telling the owner something is done, check it (screenshots, tests, or reading the data).

## 8. Open items

1. Google Play: finish once identity is verified (see section 6). Help with each Play Console screen.
2. theherdstudio.com dropped out of Google's index (new site). If still missing after about a week:
   Search Console → URL Inspection → Request indexing. The Google Business Profile is awaiting verification.
3. Optional: show approved traveler photos in the "Companions on Instagram" spot (the owner chose
   to keep just the Follow link for now).
4. Optional: decide whether to publish on the Apple App Store.
5. Test photos from the owner's trial run are still in the Wix Media Manager folder
   "Herd Around the World" (unused, safe to delete if asked).
