// Translations: English is written in the code; Spanish, French and Japanese come from the app's
// translations (translations.js) plus a few website-only lines (translations-web.js).
// Works like the app's tr(): sentences with names or numbers ("You found #07!") are matched by
// pattern ("You found {0}!"). Travelers' own chapters and chat messages are never translated.
import { appTranslations } from './translations.js';
import { webTranslations } from './translations-web.js';

export const languages = [
  { code: 'en', label: 'English' },
  { code: 'es', label: 'Español' },
  { code: 'fr', label: 'Français' },
  { code: 'ja', label: '日本語' },
];

const tables = {};
for (const code of ['es', 'fr', 'ja']) tables[code] = { ...(appTranslations[code] || {}), ...(webTranslations[code] || {}) };

let current = 'en';
try {
  const fromUrl = new URLSearchParams(location.search).get('lang');
  const saved = fromUrl || localStorage.getItem('herd.lang');
  if (saved && (saved === 'en' || tables[saved])) current = saved;
} catch (e) { /* storage blocked: English */ }

export function lang() { return current; }
export function setLang(code) {
  current = code === 'en' || tables[code] ? code : 'en';
  try { localStorage.setItem('herd.lang', current); } catch (e) { /* ignore */ }
  document.documentElement.lang = current;
}

const patternCache = {};
function patterns(code) {
  if (patternCache[code]) return patternCache[code];
  const table = tables[code];
  const keys = Object.keys(table).filter((k) => k.includes('{0}'));
  // Most specific first, so "Want {0} to check in with you?" wins over "{0} in {1}".
  keys.sort((a, b) => b.replace(/\{\d\}/g, '').length - a.replace(/\{\d\}/g, '').length);
  const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  patternCache[code] = keys.map((k) => [new RegExp('^' + esc(k).replace(/\\\{(\d)\\\}/g, '(.+?)') + '$', 's'), table[k]]);
  return patternCache[code];
}

/** Every English line that had no translation (for checking new text). */
export const missing = new Set();

/** Translates one piece of website text into the current language. */
export function tr(english) {
  if (current === 'en' || !english) return english;
  const table = tables[current];
  if (Object.prototype.hasOwnProperty.call(table, english)) return table[english];
  for (const [re, translated] of patterns(current)) {
    const m = english.match(re);
    if (m) {
      let out = translated;
      for (let i = 1; i < m.length; i++) out = out.split('{' + (i - 1) + '}').join(tr(m[i]));
      return out;
    }
  }
  missing.add(english);
  return english;
}
if (typeof window !== 'undefined') window.__missing = missing;
