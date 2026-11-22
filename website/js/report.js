// "Report": lets anyone flag a chat message or a stop for The Herd to look at (Google Play asks
// apps with traveler posts for this). The checker adds a line to Companion Reports, which shows in
// The Herd's daily email.
import { send } from './data.js';
import { esc, t } from './ui.js';
import { tr } from './i18n.js';

export function reportLink(kind, id) {
  if (!id) return '';
  return `<button type="button" class="report-link" data-report="${kind}" data-id="${esc(id)}">${t('Report')}</button>`;
}

/** Wires every Report link inside root (set up once per page). */
export function bindReports(root, number) {
  root.addEventListener('click', async (e) => {
    const b = e.target.closest('[data-report]');
    if (!b || b.disabled) return;
    if (!window.confirm(tr('Report this to The Herd? They’ll take a look and remove it if it breaks the rules.'))) return;
    b.disabled = true;
    const res = await send('herdFlag', { number, kind: b.dataset.report, id: b.dataset.id });
    if (res.ok) {
      b.outerHTML = `<span class="report-done">${t('Reported. Thank you!')}</span>`;
    } else {
      b.disabled = false;
      window.alert(tr('That didn’t go through. Please try again.'));
    }
  });
}
