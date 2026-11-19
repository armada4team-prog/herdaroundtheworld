// Runs the Wix checker (wix/backend/http-functions.js) against a pretend Wix database.
// Run from the project folder:  node wix/test/backend.test.mjs
import { readFileSync, writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const db = { Companions: [], CompanionFindCodes: [], CompanionHolds: [], CompanionStops: [], CompanionChat: [], CompanionReports: [] };
let nextId = 1;
const query = (name) => {
  const filters = [];
  const q = {
    eq(f, v) { filters.push((i) => i[f] === v); return q; },
    limit() { return q; },
    async find() { return { items: db[name].filter((i) => filters.every((fn) => fn(i))).map((i) => ({ ...i })) }; },
  };
  return q;
};
globalThis.__wixData = {
  query,
  async insert(name, item) { const saved = { ...item, _id: String(nextId++) }; db[name].push(saved); return saved; },
  async update(name, item) { const i = db[name].findIndex((x) => x._id === item._id); db[name][i] = { ...item }; return item; },
};
globalThis.__media = { async upload(folder, buffer, name) { return { fileUrl: 'wix:image://v1/' + name }; } };
const respond = (status) => (o) => ({ status, body: o.body, headers: o.headers });
globalThis.__http = { ok: respond(200), badRequest: respond(400), serverError: respond(500) };

let src = readFileSync('wix/backend/http-functions.js', 'utf8')
  .replace("import { ok, badRequest, serverError } from 'wix-http-functions';", 'const { ok, badRequest, serverError } = globalThis.__http;')
  .replace("import wixData from 'wix-data';", 'const wixData = globalThis.__wixData;')
  .replace("import { mediaManager } from 'wix-media-backend';", 'const mediaManager = globalThis.__media;');
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
assert.equal(db.CompanionStops.at(-1).latitude, 39.7, 'find dot blurred to about the city');
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
console.log('All Wix checker tests passed.');
