// Runs the Cloudflare Worker checker (worker/dist/worker.js, built first) through its fetch()
// against a pretend Wix REST API kept in memory: Data Items, Media Manager upload and Email
// Transmissions. Same scenarios as wix/test/backend.test.mjs, plus CORS and set-up checks.
// Run from the project folder:  node worker/test/worker.test.mjs
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';
import assert from 'node:assert/strict';

const here = dirname(fileURLToPath(import.meta.url));
execFileSync('node', [join(here, '..', 'build.mjs')], { stdio: 'inherit' });
const worker = (await import(pathToFileURL(join(here, '..', 'dist', 'worker.js')).href + '?t=' + Date.now())).default;

const KEY = 'test-api-key';
const SITE = '84ee9f27-4b02-43aa-929d-1b05a51923a2';
const env = { WIX_API_KEY: KEY, WIX_SITE_ID: SITE, EMAIL_PROVIDER: 'wix' };

// ── Pretend Wix ─────────────────────────────────────────────────────────────────────────
const db = { Companions: [], CompanionFindCodes: [], CompanionHolds: [], CompanionStops: [], CompanionChat: [], CompanionReports: [], CompanionTravelers: [], CompanionSettings: [] };
const sentEmails = [];
const uploads = [];
const wixCalls = [];
let nextId = 1;
const now = () => ({ $date: new Date().toISOString() });

function matches(item, filter) {
  if (!filter || Object.keys(filter).length === 0) return true;
  return Object.entries(filter).every(([field, cond]) => {
    if (field === '$and') return cond.every((f) => matches(item, f));
    if (cond && typeof cond === 'object' && !Array.isArray(cond)) {
      if ('$eq' in cond) return item[field] === cond.$eq;
      if ('$hasSome' in cond) return Array.isArray(item[field]) && item[field].some((x) => cond.$hasSome.includes(x));
      throw new Error('pretend Wix: unknown operator in ' + JSON.stringify(cond));
    }
    return item[field] === cond;
  });
}
function asWixItem(name, data) {
  return { id: data._id, dataCollectionId: name, data: { ...data } };
}
function reply(status, body) {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });
}

const realFetch = globalThis.fetch;
globalThis.fetch = async (input, init = {}) => {
  const url = new URL(typeof input === 'string' ? input : input.url);
  const method = (init.method || 'GET').toUpperCase();
  if (url.host === 'upload.wixmp.test') {
    // The signed upload address: no API key.
    assert.equal(method, 'PUT');
    assert.equal(new Headers(init.headers).get('Authorization'), null, 'the key never goes to the upload address');
    const bytes = new Uint8Array(init.body);
    const name = url.searchParams.get('filename');
    uploads.push({ name, size: bytes.length, type: new Headers(init.headers).get('Content-Type'), path: url.searchParams.get('path') });
    const id = 'abc123_' + uploads.length + '~mv2.jpg';
    return reply(200, { file: { id, displayName: name, url: 'https://static.wixstatic.com/media/' + id, mediaType: 'IMAGE', media: { image: { image: { id, url: 'https://static.wixstatic.com/media/' + id, width: 800, height: 600, filename: name } } }, operationStatus: 'READY' } });
  }
  if (url.host !== 'www.wixapis.com') throw new Error('unexpected fetch ' + url);
  const h = new Headers(init.headers);
  assert.equal(h.get('Authorization'), KEY, 'API key in Authorization');
  assert.equal(h.get('wix-site-id'), SITE, 'site in wix-site-id');
  const body = init.body ? JSON.parse(init.body) : null;
  wixCalls.push({ method, path: url.pathname, body });
  const col = body ? body.dataCollectionId : url.searchParams.get('dataCollectionId');
  if (url.pathname.startsWith('/wix-data/')) assert.match(col, /^Companion/, 'only the Companion lists');

  if (method === 'POST' && url.pathname === '/wix-data/v2/items/query') {
    assert.equal(body.consistentRead, true);
    const { filter, paging } = body.query;
    assert.ok(paging.limit >= 1 && paging.limit <= 100, 'page size 1–100');
    const all = db[col].filter((i) => matches(i, filter));
    const page = all.slice(paging.offset || 0, (paging.offset || 0) + paging.limit);
    return reply(200, { dataItems: page.map((d) => asWixItem(col, d)), pagingMetadata: { count: page.length, offset: paging.offset || 0 } });
  }
  if (method === 'POST' && url.pathname === '/wix-data/v2/items') {
    assert.ok(!('_id' in body.dataItem.data));
    const saved = { ...body.dataItem.data, _id: 'id' + nextId++, _createdDate: now(), _updatedDate: now() };
    db[col].push(saved);
    return reply(200, { dataItem: asWixItem(col, saved) });
  }
  const itemPath = url.pathname.match(/^\/wix-data\/v2\/items\/([^/]+)$/);
  if (method === 'PUT' && itemPath) {
    const id = decodeURIComponent(itemPath[1]);
    assert.equal(body.dataItem.id, id);
    assert.ok(!('_id' in body.dataItem.data) && !('_createdDate' in body.dataItem.data), 'system fields are not sent');
    const i = db[col].findIndex((x) => x._id === id);
    if (i < 0) return reply(404, { message: 'ITEM_NOT_FOUND' });
    db[col][i] = { ...body.dataItem.data, _id: id, _createdDate: db[col][i]._createdDate, _updatedDate: now() };
    return reply(200, { dataItem: asWixItem(col, db[col][i]) });
  }
  if (method === 'DELETE' && itemPath) {
    const id = decodeURIComponent(itemPath[1]);
    const gone = db[col].find((x) => x._id === id);
    db[col] = db[col].filter((x) => x._id !== id);
    return reply(200, { dataItem: gone ? asWixItem(col, gone) : undefined });
  }
  if (method === 'POST' && url.pathname === '/site-media/v1/files/generate-upload-url') {
    assert.ok(['image/jpeg', 'image/png', 'image/webp'].includes(body.mimeType));
    assert.equal(body.filePath, '/Herd Around the World');
    return reply(200, { uploadUrl: 'https://upload.wixmp.test/upload/xyz?token=signed' });
  }
  if (method === 'POST' && url.pathname === '/email-transmissions/v1/email-transmissions/send') {
    const t = body.emailTransmission;
    assert.equal(t.type, 'TRANSACTIONAL');
    assert.match(body.idempotencyKey, /^[0-9a-f-]{36}$/);
    const code = (t.emailTextContent.match(/\b(\d{6})\b/) || [])[1];
    sentEmails.push({ to: t.toRecipients[0].emailAddress, code, subject: t.emailSubject });
    return reply(200, { emailTransmission: { ...t, id: 'tx' + sentEmails.length, status: 'ACCEPTED' } });
  }
  throw new Error(`pretend Wix: no ${method} ${url.pathname}`);
};

