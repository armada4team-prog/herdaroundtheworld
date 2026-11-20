// Where the website's data comes from.
//
// LIVE: reads The Herd's Wix CMS lists with a Wix Headless visitor token, and sends every find,
// pass-on, wish, chat message and report to The Herd's checker (wix/backend/handlers.src.js, run as
// the Cloudflare Worker in worker/, which saves to the same Wix lists).
// PREVIEW: used automatically when the live lists can't be read or the checker doesn't answer yet
// (before the Worker is set up), or with ?preview=1. Reads the
// bundled sample data (data/sample.json) and checks writes right here in the browser with the
// same rules as the Wix checker. Nothing is saved anywhere but this browser.
import {
  checkNickname, checkPublicText, checkWish, checkHint, checkPlaceFormat, isEmail, mentionsSelfHarm,
  containsBlockedLanguage, selfHarmMessage, hideContactDetails, cleanNumber, cleanFindCode, milesBetween,
  blur, minMilesToLeave,
} from '../../shared/rules.js';
import { relativeTime, daysAgo } from './model.js';
import { asset } from './env.js';

const WIX_CLIENT_ID = '492b0619-e1c9-49e2-958c-b24c49fc5771';
const WIX_API = 'https://www.wixapis.com';
// ▶ THE CHECKER ADDRESS (the Cloudflare Worker in worker/). Change it here once the Worker is
// deployed; the app has the same address in lib/wix_api.dart (checkerBase). Until it answers, the
// site stays in preview mode.
const CHECKER = 'https://herd-checker.growtheherd.workers.dev/';

export const state = { mode: 'loading', companions: [], chats: {} };

const params = new URLSearchParams(location.search);
const forcePreview = params.get('preview') === '1' || /[?&]preview=1/.test(location.hash);

// ── Small storage helpers (storage can be blocked: everything still works for this visit) ──
const memory = {};
function readJSON(store, key, fallback) {
  try {
    const raw = store.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch (e) {
    return key in memory ? memory[key] : fallback;
  }
}
function writeJSON(store, key, value) {
  memory[key] = value;
  try { store.setItem(key, JSON.stringify(value)); } catch (e) { /* full or blocked */ }
}
const local = typeof localStorage !== 'undefined' ? localStorage : null;
const session = typeof sessionStorage !== 'undefined' ? sessionStorage : null;

// ── Wix images ("wix:image://v1/<id>/<name>#..." → https://static.wixstatic.com/media/<id>) ──
export function wixImageUrl(value) {
  if (!value || typeof value !== 'string') return null;
  if (/^https?:\/\//.test(value) || value.startsWith('data:')) return value;
  const m = value.match(/^wix:image:\/\/v1\/([^/#]+)/);
  return m ? 'https://static.wixstatic.com/media/' + m[1] : null;
}

// ── LIVE: visitor token and reading the CMS lists ───────────────────────────────────────
async function token(forceNew = false) {
  const saved = readJSON(local, 'herd.wixToken', null);
  if (!forceNew && saved && saved.expiresAt > Date.now() + 60000) return saved.access_token;
  const body = saved && saved.refresh_token
    ? { clientId: WIX_CLIENT_ID, grantType: 'refresh_token', refresh_token: saved.refresh_token }
    : { clientId: WIX_CLIENT_ID, grantType: 'anonymous' };
  let res = await fetch(WIX_API + '/oauth2/token', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!res.ok && body.grantType === 'refresh_token') {
    res = await fetch(WIX_API + '/oauth2/token', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ clientId: WIX_CLIENT_ID, grantType: 'anonymous' }),
    });
  }
  if (!res.ok) throw new Error('token ' + res.status);
  const json = await res.json();
  writeJSON(local, 'herd.wixToken', {
    access_token: json.access_token,
    refresh_token: json.refresh_token,
    expiresAt: Date.now() + (Number(json.expires_in) || 14400) * 1000,
  });
  return json.access_token;
}

async function queryAll(collection, filter = {}) {
  const items = [];
  for (let offset = 0; offset < 20000; offset += 100) {
    let auth = await token();
    const call = (a) => fetch(WIX_API + '/wix-data/v2/items/query', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: a },
      body: JSON.stringify({ dataCollectionId: collection, query: { filter, paging: { limit: 100, offset } } }),
    });
    let res = await call(auth);
    if (res.status === 401 || res.status === 403) { auth = await token(true); res = await call(auth); }
    if (!res.ok) throw new Error(collection + ' ' + res.status);
    const json = await res.json();
    const page = (json.dataItems || []).map((d) => d.data || {});
    items.push(...page);
    if (page.length < 100) break;
  }
  return items;
}

