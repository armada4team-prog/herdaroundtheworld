// Herd Around the World website: header, footer, preview banner and the page router (#/map, #/c/07, …).
// Used by the standalone page (app.js) and by the Wix custom element (element.js).
import { load, state, resetPreview, account, syncAccount } from './data.js';
import { openSignInSheet } from './signin.js';
import { tr, lang, setLang, languages } from './i18n.js';
import { esc, t, icons } from './ui.js';
import { env, configure, byId, scrollToAppTop, clickedInside } from './env.js';
import * as home from './pages/home.js';
import * as mapPage from './pages/map.js';
import * as findPage from './pages/find.js';
import * as care from './pages/care.js';
import * as passport from './pages/passport.js';
import * as companionPage from './pages/companion.js';
import * as foundForm from './pages/found.js';
import * as passOn from './pages/pass-on.js';
import * as wish from './pages/wish.js';
import * as sent from './pages/sent.js';
import * as broke from './pages/broke.js';
import * as chat from './pages/chat.js';
import * as story from './pages/story.js';

export const HERD_SITE = 'https://www.theherdstudio.com';

const routes = [
  [/^\/?$/, home, 'home'],
  [/^\/map$/, mapPage, 'map'],
  [/^\/found$/, findPage, 'found'],
  [/^\/care$/, care, 'care'],
  [/^\/passport$/, passport, 'passport'],
  [/^\/c\/(\d+)$/, companionPage],
  [/^\/c\/(\d+)\/found$/, foundForm],
  [/^\/c\/(\d+)\/pass-on$/, passOn],
  [/^\/c\/(\d+)\/wish$/, wish],
  [/^\/c\/(\d+)\/sent$/, sent],
  [/^\/c\/(\d+)\/something-happened$/, broke],
  [/^\/c\/(\d+)\/chat$/, chat],
  [/^\/c\/(\d+)\/story$/, story],
];

let main = null;
let cleanup = null;
let currentKey = null;

