// The daily email to The Herd: new travelers' photos waiting for approval, and new reports
// (broke, chipped, lost, adopted). Runs with the daily cron (wrangler.toml). Sent only on days
// when something new came in, to the address in CompanionSettings `ownerEmail`.
// Each photo has an "Approve photo" button (a one-time link to /herdApprove on this checker) and
// a link to open the Companion Stops list in the Wix dashboard.
import wixData from './adapters/wix-data.js';
import { randomBytes } from './adapters/crypto.js';
import { sendDigest } from './email.js';

const DASHBOARD = (siteId, collection) => `https://manage.wix.com/dashboard/${siteId}/database/data/${collection}`;

async function setting(key) {
  const res = await wixData.query('CompanionSettings').eq('key', key).find();
  return res.items[0] ? String(res.items[0].value || '').trim() : '';
}

/** wix:image://v1/<id>/… → a normal web address for the photo. */
export function photoUrl(value) {
  if (!value || typeof value !== 'string') return null;
  if (/^https?:\/\//.test(value)) return value;
  const m = value.match(/^wix:image:\/\/v1\/([^/#]+)/);
  return m ? 'https://static.wixstatic.com/media/' + m[1] : null;
}

/** Sends today's email if anything new came in. Returns { photos, reports } counted. */
export async function sendOwnerDigest({ checkerUrl, siteId, now = Date.now() } = {}) {
  const to = await setting('ownerEmail');
  if (!to || !(await setting('signInEmailId'))) return { photos: 0, reports: 0 };
  const base = String(checkerUrl || '').replace(/\/+$/, '');

  const stops = (await wixData.query('CompanionStops').eq('photoApproved', false).limit(1000).find()).items
    .filter((st) => st.photo && !st.ownerNotifiedAt);
  const reports = (await wixData.query('CompanionReports').limit(1000).find()).items
    .filter((r) => !r.ownerNotifiedAt);
  if (stops.length === 0 && reports.length === 0) return { photos: 0, reports: 0 };

  const companions = (await wixData.query('Companions').limit(1000).find()).items;
  const nameOf = (n) => { const c = companions.find((x) => x.number === n); return c && c.name ? `#${n} ${c.name}` : `#${n}`; };

  const photoItems = [];
  for (const st of stops) {
    const token = randomBytes(24).toString('hex');
    photoItems.push({
      stop: { ...st, approveToken: token },
      title: nameOf(st.companionNumber),
      where: st.city || '',
      by: st.byName || '',
      chapter: st.chapter || '',
      photo: photoUrl(st.photo),
      wishPhoto: photoUrl(st.wishPhoto),
      approveUrl: `${base}/herdApprove?t=${token}`,
    });
  }
  const reportItems = reports.map((r) => ({
    report: r,
    title: nameOf(r.companionNumber),
    what: r.what,
    where: r.city || '',
    by: r.byName || '',
    note: r.note || '',
    email: r.email || '',
    sendPieces: !!r.sendPieces,
  }));

  await sendDigest(to, {
    photos: photoItems,
    reports: reportItems,
    stopsUrl: DASHBOARD(siteId, 'CompanionStops'),
    reportsUrl: DASHBOARD(siteId, 'CompanionReports'),
  });
  // Only after the email went out: mark them, so each shows up in one email.
  for (const p of photoItems) await wixData.update('CompanionStops', { ...p.stop, ownerNotifiedAt: now });
  for (const r of reportItems) await wixData.update('CompanionReports', { ...r.report, ownerNotifiedAt: now });
  return { photos: photoItems.length, reports: reportItems.length };
}

/** The "Approve photo" button: ticks Photo approved on that stop. Returns a short label, or null. */
export async function approveFromEmail(token) {
  if (!token || !/^[0-9a-f]{48}$/.test(token)) return null;
  const res = await wixData.query('CompanionStops').eq('approveToken', token).limit(1).find();
  const stop = res.items[0];
  if (!stop) return null;
  if (!stop.photoApproved) await wixData.update('CompanionStops', { ...stop, photoApproved: true });
  return `#${stop.companionNumber}${stop.city ? ' in ' + stop.city : ''}`;
}