function dateOf(v) {
  if (!v) return null;
  const s = typeof v === 'object' ? v.$date : v;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

function whenFor(stop) {
  if (stop.whenText) return stop.whenText;
  if (stop.sample) return '';
  const d = dateOf(stop._createdDate);
  return d ? relativeTime(d) : '';
}

function liveCompanion(c, stops) {
  const sorted = [...stops].sort((a, b) => {
    if (a.kind === 'made' && b.kind !== 'made') return -1;
    if (b.kind === 'made' && a.kind !== 'made') return 1;
    return (dateOf(a._createdDate)?.getTime() || 0) - (dateOf(b._createdDate)?.getTime() || 0);
  });
  const mapped = sorted.map((s) => ({
    kind: s.kind || 'left',
    city: s.city || '',
    place: s.place || null,
    latitude: Number(s.latitude) || 0,
    longitude: Number(s.longitude) || 0,
    byName: s.byName || null,
    chapter: s.chapter || null,
    // Only photos The Herd has approved are shown.
    photo: s.photoApproved ? wixImageUrl(s.photo) : null,
    wishPhoto: s.photoApproved ? wixImageUrl(s.wishPhoto) : null,
    photoApproved: !!s.photoApproved,
    when: whenFor(s),
    date: dateOf(s._createdDate),
  }));
  const last = mapped[mapped.length - 1];
  const moves = mapped.filter((s) => s.kind !== 'made');
  const lastMove = moves[moves.length - 1];
  const travelers = new Set(moves.map((s) => s.byName).filter(Boolean)).size;
  const status = c.status || 'moving';
  return {
    number: String(c.number ?? ''),
    name: c.name || null,
    status,
    isOriginal: !!c.isOriginal,
    wish: String(c.wish || '').replace(/^i want to /i, '').replace(/\.$/, ''),
    wishGranted: !!c.wishGranted,
    blurb: c.blurb || 'A short blurb about this Companion, written by The Herd.',
    originStory: c.originStory || 'Their origin story, written by The Herd.',
    profilePhoto: wixImageUrl(c.profilePhoto),
    glaze: c.glaze || 'A8DCC9',
    accent: c.accent || 'D98C86',
    blob: c.blob || 'DDF0E8',
    stops: mapped,
    lastMoved: status === 'waiting' && !lastMove ? 'Waiting to be found' : (last ? last.when : ''),
    movedThisWeek: lastMove ? (lastMove.date && !lastMove.when ? (Date.now() - lastMove.date) < 7 * 864e5 : daysAgo(lastMove.when) <= 7) : false,
    travelers: Math.max(travelers, 1),
  };
}

async function loadLive() {
  const [companions, stops] = await Promise.all([queryAll('Companions'), queryAll('CompanionStops')]);
  const byNumber = {};
  for (const s of stops) (byNumber[cleanNumber(s.companionNumber)] ||= []).push(s);
  return companions.map((c) => liveCompanion(c, byNumber[cleanNumber(c.number)] || []));
}

// ── PREVIEW: the bundled sample data plus what was done in this browser ──────────────────
let sample = null;
const previewKey = 'herd.preview.v1';
const previewDb = () => readJSON(local, previewKey, { holds: {}, stops: {}, companions: {}, chats: {}, reports: [] });
const savePreviewDb = (db) => writeJSON(local, previewKey, db);
const previewPhotos = () => readJSON(session, 'herd.preview.photos', {});

function previewStop(s) {
  return {
    kind: s.kind || 'left', city: s.city || '', place: s.place || null,
    latitude: Number(s.latitude) || 0, longitude: Number(s.longitude) || 0,
    byName: s.byName || null, chapter: s.chapter || null,
    photo: s.photo ? (previewPhotos()[s.photo] || memoryPhotos[s.photo] || null) : null,
    wishPhoto: s.wishPhoto ? (previewPhotos()[s.wishPhoto] || memoryPhotos[s.wishPhoto] || null) : null,
    photoApproved: !!s.photoApproved,
    when: s.createdAt ? relativeTime(s.createdAt) : (s.whenText || ''),
    date: s.createdAt ? new Date(s.createdAt) : null,
  };
}

function buildPreview() {
  const db = previewDb();
  const list = sample.companions.map((raw) => {
    const n = cleanNumber(raw.number);
    const over = db.companions[n] || {};
    const added = db.stops[n] || [];
    const stops = [...raw.stops, ...added].map(previewStop);
    const lastAdded = added[added.length - 1];
    return {
      number: raw.number,
      name: raw.name || null,
      status: over.status || raw.status,
      isOriginal: !!raw.isOriginal,
      wish: over.wish ?? raw.wish,
      wishGranted: over.wishGranted ?? !!raw.wishGranted,
      blurb: raw.blurb || 'A short blurb about this Companion, written by The Herd.',
      originStory: raw.originStory || 'Their origin story, written by The Herd.',
      profilePhoto: null,
      glaze: raw.glaze, accent: raw.accent, blob: raw.blob,
      stops,
      lastMoved: lastAdded ? relativeTime(lastAdded.createdAt) : raw.lastMoved,
      movedThisWeek: lastAdded ? true : !!raw.movedThisWeek,
      travelers: (raw.travelers || 1) + added.filter((s) => s.kind !== 'found').length,
    };
  });
  const chats = {};
  for (const [n, msgs] of Object.entries(sample.chats || {})) chats[cleanNumber(n)] = msgs.map((m) => ({ ...m }));
  for (const [n, msgs] of Object.entries(db.chats)) (chats[n] ||= []).push(...msgs);
  return { list, chats };
}

async function loadSample() {
  if (!sample) {
    const res = await fetch(asset('data/sample.json'));
    sample = await res.json();
  }
  const { list, chats } = buildPreview();
  state.companions = list;
  state.chats = chats;
}

// ── Loading ─────────────────────────────────────────────────────────────────────────────
/**
 * True when the Wix checker answers. Before the site is published the lists may be readable but
 * the checker doesn't exist yet, so writes would fail: then the site stays in preview.
 * herdMine with no session answers 400 { field: 'session' } when the checker is live.
 */
export async function checkerIsLive() {
  try {
    const res = await Promise.race([
      fetch(CHECKER + 'herdMine', { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: '{}' }),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 6000)),
    ]);
    if (res.status !== 400) return false;
    const json = await res.json();
    return !!json && json.field === 'session';
  } catch (e) {
    return false;
  }
}

