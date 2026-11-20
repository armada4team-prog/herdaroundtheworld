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

const ROUTES = {
  herdFind: checker.post_herdFind,
  herdPassOn: checker.post_herdPassOn,
  herdWish: checker.post_herdWish,
  herdChat: checker.post_herdChat,
  herdReport: checker.post_herdReport,
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

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    const name = new URL(request.url).pathname.replace(/^\/+|\/+$/g, '').replace(/^_functions\//, '');
    if (name === '') return json(200, { ok: true, name: 'Herd Around the World checker' });
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
