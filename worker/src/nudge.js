// The gentle reminder for Companions that have stayed with one traveler a long time.
// Once a day (a Cloudflare cron, see wrangler.toml) this looks at who is holding each Companion.
// When someone signed in with their email has held one for `nudgeDays` (CompanionSettings,
// default 60) and hasn't been reminded yet, they get one email: pass them on, or tell The Herd
// "they're staying with me". That answer marks the Companion Adopted and adds a line to
// Companion Reports, so The Herd can see it in the Wix dashboard.
// Set CompanionSettings `nudges` to "off" to stop the emails.
import wixData from './adapters/wix-data.js';
import { randomBytes } from './adapters/crypto.js';
import { sendNudge } from './email.js';

const DAY = 24 * 60 * 60 * 1000;
const SITE = 'https://companions.theherdstudio.com';

async function setting(key) {
  const res = await wixData.query('CompanionSettings').eq('key', key).find();
  return res.items[0] ? String(res.items[0].value || '').trim() : '';
}

async function first(collection, field, value) {
  const res = await wixData.query(collection).eq(field, value).limit(1).find();
  return res.items[0] || null;
}

const nameOf = (c) => (c && c.name ? c.name : '#' + (c ? c.number : ''));

/** Sends the reminders that are due. Returns how many were sent. */
export async function nudgeLongHolds({ checkerUrl, now = Date.now() } = {}) {
  if ((await setting('nudges')).toLowerCase() === 'off') return 0;
  if (!(await setting('signInEmailId'))) return 0; // emails are off altogether
  const days = Number(await setting('nudgeDays')) || 60;
  const holds = await wixData.query('CompanionHolds').eq('active', true).limit(1000).find();
  let sent = 0;
  for (const hold of holds.items) {
    if (!hold.travelerId || hold.nudgedAt || hold.adoptedAt) continue;
    const since = Date.parse(hold._createdDate);
    if (!since || now - since < days * DAY) continue;
    const traveler = await first('CompanionTravelers', '_id', hold.travelerId);
    if (!traveler || !traveler.email) continue;
    const companion = await first('Companions', 'number', hold.companionNumber);
    if (!companion || companion.status === 'retired' || companion.status === 'adopted') continue;
    const token = randomBytes(24).toString('hex');
    try {
      await sendNudge(traveler.email, {
        name: nameOf(companion),
        nickname: hold.byName || traveler.nickname || '',
        days: Math.floor((now - since) / DAY),
        passOnUrl: `${SITE}/#/c/${companion.number}/pass-on`,
        adoptUrl: `${String(checkerUrl || '').replace(/\/+$/, '')}/herdAdopted?t=${token}`,
      });
    } catch (err) {
      console.error('reminder for #' + companion.number + ' was not sent:', err && err.message);
      continue; // try again tomorrow
    }
    await wixData.update('CompanionHolds', { ...hold, nudgedAt: now, nudgeToken: token });
    sent++;
  }
  return sent;
}

/** "They're staying with me": marks the Companion Adopted. Returns the Companion's name, or null. */
export async function adoptFromEmail(token, { now = Date.now() } = {}) {
  if (!token || !/^[0-9a-f]{48}$/.test(token)) return null;
  const hold = await first('CompanionHolds', 'nudgeToken', token);
  if (!hold) return null;
  const companion = await first('Companions', 'number', hold.companionNumber);
  if (!companion) return null;
  if (hold.adoptedAt) return nameOf(companion); // clicked twice
  if (!hold.active) return null; // someone else has found them since
  await wixData.update('Companions', { ...companion, status: 'adopted' });
  await wixData.update('CompanionHolds', { ...hold, adoptedAt: now });
  const traveler = hold.travelerId ? await first('CompanionTravelers', '_id', hold.travelerId) : null;
  await wixData.insert('CompanionReports', {
    companionNumber: companion.number,
    what: 'adopted',
    city: hold.city || null,
    note: 'Answered the reminder email: they found a forever home with this traveler.',
    byName: hold.byName || null,
    sendPieces: false,
    email: traveler ? traveler.email : null,
  });
  return nameOf(companion);
}
