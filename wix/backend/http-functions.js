// Built by tool/build_wix_backend.py from shared/rules.js and wix/backend/handlers.src.js.
// Paste this whole file into your Wix site as backend/http-functions.js (see wix/README.md).

import { ok, badRequest, serverError } from 'wix-http-functions';
import wixData from 'wix-data';
import { mediaManager } from 'wix-media-backend';
import { contacts, triggeredEmails } from 'wix-crm-backend';
import crypto from 'crypto';

// ── Rules (same as the app and the website) ──
const blockedWords = new Set([
  // Swearing
  'fuck', 'fucks', 'fucker', 'fuckers', 'fucking', 'fucked', 'fck', 'fuk', 'fuq', 'fking', 'fkn', 'wtf', 'stfu',
  'shit', 'shits', 'shitty', 'shite', 'bullshit', 'sht',
  'bitch', 'bitches', 'bitchy', 'btch',
  'cunt', 'cunts', 'twat', 'twats', 'prick', 'pricks', 'wanker', 'wankers', 'bollocks',
  'ass', 'asses', 'asshole', 'assholes', 'arse', 'arsehole', 'jackass', 'dumbass', 'badass',
  'dick', 'dicks', 'dickhead', 'cock', 'cocks', 'pussy', 'pussies', 'bastard', 'bastards',
  'motherfucker', 'motherfucking', 'mf', 'mofo', 'piss', 'pissed', 'crap', 'douche', 'douchebag',
  // Sexual or gross
  'sex', 'sexy', 'porn', 'porno', 'nude', 'nudes', 'naked', 'boob', 'boobs', 'tits', 'titties', 'penis', 'vagina',
  'dildo', 'cum', 'jizz', 'horny', 'blowjob', 'handjob', 'orgasm', 'masturbate', 'erection', 'anal', 'milf',
  'poop', 'vomit', 'puke', 'diarrhea', 'semen', 'genitals',
  // Hateful
  'nazi', 'nazis', 'hitler', 'heil', 'kkk',
  // Harm
  'kys', 'suicide', 'rape', 'raped', 'rapist', 'molest', 'pedo', 'pedophile', 'terrorist', 'gore', 'murder', 'murdered',
]);

const blockedStarts = [
  'fuck', 'shit', 'bitch', 'cunt', 'whore', 'slut', 'motherf', 'nigg', 'nigga', 'niga', 'fagg', 'faggot', 'retard',
  'spic', 'chink', 'kike', 'wetback', 'tranny', 'dyke', 'gook', 'beaner', 'raghead', 'towelhead', 'coon', 'pornh',
  'xxx', 'dickh', 'cocks', 'pussi', 'asshol',
];

const blockedPhrases = ['kill yourself', 'kill your self', 'kill myself', 'go die', 'hope you die', 'blow job', 'hand job', 'son of a bitch'];

const selfHarmPhrases = [
  'want to die', 'wanna die', 'wish i was dead', 'wish i were dead', 'kill myself', 'kill my self', 'end my life',
  'take my life', 'suicide', 'suicidal', 'hurt myself', 'harm myself', 'cut myself', 'self harm', 'not be alive',
];

const harmfulWishWords = new Set([
  'die', 'dies', 'dying', 'kill', 'kills', 'killing', 'murder', 'suicide', 'suicidal', 'hurt', 'harm', 'shoot', 'stab',
  'bomb', 'gun', 'guns', 'weapon', 'weapons', 'poison', 'overdose', 'drug', 'drugs', 'steal', 'rob', 'punch', 'fight',
  'beat', 'drown', 'hang', 'blood', 'torture', 'attack',
]);

