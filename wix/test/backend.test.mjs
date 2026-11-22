// Runs the Wix checker (wix/backend/http-functions.js) against a pretend Wix database.
// Run from the project folder:  node wix/test/backend.test.mjs
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const db = { Companions: [], CompanionFindCodes: [], CompanionHolds: [], CompanionStops: [], CompanionChat: [], CompanionReports: [], CompanionTravelers: [], CompanionSettings: [] };
let nextId = 1;
const query = (name) => {
  const filters = [];
  const q = {
    eq(f, v) { filters.push((i) => i[f] === v); return q; },
    hasSome(f, vs) { filters.push((i) => Array.isArray(i[f]) && i[f].some((x) => vs.includes(x))); return q; },
    limit() { return q; },
    async find() { return { items: db[name].filter((i) => filters.every((fn) => fn(i))).map((i) => ({ ...i })) }; },
  };
  return q;
};
globalThis.__wixData = {
  query,
  async insert(name, item) { const saved = { ...item, _id: String(nextId++) }; db[name].push(saved); return saved; },
  async update(name, item) { const i = db[name].findIndex((x) => x._id === item._id); db[name][i] = { ...item }; return item; },
  async remove(name, id) { db[name] = db[name].filter((x) => x._id !== id); },
};
const sentEmails = [];
globalThis.__crm = {
  contacts: { async appendOrCreateContact(info) { return { contactId: 'contact-' + info.emails[0].email } } },
  triggeredEmails: { async emailContact(emailId, contactId, opts) { sentEmails.push({ emailId, contactId, code: opts.variables.code }); } },
};
globalThis.__media = { async upload(folder, buffer, name) { return { fileUrl: 'wix:image://v1/' + name }; } };
const respond = (status) => (o) => ({ status, body: o.body, headers: o.headers });
globalThis.__http = { ok: respond(200), badRequest: respond(400), serverError: respond(500) };

let src = readFileSync('wix/backend/http-functions.js', 'utf8')
  .replace("import { ok, badRequest, serverError } from 'wix-http-functions';", 'const { ok, badRequest, serverError } = globalThis.__http;')
  .replace("import wixData from 'wix-data';", 'const wixData = globalThis.__wixData;')
  .replace("import { mediaManager } from 'wix-media-backend';", 'const mediaManager = globalThis.__media;')
  .replace("import { contacts, triggeredEmails } from 'wix-crm-backend';", 'const { contacts, triggeredEmails } = globalThis.__crm;');
const dir = mkdtempSync(join(tmpdir(), 'herd-'));
writeFileSync(join(dir, 'f.mjs'), src);
const f = await import(join(dir, 'f.mjs'));
const call = (fn, body) => f[fn]({ body: { text: async () => JSON.stringify(body) } });

db.Companions.push({ _id: 'c7', number: '07', status: 'moving', wish: 'see the ocean', wishGranted: false });
db.CompanionFindCodes.push({ _id: 'k7', companionNumber: '07', code: 'KCVT' });
const aurora = { latitude: 39.7294, longitude: -104.8319, city: 'Aurora, CO' };
const near = { latitude: 39.72, longitude: -104.79, city: 'Aurora, CO' };
const boulder = { latitude: 40.015, longitude: -105.2705, city: 'Boulder, CO' };
const photo = { base64: Buffer.from('fake image').toString('base64'), mimeType: 'image/jpeg' };