function parseHash() {
  const raw = location.hash.replace(/^#/, '') || '/';
  const [path, qs] = raw.split('?');
  return { path: path || '/', query: new URLSearchParams(qs || '') };
}

/** Goes to a page: go('/c/07/found'). */
export function go(path, { replace = false } = {}) {
  const target = '#' + path;
  if (location.hash === target) { render(); return; }
  if (replace) location.replace(target); else location.hash = target;
}

/** Embedded in the Wix site: a slim bar (Wix has the site header and footer). */
function embeddedBar(active) {
  const links = [
    ['home', '#/', 'Home'],
    ['map', '#/map', 'Map'],
    ['found', '#/found', 'Found a Companion'],
    ['care', '#/care', 'Companions in Your Care'],
    ['passport', '#/passport', 'Passport'],
  ];
  const current = languages.find((l) => l.code === lang());
  return `<nav class="herd-bar" aria-label="${t('Herd Around the World')}">
    <div class="herd-bar-links">${links.map(([k, href, text]) => `<a href="${href}"${active === k ? ' aria-current="page"' : ''}>${t(text)}</a>`).join('')}</div>
    <div class="herd-bar-tools">
      ${accountButton('account-btn in-bar embedded')}
      ${langMenu(current)}
    </div>
  </nav>`;
}

function langMenu(current) {
  return `<div class="lang">
      <button class="lang-btn" type="button" aria-haspopup="true" aria-expanded="false" aria-label="${t('Language')}: ${esc(current.label)}">${icons.globe}<span>${esc(lang().toUpperCase())}</span></button>
      <ul class="lang-list" role="menu" hidden>
        ${languages.map((l) => `<li role="none"><button type="button" role="menuitemradio" aria-checked="${l.code === lang()}" data-lang="${l.code}">${esc(l.label)}</button></li>`).join('')}
      </ul>
    </div>`;
}

function header(active) {
  // Looks like The Herd's own site header: the logo, then the pages side by side in a mint pill.
  const links = [
    ['home', '#/', 'Home'],
    ['map', '#/map', 'Map'],
    ['found', '#/found', 'Found a Companion'],
    ['care', '#/care', 'Companions in Your Care'],
    ['passport', '#/passport', 'Passport'],
  ];
  const current = languages.find((l) => l.code === lang());
  return `<nav aria-label="${t('Main')}">
    <a class="herd-logo" href="${HERD_SITE}"><img src="img/herd-logo.png" alt="${t('The Herd')}" width="457" height="77"></a>
    <div class="menu-pill" id="menu">
      ${accountButton('account-btn in-menu')}
      ${links.map(([k, href, text]) => `<a href="${href}"${active === k ? ' aria-current="page"' : ''}>${t(text)}</a>`).join('')}
    </div>
    ${accountButton('account-btn in-bar')}
    ${langMenu(current)}
    <button class="circle-btn menu-btn" type="button" aria-expanded="false" aria-controls="menu" aria-label="${t('Menu')}">${icons.menu}</button>
  </nav>`;
}

/** "Sign up or sign in" (optional), or the signed-in traveler's email. */
function accountButton(cls) {
  const acct = account();
  const label = acct ? acct.email : tr('Sign up or sign in');
  return `<button type="button" class="${cls}" data-account aria-haspopup="dialog" aria-label="${esc(acct ? tr(`Signed in as ${acct.email}`) : label)}">${acct ? icons.check : icons.mail}<span>${esc(label)}</span></button>`;
}

function bindHeader(el) {
  el.querySelectorAll('[data-account]').forEach((b) => b.addEventListener('click', () => {
    el.classList.remove('menu-open');
    openSignInSheet();
  }));
  const langBtn = el.querySelector('.lang-btn');
  const list = el.querySelector('.lang-list');
  langBtn.addEventListener('click', () => {
    const open = list.hidden;
    list.hidden = !open;
    langBtn.setAttribute('aria-expanded', String(open));
    if (open) list.querySelector('[aria-checked="true"]').focus();
  });
  list.addEventListener('click', (e) => {
    const b = e.target.closest('[data-lang]');
    if (!b) return;
    setLang(b.dataset.lang);
    list.hidden = true;
    render(true);
  });
  const menuBtn = el.querySelector('.menu-btn');
  menuBtn?.addEventListener('click', () => {
    const open = !el.classList.contains('menu-open');
    el.classList.toggle('menu-open', open);
    menuBtn.setAttribute('aria-expanded', String(open));
  });
}

/** Closes the language list and menus on outside clicks or Escape (set up once). */
function closeMenusOnOutsideClick() {
  document.addEventListener('click', (e) => {
    const el = byId('header');
    if (!el) return;
    const list = el.querySelector('.lang-list');
    if (list && !clickedInside(e, 'lang')) { list.hidden = true; el.querySelector('.lang-btn')?.setAttribute('aria-expanded', 'false'); }
  });
  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    const el = byId('header');
    if (!el) return;
    const list = el.querySelector('.lang-list');
    if (list) list.hidden = true;
    el.classList.remove('menu-open');
  });
}

const INSTAGRAM = 'https://www.instagram.com/growtheherdstudio';

function footer() {
  // Laid out like The Herd's own site footer, with the Companions pages in the columns.
  return `<div class="foot">
    <div class="foot-brand">
      <p class="foot-title">The Herd</p>
      <p class="foot-tag">${t('Made to be part of the family.')}</p>
      <p class="foot-copy">${t('© 2026 The Herd. Made to be part of the family.')}</p>
    </div>
    <nav class="foot-cols" aria-label="${t('Footer')}">
      <div class="foot-col">
        <h2>${t('Explore')}</h2>
        <a href="#/map">${t('Map')}</a>
        <a href="#/found">${t('Found a Companion')}</a>
        <a href="#/passport">${t('Passport')}</a>
      </div>
      <div class="foot-col">
        <h2>${t('Connect')}</h2>
        <a href="${HERD_SITE}">${t('The Herd')}</a>
        <div class="foot-social">
          <a class="social" href="${INSTAGRAM}" target="_blank" rel="noopener" aria-label="Instagram"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4.5" y="4.5" width="15" height="15" rx="4.2" fill="none" stroke="#fff" stroke-width="1.8"/><circle cx="12" cy="12" r="3.6" fill="none" stroke="#fff" stroke-width="1.8"/><circle cx="16.3" cy="7.7" r="1.05" fill="#fff"/></svg></a>
        </div>
      </div>
      <div class="foot-col">
        <h2>${t('Other')}</h2>
        <a href="#/care">${t('Companions in Your Care')}</a>
        <button type="button" class="foot-link" data-foot-account>${t('Sign up or sign in')}</button>
      </div>
    </nav>
  </div>`;
}