const leet = { '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '8': 'b', '@': 'a', '$': 's', '!': 'i', '|': 'l', '+': 't' };

const selfHarmMessage =
  'Please choose different words. If you’re going through a hard time, you’re not alone: in the US you can call or text 988 any time to talk to someone.';

function clean(text) {
  return [...String(text).toLowerCase()].map((ch) => leet[ch] ?? ch).join('');
}

/** "fuuuuck" → "fuck" */
function squash(word) {
  return word.replace(/(.)\1{2,}/g, '$1');
}

function isBlockedWord(word) {
  if (!word) return false;
  const forms = new Set([word, squash(word), word.replace(/(.)\1+/g, '$1')]);
  for (const w of forms) {
    if (blockedWords.has(w)) return true;
    if (blockedStarts.some((s) => w.startsWith(s))) return true;
  }
  return false;
}

function spacedWords(text) {
  return ' ' + clean(text).replace(/[^a-z ]+/g, ' ').replace(/\s+/g, ' ').trim() + ' ';
}

function containsBlockedLanguage(text) {
  const cleaned = clean(text);
  const words = cleaned.split(/[^a-z]+/).filter(Boolean);
  if (words.some(isBlockedWord)) return true;
  const spaced = cleaned.replace(/[^a-z ]+/g, ' ').replace(/\s+/g, ' ');
  if (blockedPhrases.some((p) => spaced.includes(p))) return true;
  // Runs of single letters: "f u c k", "f.u.c.k"
  let run = '';
  for (const w of [...words, '']) {
    if (w.length === 1) {
      run += w;
    } else {
      if (run.length >= 3 && isBlockedWord(run)) return true;
      run = '';
    }
  }
  return false;
}

function mentionsSelfHarm(text) {
  const spaced = spacedWords(text);
  return selfHarmPhrases.some((p) => spaced.includes(' ' + p + ' '));
}

const linkRe = /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|io|co|app|xyz|info|biz|ly|me|gg)\b)/i;
const emailRe = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const phoneRe = /\+?\d[\d\s().-]{7,}\d/;

/** Text other people will see. Returns a friendly message, or null if it's fine. */
function checkPublicText(text, maxLength) {
  const t = String(text ?? '').trim();
  if (maxLength && t.length > maxLength) return `Please keep it under ${maxLength} characters.`;
  if (mentionsSelfHarm(t)) return selfHarmMessage;
  if (containsBlockedLanguage(t)) return 'Please keep it kind. Some words aren’t allowed here.';
  if (linkRe.test(t)) return 'Links can’t be added here.';
  if (emailRe.test(t) || phoneRe.test(t)) return 'Please don’t share phone numbers, emails or addresses.';
  return null;
}

function checkNickname(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add a name or nickname.';
  if (t.length < 2) return 'Please use at least 2 letters.';
  if (!/[A-Za-zÀ-ÿЀ-ӿ぀-ヿ一-鿿]/.test(t)) return 'Please use letters in your nickname.';
  return checkPublicText(t, 30);
}

/** A wish (what comes after "I want to"). */
function checkWish(text) {
  if (mentionsSelfHarm('I want to ' + text)) return selfHarmMessage;
  const general = checkPublicText(text, 50);
  if (general) return general;
  const words = spacedWords(text).trim().split(' ');
  if (words.some((w) => harmfulWishWords.has(w) || harmfulWishWords.has(squash(w)))) {
    return 'Wishes need to be kind and safe for the Companion and the next traveler. Please try different words.';
  }
  return null;
}

/** The hint for where a Companion was left: required, kind, no street address. */
function checkHint(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add a hint so the next person can find them.';
  if (/\d+\s+\w+\s+(st|street|ave|avenue|rd|road|blvd|boulevard|ln|lane|dr|drive|way|ct|court|pl|place)\b/i.test(t)) {
    return 'Please describe the spot instead of giving a street address.';
  }
  return checkPublicText(t, 120);
}

