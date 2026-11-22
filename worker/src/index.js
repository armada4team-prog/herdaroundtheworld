// ── Herd Around the World: the checker, as a Cloudflare Worker ─────────────────────────
// The same checker as wix/backend/handlers.src.js (the rules from shared/rules.js, the find
// codes kept private), running on Cloudflare instead of Velo, because The Herd's Wix site
// (Wix Harmony) can't run custom code. It reads and writes the same Wix CMS lists over the
// Wix REST API with an API key. The build (worker/build.mjs) swaps Velo's modules for the
// small stand-ins in ./adapters.
//
// Addresses: https://herd-checker.<your-subdomain>.workers.dev/herdFind  (and the others below)
// Send a POST with a JSON body (Content-Type text/plain is fine, so browsers skip the preflight).
import * as checker from '../../wix/backend/http-functions.js';
import { configure, isConfigured } from './wix-rest.js';
import { nudgeLongHolds, adoptFromEmail } from './nudge.js';
import { sendOwnerDigest, approveFromEmail } from './digest.js';

const ROUTES = {
  herdFind: checker.post_herdFind,
  herdPassOn: checker.post_herdPassOn,
  herdWish: checker.post_herdWish,
  herdChat: checker.post_herdChat,
  herdReport: checker.post_herdReport,
  herdFlag: checker.post_herdFlag,
  herdSignInStart: checker.post_herdSignInStart,
  herdSignInVerify: checker.post_herdSignInVerify,
  herdMine: checker.post_herdMine,
  herdFollow: checker.post_herdFollow,
  herdSignOut: checker.post_herdSignOut,
  herdForgetMe: checker.post_herdForgetMe,
};

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

function json(status, body) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json', ...CORS } });
}

function withCors(res) {
  const headers = new Headers(res.headers);
  for (const [k, v] of Object.entries(CORS)) headers.set(k, v);
  if (!headers.has('Content-Type')) headers.set('Content-Type', 'application/json');
  return new Response(res.body, { status: res.status, headers });
}

const escHtml = (s) => String(s).replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));

/** The small page someone sees after clicking "They're staying with me" in the reminder email. */
function page(title, message) {
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escHtml(title)}</title></head>
<body style="margin:0;background:#FDF8F3;font-family:'Fira Sans',Arial,sans-serif;color:#566E62;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:24px;box-sizing:border-box">
<div style="max-width:460px;text-align:center"><h1 style="color:#3F5A4C;font-size:28px">${escHtml(title)}</h1><p style="font-size:17px;line-height:1.5">${escHtml(message)}</p>
<p><a href="https://companions.theherdstudio.com" style="display:inline-block;background:#5B7869;color:#fff;text-decoration:none;font-weight:bold;padding:12px 22px;border-radius:999px">Herd Around the World</a></p></div></body></html>`;
  return new Response(html, { status: 200, headers: { 'Content-Type': 'text/html; charset=utf-8' } });
}

export default {
  // Once a day (wrangler.toml [triggers]): remind long-time holders to pass their Companion on.
  async scheduled(_event, env, ctx) {
    if (!isConfigured(env)) return;
    configure(env);
    ctx.waitUntil((async () => {
      try { console.log('reminders sent:', await nudgeLongHolds({ checkerUrl: env.CHECKER_URL })); } catch (err) { console.error('reminders:', err); }
      try { console.log('daily email to The Herd:', JSON.stringify(await sendOwnerDigest({ checkerUrl: env.CHECKER_URL, siteId: env.WIX_SITE_ID }))); } catch (err) { console.error('daily email:', err); }
    })());
  },

  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    const url = new URL(request.url);
    const name = url.pathname.replace(/^\/+|\/+$/g, '').replace(/^_functions\//, '');
    if (name === '') return json(200, { ok: true, name: 'Herd Around the World checker' });
    // The "Approve photo" button in The Herd's daily email.
    if (name === 'herdApprove' && request.method === 'GET') {
      if (!isConfigured(env)) return page('Something went wrong', 'Please try the link again in a few minutes.');
      configure(env);
      try {
        const what = await approveFromEmail(url.searchParams.get('t') || '');
        return what
          ? page('Photo approved', `The photo from ${what} now shows on the Companion’s page.`)
          : page('This link didn’t work', 'The photo may have been removed. You can still approve photos in Wix: CMS, then Companion Stops.');
      } catch (err) {
        console.error(err);
        return page('Something went wrong', 'Please try the link again in a few minutes.');
      }
    }
    // The "They're staying with me" link in the reminder email (a plain link, so a GET).
    if (name === 'herdAdopted' && request.method === 'GET') {
      if (!isConfigured(env)) return page('Something went wrong', 'Please try the link again in a few minutes.');
      configure(env);
      try {
        const who = await adoptFromEmail(url.searchParams.get('t') || '');
        return who
          ? page(`${who} found a forever home`, `Thank you for letting us know! ${who}’s page now shows they’ve been adopted, and their whole journey stays safe for everyone to see.`)
          : page('This link has expired', 'Someone may have found this Companion since. Thank you for being part of their journey!');
      } catch (err) {
        console.error(err);
        return page('Something went wrong', 'Please try the link again in a few minutes.');
      }
    }
    const handler = Object.prototype.hasOwnProperty.call(ROUTES, name) ? ROUTES[name] : null;
    if (!handler) return json(404, { ok: false, message: 'Not found.' });
    if (request.method !== 'POST') return json(405, { ok: false, message: 'Please send a POST.' });
    // Without the Wix key nothing can be saved: answer 500 so the website and app stay in preview.
    if (!isConfigured(env)) {
      console.error('WIX_API_KEY or WIX_SITE_ID is missing');
      return json(500, { ok: false, message: 'Something went wrong on our side. Please try again in a minute.' });
    }
    configure(env);
    const text = await request.text();
    const res = await handler({ body: { text: async () => text } });
    return withCors(res);
  },
};