// ── Calling the Worker ──────────────────────────────────────────────────────────────────
async function call(name, body, e = env) {
  const res = await worker.fetch(new Request('https://herd-checker.example.workers.dev/' + name, {
    method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: JSON.stringify(body),
  }), e);
  assert.equal(res.headers.get('Access-Control-Allow-Origin'), '*', name + ' answers with CORS');
  assert.match(res.headers.get('Content-Type'), /application\/json/);
  return { status: res.status, body: await res.json() };
}

// CORS preflight, unknown paths, set-up
let res = await worker.fetch(new Request('https://herd-checker.example.workers.dev/herdFind', { method: 'OPTIONS', headers: { Origin: 'https://companions.theherdstudio.com', 'Access-Control-Request-Method': 'POST' } }), env);
assert.equal(res.status, 204);
assert.equal(res.headers.get('Access-Control-Allow-Origin'), '*');
assert.match(res.headers.get('Access-Control-Allow-Methods'), /POST/);
assert.match(res.headers.get('Access-Control-Allow-Headers'), /Content-Type/);
res = await worker.fetch(new Request('https://herd-checker.example.workers.dev/nope', { method: 'POST', body: '{}' }), env);
assert.equal(res.status, 404);
res = await worker.fetch(new Request('https://herd-checker.example.workers.dev/herdMine'), env);
assert.equal(res.status, 405);
let r = await call('herdMine', {}, { WIX_SITE_ID: SITE });
assert.equal(r.status, 500, 'without the Wix key the probe fails, so the website and app stay in preview');
r = await call('herdMine', {});
assert.equal(r.status, 400); assert.equal(r.body.field, 'session', 'the live probe answer');
r = await call('_functions/herdMine', {});
assert.equal(r.body.field, 'session', 'old /_functions/ paths work too');
r = await worker.fetch(new Request('https://herd-checker.example.workers.dev/herdFind', { method: 'POST', body: 'not json' }), env);
assert.equal(r.status, 400);

// The same scenarios as the Wix checker test
db.Companions.push({ _id: 'c7', number: '07', status: 'moving', wish: 'see the ocean', wishGranted: false, _createdDate: now() });
db.CompanionFindCodes.push({ _id: 'k7', companionNumber: '07', code: 'KCVT' });
const aurora = { latitude: 39.7294, longitude: -104.8319, city: 'Aurora, CO' };
const near = { latitude: 39.72, longitude: -104.79, city: 'Aurora, CO' };
const boulder = { latitude: 40.015, longitude: -105.2705, city: 'Boulder, CO' };
const photo = { base64: Buffer.from('fake image').toString('base64'), mimeType: 'image/jpeg' };

