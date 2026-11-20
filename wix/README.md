# The Herd's Wix site: the Companions checker

The website and the app send every find, pass-on, wish, chat message and report to a small
piece of code on The Herd's Wix site. It checks the rules (find code, found → left order,
5 miles to leave one somewhere, word filter, required photo) before anything is saved to
the CMS lists, and it keeps the find codes private.

> **The checker now runs on Cloudflare, not on Wix.** The Herd's site uses the Wix Harmony
> editor, which can't run custom code (no Velo, no `http-functions.js`). So the same checker runs
> as a free Cloudflare Worker that reads and writes these same CMS lists with a Wix API key. Set-up
> steps are in [`../worker/README.md`](../worker/README.md). The Velo paste-in file below is still
> built and tested (the Worker is made from it), but you don't need to paste it anywhere.

## The lists in your Wix dashboard (CMS)

| List | What it's for | Who can see it |
|---|---|---|
| Companions | Each Companion: number, name, story, profile photo, wish, status | Everyone |
| Companion Stops | Every find, pass-on and leave, with city, hint, photo and chapter | Everyone (photos show once you tick **Photo approved**) |
| Companion Chat | Traveler chat. Tick **Hidden** to remove a message | Everyone |
| Companion Reports | "Something happened" reports | Only you |
| Companion Find Codes (private) | The secret code for each Companion | Only you |
| Companion Holds (private) | Who's holding each Companion right now | Only you |

The real Companions are #0–#5. Each starts fresh at "Where they were made · Aurora, CO" and
waits to be found. Their secret find codes are only in **Companion Find Codes (private)**:
print those on the bottom labels. (`tool/print_codes.dart` only lists the made-up codes the app
uses for testing before launch; they don't work on the real site.)

## For whoever maintains the code

- The rules live in `shared/rules.js` (used by the website) and match `lib/validation.dart`
  (used by the app). `wix/backend/handlers.src.js` is the checker. The Cloudflare Worker
  (`worker/`) is built from the same two files with Velo's modules swapped for Wix REST calls.
- After changing either, rebuild the paste-in file and run its tests (and the Worker's,
  `node worker/test/worker.test.mjs`):

```bash
python3 tool/build_wix_backend.py
```

```bash
node wix/test/backend.test.mjs
```