/** A typed place for "something happened": "City, State" or "City, Country". */
function checkPlaceFormat(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add the city and state or country.';
  if (/\d/.test(t)) return 'Just the city and state or country, please. No street addresses.';
  const parts = t.split(',').map((p) => p.trim()).filter(Boolean);
  if (parts.length < 2) return 'Please write it as City, State (or City, Country). For example: Santa Fe, NM';
  if (parts.length > 3) return 'Just the city and state or country, please.';
  if (!parts.every((p) => /^[A-Za-zÀ-ÖØ-öø-ÿĀ-žḀ-ỿ .'’-]{2,60}$/.test(p))) return 'Please use only letters for the city and state or country.';
  if (containsBlockedLanguage(t)) return 'Please enter a real place.';
  return null;
}

function isEmail(text) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(String(text ?? '').trim());
}

/** Chat messages: contact details are hidden instead of refused. */
function hideContactDetails(text) {
  return String(text)
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[hidden]')
    .replace(/\+?\d[\d\s().-]{7,}\d/g, '[hidden]');
}

/** "07", "7" and "No. 7" are the same Companion. */
function cleanNumber(raw) {
  const digits = String(raw ?? '').replace(/\D/g, '');
  const trimmed = digits.replace(/^0+/, '');
  return trimmed || (digits ? '0' : '');
}

function cleanFindCode(typed) {
  return String(typed ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** Miles between two map points. */
function milesBetween(lat1, lng1, lat2, lng2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 3958.8 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Map dots: the exact spot (about 1 m), or, when the traveler prefers (and for hand-offs), the
 *  general area: rounded to a 0.05° grid, so the dot is always within about 3 miles. */
function blur(value, exact) {
  const v = Number(value);
  return exact ? Number(v.toFixed(5)) : Number((Math.round(v * 20) / 20).toFixed(2));
}

const minMilesToLeave = 5;

// ── Herd Around the World: the checker on The Herd's Wix site ──────────────────────────
// Every find, pass-on, wish, chat message and report from the website or the app comes
// through here. Each is checked against the rules before it's saved to the CMS lists,
// and the find codes never leave Wix.
//
// Addresses (once the site is published):
//   https://www.theherdstudio.com/_functions/herdFind     and herdPassOn, herdWish, herdChat, herdReport
// Send a POST with a JSON body (Content-Type text/plain is fine, so browsers don't need a preflight).


const ADMIN = { suppressAuth: true };
const HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
};
const MAX_PHOTO_BYTES = 8 * 1024 * 1024;

function reply(body) {
  return ok({ headers: HEADERS, body });
}
/** A problem the person can fix: `field` says which box to mark in red. */
function problem(message, field) {
  return badRequest({ headers: HEADERS, body: { ok: false, field: field || null, message } });
}
function oops(err) {
  console.error(err);
  return serverError({ headers: HEADERS, body: { ok: false, message: 'Something went wrong on our side. Please try again in a minute.' } });
}

async function readBody(request) {
  try {
    return JSON.parse(await request.body.text());
  } catch (e) {
    return null;
  }
}

function randomToken() {
  return crypto.randomBytes(24).toString('hex');
}
function hash(text) {
  return crypto.createHash('sha256').update(String(text)).digest('hex');
}

/** The signed-in traveler for a session, or null (signing in is optional). */
async function travelerBySession(session) {
  if (!session || typeof session !== 'string') return null;
  const res = await wixData.query('CompanionTravelers').hasSome('sessions', [hash(session)]).find(ADMIN);
  return res.items[0] || null;
}

async function findCompanion(number) {
  const clean = cleanNumber(number);
  const res = await wixData.query('Companions').limit(1000).find(ADMIN);
  return res.items.find((c) => cleanNumber(c.number) === clean) || null;
}

async function activeHold(companionNumber) {
  const res = await wixData.query('CompanionHolds').eq('companionNumber', companionNumber).eq('active', true).find(ADMIN);
  return res.items[0] || null;
}

function isNumber(v) {
  return typeof v === 'number' && Number.isFinite(v);
}

async function savePhoto(photo, companionNumber, label) {
  if (!photo || typeof photo.base64 !== 'string') return null;
  const mimeType = ['image/jpeg', 'image/png', 'image/webp'].includes(photo.mimeType) ? photo.mimeType : 'image/jpeg';
  const buffer = Buffer.from(photo.base64, 'base64');
  if (buffer.length === 0 || buffer.length > MAX_PHOTO_BYTES) return null;
  const ext = mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg';
  const file = await mediaManager.upload('/Herd Around the World', buffer, `companion-${companionNumber}-${label}-${Date.now()}.${ext}`, {
    mediaOptions: { mimeType, mediaType: 'image' },
    metadataOptions: { isPrivate: false, isVisitorUpload: true },
  });
  return file.fileUrl;
}

// ── Found ───────────────────────────────────────────────────────────────────────────────
// { number, code, nickname, city, latitude, longitude, holdToken?, exactSpot? }
export async function post_herdFind(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that number. Check their bottom and try again.', 'number');
    if (companion.status === 'retired') return problem('This Companion has retired, so their journey is complete.', 'number');

    const codes = await wixData.query('CompanionFindCodes').eq('companionNumber', companion.number).find(ADMIN);
    const code = codes.items[0] && codes.items[0].code;
    if (!code || cleanFindCode(b.code) !== cleanFindCode(code)) {
      return problem('That code doesn’t match #' + companion.number + '. Check the letters under their number.', 'code');
    }

    const hold = await activeHold(companion.number);
    if (hold && b.holdToken && hold.token === b.holdToken) {
      return problem('You’ve already logged finding #' + companion.number + '. When you’re ready, pass them on.', 'number');
    }

    const nicknameError = checkNickname(b.nickname);
    if (nicknameError) return problem(nicknameError, 'nickname');
    if (!b.city || !isNumber(b.latitude) || !isNumber(b.longitude)) return problem('We need your location to log a find.', 'where');
    const cityError = checkPublicText(b.city, 80);
    if (cityError) return problem('We couldn’t read your location. Please refresh it and try again.', 'where');

    // Someone new found them, so any earlier "holding" ends (they can't be passed on twice).
    if (hold) await wixData.update('CompanionHolds', { ...hold, active: false }, ADMIN);

    const traveler = await travelerBySession(b.session);
    const token = randomToken();
    await wixData.insert('CompanionHolds', {
      companionNumber: companion.number,
      token,
      active: true,
      travelerId: traveler ? traveler._id : null,
      city: String(b.city).trim(),
      byName: String(b.nickname).trim(),
      foundLatitude: b.latitude,
      foundLongitude: b.longitude,
    }, ADMIN);
    await wixData.insert('CompanionStops', {
      companionNumber: companion.number,
      kind: 'found',
      city: String(b.city).trim(),
      // The exact spot unless the finder chose "general area" (exactSpot: false).
      latitude: blur(b.latitude, b.exactSpot !== false),
      longitude: blur(b.longitude, b.exactSpot !== false),
      byName: String(b.nickname).trim(),
      travelerId: traveler ? traveler._id : null,
    }, ADMIN);
    if (traveler && !traveler.nickname) await wixData.update('CompanionTravelers', { ...traveler, nickname: String(b.nickname).trim() }, ADMIN);
    await wixData.update('Companions', { ...companion, status: 'moving' }, ADMIN);
    return reply({ ok: true, number: companion.number, holdToken: token });
  } catch (err) {
    return oops(err);
  }
}

// ── Pass on ─────────────────────────────────────────────────────────────────────────────
// { number, holdToken, handedOn, city, latitude, longitude, hint, chapter, nickname,
//   photo: { base64, mimeType }, wishGranted, wishPhoto? }
export async function post_herdPassOn(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');

    const hold = await activeHold(companion.number);
    if (!hold || !b.holdToken || hold.token !== b.holdToken) {
      return problem('Every Companion’s journey goes found, then left, then found again. Log that you found #' + companion.number + ' before you pass them on.', 'number');
    }

    const handedOn = b.handedOn === true;
    if (!b.city || !isNumber(b.latitude) || !isNumber(b.longitude)) return problem('We need your location to pass them on.', 'where');
    if (!handedOn) {
      const miles = milesBetween(hold.foundLatitude, hold.foundLongitude, b.latitude, b.longitude);
      if (miles < minMilesToLeave) {
        return problem('To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re about ' + Math.round(miles) + ' miles away. (Handing them to someone is fine anywhere.)', 'where');
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

    const photo = await savePhoto(b.photo, companion.number, 'stop');
    if (!photo) return problem('That photo couldn’t be used. Please try a different one (under 8 MB).', 'photo');
    const wishPhoto = b.wishGranted ? await savePhoto(b.wishPhoto, companion.number, 'wish') : null;
    if (b.wishGranted && !wishPhoto) return problem('That wish photo couldn’t be used. Please try a different one.', 'wishPhoto');

    const stop = {
      companionNumber: companion.number,
      kind: handedOn ? 'passedOn' : 'left',
      city: String(b.city).trim(),
      latitude: blur(b.latitude, b.exactSpot !== false),
      longitude: blur(b.longitude, b.exactSpot !== false),
      byName: String(b.nickname).trim(),
      photo,
      photoApproved: false,
      travelerId: hold.travelerId || null,
    };
    const passer = await travelerBySession(b.session);
    if (passer) stop.travelerId = passer._id;
    if (!handedOn) stop.place = String(b.hint).trim();
    if (b.chapter) stop.chapter = String(b.chapter).trim();
    if (wishPhoto) stop.wishPhoto = wishPhoto;
    await wixData.insert('CompanionStops', stop, ADMIN);

    const wishToken = b.wishGranted ? randomToken() : null;
    await wixData.update('CompanionHolds', { ...hold, active: false, wishToken }, ADMIN);
    await wixData.update('Companions', {
      ...companion,
      status: handedOn ? 'moving' : 'waiting',
      wishGranted: b.wishGranted ? true : companion.wishGranted,
    }, ADMIN);
    return reply({ ok: true, number: companion.number, wishToken });
  } catch (err) {
    return oops(err);
  }
}

// ── Next wish (after granting one) ──────────────────────────────────────────────────────
// { number, wishToken, wish }
export async function post_herdWish(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');
    const holds = await wixData.query('CompanionHolds').eq('companionNumber', companion.number).eq('wishToken', b.wishToken || '-').find(ADMIN);
    if (!b.wishToken || holds.items.length === 0) return problem('Only the traveler who granted their wish can choose the next one.', 'wish');
    let wish = String(b.wish || '').trim();
    if (/^i want to /i.test(wish)) wish = wish.slice(10);
    wish = wish.replace(/\.$/, '');
    const wishError = checkWish(wish);
    if (wishError) return problem(wishError, 'wish');
    await wixData.update('Companions', { ...companion, wish, wishGranted: false }, ADMIN);
    await wixData.update('CompanionHolds', { ...holds.items[0], wishToken: null }, ADMIN);
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}

// ── Traveler chat ───────────────────────────────────────────────────────────────────────
// { number, author, message }
export async function post_herdChat(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');
    const authorError = checkNickname(b.author);
    if (authorError) return problem(authorError, 'author');
    const text = String(b.message || '').trim();
    if (!text) return problem('Please write a message.', 'message');
    if (mentionsSelfHarm(text)) return problem(selfHarmMessage, 'message');
    if (containsBlockedLanguage(text)) return problem('Please keep it kind. Some words aren’t allowed here.', 'message');
    if (text.length > 500) return problem('Please keep it under 500 characters.', 'message');
    const item = await wixData.insert('CompanionChat', {
      companionNumber: companion.number,
      author: String(b.author).trim(),
      message: hideContactDetails(text),
      hidden: false,
    }, ADMIN);
    return reply({ ok: true, id: item._id, message: item.message });
  } catch (err) {
    return oops(err);
  }
}

// ── Something happened ──────────────────────────────────────────────────────────────────
// { number, what: 'broke' | 'chipped' | 'lost', city, note, byName, sendPieces, email }
export async function post_herdReport(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');
    if (!['broke', 'chipped', 'lost'].includes(b.what)) return problem('Please choose what happened.', 'what');
    const placeError = checkPlaceFormat(b.city);
    if (placeError) return problem(placeError, 'where');
    const noteError = b.note ? checkPublicText(b.note, 500) : null;
    if (noteError) return problem(noteError, 'note');
    if (b.email && !isEmail(b.email)) return problem('Please enter a valid email, or leave it empty.', 'email');
    await wixData.insert('CompanionReports', {
      companionNumber: companion.number,
      what: b.what,
      city: String(b.city).trim(),
      note: b.note ? String(b.note).trim() : null,
      byName: b.byName ? String(b.byName).trim() : null,
      sendPieces: b.sendPieces === true,
      email: b.email ? String(b.email).trim() : null,
    }, ADMIN);
    if (b.what !== 'chipped') await wixData.update('Companions', { ...companion, status: 'retired' }, ADMIN);
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}

// ── Report something (a chat message or a stop) ───────────────────────────────────────────
// { number, kind: 'chat' | 'stop', id } → a "flagged" line in Companion Reports for The Herd to look at.
export async function post_herdFlag(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');
    const collection = b.kind === 'chat' ? 'CompanionChat' : b.kind === 'stop' ? 'CompanionStops' : null;
    if (!collection || !b.id || typeof b.id !== 'string') return problem('We couldn’t find that.', 'id');
    const found = await wixData.query(collection).eq('_id', b.id).find(ADMIN);
    const item = found.items[0];
    if (!item || String(item.companionNumber) !== String(companion.number)) return problem('We couldn’t find that.', 'id');
    const already = await wixData.query('CompanionReports').eq('flaggedId', b.id).find(ADMIN);
    if (already.items.length === 0) {
      const what = b.kind === 'chat'
        ? 'Chat message by ' + (item.author || 'someone') + ': “' + String(item.message || '').slice(0, 300) + '”'
        : 'Stop by ' + (item.byName || 'someone') + (item.chapter ? ': “' + String(item.chapter).slice(0, 300) + '”' : '') + (item.photo ? ' (with a photo)' : '');
      await wixData.insert('CompanionReports', {
        companionNumber: companion.number,
        what: 'flagged',
        city: item.city || null,
        note: 'Reported by a traveler. ' + what,
        flaggedId: b.id,
        flaggedKind: b.kind,
        sendPieces: false,
      }, ADMIN);
    }
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}

// ── Optional sign-in: an emailed 6-digit code, no password ────────────────────────────
// Everything above works without signing in. Signing in keeps a traveler's Passport,
// Companions in their care and the Companions they follow on every device.

const CODE_MINUTES = 15;

async function travelerByEmail(email) {
  const res = await wixData.query('CompanionTravelers').eq('email', email).find(ADMIN);
  return res.items[0] || null;
}

async function setting(key) {
  const res = await wixData.query('CompanionSettings').eq('key', key).find(ADMIN);
  return res.items[0] ? String(res.items[0].value || '').trim() : '';
}

/** What a signed-in traveler sees: their Companions, wishes to choose, travels and follows. */
async function profile(traveler) {
  const holds = await wixData.query('CompanionHolds').eq('travelerId', traveler._id).limit(1000).find(ADMIN);
  const stops = await wixData.query('CompanionStops').eq('travelerId', traveler._id).limit(1000).find(ADMIN);
  const wishTokens = {};
  for (const h of holds.items) if (h.wishToken) wishTokens[h.companionNumber] = h.wishToken;
  return {
    email: traveler.email,
    nickname: traveler.nickname || '',
    following: traveler.following || [],
    holds: holds.items.filter((h) => h.active).map((h) => ({ number: h.companionNumber, token: h.token, city: h.city || '', date: h._createdDate })),
    wishTokens,
    journal: stops.items.map((st) => ({
      number: st.companionNumber,
      kind: st.kind,
      city: st.city,
      date: st._createdDate,
      wishGranted: !!st.wishPhoto,
    })),
  };
}

// { email }
export async function post_herdSignInStart(request) {
  try {
    const b = await readBody(request);
    const email = String((b && b.email) || '').trim().toLowerCase();
    if (!isEmail(email)) return problem('Please enter a valid email.', 'email');
    let traveler = await travelerByEmail(email);
    const now = Date.now();
    if (traveler && traveler.codeSentAt && now - traveler.codeSentAt < 60 * 1000) {
      return problem('We just sent you a code. Please wait a minute before asking for another one.', 'email');
    }
    const emailId = await setting('signInEmailId');
    if (!emailId) return problem('Email sign-in isn’t switched on yet. You can keep using everything without it.', 'email');
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    const fields = { codeHash: hash(email + ':' + code), codeExpires: now + CODE_MINUTES * 60 * 1000, codeTries: 0, codeSentAt: now };
    traveler = traveler
      ? await wixData.update('CompanionTravelers', { ...traveler, ...fields }, ADMIN)
      : await wixData.insert('CompanionTravelers', { email, following: [], sessions: [], ...fields }, ADMIN);
    const contact = await contacts.appendOrCreateContact({ emails: [{ email }] });
    await triggeredEmails.emailContact(emailId, contact.contactId, { variables: { code } });
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}

// { email, code, holds: { number: holdToken }, following: [numbers], nickname }
export async function post_herdSignInVerify(request) {
  try {
    const b = await readBody(request);
    if (!b) return problem('Something was missing. Please try again.');
    const email = String(b.email || '').trim().toLowerCase();
    const traveler = await travelerByEmail(email);
    if (!traveler || !traveler.codeHash) return problem('Please ask for a sign-in code first.', 'code');
    if (Date.now() > traveler.codeExpires) return problem('That code has expired. Please ask for a new one.', 'code');
    if ((traveler.codeTries || 0) >= 5) return problem('Too many tries. Please ask for a new code.', 'code');
    const code = String(b.code || '').replace(/\D/g, '');
    if (hash(email + ':' + code) !== traveler.codeHash) {
      await wixData.update('CompanionTravelers', { ...traveler, codeTries: (traveler.codeTries || 0) + 1 }, ADMIN);
      return problem('That code isn’t right. Check the email and try again.', 'code');
    }
    const session = randomToken();
    const following = [...new Set([...(traveler.following || []), ...((Array.isArray(b.following) ? b.following : []).map(String).filter((n) => /^\d{1,4}$/.test(n)))])];
    const nicknameOk = b.nickname && !checkNickname(b.nickname);
    const updated = await wixData.update('CompanionTravelers', {
      ...traveler,
      codeHash: null,
      codeExpires: null,
      codeTries: 0,
      sessions: [...(traveler.sessions || []).slice(-9), hash(session)],
      following,
      nickname: traveler.nickname || (nicknameOk ? String(b.nickname).trim() : ''),
    }, ADMIN);
    // Companions found on this device before signing in come along.
    const holds = b.holds && typeof b.holds === 'object' ? b.holds : {};
    for (const [number, token] of Object.entries(holds)) {
      const res = await wixData.query('CompanionHolds').eq('token', String(token)).find(ADMIN);
      const hold = res.items[0];
      if (hold && cleanNumber(hold.companionNumber) === cleanNumber(number) && !hold.travelerId) {
        await wixData.update('CompanionHolds', { ...hold, travelerId: updated._id }, ADMIN);
      }
    }
    return reply({ ok: true, session, profile: await profile(updated) });
  } catch (err) {
    return oops(err);
  }
}

// { session }
export async function post_herdMine(request) {
  try {
    const b = await readBody(request);
    const traveler = await travelerBySession(b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    return reply({ ok: true, profile: await profile(traveler) });
  } catch (err) {
    return oops(err);
  }
}

// { session, number, on }
export async function post_herdFollow(request) {
  try {
    const b = await readBody(request);
    const traveler = await travelerBySession(b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    const companion = await findCompanion(b.number);
    if (!companion) return problem('We couldn’t find that Companion.', 'number');
    const set = new Set(traveler.following || []);
    if (b.on) set.add(companion.number); else set.delete(companion.number);
    await wixData.update('CompanionTravelers', { ...traveler, following: [...set] }, ADMIN);
    return reply({ ok: true, following: [...set] });
  } catch (err) {
    return oops(err);
  }
}

// { session }
export async function post_herdSignOut(request) {
  try {
    const b = await readBody(request);
    const traveler = await travelerBySession(b && b.session);
    if (traveler) {
      const h = hash(b.session);
      await wixData.update('CompanionTravelers', { ...traveler, sessions: (traveler.sessions || []).filter((x) => x !== h) }, ADMIN);
    }
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}

// { session }: removes the traveler's email and sign-in. Their chapters stay, without the link.
export async function post_herdForgetMe(request) {
  try {
    const b = await readBody(request);
    const traveler = await travelerBySession(b && b.session);
    if (!traveler) return problem('Please sign in again.', 'session');
    for (const name of ['CompanionHolds', 'CompanionStops']) {
      const res = await wixData.query(name).eq('travelerId', traveler._id).limit(1000).find(ADMIN);
      for (const item of res.items) await wixData.update(name, { ...item, travelerId: null }, ADMIN);
    }
    await wixData.remove('CompanionTravelers', traveler._id, ADMIN);
    return reply({ ok: true });
  } catch (err) {
    return oops(err);
  }
}