r = await call('herdFind', { number: '7', code: 'WRONG', nickname: 'Sam', ...aurora });
assert.equal(r.status, 400); assert.equal(r.body.field, 'code'); assert.equal(r.body.ok, false);
r = await call('herdFind', { number: '7', code: 'kcvt', nickname: 'sh1t', ...aurora });
assert.equal(r.body.field, 'nickname');
r = await call('herdPassOn', { number: '07', holdToken: 'nope', handedOn: true, nickname: 'Sam', photo, ...aurora });
assert.equal(r.status, 400, 'cannot pass on before finding');
r = await call('herdFind', { number: '7', code: 'kcvt', nickname: 'Sam', ...aurora });
assert.equal(r.status, 200); const hold = r.body.holdToken;
assert.match(hold, /^[0-9a-f]{48}$/);
assert.equal(db.CompanionStops.at(-1).kind, 'found');
assert.equal(db.CompanionStops.at(-1).latitude, 39.7, 'find dot blurred to about the city');
assert.equal(db.Companions[0].status, 'moving');
assert.ok(db.Companions[0]._createdDate, 'a full update keeps the item');
r = await call('herdFind', { number: '7', code: 'kcvt', nickname: 'Sam', holdToken: hold, ...aurora });
assert.equal(r.status, 400, 'cannot find twice in a row');
r = await call('herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'by the window', nickname: 'Sam', photo, ...near });
assert.equal(r.body.field, 'where', 'leaving needs 5 miles');
r = await call('herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: '', nickname: 'Sam', photo, ...boulder });
assert.equal(r.body.field, 'hint');
r = await call('herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'bookshelf at Bean Cafe', nickname: 'Sam', ...boulder });
assert.equal(r.body.field, 'photo', 'photo required');
r = await call('herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'bookshelf at Bean Cafe', chapter: 'We hiked!', nickname: 'Sam', photo, wishGranted: true, wishPhoto: photo, ...boulder });
assert.equal(r.status, 200); const wishToken = r.body.wishToken; assert.ok(wishToken);
const left = db.CompanionStops.at(-1);
assert.equal(left.kind, 'left'); assert.equal(left.place, 'bookshelf at Bean Cafe'); assert.equal(left.photoApproved, false);
assert.match(left.photo, /^wix:image:\/\/v1\/abc123_\d~mv2\.jpg\/companion-07-stop-\d+\.jpg#originWidth=800&originHeight=600$/, 'photo saved as a wix:image address');
assert.match(left.wishPhoto, /^wix:image:\/\/v1\/.*companion-07-wish-/);
assert.equal(uploads.length, 2); assert.equal(uploads[0].size, 'fake image'.length); assert.equal(uploads[0].type, 'image/jpeg');
assert.equal(db.Companions[0].status, 'waiting'); assert.equal(db.Companions[0].wishGranted, true);
r = await call('herdPassOn', { number: '07', holdToken: hold, handedOn: true, nickname: 'Sam', photo, ...boulder });
assert.equal(r.status, 400, 'cannot leave twice in a row');
r = await call('herdWish', { number: '07', wishToken, wish: 'die' });
assert.equal(r.body.field, 'wish');
r = await call('herdWish', { number: '07', wishToken, wish: 'I want to ride a train.' });
assert.equal(r.status, 200); assert.equal(db.Companions[0].wish, 'ride a train');
r = await call('herdWish', { number: '07', wishToken, wish: 'meet a dog' });
assert.equal(r.status, 400, 'a wish token works once');
// Handing to someone works right where it was found.
r = await call('herdFind', { number: '07', code: 'KCVT', nickname: 'Ana', ...aurora });
r = await call('herdPassOn', { number: '07', holdToken: r.body.holdToken, handedOn: true, nickname: 'Ana', photo, ...aurora });
assert.equal(r.status, 200); assert.equal(db.CompanionStops.at(-1).kind, 'passedOn');
r = await call('herdChat', { number: '07', author: 'Ana', message: 'call me +1 303 555 0100' });
assert.equal(r.status, 200); assert.equal(r.body.message, 'call me [hidden]'); assert.ok(r.body.id);
r = await call('herdChat', { number: '07', author: 'Ana', message: 'you are a b1tch' });
assert.equal(r.status, 400);
r = await call('herdReport', { number: '07', what: 'chipped', city: 'Bali' });
assert.equal(r.body.field, 'where');
r = await call('herdReport', { number: '07', what: 'chipped', city: 'Denver, CO' });
assert.equal(r.status, 200); assert.equal(db.Companions[0].status, 'moving');
assert.equal(db.CompanionReports.length, 1);
assert.ok(JSON.stringify(db).includes('KCVT'));
// ── Optional sign-in ──
r = await call('herdSignInStart', { email: 'sam@example.com' });
assert.equal(r.status, 400, 'sign-in not switched on yet: friendly message');
db.CompanionSettings.push({ _id: 's1', key: 'signInEmailId', value: 'on' });
r = await call('herdSignInStart', { email: 'not an email' });
assert.equal(r.body.field, 'email');
// Found on this device before signing in:
r = await call('herdFind', { number: '07', code: 'KCVT', nickname: 'Sam', ...aurora });
const earlyHold = r.body.holdToken;
r = await call('herdSignInStart', { email: ' Sam@Example.com ' });
assert.equal(r.status, 200); assert.equal(sentEmails.length, 1);
assert.equal(sentEmails[0].to, 'sam@example.com'); assert.match(sentEmails[0].code, /^\d{6}$/);
assert.equal(db.CompanionTravelers[0].codeHash, createHash('sha256').update('sam@example.com:' + sentEmails[0].code).digest('hex'), 'SHA-256 matches Node');
r = await call('herdSignInStart', { email: 'sam@example.com' });
assert.equal(r.status, 400, 'one code a minute');
r = await call('herdSignInVerify', { email: 'sam@example.com', code: '000000' === sentEmails[0].code ? '111111' : '000000' });
assert.equal(r.body.field, 'code');
r = await call('herdSignInVerify', { email: 'sam@example.com', code: sentEmails[0].code, holds: { '07': earlyHold }, following: ['07'], nickname: 'Sam' });
assert.equal(r.status, 200); const session = r.body.session;
assert.deepEqual(r.body.profile.holds.map((h) => h.number), ['07'], 'the find from before signing in came along');
assert.equal(typeof r.body.profile.holds[0].date, 'string', 'Wix dates come back as plain date strings');
assert.ok(!Number.isNaN(Date.parse(r.body.profile.holds[0].date)));
assert.deepEqual(r.body.profile.following, ['07']);
assert.ok(!JSON.stringify(db.CompanionTravelers).includes(session), 'only a scrambled copy of the session is stored');
r = await call('herdSignInVerify', { email: 'sam@example.com', code: sentEmails[0].code });
assert.equal(r.status, 400, 'a code works once');
r = await call('herdPassOn', { number: '07', holdToken: earlyHold, handedOn: true, nickname: 'Sam', photo, session, ...boulder });
assert.equal(r.status, 200);
r = await call('herdMine', { session });
assert.equal(r.status, 200);
assert.equal(r.body.profile.holds.length, 0);
assert.ok(r.body.profile.journal.some((j) => j.kind === 'passedOn' && j.number === '07'));
r = await call('herdFind', { number: '07', code: 'KCVT', nickname: 'Ana', ...aurora });
r = await call('herdMine', { session });
assert.equal(r.body.profile.holds.length, 0);
r = await call('herdFollow', { session, number: '3', on: true });
assert.equal(r.status, 400, 'unknown Companion');
r = await call('herdFollow', { session, number: '07', on: false });
assert.deepEqual(r.body.following, []);
r = await call('herdSignOut', { session });
assert.equal(r.status, 200);
r = await call('herdMine', { session });
assert.equal(r.body.field, 'session', 'signed out');
// Sign in again and delete my data
db.CompanionTravelers[0].codeSentAt = 0;
await call('herdSignInStart', { email: 'sam@example.com' });
r = await call('herdSignInVerify', { email: 'sam@example.com', code: sentEmails.at(-1).code });
r = await call('herdForgetMe', { session: r.body.session });
assert.equal(r.status, 200); assert.equal(db.CompanionTravelers.length, 0);
assert.ok(db.CompanionStops.every((st) => !st.travelerId), 'chapters stay, unlinked');
assert.ok(wixCalls.some((c) => c.method === 'DELETE'), 'forget me removes the traveler');

// A Wix error becomes the friendly 500
const before = globalThis.fetch;
globalThis.fetch = async () => new Response('{"message":"PERMISSION_DENIED"}', { status: 403 });
const quiet = console.error; console.error = () => {};
r = await call('herdChat', { number: '07', author: 'Ana', message: 'hello' });
console.error = quiet;
assert.equal(r.status, 500); assert.equal(r.body.ok, false);
globalThis.fetch = before;

globalThis.fetch = realFetch;

// The plain-JavaScript SHA-256 matches Node's on awkward lengths and non-English text
const { sha256Hex } = await import(pathToFileURL(join(here, '..', 'src', 'adapters', 'crypto.js')).href);
for (const s of ['', 'abc', 'é😀 Zoë', 'x'.repeat(55), 'x'.repeat(56), 'x'.repeat(64), 'y'.repeat(1000)]) {
  assert.equal(sha256Hex(s), createHash('sha256').update(s).digest('hex'));
}
console.log('All Worker checker tests passed.');
