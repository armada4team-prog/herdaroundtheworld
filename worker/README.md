# The Herd's checker on Cloudflare (free)

Every find, pass-on, wish, chat message, report and sign-in from the website and the app goes
to a small "checker". It checks the rules (the secret find code, found → left order, 5 miles
to leave a Companion somewhere, the word filter, the photo) and only then saves to your Wix CMS
lists. It also keeps the find codes secret.

Your Wix site uses the Wix Harmony editor, which can't run code like this. So the checker runs
on **Cloudflare Workers** (free plan) and saves into **the same Wix lists** you already have
(Companions, Companion Stops, Companion Chat, …), using a private **Wix API key**. Nothing about
your lists changes.

**Until the checker is set up, the website and app keep working in preview / sample mode.**
They only switch to your real lists once the checker answers.

You'll do 5 things, about 20 minutes in total. Steps 1, 2, 4 and 5 are yours; step 3 is done for
you by whoever deploys it.

---

## 1. Make a free Cloudflare account

1. Go to <https://dash.cloudflare.com/sign-up> and sign up with your email and a password.
   Choose the **Free** plan if asked. No card is needed for Workers.
2. In the left menu, open **Workers & Pages** (under *Compute*). The first time, Cloudflare asks
   you to pick a **workers.dev subdomain**, for example `theherd`. Pick something short and save.
   Your checker's address will then be `https://herd-checker.<your-subdomain>.workers.dev/`.
3. Tell your developer that subdomain (for example "theherd").

## 2. Make a Wix API key for The Herd site

The key lets the checker read and write your Companion lists, upload photos and send sign-in
codes. Treat it like a password.

1. Open the Wix **API Keys Manager**: <https://manage.wix.com/account/api-keys>
   (you must be the account owner or a co-owner).
