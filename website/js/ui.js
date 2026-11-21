// Shared pieces: escaping, icons, the clay Companion figure, error notes and the fix list.
import { tr } from './i18n.js';

export const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
/** Translate, then escape. */
export const t = (s) => esc(tr(s));

const stroke = (d, w = 2) => `<svg class="ic" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
export const icons = {
  share: stroke('<circle cx="18" cy="5" r="2.6"/><circle cx="6" cy="12" r="2.6"/><circle cx="18" cy="19" r="2.6"/><path d="M8.3 10.8l7.4-4.4M8.3 13.2l7.4 4.4"/>'),
  pin: stroke('<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21Z"/><circle cx="12" cy="9.5" r="2.5"/>'),
  star: '<svg class="ic" aria-hidden="true" viewBox="0 0 24 24" fill="#E0B94A"><path d="M12 3l2.6 5.5 6 .8-4.4 4.2 1.1 6L12 16.6 6.7 19.5l1.1-6L3.4 9.3l6-.8z"/></svg>',
  back: stroke('<path d="M15 18l-6-6 6-6"/>', 2.2),
  chevronDown: stroke('<path d="M6 9l6 6 6-6"/>', 2.4),
  chevronRight: stroke('<path d="M9 6l6 6-6 6"/>', 2.2),
  globe: stroke('<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>', 1.8),
  search: stroke('<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>'),
  camera: stroke('<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>', 1.8),
  lock: stroke('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>', 1.8),
  error: stroke('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5v.01"/>', 2.2),
  warn: stroke('<path d="M12 3.5L2.5 20h19z"/><path d="M12 10v4.5M12 17.5v.01"/>', 2.2),
  refresh: stroke('<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>'),
  close: stroke('<path d="M6 6l12 12M18 6L6 18"/>', 2.2),
  arrow: stroke('<path d="M5 12h14M13 6l6 6-6 6"/>', 2.2),
  arrowDown: stroke('<path d="M12 5v14M6 13l6 6 6-6"/>', 2.2),
  locate: stroke('<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/>'),
  menu: stroke('<path d="M4 7h16M4 12h16M4 17h16"/>'),
  heart: '<svg class="ic" aria-hidden="true" viewBox="0 0 24 24" fill="#D98C86"><path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z"/></svg>',
  send: stroke('<path d="M4 12l16-8-6 16-2.5-6.5z"/>'),
  check: stroke('<path d="M5 12.5l4.5 4.5L19 7.5"/>', 2.4),
  mail: stroke('<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3.5 6.5l8.5 6.5 8.5-6.5"/>', 1.8),
};

/**
 * The little clay Companion (60 × 80 grid, like the SVG in the designs).
 * opts: { size (px width), glaze, waving, happy, scroll, number, label, hat }
 */
export function figure(opts = {}) {
  const g = '#' + String(opts.glaze || 'A8DCC9').replace('#', '');
  const ink = '#3F5A4C';
  const a11y = opts.label ? `role="img" aria-label="${esc(opts.label)}"` : 'aria-hidden="true"';
  const face = opts.happy
    ? `<path d="M23 19 Q25 16 27 19 M33 19 Q35 16 37 19" stroke="${ink}" stroke-width="1.6" fill="none" stroke-linecap="round"/>
       <path d="M24 24 Q30 31 36 24 Z" fill="#F2B4B0" stroke="${ink}" stroke-width="1.5" stroke-linejoin="round"/>`
    : `<circle cx="25" cy="19" r="1.8" fill="${ink}"/><circle cx="35" cy="19" r="1.8" fill="${ink}"/>
       <path d="M26 25 Q30 28 34 25" stroke="${ink}" stroke-width="1.5" fill="none" stroke-linecap="round"/>`;
  const arm = opts.waving ? `<path d="M14 44 Q6 36 9 27" stroke="${g}" stroke-width="6" fill="none" stroke-linecap="round"/>` : '';
  const scroll = opts.scroll === false ? '' : `<rect x="33" y="47" width="13" height="9" rx="2" fill="#FDF8F3" stroke="#5B7869" stroke-width="1"/><path d="M36 50.5 H43 M36 53 H41" stroke="#5B7869" stroke-width="0.8"/>`;
  const num = opts.number != null ? `<text x="30" y="66" text-anchor="middle" font-family="'Baloo 2'" font-weight="800" font-size="10" fill="${ink}" opacity="0.55">${esc(opts.number)}</text>` : '';
  return `<svg class="figure" ${a11y} viewBox="0 0 60 80" style="width:${opts.size || 60}px">
    <ellipse cx="30" cy="77" rx="18" ry="2.5" fill="${ink}" opacity="0.14"/>
    ${arm}
    <path d="M14 46 Q14 33 30 33 Q46 33 46 46 L46 70 Q46 75 41 75 L19 75 Q14 75 14 70 Z" fill="${g}"/>
    <circle cx="30" cy="20" r="14" fill="${g}"/>
    <circle cx="20" cy="50" r="0.9" fill="${ink}" opacity="0.35"/><circle cx="38" cy="64" r="0.9" fill="${ink}" opacity="0.35"/><circle cx="24" cy="12" r="0.8" fill="${ink}" opacity="0.3"/>
    ${face}
    <circle cx="21" cy="23.5" r="2.2" fill="#F2B4B0" opacity="0.8"/><circle cx="39" cy="23.5" r="2.2" fill="#F2B4B0" opacity="0.8"/>
    ${opts.number != null ? '' : scroll}${num}
  </svg>`;
}

/** A Companion figure on their coloured blob ("badge"). */
export function badge(c, size = 104, extra = {}) {
  const photo = c.profilePhoto
    ? `<img src="${esc(c.profilePhoto)}" alt="" class="badge-photo">`
    : figure({ glaze: c.glaze, size: Math.round(size * 0.5), ...extra });
  return `<span class="badge" style="width:${size}px;height:${size}px;background:#${esc(c.blob)}">${photo}</span>`;
}

/** Soft background blob shapes from the designs. */
export function blob(color, cls = '') {
  return `<span class="blob ${cls}" aria-hidden="true" style="background:${color}"></span>`;
}

/** A "needs fixing" message: red, with a warning icon (like the app's ErrorNote). */
export const errorNote = (text, id = '') => `<p class="error-note" role="alert"${id ? ` id="${id}"` : ''}>${icons.error}<span>${t(text)}</span></p>`;

/** The list above a form's send button when something still needs fixing (the app's FixList). */
export function fixList(problems) {
  if (!problems.length) return '';
  return `<div class="fix-list" role="alert" tabindex="-1">
    <p class="fix-title">${icons.warn}<span>${t('Almost there! Please fix these first:')}</span></p>
    <ul>${problems.map((p) => `<li>${t(p)}</li>`).join('')}</ul>
  </div>`;
}

export const pill = (text, cls = '') => `<span class="pill ${cls}">${t(text)}</span>`;

/** Shares a link with the phone's share sheet, or copies it. */
export async function share(text, url, button) {
  try {
    if (navigator.share) { await navigator.share({ text, url }); return; }
  } catch (e) { if (e && e.name === 'AbortError') return; }
  try {
    await navigator.clipboard.writeText(text + ' ' + url);
    if (button) {
      const old = button.innerHTML;
      button.innerHTML = icons.check + `<span>${t('Link copied')}</span>`;
      setTimeout(() => { button.innerHTML = old; }, 1800);
    }
  } catch (e) { /* nothing more we can do */ }
}

/** Scrolls so the first problem on a form is on screen, and focuses it. */
export function scrollToFirstProblem(root) {
  const first = root.querySelector('.has-error');
  if (!first) return;
  first.scrollIntoView({ behavior: 'smooth', block: 'center' });
  const input = first.querySelector('input, textarea, button');
  if (input) setTimeout(() => input.focus({ preventScroll: true }), 350);
}