function banner() {
  const el = byId('banner');
  if (state.mode !== 'preview') { el.innerHTML = ''; return; }
  el.innerHTML = `<div class="preview-banner" role="status"><span>${t('Preview: nothing is saved yet')}</span>
    <button type="button" id="reset-preview">${t('Start over')}</button></div>`;
  el.querySelector('#reset-preview').addEventListener('click', () => {
    resetPreview();
    location.reload();
  });
}

async function render(keepScroll = false) {
  const { path, query } = parseHash();
  let match = null, page = null, active = null;
  for (const [re, mod, key] of routes) {
    const m = path.match(re);
    if (m) { match = m; page = mod; active = key || null; break; }
  }
  if (!page) { go('/', { replace: true }); return; }
  if (cleanup) { try { cleanup(); } catch (e) { /* ignore */ } cleanup = null; }
  if (!env.embedded) document.documentElement.lang = lang();
  const skip = byId('skip');
  if (skip) skip.textContent = tr('Skip to content');
  const headerEl = byId('header');
  headerEl.className = env.embedded ? 'site-header embedded' : 'site-header';
  headerEl.innerHTML = env.embedded ? embeddedBar(active) : header(active);
  bindHeader(headerEl);
  const footerEl = byId('footer');
  if (footerEl) {
    footerEl.innerHTML = env.embedded ? '' : footer();
    footerEl.querySelector('[data-foot-account]')?.addEventListener('click', () => openSignInSheet());
  }
  appBody().dataset.page = active || path.split('/').slice(0, 3).join('-').replace(/^-/, '') || 'home';
  banner();
  const key = path + '?' + query.toString();
  const sameKey = key === currentKey;
  currentKey = key;
  main.innerHTML = '';
  const ctx = { params: match.slice(1), query, root: main, go, path };
  const result = await page.render(ctx);
  if (typeof result === 'function') cleanup = result;
  if (!keepScroll && !sameKey) {
    scrollToAppTop();
    const h1 = [...main.querySelectorAll('h1')].find((h) => h.offsetParent !== null);
    if (h1) { h1.setAttribute('tabindex', '-1'); h1.focus({ preventScroll: true }); }
  }
}

/** The element that carries data-mode / data-ready / data-page (body, or the element's wrapper). */
const appBody = () => (env.embedded ? byId('herd-app') : document.body);

/**
 * A QR link in query form (…/herd-around-the-world?c=07&k=CODE, or index.html?c=07&k=CODE) becomes
 * the Companion's page: #/c/07?k=CODE. The c and k are taken out of the address.
 */
function readQrQuery() {
  const q = new URLSearchParams(location.search);
  const c = q.get('c');
  if (!c || !/^\d{1,4}$/.test(c)) return;
  const k = q.get('k');
  q.delete('c'); q.delete('k');
  const rest = q.toString();
  const hash = '#/c/' + c + (k ? '?k=' + encodeURIComponent(k) : '');
  try {
    history.replaceState(history.state, '', location.pathname + (rest ? '?' + rest : '') + hash);
  } catch (e) {
    location.hash = hash;
  }
}

let started = false;
/** Starts the site. opts: see env.js (embedded, root, portal, host, base). */
export async function startApp(opts = {}) {
  if (started) return;
  started = true;
  configure(opts);
  main = byId('main');
  readQrQuery();
  window.addEventListener('hashchange', () => render());
  window.addEventListener('herd:account', () => render(true));
  closeMenusOnOutsideClick();
  setLang(lang());
  await load();
  await syncAccount();
  appBody().dataset.mode = state.mode;
  await render();
  appBody().dataset.ready = '1';
}