2. Click **Generate API Key**.
3. **Name**: `Herd checker (Cloudflare)`.
4. **Sites**: choose **Specific sites** and select only **The Herd**.
5. **Permissions**: next to **All site permissions**, click **See all**, then tick only these
   (the names in the list may differ slightly):
   - **Wix Data** / **CMS** (reading and changing data items in your collections)
   - **Media Manager** (to save travelers' photos)
   - **Email Marketing** (to email the 6-digit sign-in codes)
6. Click **Generate Key**. Wix shows the key **once**: click copy and keep it somewhere safe
   until step 4 (don't email it or paste it in a chat).

(From Wix's guides: [Generate an API key](https://dev.wix.com/docs/go-headless/authentication/admin/generate-an-api-key),
[API keys in the Help Center](https://support.wix.com/en/article/wix-online-programs-working-with-online-programs-apis).)

## 3. Deploying the checker (done for you)

Your developer deploys it with Cloudflare's `wrangler` tool. They need, from you:

- your **Cloudflare Account ID** (Cloudflare dashboard → **Workers & Pages** → it's shown on the
  right, or in the address bar after `dash.cloudflare.com/`), and
- a **Cloudflare API token** that can deploy Workers:
  1. Click your profile icon (top right) → **My Profile** → **API Tokens** → **Create Token**.
  2. Use the **Edit Cloudflare Workers** template.
  3. Under **Account Resources** choose your account. Under **Zone Resources** choose
     **All zones from an account** → your account (you have no zones; that's fine).
  4. **Continue to summary** → **Create Token**, and copy it.

  If you'd rather give less access, create a **Custom token** with only:
  **Account → Workers Scripts → Edit**, **Account → Account Settings → Read** and
  **User → User Details → Read**.

  Share the token privately, and delete it (same page → **⋯** → **Delete**) once the checker is
  deployed. A new one can be made any time.

What they run, from this folder:

```bash
CLOUDFLARE_API_TOKEN=… CLOUDFLARE_ACCOUNT_ID=… npx wrangler@4 deploy
```

`wrangler.toml` builds the Worker first (`node build.mjs`) and deploys it as `herd-checker`.
Then they set the checker address in two places and publish the website and app:
`website/js/data.js` (`CHECKER`) and `lib/wix_api.dart` (`checkerBase`), both
`https://herd-checker.<your-subdomain>.workers.dev/`.

## 4. Paste the Wix API key into Cloudflare (only you see it)

Do this after step 3 (the Worker has to exist first).

1. Cloudflare dashboard → **Workers & Pages** → click **herd-checker**.
2. **Settings** → **Variables and Secrets** → **Add**.
3. **Type**: **Secret**. **Variable name**: `WIX_API_KEY`. **Value**: paste the Wix API key.
4. Click **Deploy** (or **Save and deploy**).

A secret can't be read back by anyone, including you, your developer or the website's visitors.
Deploying a new version of the checker keeps it. To change it, add it again with the same name.
Leave `WIX_SITE_ID` as it is (it's your site's ID, not a secret).

Check it works: open `https://herd-checker.<your-subdomain>.workers.dev/` in a browser. It says
`{"ok":true,"name":"Herd Around the World checker"}`. Then open the website: the yellow
"Preview" bar is gone.

## 5. Switch on the emailed sign-in codes

Signing in is optional for travelers. It emails a 6-digit code (no password). The checker sends
it through your Wix site's own email sending, so there's nothing extra to sign up for.

1. Wix dashboard → **CMS** → **Companion Settings**.
2. In the row with key **signInEmailId**, set **value** to `on` and save.
   (The old help text there mentions a "triggered email ID": that's no longer needed. Any value
   switches sign-in on; leave it empty to keep sign-in off.)

Good to know:

- The emails come from **"The Herd"** at Wix's sending address (`no-reply@et.wixsitemail.com`).
  If you'd like replies to reach you, your developer can add a variable `EMAIL_REPLY_TO` with
  your address in `wrangler.toml`.
- They count toward your site's **Wix Email Marketing** monthly allowance (Wix dashboard →
  **Marketing** → **Email Marketing** shows what's left). Each sign-in is one email.
- If you ever want to send from another email service instead, the code is ready for it
  (`src/email.js`, `EMAIL_PROVIDER`).

---

## For developers

- `src/index.js`: the Worker (`export default { fetch }`). POST `/herdFind`, `/herdPassOn`,
  `/herdWish`, `/herdChat`, `/herdReport`, `/herdSignInStart`, `/herdSignInVerify`, `/herdMine`,
  `/herdFollow`, `/herdSignOut`, `/herdForgetMe` (old `/_functions/…` paths work too). JSON
  bodies (text/plain is fine), JSON answers with `Access-Control-Allow-Origin: *`, OPTIONS
  preflight answered. 200 ok · 400 `{ ok:false, field, message }` · 500. Without `WIX_API_KEY`
  everything answers 500, so the website/app probe (POST `herdMine {}` → 400 `field: session`)
  fails and they stay in preview.
- The checker logic is `wix/backend/handlers.src.js` + `shared/rules.js`, unchanged:
  `build.mjs` joins them (`tool/build_wix_backend.py`) and bundles with esbuild 0.24.2, aliasing
  Velo's modules to `src/adapters/`:

  | Velo | Worker stand-in | Wix REST |
  |---|---|---|
  | `wix-data` query/insert/update/remove | `adapters/wix-data.js` | `POST /wix-data/v2/items/query` (filter `$eq`, `$hasSome`, `$and`; offset paging, 100 a page; `consistentRead`), `POST /wix-data/v2/items`, `PUT /wix-data/v2/items/{id}` (full replace), `DELETE /wix-data/v2/items/{id}?dataCollectionId=` |
  | `mediaManager.upload` | `adapters/wix-media-backend.js` | `POST /site-media/v1/files/generate-upload-url` (`filePath: /Herd Around the World`), then `PUT <uploadUrl>?filename=` with the bytes; saved as `wix:image://v1/<id>/<name>#originWidth=…&originHeight=…` |
  | `contacts` + `triggeredEmails` | `adapters/wix-crm-backend.js` → `src/email.js` | `POST /email-transmissions/v1/email-transmissions/send` (`type: TRANSACTIONAL`, recipient by `emailAddress`) |
  | `ok/badRequest/serverError` | `adapters/wix-http-functions.js` | `Response` |
  | `crypto` | `adapters/crypto.js` | Web Crypto random + sync SHA-256 |
  | `Buffer.from(b64)` | `adapters/buffer.js` (injected) | `atob` |

  Every Wix call sends `Authorization: <WIX_API_KEY>` and `wix-site-id: <WIX_SITE_ID>`. Only
  collections named `Companions` / `Companion…` can be touched.
- Variables: `WIX_API_KEY` (secret), `WIX_SITE_ID`, `EMAIL_PROVIDER` (`wix`),
  `EMAIL_SENDER_NAME`, optional `EMAIL_FROM` (a sender address verified in Wix),
  `EMAIL_REPLY_TO`.
- Test (builds first, runs the Worker's `fetch()` against an in-memory pretend Wix REST API):

```bash
node worker/test/worker.test.mjs
```

## Reminder emails for long-time holders

Once a day (10:23am Colorado time, a free Cloudflare cron trigger in `wrangler.toml`) the checker
looks at who is holding each Companion. Anyone signed in with their email who has held one for
60 days gets **one** friendly email: "Pass them on" (opens the pass-on page) or "They're staying
with me". That second link marks the Companion **Adopted** and adds an `adopted` line to
**Companion Reports**, so you can see it in the Wix dashboard.

Settings (in the **Companion Settings (private)** list in Wix):
- `nudgeDays`: how many days before the reminder (default 60).
- `nudges`: set to `off` to stop the reminders.
- Reminders only go out when emails are switched on (`signInEmailId` has a value).

Travelers who never signed in have no email on file, so they don't get reminders.
