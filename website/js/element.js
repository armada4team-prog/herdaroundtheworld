// <herd-around-the-world>: the whole Companions website as one Wix "Custom Element".
// Built into herd-around-the-world.js by tools/build-element.mjs (with the site's CSS inside).
// It draws in its own shadow root, so Wix's styles and ours don't mix, under Wix's header/footer.
import siteCss from '../css/site.css';
import { startApp } from './shell.js';

const FONTS = 'https://fonts.googleapis.com/css2?family=Shadows+Into+Light+Two&family=Fira+Sans:wght@400;500;600&family=Baloo+2:wght@600;700;800&display=swap';
const LEAFLET_JS = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js';
const LEAFLET_CSS = 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.css';

// Where this script came from: data files are fetched from the same place, not from the Wix page.
const scriptUrl = (document.currentScript && document.currentScript.src) || '';
const PUBLISHED = 'https://armada4team-prog.github.io/herdaroundtheworld/';
function baseUrl(el) {
  if (el.getAttribute('base')) return new URL(el.getAttribute('base'), location.href).href;
  if (!scriptUrl) return PUBLISHED;
  const dir = new URL('./', scriptUrl);
  // A local build lives in website/dist/; the published site has the file at its root.
  return dir.pathname.endsWith('/dist/') ? new URL('../', dir).href : dir.href;
}

/** The page CSS works on :root and body; inside the element those are the host and our wrapper. */
function shadowCss(css) {
  return css
    .replace(/:root/g, ':host')
    .replace(/(^|[\s,}])html\s*\{/g, '$1.herd-html {')
    .replace(/(^|[\s,}])body\s*\{/g, '$1.herd-body {');
}

function addToHead(tag, attrs) {
  const el = document.createElement(tag);
  Object.assign(el, attrs);
  document.head.appendChild(el);
  return el;
}

/** Fonts don't load from inside a shadow root, so their stylesheet goes in the page's head. */
function loadFonts() {
  if (document.querySelector('link[data-herd-fonts]')) return;
  const link = addToHead('link', { rel: 'stylesheet', href: FONTS });
  link.dataset.herdFonts = '1';
}

/** The map library, loaded once for the page (the site still works if it can't load). */
let leafletPromise = null;
function loadLeaflet() {
  if (window.L) return Promise.resolve();
  leafletPromise ??= new Promise((resolve) => {
    const s = addToHead('script', { src: LEAFLET_JS, crossOrigin: 'anonymous', referrerPolicy: 'no-referrer' });
    s.onload = () => resolve();
    s.onerror = () => resolve();
    setTimeout(resolve, 10000);
  });
  return leafletPromise;
}

class HerdAroundTheWorld extends HTMLElement {
  async connectedCallback() {
    if (this.shadowRoot) return;
    loadFonts();
    const shadow = this.attachShadow({ mode: 'open' });
    shadow.innerHTML = `
      <style>
        :host { display: block; position: relative; width: 100%; }
        ${shadowCss(siteCss)}
      </style>
      <link rel="stylesheet" href="${LEAFLET_CSS}" crossorigin="anonymous" referrerpolicy="no-referrer">
      <div id="herd-app" class="herd-body herd-embedded">
        <div id="banner"></div>
        <header class="site-header embedded" id="header"></header>
        <main id="main" tabindex="-1"><div class="loading" role="status"><span class="spinner" style="display:inline-block"></span></div></main>
        <div id="portal"></div>
      </div>`;
    await loadLeaflet();
    startApp({ embedded: true, root: shadow, host: this, portal: shadow.getElementById('portal'), base: baseUrl(this) });
  }
}

if (!customElements.get('herd-around-the-world')) customElements.define('herd-around-the-world', HerdAroundTheWorld);
