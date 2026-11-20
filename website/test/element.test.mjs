// The <herd-around-the-world> custom element inside a page that stands in for The Herd's Wix site:
// a fake Wix header and footer, and the element's script loaded from a different origin (like
// GitHub Pages). Preview mode. Builds the bundle first.
// Run from the repository root:  node --test website/test/*.test.mjs
// Optional: LEAFLET_DIR=path/to/leaflet/dist serves the map library locally (no internet here).
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, join, normalize, extname } from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json' };
const PHOTO = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGNYceckVsQwtCQAgN+TQWgDodIAAAAASUVORK5CYII=', 'base64');
const LEAFLET_DIR = process.env.LEAFLET_DIR || '';
const hasLeaflet = LEAFLET_DIR && existsSync(join(LEAFLET_DIR, 'leaflet.js'));

const WIX_PAGE = `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Herd Around the World | The Herd</title>
<style>body{margin:0;font-family:Georgia,serif;color:#222} .wix-header,.wix-footer{background:#2d2d2d;color:#fff;padding:24px 40px}
.wix-header nav a{color:#fff;margin-right:20px} p, h1, a, button { all: revert }</style></head>
<body><header class="wix-header" id="wix-header"><b>The Herd</b> <nav><a href="#">Home</a><a href="#">Portfolio</a><a href="/herd-around-the-world#/map">Herd Around the World</a></nav></header>
<section><herd-around-the-world></herd-around-the-world></section>
<footer class="wix-footer" id="wix-footer">© The Herd (Wix footer)</footer>
<script src="SCRIPT"></script></body></html>`;

let host, wix, browser, page, wixBase;

function serve(handler) {
  const s = createServer(handler);
  return new Promise((r) => s.listen(0, '127.0.0.1', () => r(s)));
}

before(async () => {
  execFileSync('node', [join(root, 'website', 'tools', 'build-element.mjs')], { stdio: 'inherit' });
  // "GitHub Pages": the bundle and data files, with CORS like Pages sends.
  host = await serve(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^(\.\.[/\\])+/, '');
    try {
      const body = await readFile(join(root, path));
      res.writeHead(200, { 'Content-Type': types[extname(path)] || 'application/octet-stream', 'Access-Control-Allow-Origin': '*' });
      res.end(body);
    } catch (e) { res.writeHead(404); res.end(); }
  });
  const script = `http://127.0.0.1:${host.address().port}/website/dist/herd-around-the-world.js`;
  // "The Herd's Wix site": one page with the element on it.
  wix = await serve((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(WIX_PAGE.replace('SCRIPT', script));
  });
  wixBase = `http://localhost:${wix.address().port}/herd-around-the-world`;
  browser = await chromium.launch();
});
after(async () => { await browser?.close(); host?.close(); wix?.close(); });

async function newPage(viewport) {
  const ctx = await browser.newContext({ viewport });
  // Outside services are off (the later route below wins for the map library).
  await ctx.route(/^https?:\/\/(?!127\.0\.0\.1|localhost)/, (route) => (route.request().url().includes('fonts.g') ? route.continue() : route.abort()));
  await ctx.route(/cdnjs\.cloudflare\.com\/ajax\/libs\/leaflet\/1\.9\.4\/(.*)$/, (route) => {
    if (!hasLeaflet) return route.abort();
    const file = route.request().url().split('/').pop().replace('.min', '');
    return route.fulfill({ path: join(LEAFLET_DIR, file), contentType: file.endsWith('.css') ? 'text/css' : 'application/javascript' });
  });
  page = await ctx.newPage();
  page.on('pageerror', (e) => { throw e; });
  return page;
}
async function open(path) {
  const url = wixBase + path;
  if (page.url() === url) await page.reload(); else await page.goto(url);
  await page.locator('#herd-app[data-ready="1"]').waitFor({ state: 'attached' });
}
const app = () => page.locator('herd-around-the-world');
const button = (name) => app().getByRole('button', { name, exact: false });
const expectIn = (scope, text) => scope.getByText(text, { exact: false }).first().waitFor({ state: 'visible', timeout: 5000 });