export async function load() {
  if (!forcePreview) {
    try {
      const [list, live] = await Promise.race([
        Promise.all([loadLive(), checkerIsLive()]),
        new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 8000)),
      ]);
      if (!live) throw new Error('the checker isn’t answering yet');
      state.mode = 'live';
      state.companions = list;
      return state;
    } catch (e) {
      console.info('Live data unavailable, using the preview data:', e.message);
    }
  }
  state.mode = 'preview';
  await loadSample();
  return state;
}

/** Re-reads the data after a change (keeps the same mode). */
export async function refresh() {
  if (state.mode === 'preview') { await loadSample(); return; }
  try { state.companions = await loadLive(); state.chats = {}; } catch (e) { /* keep what we have */ }
}

export function companion(number) {
  const n = cleanNumber(number);
  if (!n) return null;
  return state.companions.find((c) => cleanNumber(c.number) === n) || null;
}

/** Traveler chat for one Companion (hidden messages are never shown). */
export async function chatFor(number) {
  const n = cleanNumber(number);
  if (state.mode === 'preview') return state.chats[n] || [];
  if (state.chats[n]) return state.chats[n];
  try {
    const c = companion(n);
    const items = await queryAll('CompanionChat', { companionNumber: c ? c.number : number });
    const sorted = items
      .filter((m) => !m.hidden)
      .sort((a, b) => (dateOf(a._createdDate)?.getTime() || 0) - (dateOf(b._createdDate)?.getTime() || 0));
    state.chats[n] = sorted.map((m) => ({ author: m.author, message: m.message, when: dateOf(m._createdDate) ? relativeTime(dateOf(m._createdDate)) : '' }));
  } catch (e) {
    state.chats[n] = [];
  }
  return state.chats[n];
}

// ── Writing: the Wix checker (live) or the same rules in the browser (preview) ─────────────
/** Sends one request. Always resolves to { ok, status, field?, message?, ...data }. */
export async function send(name, body) {
  if (state.mode === 'preview') {
    await new Promise((r) => setTimeout(r, 250));
    let out;
    try {
      out = await previewServer[name](body);
    } catch (e) {
      console.error(e);
      out = { status: 500, body: { ok: false, message: 'Something went wrong on our side. Please try again in a minute.' } };
    }
    if (out.status === 200) await loadSample();
    return { status: out.status, ...out.body };
  }
  try {
    const res = await fetch(CHECKER + name, { method: 'POST', headers: { 'Content-Type': 'text/plain' }, body: JSON.stringify(body) });
    let json = {};
    try { json = await res.json(); } catch (e) { /* not JSON */ }
    if (res.status === 200 && json.ok !== false) {
      if (!/^herd(SignIn|Mine|Follow|SignOut|ForgetMe)/.test(name)) await refresh(); // sign-in calls don't change the map
      return { ...json, ok: true, status: 200 };
    }
    if (res.status === 400) return { ok: false, status: 400, field: json.field || null, message: json.message || 'Something was missing. Please try again.' };
    return { ok: false, status: res.status, message: json.message || 'Something went wrong on our side. Please try again in a minute.' };
  } catch (e) {
    return { ok: false, status: 0, message: 'We couldn’t reach The Herd. Check your connection and try again.' };
  }
}

