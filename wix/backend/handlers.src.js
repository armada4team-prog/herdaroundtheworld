// ── Herd Around the World: the checker on The Herd's Wix site ──────────────────────────
// Every find, pass-on, wish, chat message and report from the website or the app comes
// through here. Each is checked against the rules before it's saved to the CMS lists,
// and the find codes never leave Wix.
//
// Addresses (once the site is published):
//   https://www.theherdstudio.com/_functions/herdFind     and herdPassOn, herdWish, herdChat, herdReport
// Send a POST with a JSON body (Content-Type text/plain is fine, so browsers don't need a preflight).

import { ok, badRequest, serverError } from 'wix-http-functions';
import wixData from 'wix-data';
import { mediaManager } from 'wix-media-backend';

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
  const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
  let out = '';
  for (let i = 0; i < 32; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
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
// { number, code, nickname, city, latitude, longitude, holdToken? }
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

    const token = randomToken();
    await wixData.insert('CompanionHolds', {
      companionNumber: companion.number,
      token,
      active: true,
      byName: String(b.nickname).trim(),
      foundLatitude: b.latitude,
      foundLongitude: b.longitude,
    }, ADMIN);
    await wixData.insert('CompanionStops', {
      companionNumber: companion.number,
      kind: 'found',
      city: String(b.city).trim(),
      latitude: blur(b.latitude, false),
      longitude: blur(b.longitude, false),
      byName: String(b.nickname).trim(),
    }, ADMIN);
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
      latitude: blur(b.latitude, !handedOn),
      longitude: blur(b.longitude, !handedOn),
      byName: String(b.nickname).trim(),
      photo,
      photoApproved: false,
    };
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