test('the element runs inside a Wix-like page', async () => {
  await newPage({ width: 1440, height: 900 });
  await open('?preview=1#/');
  await page.evaluate(() => { localStorage.clear(); sessionStorage.clear(); });
  await open('?preview=1#/');
  // Wix's header and footer stay; the element has its own slim bar and no header/footer of its own.
  assert.ok(await page.locator('#wix-header').isVisible());
  assert.ok(await page.locator('#wix-footer').isVisible());
  await expectIn(app(), 'Watch them go.');
  await expectIn(app(), 'Preview: nothing is saved yet');
  assert.equal(await app().locator('.site-footer').count(), 0);
  for (const name of ['Map', 'Found a Companion', 'Companions in Your Care', 'Passport']) {
    assert.ok(await app().locator('.herd-bar').getByRole('link', { name, exact: true }).isVisible(), name);
  }
  assert.ok(await page.locator('head link[data-herd-fonts]').count(), 'fonts are loaded in the page head');
  // The element grows with its content (no scrollbar of its own).
  const size = await page.evaluate(() => { const e = document.querySelector('herd-around-the-world'); return { h: e.getBoundingClientRect().height, sh: e.scrollHeight, ch: e.clientHeight }; });
  assert.ok(size.h > 2000, 'tall like its content');
  assert.equal(size.sh, size.ch);
  // Data files come from the script's host, not the Wix page.
  assert.ok(await app().locator('.originals .original').count() >= 6);

  // Map with filters.
  await app().locator('.herd-bar').getByRole('link', { name: 'Map', exact: true }).click();
  await expectIn(app(), 'Where the Companions are');
  await app().locator('[data-filter="originals"]').click();
  await expectIn(app().locator('.list-panel'), 'Originals #0–5');
  if (hasLeaflet) {
    await app().locator('.leaflet-container').waitFor();
    assert.ok(await app().locator('.herd-dot').count() > 10, 'dots on the map');
    assert.ok(await app().locator('.herd-dot.faded').count() > 10, 'others fade');
  }
  await app().locator('[data-pick="3"]').click();
  await expectIn(app().locator('.dot-card'), 'Wish: meet a dog');
  // The language button opens its list (clicks inside the shadow root aren't mistaken for outside).
  await app().locator('.lang-btn').click();
  assert.ok(await app().locator('.lang-list').isVisible());
  await page.locator('#wix-header').click();
  assert.equal(await app().locator('.lang-list').isVisible(), false);
});

test('find and pass on, inside the element', async () => {
  await open('?preview=1#/found?n=07');
  await app().locator('#code').fill('KCVT');
  await button('Find them').click();
  await app().locator('#hello').waitFor();
  await app().locator('#hello .close').click();
  await app().getByRole('link', { name: 'I just found them' }).click();
  await button('Aurora, CO').click();
  await app().locator('#nickname').fill('Robin');
  await button('Log my find').click();
  await expectIn(app(), 'Logged! Enjoy your time together.');
  await app().getByRole('link', { name: 'I’m passing them on now' }).click();
  await app().getByRole('radio', { name: 'Leaving them somewhere' }).click();
  await button('Aurora, CO').click();
  await button('Send them on their way').click();
  await expectIn(app(), 'Almost there! Please fix these first:');
  await button('Boulder, CO').click();
  await app().locator('#hint').fill('Bookshelf by the window at Bean Café');
  await app().locator('#photo').setInputFiles({ name: 'p.png', mimeType: 'image/png', buffer: PHOTO });
  await app().locator('[data-photo="photo"].filled').waitFor();
  await button('Send them on their way').click();
  await expectIn(app(), 'Thank you! They’re on their way.');
  assert.match(page.url(), /herd-around-the-world\?preview=1#\/c\/07\/sent$/);
  await open('?preview=1#/c/07');
  await expectIn(app(), 'Left by Robin');
});

test('sign up or sign in from the slim bar', async () => {
  await open('?preview=1#/care');
  await app().locator('.herd-bar .account-btn').click();
  const sheet = app().locator('.sheet');
  await expectIn(sheet, 'Save your Passport');
  await sheet.locator('input[type="email"]').fill('robin@example.com');
  await sheet.getByRole('button', { name: 'Email me a sign-in code' }).click();
  const code = (await sheet.locator('.preview-code').innerText()).match(/\d{6}/)[0];
  await sheet.locator('.code-input').fill(code);
  await sheet.getByRole('button', { name: 'Sign in' }).click();
  await expectIn(sheet, 'Signed in as robin@example.com');
  await sheet.locator('.sheet-close').click();
  await expectIn(app().locator('.herd-bar'), 'robin@example.com');
});

test('a QR link in query form (?c=3&k=MHE6) unlocks a find', async () => {
  await newPage({ width: 390, height: 844 });
  await page.goto(wixBase + '?preview=1&c=3&k=MHE6');
  await app().locator('#hello').waitFor();
  assert.match(page.url(), /herd-around-the-world\?preview=1#\/c\/3\?hello=1$/);
  await app().locator('#hello .close').click();
  assert.ok(await app().getByRole('link', { name: 'I just found them' }).isVisible());
});