let r = await call('post_herdFind', { number: '7', code: 'WRONG', nickname: 'Sam', ...aurora });
assert.equal(r.status, 400); assert.equal(r.body.field, 'code');
r = await call('post_herdFind', { number: '7', code: 'kcvt', nickname: 'sh1t', ...aurora });
assert.equal(r.body.field, 'nickname');
r = await call('post_herdPassOn', { number: '07', holdToken: 'nope', handedOn: true, nickname: 'Sam', photo, ...aurora });
assert.equal(r.status, 400, 'cannot pass on before finding');
r = await call('post_herdFind', { number: '7', code: 'kcvt', nickname: 'Sam', ...aurora });
assert.equal(r.status, 200); const hold = r.body.holdToken;
assert.equal(db.CompanionStops.at(-1).kind, 'found');
assert.equal(db.CompanionStops.at(-1).latitude, 39.7294, 'find dot is the exact spot');
r = await call('post_herdFind', { number: '7', code: 'kcvt', nickname: 'Sam', holdToken: hold, ...aurora });
assert.equal(r.status, 400, 'cannot find twice in a row');
r = await call('post_herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'by the window', nickname: 'Sam', photo, ...near });
assert.equal(r.body.field, 'where', 'leaving needs 5 miles');
r = await call('post_herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: '', nickname: 'Sam', photo, ...boulder });
assert.equal(r.body.field, 'hint');
r = await call('post_herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'bookshelf at Bean Cafe', nickname: 'Sam', ...boulder });
assert.equal(r.body.field, 'photo', 'photo required');
r = await call('post_herdPassOn', { number: '07', holdToken: hold, handedOn: false, hint: 'bookshelf at Bean Cafe', chapter: 'We hiked!', nickname: 'Sam', photo, wishGranted: true, wishPhoto: photo, ...boulder });
assert.equal(r.status, 200); const wishToken = r.body.wishToken; assert.ok(wishToken);
const left = db.CompanionStops.at(-1);
assert.equal(left.kind, 'left'); assert.equal(left.place, 'bookshelf at Bean Cafe'); assert.equal(left.photoApproved, false);
assert.equal(db.Companions[0].status, 'waiting'); assert.equal(db.Companions[0].wishGranted, true);
r = await call('post_herdPassOn', { number: '07', holdToken: hold, handedOn: true, nickname: 'Sam', photo, ...boulder });
assert.equal(r.status, 400, 'cannot leave twice in a row');
r = await call('post_herdWish', { number: '07', wishToken, wish: 'die' });
assert.equal(r.body.field, 'wish');
r = await call('post_herdWish', { number: '07', wishToken, wish: 'I want to ride a train.' });
assert.equal(r.status, 200); assert.equal(db.Companions[0].wish, 'ride a train');
r = await call('post_herdWish', { number: '07', wishToken, wish: 'meet a dog' });
assert.equal(r.status, 400, 'a wish token works once');
// Handing to someone works right where it was found.
r = await call('post_herdFind', { number: '07', code: 'KCVT', nickname: 'Ana', ...aurora });
r = await call('post_herdPassOn', { number: '07', holdToken: r.body.holdToken, handedOn: true, nickname: 'Ana', photo, ...aurora });
assert.equal(r.status, 200); assert.equal(db.CompanionStops.at(-1).kind, 'passedOn');
r = await call('post_herdChat', { number: '07', author: 'Ana', message: 'call me +1 303 555 0100' });
assert.equal(r.body.message, 'call me [hidden]');
r = await call('post_herdChat', { number: '07', author: 'Ana', message: 'you are a b1tch' });
assert.equal(r.status, 400);
r = await call('post_herdReport', { number: '07', what: 'chipped', city: 'Bali' });
assert.equal(r.body.field, 'where');
r = await call('post_herdReport', { number: '07', what: 'chipped', city: 'Denver, CO' });
assert.equal(r.status, 200); assert.equal(db.Companions[0].status, 'moving');
assert.equal(JSON.stringify(db).includes('KCVT') && !JSON.stringify(r).includes('KCVT'), true, 'codes never sent back');
// Report a chat message: one "flagged" report, even if reported twice; unknown ids are refused
{
  const msg = db.CompanionChat.find((m) => m.companionNumber === '07');
  const before = db.CompanionReports.length;
  r = await call('post_herdFlag', { number: '07', kind: 'chat', id: msg._id });
  assert.equal(r.status, 200);
  r = await call('post_herdFlag', { number: '07', kind: 'chat', id: msg._id });
  assert.equal(r.status, 200);
  assert.equal(db.CompanionReports.length, before + 1, 'reported once');
  assert.equal(db.CompanionReports.at(-1).what, 'flagged');
  assert.match(db.CompanionReports.at(-1).note, /Chat message by/);
  r = await call('post_herdFlag', { number: '07', kind: 'chat', id: 'nope' });
  assert.equal(r.status, 400);
  r = await call('post_herdFlag', { number: '07', kind: 'other', id: msg._id });
  assert.equal(r.status, 400);
}
// ── Optional sign-in ──
r = await call('post_herdSignInStart', { email: 'sam@example.com' });
assert.equal(r.status, 400, 'no email template yet: friendly message');
db.CompanionSettings.push({ _id: 's1', key: 'signInEmailId', value: 'TEMPLATE1' });
r = await call('post_herdSignInStart', { email: 'not an email' });
assert.equal(r.body.field, 'email');
// Found on this device before signing in:
r = await call('post_herdFind', { number: '07', code: 'KCVT', nickname: 'Sam', ...aurora });
const earlyHold = r.body.holdToken;
r = await call('post_herdSignInStart', { email: ' Sam@Example.com ' });
assert.equal(r.status, 200); assert.equal(sentEmails.length, 1); assert.equal(sentEmails[0].emailId, 'TEMPLATE1');
r = await call('post_herdSignInStart', { email: 'sam@example.com' });
assert.equal(r.status, 400, 'one code a minute');
r = await call('post_herdSignInVerify', { email: 'sam@example.com', code: '000000' === sentEmails[0].code ? '111111' : '000000' });
assert.equal(r.body.field, 'code');
r = await call('post_herdSignInVerify', { email: 'sam@example.com', code: sentEmails[0].code, holds: { '07': earlyHold }, following: ['07'], nickname: 'Sam' });
assert.equal(r.status, 200); const session = r.body.session;
assert.deepEqual(r.body.profile.holds.map((h) => h.number), ['07'], 'the find from before signing in came along');
assert.deepEqual(r.body.profile.following, ['07']);
assert.ok(!JSON.stringify(db.CompanionTravelers).includes(session), 'only a scrambled copy of the session is stored');
r = await call('post_herdSignInVerify', { email: 'sam@example.com', code: sentEmails[0].code });
assert.equal(r.status, 400, 'a code works once');
// Pass on while signed in: it shows in their travels on every device
r = await call('post_herdPassOn', { number: '07', holdToken: earlyHold, handedOn: true, nickname: 'Sam', photo, session, ...boulder });
assert.equal(r.status, 200);
r = await call('post_herdMine', { session });
assert.equal(r.body.profile.holds.length, 0);
assert.ok(r.body.profile.journal.some((j) => j.kind === 'passedOn' && j.number === '07'));
// Someone else finds it later: it never shows as in Sam's care
r = await call('post_herdFind', { number: '07', code: 'KCVT', nickname: 'Ana', ...aurora });
r = await call('post_herdMine', { session });
assert.equal(r.body.profile.holds.length, 0);
r = await call('post_herdFollow', { session, number: '3', on: true });
assert.equal(r.status, 400, 'unknown Companion');
r = await call('post_herdFollow', { session, number: '07', on: false });
assert.deepEqual(r.body.following, []);
r = await call('post_herdSignOut', { session });
r = await call('post_herdMine', { session });
assert.equal(r.body.field, 'session', 'signed out');
// Sign in again and delete my data
await call('post_herdSignInStart', { email: 'sam@example.com' }).catch(() => {});
db.CompanionTravelers[0].codeSentAt = 0;
await call('post_herdSignInStart', { email: 'sam@example.com' });
r = await call('post_herdSignInVerify', { email: 'sam@example.com', code: sentEmails.at(-1).code });
r = await call('post_herdForgetMe', { session: r.body.session });
assert.equal(r.status, 200); assert.equal(db.CompanionTravelers.length, 0);
assert.ok(db.CompanionStops.every((st) => !st.travelerId), 'chapters stay, unlinked');
console.log('All Wix checker tests passed.');
