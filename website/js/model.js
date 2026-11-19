// Small helpers about Companions and their stops (the same rules as lib/models.dart).
import { milesBetween, cleanNumber } from '../../shared/rules.js';

export { cleanNumber };

export const statusLabels = {
  moving: 'On the move',
  waiting: 'Waiting to be found',
  quiet: 'Quiet lately',
  adopted: 'Adopted',
  retired: 'Retired',
};

/** Map filters, with the same colours as the app. */
export const filters = [
  { id: 'all', label: 'All', bg: 'FDF8F3', fg: '3F5A4C', dot: null },
  { id: 'following', label: 'Following', bg: 'FDF8F3', fg: '3F5A4C', dot: null },
  { id: 'nearMe', label: 'Near me', bg: 'FDF8F3', fg: '3F5A4C', dot: null },
  { id: 'originals', label: 'Originals #0–5', bg: 'FBE4E2', fg: '6B3F3A', dot: 'D98C86' },
  { id: 'movedThisWeek', label: 'Moved this week', bg: 'DDF0E8', fg: '2F4A3D', dot: '6BBFA3' },
  { id: 'waiting', label: 'Waiting to be found', bg: 'DCEAF5', fg: '2D4A63', dot: '6A9BC3' },
  { id: 'quiet', label: 'Quiet lately', bg: 'EDE6DC', fg: '4A4440', dot: 'A69C90' },
  { id: 'adopted', label: 'Adopted', bg: 'E6DDF5', fg: '4A3D63', dot: '9C86C9' },
  { id: 'retired', label: 'Retired', bg: 'F8DCC8', fg: '6B4430', dot: 'D08A5E' },
  { id: 'wishesGranted', label: 'Wishes granted', bg: 'F9EBB5', fg: '5A4C1E', dot: 'E0B94A' },
];

export function matches(c, filterId, following) {
  switch (filterId) {
    case 'all': case 'nearMe': return true;
    case 'following': return following.includes(cleanNumber(c.number));
    case 'originals': return !!c.isOriginal;
    case 'movedThisWeek': return !!c.movedThisWeek;
    case 'waiting': return c.status === 'waiting';
    case 'quiet': return c.status === 'quiet';
    case 'adopted': return c.status === 'adopted';
    case 'retired': return c.status === 'retired';
    case 'wishesGranted': return !!c.wishGranted;
    default: return true;
  }
}

export const displayName = (c) => c.name || '#' + c.number;
export const label = (c) => (c.name ? `#${c.number} · ${c.name}` : '#' + c.number);
export const current = (c) => (c.stops.length ? c.stops[c.stops.length - 1] : null);
export const wishSentence = (c) => `I want to ${c.wish}.`;
/** The first entry is the studio in Aurora, so it isn't counted as a stop. */
export const stopCount = (c) => Math.max(c.stops.length - 1, 0);

export function miles(c) {
  let total = 0;
  for (let i = 1; i < c.stops.length; i++) {
    const a = c.stops[i - 1], b = c.stops[i];
    total += milesBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }
  return Math.round(total);
}

/** "Found by Sam", "Passed on by Sam" or "Left by Sam". */
export function byLine(stop) {
  if (!stop.byName) return null;
  if (stop.kind === 'found') return 'Found by ' + stop.byName;
  if (stop.kind === 'passedOn') return 'Passed on by ' + stop.byName;
  return 'Left by ' + stop.byName;
}

/** "3 days ago" → 3 (for sorting), like AppModel.daysAgo. */
export function daysAgo(text) {
  const n = parseInt(String(text || '').split(' ')[0], 10);
  if (Number.isNaN(n)) return text === 'Just now' ? 0 : 999;
  if (/hour|minute/.test(text)) return 0;
  if (/week/.test(text)) return n * 7;
  if (/month/.test(text)) return n * 30;
  return n;
}

/** A date → "Just now", "5 hours ago", "3 days ago", "2 weeks ago", "4 months ago". */
export function relativeTime(date, now = Date.now()) {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return '';
  const hours = (now - d.getTime()) / 3600000;
  if (hours < 1) return 'Just now';
  if (hours < 24) { const h = Math.floor(hours); return h === 1 ? '1 hour ago' : `${h} hours ago`; }
  const days = Math.floor(hours / 24);
  if (days < 7) return days === 1 ? '1 day ago' : `${days} days ago`;
  if (days < 30) { const w = Math.floor(days / 7); return w === 1 ? '1 week ago' : `${w} weeks ago`; }
  const m = Math.max(1, Math.floor(days / 30));
  return m === 1 ? '1 month ago' : `${m} months ago`;
}

/** The 10 Companions with the most stops, most recently moved first when tied. */
export function mostActive(list) {
  return [...list]
    .sort((a, b) => (stopCount(b) - stopCount(a)) || (daysAgo(a.lastMoved) - daysAgo(b.lastMoved)))
    .slice(0, 10);
}

export const formatThousands = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

/** Rough country from "City, Country" (US state abbreviations count as the US). */
export function countryOf(city) {
  const parts = String(city || '').split(',').map((s) => s.trim());
  if (parts.length < 2) return parts[0] || '';
  const last = parts[parts.length - 1];
  return /^[A-Z]{2}$/.test(last) ? 'USA' : last;
}
