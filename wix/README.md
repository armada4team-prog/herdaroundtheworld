# The Herd's Wix site: the Companions checker

The website and the app send every find, pass-on, wish, chat message and report to a small
piece of code on The Herd's Wix site. It checks the rules (find code, found → left order,
5 miles to leave one somewhere, word filter, required photo) before anything is saved to
the CMS lists, and it keeps the find codes private.

**Nothing here is live until The Herd's Wix site is published.** Do these steps when you're
ready to launch.

## When you're ready to launch (about 10 minutes)

1. Open The Herd's site in the Wix editor.
2. Turn on coding:
   - **Wix Editor:** click **Dev Mode** in the top bar, then **Turn on Dev Mode**.
   - **Wix Studio:** click the **{ }** (Code) icon in the left sidebar.
3. In the code panel, under **Backend & Public → Backend**, click **+** and choose
   **Expose site API**. Wix creates a file called `http-functions.js`.
4. Delete everything in that file, then paste in the whole of
   [`backend/http-functions.js`](backend/http-functions.js) and save.
5. Publish the site.

That's it. The website and app start saving to your Wix lists right away.

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
  (used by the app). `wix/backend/handlers.src.js` is the checker.
- After changing either, rebuild the paste-in file and run its tests:

```bash
python3 tool/build_wix_backend.py
```

```bash
node wix/test/backend.test.mjs
```
