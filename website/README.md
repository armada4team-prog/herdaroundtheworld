# Herd Around the World: the website

The Companions website for The Herd: the world map, each Companion's page, "I found them",
"Pass them on", wishes, the traveler chat, Companions in Your Care and the Passport. It looks like
the Page 3 designs and follows the same rules as the Herd Around the World app. Nothing is for sale.

**It is not online yet.** Nothing here has been published, and the site reads and writes nothing
until the checker (the Cloudflare Worker in `worker/`, see `worker/README.md`) is running and its
address is set in `js/data.js` (`CHECKER`).

The plan is a standalone site at `https://companions.theherdstudio.com` (GitHub Pages publishes
`website/`). QR codes point to `https://companions.theherdstudio.com/c/<number>?k=<code>` and share
links to `https://companions.theherdstudio.com/#/c/<number>`.

## Embedding in the Wix site (no longer the plan)

The Herd's site uses the Wix Harmony editor, so this was set aside, but the element still builds.
The website can live inside theherdstudio.com, under Wix's own header and footer, as a Wix
**Custom Element**:

1. In the Wix editor, add a page called **Herd Around the World** (page address
   `herd-around-the-world`).
2. Add → Embed Code → **Custom Element**. Stretch it to the full width of the page.
3. Choose **Server URL** and enter
   `https://armada4team-prog.github.io/herdaroundtheworld/herd-around-the-world.js`
4. **Tag Name**: `herd-around-the-world`
5. Menu links (Site Menu → Add a link → Web address, open in the same window):
   - Herd Around the World: `https://www.theherdstudio.com/herd-around-the-world`
   - Map: `https://www.theherdstudio.com/herd-around-the-world#/map`
   - Found a Companion: `https://www.theherdstudio.com/herd-around-the-world#/found`
   - Companions in Your Care: `https://www.theherdstudio.com/herd-around-the-world#/care`
   - Passport: `https://www.theherdstudio.com/herd-around-the-world#/passport`
6. Publish the Wix site. The element grows with its page, so give it no fixed height.

The element is the same website in one file: `node website/tools/build-element.mjs` makes
`website/dist/herd-around-the-world.js` (all the JavaScript, the shared rules and the CSS; esbuild
is pinned in the script). The GitHub Pages workflow builds it and publishes it at the site's root,
next to the data files it reads (`data/sample.json`, `data/world-land.json`). Inside Wix it draws in
its own shadow root, so Wix's styles and the site's don't mix; the fonts are added to the page head
and the map library is loaded from cdnjs.

## Try it on your computer (preview)

From the repository folder (the one with `website/` and `shared/` in it):

```sh
python3 -m http.server 8000
```

Then open <http://localhost:8000/website/index.html?preview=1>.

Preview mode uses the 52 sample Companions from the app and keeps everything you do in this
browser only (a yellow bar says "Preview: nothing is saved yet"; "Start over" clears it). In
preview, the "Where are you?" box also offers test spots (Aurora, Denver and Boulder, CO), so the
5-mile rule can be tried from a computer. Sample find codes: #07 = `KCVT`, #3 = `MHE6`, #12 = `TH3M`.
Try a QR link like <http://localhost:8000/website/index.html?preview=1#/c/07?k=KCVT>.

Without `?preview=1` the site uses the live Wix data only when it can read the lists *and* The
Herd's checker answers (`herdMine`); otherwise (for example before the Worker is set up) it
falls back to preview by itself, so it never sends finds to a checker that isn't there yet.

## Pages

`#/` home · `#/map` · `#/found` (Found a Companion: number + find code) · `#/care` · `#/passport` ·
`#/c/07` (a Companion) · `#/c/07/found` · `#/c/07/pass-on` · `#/c/07/wish` · `#/c/07/sent` ·
`#/c/07/something-happened` · `#/c/07/chat` · `#/c/07/story`.

QR codes are `/c/07?k=CODE`; on a static host `404.html` sends them to `index.html#/c/07?k=CODE`.
The query form `…?c=07&k=CODE` still works too: the site turns it into `#/c/07?k=CODE`.

## How it connects to Wix

All of this is in `js/data.js`.

- **Reading**: a Wix Headless visitor token (client ID `492b0619-…`), then the CMS lists
  `Companions`, `CompanionStops` and `CompanionChat`. Only photos marked `photoApproved` are shown,
  and chat messages marked `hidden` never are.
- **Writing**: every find, pass-on, wish, chat message and report goes to The Herd's checker, a
  Cloudflare Worker (`CHECKER` in `js/data.js`, e.g. `https://herd-checker.<subdomain>.workers.dev/herdFind`,
  `herdPassOn`, `herdWish`, `herdChat`, `herdReport`; see `worker/` and
  `wix/backend/handlers.src.js`). It saves to the same Wix lists. The checker has the final say, and
  the field it names is marked in red on the form. Find codes never leave Wix and the Worker.
- What you hold (and the wish you get to choose) is remembered in this browser, which is how
  Companions in Your Care and the Passport work.

The word filter, the 988 note and the wish check come from `shared/rules.js`, the same file the Wix
checker is built from. Keep `shared/` next to `website/` when hosting (or copy it there).

## Optional sign-in

Everything works without signing in. "Sign up or sign in" (header, Companions in Your Care, and the
Passport's "Keep your stamps safe" card) emails a 6-digit code (`herdSignInStart` /
`herdSignInVerify`); the first code creates the account. Signed in, the Passport, Companions in Your
Care, follows and nickname follow the traveler to every device (`herdMine`, `herdFollow`), and finds
and pass-ons carry the session. Companions found before signing in come along. Signing out or
"Delete my data" (`herdSignOut`, `herdForgetMe`) goes back to this browser only. In preview, no email
is sent: the code is shown on screen, with the same rules (one code a minute, 5 tries, 15 minutes).
Until The Herd sets up the sign-in email in Wix, the sheet says "Email sign-in isn’t switched on yet".

## Languages

English, Spanish, French and Japanese. Most text comes from the app (`lib/translations.dart`);
after changing it, run `node website/tools/build-translations.mjs`. Website-only text is in
`js/translations-web.js`. Travelers' chapters and chat messages are never translated.

## Tests

```sh
node --test website/test/*.test.mjs
```

Walks find → leave → find → hand on in preview mode (wrong and right codes, the 5-mile rule, the
fix list, the word filter, the 988 note and the 10-minute pause after 5 wrong codes).
Needs Node 18+ and Playwright with Chromium.

## Other files

- `data/sample.json`: the preview data (`node website/tools/build-sample.mjs path/to/sample.json`).
- Map: Leaflet 1.9.4 with OpenStreetMap tiles. For a big launch, move to a tile provider with an
  account, as OpenStreetMap asks.