// The preview "checker": the same rules and order as wix/backend/handlers.src.js.
const memoryPhotos = {};
const ok = (body) => ({ status: 200, body: { ok: true, ...body } });
const problem = (message, field) => ({ status: 400, body: { ok: false, field: field || null, message } });
const isNumber = (v) => typeof v === 'number' && Number.isFinite(v);
function randomToken() {
  const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
  let out = '';
  for (let i = 0; i < 32; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}
function sampleCompanion(number) {
  const n = cleanNumber(number);
  const raw = n ? sample.companions.find((c) => cleanNumber(c.number) === n) : null;
  if (!raw) return null;
  return companion(raw.number) || null;
}
function savePreviewPhoto(photo) {
  if (!photo || typeof photo.base64 !== 'string' || !photo.base64) return null;
  if (photo.base64.length * 0.75 > 8 * 1024 * 1024) return null;
  const id = 'p' + Date.now() + Math.random().toString(36).slice(2, 7);
  const url = 'data:' + (photo.mimeType || 'image/jpeg') + ';base64,' + photo.base64;
  memoryPhotos[id] = url;
  const all = previewPhotos();
  all[id] = url;
  writeJSON(session, 'herd.preview.photos', all);
  return id;
}

function previewTraveler(db, sessionValue) {
  if (!sessionValue || typeof sessionValue !== 'string') return null;
  return Object.values(db.travelers || {}).find((x) => (x.sessions || []).includes(sessionValue)) || null;
}
function previewProfile(db, traveler) {
  const holds = [];
  const wishTokens = {};
  for (const [n, h] of Object.entries(db.holds)) {
    if (h.travelerId !== traveler.id) continue;
    const number = (sample.companions.find((x) => cleanNumber(x.number) === n) || {}).number || n;
    if (h.wishToken) wishTokens[number] = h.wishToken;
    if (h.active) holds.push({ number, token: h.token, city: h.city || '', date: h.createdAt || null });
  }
  const journal = [];
  for (const [n, list] of Object.entries(db.stops)) {
    const number = (sample.companions.find((x) => cleanNumber(x.number) === n) || {}).number || n;
    for (const st of list) if (st.travelerId === traveler.id) journal.push({ number, kind: st.kind, city: st.city, date: st.createdAt, wishGranted: !!st.wishPhoto });
  }
  return { email: traveler.email, nickname: traveler.nickname || '', following: traveler.following || [], holds, wishTokens, journal };
}

const previewServer = {
  async herdFind(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that number. Check their bottom and try again.', 'number');
    if (c.status === 'retired') return problem('This Companion has retired, so their journey is complete.', 'number');
    const raw = sample.companions.find((x) => cleanNumber(x.number) === cleanNumber(c.number));
    if (!raw.code || cleanFindCode(b.code) !== cleanFindCode(raw.code)) {
      return problem('That code doesn’t match #' + c.number + '. Check the letters under their number.', 'code');
    }
    const db = previewDb();
    const n = cleanNumber(c.number);
    const hold = db.holds[n] && db.holds[n].active ? db.holds[n] : null;
    if (hold && b.holdToken && hold.token === b.holdToken) {
      return problem('You’ve already logged finding #' + c.number + '. When you’re ready, pass them on.', 'number');
    }
    const nicknameError = checkNickname(b.nickname);
    if (nicknameError) return problem(nicknameError, 'nickname');
    if (!b.city || !isNumber(b.latitude) || !isNumber(b.longitude)) return problem('We need your location to log a find.', 'where');
    if (checkPublicText(b.city, 80)) return problem('We couldn’t read your location. Please refresh it and try again.', 'where');
    const tokenValue = randomToken();
    const traveler = previewTraveler(db, b.session);
    db.holds[n] = {
      token: tokenValue, active: true, byName: String(b.nickname).trim(), foundLatitude: b.latitude, foundLongitude: b.longitude,
      wishToken: null, travelerId: traveler ? traveler.id : null, city: String(b.city).trim(), createdAt: new Date().toISOString(),
    };
    (db.stops[n] ||= []).push({
      kind: 'found', city: String(b.city).trim(), latitude: blur(b.latitude, false), longitude: blur(b.longitude, false),
      byName: String(b.nickname).trim(), createdAt: new Date().toISOString(), travelerId: traveler ? traveler.id : null,
    });
    if (traveler && !traveler.nickname) traveler.nickname = String(b.nickname).trim();
    db.companions[n] = { ...(db.companions[n] || {}), status: 'moving' };
    savePreviewDb(db);
    return ok({ number: c.number, holdToken: tokenValue });
  },

  async herdPassOn(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that Companion.', 'number');
    const db = previewDb();
    const n = cleanNumber(c.number);
    const hold = db.holds[n] && db.holds[n].active ? db.holds[n] : null;
    if (!hold || !b.holdToken || hold.token !== b.holdToken) {
      return problem('Every Companion’s journey goes found, then left, then found again. Log that you found #' + c.number + ' before you pass them on.', 'number');
    }
    const handedOn = b.handedOn === true;
    if (!b.city || !isNumber(b.latitude) || !isNumber(b.longitude)) return problem('We need your location to pass them on.', 'where');
    if (!handedOn) {
      const m = milesBetween(hold.foundLatitude, hold.foundLongitude, b.latitude, b.longitude);
      if (m < minMilesToLeave) {
        return problem('To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re about ' + Math.round(m) + ' miles away. (Handing them to someone is fine anywhere.)', 'where');
      }
      const hintError = checkHint(b.hint);
      if (hintError) return problem(hintError, 'hint');
    }
    const chapterError = b.chapter ? checkPublicText(b.chapter, 500) : null;
    if (chapterError) return problem(chapterError, 'chapter');
    const nicknameError = checkNickname(b.nickname);
    if (nicknameError) return problem(nicknameError, 'nickname');
    if (!b.photo || !b.photo.base64) return problem('Please add a photo.', 'photo');
    if (b.wishGranted && !(b.wishPhoto && b.wishPhoto.base64)) return problem('Please add a photo of the wish coming true.', 'wishPhoto');
    const photo = savePreviewPhoto(b.photo);
    if (!photo) return problem('That photo couldn’t be used. Please try a different one (under 8 MB).', 'photo');
    const wishPhoto = b.wishGranted ? savePreviewPhoto(b.wishPhoto) : null;
    if (b.wishGranted && !wishPhoto) return problem('That wish photo couldn’t be used. Please try a different one.', 'wishPhoto');
    const stop = {
      kind: handedOn ? 'passedOn' : 'left', city: String(b.city).trim(),
      latitude: blur(b.latitude, !handedOn), longitude: blur(b.longitude, !handedOn),
      byName: String(b.nickname).trim(), photo, photoApproved: false, createdAt: new Date().toISOString(),
      travelerId: hold.travelerId || null,
    };
    const passer = previewTraveler(db, b.session);
    if (passer) stop.travelerId = passer.id;
    if (!handedOn) stop.place = String(b.hint).trim();
    if (b.chapter) stop.chapter = String(b.chapter).trim();
    if (wishPhoto) stop.wishPhoto = wishPhoto;
    (db.stops[n] ||= []).push(stop);
    const wishToken = b.wishGranted ? randomToken() : null;
    db.holds[n] = { ...hold, active: false, wishToken };
    db.companions[n] = { ...(db.companions[n] || {}), status: handedOn ? 'moving' : 'waiting', wishGranted: b.wishGranted ? true : c.wishGranted };
    savePreviewDb(db);
    return ok({ number: c.number, wishToken });
  },

  async herdWish(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that Companion.', 'number');
    const db = previewDb();
    const n = cleanNumber(c.number);
    const hold = db.holds[n];
    if (!b.wishToken || !hold || hold.wishToken !== b.wishToken) return problem('Only the traveler who granted their wish can choose the next one.', 'wish');
    let wish = String(b.wish || '').trim();
    if (/^i want to /i.test(wish)) wish = wish.slice(10);
    wish = wish.replace(/\.$/, '');
    const wishError = checkWish(wish);
    if (wishError) return problem(wishError, 'wish');
    db.companions[n] = { ...(db.companions[n] || {}), wish, wishGranted: false };
    db.holds[n] = { ...hold, wishToken: null };
    savePreviewDb(db);
    return ok({});
  },

  async herdChat(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that Companion.', 'number');
    const authorError = checkNickname(b.author);
    if (authorError) return problem(authorError, 'author');
    const text = String(b.message || '').trim();
    if (!text) return problem('Please write a message.', 'message');
    if (mentionsSelfHarm(text)) return problem(selfHarmMessage, 'message');
    if (containsBlockedLanguage(text)) return problem('Please keep it kind. Some words aren’t allowed here.', 'message');
    if (text.length > 500) return problem('Please keep it under 500 characters.', 'message');
    const db = previewDb();
    const message = hideContactDetails(text);
    (db.chats[cleanNumber(c.number)] ||= []).push({ author: String(b.author).trim(), message, mine: true, when: 'Just now' });
    savePreviewDb(db);
    return ok({ id: randomToken(), message });
  },

  async herdReport(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that Companion.', 'number');
    if (!['broke', 'chipped', 'lost'].includes(b.what)) return problem('Please choose what happened.', 'what');
    const placeError = checkPlaceFormat(b.city);
    if (placeError) return problem(placeError, 'where');
    const noteError = b.note ? checkPublicText(b.note, 500) : null;
    if (noteError) return problem(noteError, 'note');
    if (b.email && !isEmail(b.email)) return problem('Please enter a valid email, or leave it empty.', 'email');
    const db = previewDb();
    db.reports.push({ ...b, createdAt: new Date().toISOString() });
    if (b.what !== 'chipped') db.companions[cleanNumber(c.number)] = { ...(db.companions[cleanNumber(c.number)] || {}), status: 'retired' };
    savePreviewDb(db);
    return ok({});
  },

  // ── Optional sign-in (same rules as the Wix checker; the code is shown instead of emailed) ──
  async herdSignInStart(b) {
    const email = String((b && b.email) || '').trim().toLowerCase();
    if (!isEmail(email)) return problem('Please enter a valid email.', 'email');
    const db = previewDb();
    db.travelers ||= {};
    let traveler = db.travelers[email];
    const now = Date.now();
    if (traveler && traveler.codeSentAt && now - traveler.codeSentAt < 60 * 1000) {
      return problem('We just sent you a code. Please wait a minute before asking for another one.', 'email');
    }
    const code = String(Math.floor(Math.random() * 1000000)).padStart(6, '0');
    traveler = traveler || { id: 't' + randomToken().slice(0, 10), email, following: [], sessions: [], nickname: '' };
    Object.assign(traveler, { code, codeExpires: now + 15 * 60 * 1000, codeTries: 0, codeSentAt: now });
    db.travelers[email] = traveler;
    savePreviewDb(db);
    return ok({ previewCode: code });
  },

  async herdSignInVerify(b) {
    if (!b) return problem('Something was missing. Please try again.');
    const email = String(b.email || '').trim().toLowerCase();
    const db = previewDb();
    const traveler = (db.travelers || {})[email];
    if (!traveler || !traveler.code) return problem('Please ask for a sign-in code first.', 'code');
    if (Date.now() > traveler.codeExpires) return problem('That code has expired. Please ask for a new one.', 'code');
    if ((traveler.codeTries || 0) >= 5) return problem('Too many tries. Please ask for a new code.', 'code');
    const code = String(b.code || '').replace(/\D/g, '');
    if (code !== traveler.code) {
      traveler.codeTries = (traveler.codeTries || 0) + 1;
      savePreviewDb(db);
      return problem('That code isn’t right. Check the email and try again.', 'code');
    }
    const session = randomToken();
    const extra = (Array.isArray(b.following) ? b.following : []).map(String).filter((x) => /^\d{1,4}$/.test(x));
    Object.assign(traveler, {
      code: null, codeExpires: null, codeTries: 0,
      sessions: [...(traveler.sessions || []).slice(-9), session],
      following: [...new Set([...(traveler.following || []), ...extra])],
      nickname: traveler.nickname || (b.nickname && !checkNickname(b.nickname) ? String(b.nickname).trim() : ''),
    });
    // Companions found on this device before signing in come along.
    for (const [number, tokenValue] of Object.entries(b.holds && typeof b.holds === 'object' ? b.holds : {})) {
      const hold = db.holds[cleanNumber(number)];
      if (hold && hold.token === String(tokenValue) && !hold.travelerId) {
        hold.travelerId = traveler.id;
      }
    }
    savePreviewDb(db);
    return ok({ session, profile: previewProfile(db, traveler) });
  },

  async herdMine(b) {
    const db = previewDb();
    const traveler = previewTraveler(db, b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    return ok({ profile: previewProfile(db, traveler) });
  },

  async herdFollow(b) {
    const db = previewDb();
    const traveler = previewTraveler(db, b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    const c = sampleCompanion(b.number);
    if (!c) return problem('We couldn’t find that Companion.', 'number');
    const set = new Set(traveler.following || []);
    if (b.on) set.add(c.number); else set.delete(c.number);
    traveler.following = [...set];
    savePreviewDb(db);
    return ok({ following: traveler.following });
  },

  async herdSignOut(b) {
    const db = previewDb();
    const traveler = previewTraveler(db, b && b.session);
    if (traveler) { traveler.sessions = traveler.sessions.filter((x) => x !== b.session); savePreviewDb(db); }
    return ok({});
  },

  async herdForgetMe(b) {
    const db = previewDb();
    const traveler = previewTraveler(db, b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    for (const h of Object.values(db.holds)) if (h.travelerId === traveler.id) h.travelerId = null;
    for (const list of Object.values(db.stops)) for (const st of list) if (st.travelerId === traveler.id) st.travelerId = null;
    delete db.travelers[traveler.email];
    savePreviewDb(db);
    return ok({});
  },
};

/** Clears everything the preview saved in this browser. */
export function resetPreview() {
  try { local.removeItem(previewKey); local.removeItem('herd.mine.preview'); local.removeItem('herd.session.preview'); session.removeItem('herd.preview.photos'); session.removeItem('herd.unlocked.preview'); } catch (e) { /* ignore */ }
}

// ── What this browser knows about you: what you hold, your wishes, your journal ───────────
const mineKey = () => 'herd.mine.' + (state.mode === 'live' ? 'live' : 'preview');
const emptyMine = () => ({ nickname: '', following: [], holds: {}, wishTokens: {}, journal: [], remoteJournal: [], remoteWishKeys: [], codeTries: { wrong: 0, lockedUntil: 0 } });
export function mine() { return { ...emptyMine(), ...readJSON(local, mineKey(), {}) }; }
export function updateMine(fn) { const m = mine(); fn(m); writeJSON(local, mineKey(), m); return m; }

export const holdFor = (number) => mine().holds[cleanNumber(number)] || null;
export const isHolding = (number) => !!holdFor(number);
export const wishTokenFor = (number) => mine().wishTokens[cleanNumber(number)] || null;
export const isFollowing = (number) => mine().following.includes(cleanNumber(number));
export function toggleFollow(number) {
  const n = cleanNumber(number);
  const on = !mine().following.includes(n);
  updateMine((m) => { m.following = on ? [...m.following, n] : m.following.filter((x) => x !== n); });
  const acct = account();
  if (acct) {
    // Signed in: the follow is kept with the traveler's sign-in too (it works locally either way).
    send('herdFollow', { session: acct.session, number, on }).then((res) => {
      if (res.ok && Array.isArray(res.following)) updateMine((m) => { m.following = res.following.map(cleanNumber); });
      else if (res.field === 'session') dropAccount();
    });
  }
}

// ── Optional email sign-in ──────────────────────────────────────────────────────────────
// Nothing needs it. When signed in, the Passport, Companions in Your Care, follows and nickname
// follow the traveler to every device. Without it, everything stays in this browser, as before.
const accountKey = () => 'herd.session.' + (state.mode === 'live' ? 'live' : 'preview');
/** { session, email } when signed in on this browser, otherwise null. */
export const account = () => readJSON(local, accountKey(), null);
/** Adds the session to a find or pass-on when signed in. */
export const withSession = (body) => { const a = account(); return a ? { ...body, session: a.session } : body; };

function applyProfile(profile) {
  updateMine((m) => {
    const holds = {};
    // Holds never linked to the sign-in stay; the server's list is the truth for the rest.
    for (const [n, h] of Object.entries(m.holds)) if (!h.claimed) holds[n] = h;
    for (const h of profile.holds || []) {
      const n = cleanNumber(h.number);
      const before = m.holds[n] && m.holds[n].token === h.token ? m.holds[n] : {};
      holds[n] = { ...before, token: h.token, number: String(h.number), city: h.city || before.city || '', date: h.date || before.date || null, claimed: true };
    }
    m.holds = holds;
    for (const k of m.remoteWishKeys || []) delete m.wishTokens[k];
    m.remoteWishKeys = [];
    for (const [num, tok] of Object.entries(profile.wishTokens || {})) { m.wishTokens[cleanNumber(num)] = tok; m.remoteWishKeys.push(cleanNumber(num)); }
    m.following = [...new Set([...(profile.following || []).map(cleanNumber)])];
    if (!m.nickname && profile.nickname) m.nickname = profile.nickname;
    m.remoteJournal = Array.isArray(profile.journal) ? profile.journal : [];
  });
}

/** Signed out (or the sign-in ended): the account's data leaves this browser; local finds stay. */
function dropAccount() {
  try { local.removeItem(accountKey()); } catch (e) { /* ignore */ }
  delete memory[accountKey()];
  updateMine((m) => {
    // Companions found on this device stay (their hold token still works); ones that only came
    // from the sign-in leave with it.
    for (const [n, h] of Object.entries(m.holds)) {
      if (!h.claimed) continue;
      if (Number.isFinite(h.foundLatitude)) h.claimed = false; else delete m.holds[n];
    }
    for (const k of m.remoteWishKeys || []) delete m.wishTokens[k];
    m.remoteWishKeys = [];
    m.remoteJournal = [];
  });
}

/** On load: refresh what the signed-in traveler has. Problems never block anything. */
export async function syncAccount() {
  const acct = account();
  if (!acct) return;
  const res = await Promise.race([send('herdMine', { session: acct.session }), new Promise((r) => setTimeout(() => r({ ok: false }), 6000))]);
  if (res.ok && res.profile) applyProfile(res.profile);
  else if (res.field === 'session') dropAccount();
}

export const signInStart = (email) => send('herdSignInStart', { email: String(email || '').trim() });

export async function signInVerify(email, code) {
  const m = mine();
  const holds = {};
  for (const [n, h] of Object.entries(m.holds)) if (h.token) holds[n] = h.token;
  const res = await send('herdSignInVerify', { email: String(email || '').trim(), code, holds, following: m.following, nickname: m.nickname });
  if (!res.ok) return res;
  writeJSON(local, accountKey(), { session: res.session, email: res.profile?.email || String(email).trim().toLowerCase() });
  // Holds sent along are now linked to the sign-in.
  updateMine((x) => { for (const n of Object.keys(holds)) if (x.holds[n]) x.holds[n].claimed = true; });
  applyProfile(res.profile || {});
  return res;
}

export async function signOut() {
  const acct = account();
  if (acct) await send('herdSignOut', { session: acct.session });
  dropAccount();
}

/** "Delete my data": removes the email and sign-in from The Herd. Chapters stay. */
export async function forgetMe() {
  const acct = account();
  if (!acct) return { ok: true };
  const res = await send('herdForgetMe', { session: acct.session });
  if (res.ok || res.field === 'session') { dropAccount(); return { ok: true }; }
  return res;
}

/** Your travels: this browser's journal plus the signed-in traveler's, without doubles. */
export function journal() {
  const m = mine();
  const out = [];
  const seen = new Set();
  const day = (d) => { const x = new Date(d); return Number.isNaN(x.getTime()) ? '' : x.toISOString().slice(0, 10); };
  const add = (j) => {
    const key = [cleanNumber(j.number), j.type, j.type === 'wish' ? '' : String(j.city || '').toLowerCase(), day(j.date)].join('|');
    if (seen.has(key)) return;
    seen.add(key);
    out.push(j);
  };
  m.journal.forEach(add);
  for (const r of m.remoteJournal || []) {
    add({ type: r.kind, number: String(r.number), city: r.city, date: r.date, remote: true });
    if (r.wishGranted) add({ type: 'wish', number: String(r.number), city: r.city, date: r.date, remote: true });
  }
  return out.sort((a, b) => (new Date(a.date).getTime() || 0) - (new Date(b.date).getTime() || 0));
}

// Find codes from a QR link or typed: "unlocked" until the find is logged (each scan logs one find).
const unlockedKey = () => 'herd.unlocked.' + (state.mode === 'live' ? 'live' : 'preview');
export const unlockedCode = (number) => readJSON(session, unlockedKey(), {})[cleanNumber(number)] || null;
export function setUnlocked(number, code) {
  const all = readJSON(session, unlockedKey(), {});
  if (code) all[cleanNumber(number)] = cleanFindCode(code); else delete all[cleanNumber(number)];
  writeJSON(session, unlockedKey(), all);
}

/**
 * Checks a find code with the checker without logging anything: the checker looks at the code
 * before the nickname, so "please add a name" means the code is right. After 5 wrong codes,
 * typing codes pauses for 10 minutes, like the app.
 * Returns { result: 'right' | 'wrong' | 'tooManyTries' | 'problem', message? }.
 */
export async function checkFindCode(number, code) {
  const m = mine();
  if (m.codeTries.lockedUntil > Date.now()) return { result: 'tooManyTries' };
  const res = await send('herdFind', { number, code: cleanFindCode(code), holdToken: holdFor(number)?.token });
  if (!res.ok && res.field === 'code') {
    const tries = updateMine((x) => {
      x.codeTries.wrong = (x.codeTries.wrong || 0) + 1;
      if (x.codeTries.wrong >= 5) { x.codeTries.wrong = 0; x.codeTries.lockedUntil = Date.now() + 10 * 60000; }
    });
    return { result: tries.codeTries.lockedUntil > Date.now() ? 'tooManyTries' : 'wrong', message: res.message };
  }
  if (!res.ok && (res.field === 'nickname' || res.field === 'where')) {
    updateMine((x) => { x.codeTries.wrong = 0; });
    return { result: 'right' };
  }
  return { result: 'problem', message: res.message, field: res.field };
}
