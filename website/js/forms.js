// Form pieces shared by the find, pass-on, wish, chat and "something happened" pages.
import { t, esc, icons, errorNote, fixList, badge, blob, scrollToFirstProblem } from './ui.js';
import { tr } from './i18n.js';
import { preparePhoto } from './photo.js';

/** The beige band at the top of a form page (eyebrow, script title, the Companion on a blob). */
export function formHero({ eyebrow, title, c, intro, wide = false }) {
  return `<section class="form-hero">
    ${blob('#F9EBB5', 'b-tr')}
    <div class="narrow${wide ? ' desk-wide' : ''}">
      ${c ? badge(c, 92) : ''}
      <div>
        ${eyebrow ? `<p class="eyebrow">${t(eyebrow)}</p>` : ''}
        <h1 class="script">${t(title)}</h1>
        ${intro ? `<p style="margin-top:6px">${t(intro)}</p>` : ''}
      </div>
    </div>
  </section>`;
}

/** A labelled text box. Problems show in red under it (setError). */
export function textField({ id, label, placeholder = '', max, value = '', multiline = false, help = '', counter = false, type = 'text', autocomplete = 'off', inputmode = '' }) {
  const attrs = `id="${id}" name="${id}" class="input" placeholder="${esc(tr(placeholder))}" ${max ? `maxlength="${max}"` : ''} autocomplete="${autocomplete}" ${inputmode ? `inputmode="${inputmode}"` : ''} aria-describedby="${id}-err${help ? ` ${id}-help` : ''}"`;
  const input = multiline
    ? `<textarea ${attrs} rows="4">${esc(value)}</textarea>`
    : `<input type="${type}" ${attrs} value="${esc(value)}">`;
  return `<div class="field" data-field="${id}">
    <label for="${id}">${t(label)}</label>
    ${input}
    ${counter && max ? `<p class="counter" aria-live="polite" data-counter="${id}">${value.length}/${max}</p>` : ''}
    <div id="${id}-err" class="err-slot"></div>
    ${help ? `<p class="help" id="${id}-help">${t(help)}</p>` : ''}
  </div>`;
}

/** Marks one field red with a message (or clears it). */
export function setError(root, name, message) {
  const field = root.querySelector(`[data-field="${name}"]`);
  if (!field) return;
  field.classList.toggle('has-error', !!message);
  const slot = field.querySelector(':scope > .err-slot');
  if (slot) slot.innerHTML = message ? errorNote(message) : '';
  const input = field.querySelector(':scope > .input');
  if (input) input.setAttribute('aria-invalid', message ? 'true' : 'false');
}

/** Clears a field's problem as soon as the person types in it, and keeps its counter up to date. */
export function bindTyping(root, onChange) {
  root.addEventListener('input', (e) => {
    const input = e.target;
    if (!input.id) return;
    const counter = root.querySelector(`[data-counter="${input.id}"]`);
    if (counter) {
      const max = Number(input.getAttribute('maxlength'));
      counter.textContent = `${input.value.length}/${max}`;
    }
    const field = input.closest('[data-field]');
    if (field && field.classList.contains('has-error')) setError(root, field.dataset.field, null);
    if (onChange) onChange(input);
  });
}

/** Choice cards (radio buttons): options = [{ value, title, detail, badge }]. */
export function choices(name, label, options, selected) {
  return `<div class="field" data-field="${name}">
    <p class="field-label" id="${name}-label">${t(label)}</p>
    <div class="choices" role="radiogroup" aria-labelledby="${name}-label">
      ${options.map((o) => `<button type="button" class="choice" role="radio" aria-checked="${o.value === selected}" data-choice="${name}" data-value="${esc(o.value)}">
        <span class="radio" aria-hidden="true"></span>
        <span><span class="title">${t(o.title)}</span>${o.badge ? `<span class="pill small mint">${t(o.badge)}</span>` : ''}${o.detail ? `<span class="detail">${t(o.detail)}</span>` : ''}</span>
      </button>`).join('')}
    </div>
    <div class="err-slot"></div>
  </div>`;
}

export function bindChoices(root, name, onPick) {
  root.querySelectorAll(`[data-choice="${name}"]`).forEach((b) => {
    b.addEventListener('click', () => {
      root.querySelectorAll(`[data-choice="${name}"]`).forEach((x) => x.setAttribute('aria-checked', String(x === b)));
      onPick(b.dataset.value);
    });
    b.addEventListener('keydown', (e) => {
      if (!['ArrowDown', 'ArrowUp', 'ArrowLeft', 'ArrowRight'].includes(e.key)) return;
      e.preventDefault();
      const all = [...root.querySelectorAll(`[data-choice="${name}"]`)];
      const i = all.indexOf(b) + (e.key === 'ArrowDown' || e.key === 'ArrowRight' ? 1 : -1);
      const next = all[(i + all.length) % all.length];
      next.focus();
      next.click();
    });
  });
}

/** A photo box (file input: photo library, or the camera on phones). */
export function photoField({ id, label, prompt, gold = false }) {
  return `<div class="field" data-field="${id}">
    ${label ? `<p class="field-label" id="${id}-label">${t(label)}</p>` : ''}
    <label class="photo-box${gold ? ' gold' : ''}" data-photo="${id}">
      <input type="file" accept="image/*" id="${id}" aria-describedby="${id}-err" ${label ? `aria-labelledby="${id}-label ${id}-prompt"` : ''}>
      ${icons.camera}<span id="${id}-prompt">${t(prompt)}</span>
    </label>
    <div id="${id}-err" class="err-slot"></div>
  </div>`;
}

/** onPhoto({ base64, mimeType, dataUrl }) once a photo is chosen and shrunk. */
export function bindPhoto(root, id, prompt, onPhoto) {
  const box = root.querySelector(`[data-photo="${id}"]`);
  const input = box.querySelector('input');
  input.addEventListener('change', async () => {
    const file = input.files && input.files[0];
    if (!file) return;
    try {
      const photo = await preparePhoto(file);
      box.classList.add('filled');
      box.querySelector('img')?.remove();
      box.querySelectorAll('.ic, span').forEach((n) => n.remove());
      box.insertAdjacentHTML('beforeend', `<img src="${photo.dataUrl}" alt="${t('Your photo')}"><span class="pill small white change">${t('Photo added. Tap to change it.')}</span>`);
      setError(root, id, null);
      onPhoto(photo);
    } catch (e) {
      setError(root, id, e.message || 'That photo couldn’t be used. Please try a different one.');
    }
  });
  return { prompt };
}

/** Shows the list of problems above the send button, and scrolls to the first one. */
export function showProblems(root, slot, problems) {
  slot.innerHTML = fixList(problems);
  if (problems.length) scrollToFirstProblem(root);
}

/** The friendly "not yet" screen (find first, already with you, scan their code first). */
export function outOfOrder({ c, title, message, button, href }) {
  return `<div class="narrow out-of-order">
    ${c ? badge(c, 120) : ''}
    <h1 class="script">${t(title)}</h1>
    <p class="lead">${t(message)}</p>
    <a class="btn" href="${href}">${t(button)}</a>
  </div>`;
}

export function busy(button, on, label) {
  button.disabled = on;
  button.setAttribute('aria-busy', String(on));
  if (label) button.innerHTML = label;
}
