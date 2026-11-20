// Where the website is running: as its own page (index.html), or embedded in The Herd's Wix site
// as the <herd-around-the-world> custom element (inside a shadow root, under Wix's header/footer).
export const env = {
  embedded: false,
  /** Where the site's parts live: the document, or the element's shadow root. */
  root: typeof document !== 'undefined' ? document : null,
  /** Where sheets and pop-ups are added (inside the shadow root when embedded, so they get our styles). */
  portal: null,
  /** The custom element itself (embedded only). */
  host: null,
  /** Folder the data files are served from (data/sample.json …). */
  base: null,
};

export function configure(opts) { Object.assign(env, opts); }

/** A data file next to the site: asset('data/sample.json'). */
export function asset(path) {
  if (env.base) return new URL(path, env.base).href;
  return new URL('../' + path, import.meta.url).href;
}

export const byId = (id) => env.root.getElementById(id);
export const portal = () => env.portal || document.body;

/** The focused element, even inside the shadow root. */
export function activeElement() {
  let a = document.activeElement;
  while (a && a.shadowRoot && a.shadowRoot.activeElement) a = a.shadowRoot.activeElement;
  return a;
}

/** Back to the top of the site: the top of the window, or the top of the element on the Wix page. */
export function scrollToAppTop() {
  if (!env.embedded || !env.host) { window.scrollTo(0, 0); return; }
  const top = env.host.getBoundingClientRect().top + window.scrollY;
  if (Math.abs(window.scrollY - top) > 2) window.scrollTo(0, Math.max(0, top));
}

/** Was the click inside an element with this class (works across the shadow root boundary)? */
export const clickedInside = (e, cls) => e.composedPath().some((n) => n.classList && n.classList.contains(cls));
