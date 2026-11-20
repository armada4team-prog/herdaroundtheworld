// Optional "Sign up or sign in": one email-code flow (the first code creates the account).
// Nothing on the site needs it. It's shown inline on the Passport ("Keep your stamps safe") and in
// a small sheet opened from the header and Companions in Your Care.
import { account, signInStart, signInVerify, signOut, forgetMe, state } from './data.js';
import { t, esc, icons, errorNote } from './ui.js';
import { tr } from './i18n.js';
import { portal, activeElement } from './env.js';
import { isEmail } from '../../shared/rules.js';

let flash = null; // a note that survives the page re-drawing after signing in or out
const changed = () => window.dispatchEvent(new CustomEvent('herd:account'));

/**
 * Draws the sign-in flow into `el`. opts: { inSheet, onClose }.
 * Returns nothing; the element re-draws itself as the steps change.
 */
export function mountSignIn(el, opts = {}) {
  let step = account() ? 'in' : 'email';
  let email = '';
  let previewCode = null;
  let error = null; // { field, message }
  let busy = false;
  let collapsed = false;
  let note = opts.inSheet ? null : flash;
  if (!opts.inSheet) flash = null;

  const field = (name, inner) => `<div class="field${error && error.field === name ? ' has-error' : ''}" data-field="${name}">${inner}
      <div class="err-slot" id="${name}-signin-err">${error && error.field === name ? errorNote(error.message) : ''}</div></div>`;
  const ticks = ['No password to remember, ever', 'Never shown publicly or shared', 'Optional: finding and passing on never need it'];

  function draw() {
    const acct = account();
    if (acct && step !== 'in' && step !== 'confirm') step = 'in';
    if (!acct && (step === 'in' || step === 'confirm')) step = 'email';
    let html = '';
    if (collapsed && !opts.inSheet && !acct) {
      el.innerHTML = `<div class="signin-slim"><span>${icons.lock}${t('Keep your stamps safe')}</span>
        <button type="button" class="btn soft small-btn" data-act="expand">${t('Sign up or sign in')}</button></div>`;
      bind();
      return;
    }
    if (step === 'email') {
      html = `
        <div class="col-a">${opts.inSheet ? `<h2 class="chunky signin-title">${t('Save your Passport')}</h2>` : ''}
        <p class="script signin-script">${t('Keep your stamps safe')}</p>
        <p>${t('Optional and free. Add your email to keep your Passport, stamps and the Companions in your care on any phone or computer.')}</p>
        ${note ? `<p class="card mint signin-note" role="status">${t(note)}</p>` : ''}
        </div><div class="col-b">
        <form data-form="email" novalidate class="signin-form">
          ${field('email', `<label for="signin-email-${opts.inSheet ? 's' : 'p'}">${t('Your email')}</label>
            <input class="input" type="email" id="signin-email-${opts.inSheet ? 's' : 'p'}" autocomplete="email" inputmode="email" placeholder="${esc(tr('you@email.com'))}" value="${esc(email)}" aria-describedby="email-signin-err">`)}
          <button class="btn block" type="submit"${busy ? ' aria-busy="true" disabled' : ''}>${t('Email me a sign-in code')}</button>
        </form>
        <ul class="ticks">${ticks.map((x) => `<li>${icons.check}<span>${t(x)}</span></li>`).join('')}</ul>
        <p class="center"><button type="button" class="link-btn" data-act="not-now">${t('Not now')}</button></p></div>`;
    } else if (step === 'code') {
      html = `
        <div class="col-a">${opts.inSheet ? `<h2 class="chunky signin-title">${t('Save your Passport')}</h2>` : ''}
        <p class="script signin-script">${t('Check your email')}</p>
        <p>${t(`We sent a 6-digit code to ${email}. It works for 15 minutes.`)}</p>
        ${previewCode ? `<p class="preview-code" role="status">${t(`Preview: your code is ${previewCode}. On the real site it’s emailed.`)}</p>` : ''}
        </div><div class="col-b">
        <form data-form="code" novalidate class="signin-form">
          ${field('code', `<label for="signin-code-${opts.inSheet ? 's' : 'p'}">${t('Your 6-digit code')}</label>
            <input class="input code-input" id="signin-code-${opts.inSheet ? 's' : 'p'}" inputmode="numeric" autocomplete="one-time-code" maxlength="6" placeholder="123456" aria-describedby="code-signin-err">`)}
          <button class="btn block" type="submit"${busy ? ' aria-busy="true" disabled' : ''}>${t('Sign in')}</button>
        </form>
        <p class="center signin-links"><button type="button" class="link-btn" data-act="different">${t('Use a different email')}</button>
          <button type="button" class="link-btn" data-act="resend">${t('Send a new code')}</button></p></div>`;
    } else if (step === 'in') {
      html = `
        <div class="col-a">${opts.inSheet ? `<h2 class="chunky signin-title">${t('Your sign-in')}</h2>` : `<p class="script signin-script">${t('Your stamps are safe')}</p>`}
        <p class="signed-in">${icons.check}<span>${t(`Signed in as ${acct.email}`)}</span></p>
        <p>${t('Your Passport, the Companions in your care and the ones you follow are saved with your email, on every device.')}</p>
        ${note ? `<p class="card mint signin-note" role="status">${t(note)}</p>` : ''}
        </div><div class="col-b">
        <div class="actions"><button type="button" class="btn outline" data-act="sign-out">${t('Sign out')}</button></div>
        <p><button type="button" class="link-btn danger" data-act="delete">${t('Delete my data')}</button></p></div>`;
    } else if (step === 'confirm') {
      html = `
        <div class="confirm-box" role="alertdialog" aria-labelledby="confirm-title-${opts.inSheet ? 's' : 'p'}">
          <p class="chunky" id="confirm-title-${opts.inSheet ? 's' : 'p'}" style="font-size:19px;color:var(--error)">${t('Delete your email and sign-in from The Herd?')}</p>
          <p>${t('Your chapters stay on the Companions’ pages. Everything keeps working without signing in.')}</p>
          ${error ? errorNote(error.message) : ''}
          <div class="actions"><button type="button" class="btn danger-btn" data-act="confirm-delete">${t('Yes, delete my data')}</button>
          <button type="button" class="btn outline" data-act="keep">${t('Keep it')}</button></div>
        </div>`;
    }
    el.innerHTML = `<div class="signin${step === 'confirm' ? '' : ' signin-cols'}">${html}</div>`;
    bind();
  }

  function focus(sel) { const x = el.querySelector(sel); if (x) x.focus(); }

  async function sendCode() {
    busy = true; error = null; draw();
    const res = await signInStart(email);
    busy = false;
    if (!res.ok) {
      error = { field: 'email', message: res.message || 'Something went wrong on our side. Please try again in a minute.' };
      if (step === 'code') step = 'email';
      draw(); focus('input[type="email"]');
      return;
    }
    previewCode = state.mode === 'preview' ? res.previewCode : null;
    step = 'code'; draw(); focus('.code-input');
  }

  function bind() {
    el.querySelector('[data-form="email"]')?.addEventListener('submit', (e) => {
      e.preventDefault();
      email = el.querySelector('input[type="email"]').value.trim();
      note = null;
      if (!isEmail(email)) { error = { field: 'email', message: 'Please enter a valid email.' }; draw(); focus('input[type="email"]'); return; }
      sendCode();
    });
    el.querySelector('[data-form="code"]')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const code = el.querySelector('.code-input').value.replace(/\D/g, '');
      if (code.length !== 6) { error = { field: 'code', message: 'Please enter the 6-digit code from the email.' }; draw(); focus('.code-input'); return; }
      busy = true; error = null; draw();
      const res = await signInVerify(email, code);
      busy = false;
      if (!res.ok) { error = { field: res.field === 'code' ? 'code' : 'code', message: res.message }; draw(); focus('.code-input'); return; }
      step = 'in'; note = 'You’re signed in. Companions you found on this device came along.'; if (!opts.inSheet) flash = note;
      draw();
      changed();
    });
    el.querySelectorAll('input').forEach((i) => i.addEventListener('input', () => {
      if (!error) return;
      error = null;
      const f = i.closest('.field'); f.classList.remove('has-error'); f.querySelector('.err-slot').innerHTML = '';
    }));
    el.querySelectorAll('[data-act]').forEach((b) => b.addEventListener('click', async () => {
      const act = b.dataset.act;
      if (act === 'not-now') { if (opts.inSheet) opts.onClose?.(); else { collapsed = true; draw(); } }
      if (act === 'expand') { collapsed = false; draw(); focus('input[type="email"]'); }
      if (act === 'different') { step = 'email'; error = null; previewCode = null; draw(); focus('input[type="email"]'); }
      if (act === 'resend') sendCode();
      if (act === 'sign-out') { await signOut(); step = 'email'; note = 'You’re signed out. Everything still works on this device.'; if (!opts.inSheet) flash = note; draw(); changed(); }
      if (act === 'delete') { step = 'confirm'; error = null; draw(); focus('[data-act="keep"]'); }
      if (act === 'keep') { step = 'in'; draw(); }
      if (act === 'confirm-delete') {
        const res = await forgetMe();
        if (!res.ok) { error = { field: 'delete', message: res.message }; draw(); return; }
        step = 'email'; note = 'Your email and sign-in are deleted. Everything still works without signing in.'; if (!opts.inSheet) flash = note; draw(); changed();
      }
    }));
  }

  draw();
}

/** The small sheet (dialog) used by the header button and Companions in Your Care. */
export function openSignInSheet() {
  const last = activeElement();
  const wrap = document.createElement('div');
  wrap.className = 'sheet-overlay';
  wrap.innerHTML = `<div class="sheet" role="dialog" aria-modal="true" aria-label="${esc(tr(account() ? 'Your sign-in' : 'Sign up or sign in'))}">
    <button type="button" class="circle-btn sheet-close" aria-label="${t('Close')}">${icons.close}</button>
    <div class="sheet-body"></div></div>`;
  portal().appendChild(wrap);
  document.body.style.overflow = 'hidden';
  const close = () => {
    wrap.remove();
    document.body.style.overflow = '';
    window.removeEventListener('keydown', onKey);
    if (last && last.focus) last.focus();
  };
  const onKey = (e) => { if (e.key === 'Escape') close(); };
  window.addEventListener('keydown', onKey);
  wrap.addEventListener('click', (e) => { if (e.target === wrap) close(); });
  wrap.querySelector('.sheet-close').addEventListener('click', close);
  mountSignIn(wrap.querySelector('.sheet-body'), { inSheet: true, onClose: close });
  (wrap.querySelector('input') || wrap.querySelector('button')).focus();
  return close;
}
