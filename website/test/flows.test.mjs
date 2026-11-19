// Walks the website's main flows in preview mode, like a traveler would.
// Run from the repository root:  node --test website/test/flows.test.mjs
// Needs Node 18+ and Playwright with Chromium (require('playwright') must work).
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, join, normalize, extname } from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..'); // the repository (website/ + shared/)
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.svg': 'image/svg+xml' };
// A small real picture (8×8 PNG) to use as the traveler's photo.
const PHOTO = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGNYceckVsQwtCQAgN+TQWgDodIAAAAASUVORK5CYII=', 'base64');

let server, browser, page, base;

before(async () => {
  server = createServer(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^(\.\.[/\\])+/, '');
    try {
      const body = await readFile(join(root, path));
      res.writeHead(200, { 'Content-Type': types[extname(path)] || 'application/octet-stream' });
      res.end(body);
    } catch (e) {
      res.writeHead(404); res.end('not found');
    }
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}/website/index.html?preview=1`;
  browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  // No outside services in the test: map library, map tiles, OpenStreetMap and Wix are all switched off.
  await ctx.route(/^https?:\/\/(?!127\.0\.0\.1)/, (route) => {
    const url = route.request().url();
    if (url.includes('fonts.g')) return route.continue();
    return route.abort();
  });
  page = await ctx.newPage();
  page.on('pageerror', (e) => { throw e; });
});

after(async () => {
  await browser?.close();
  server?.close();
});

async function open(hash) {
  if (page.url() === base + hash) await page.reload(); else await page.goto(base + hash);
  await page.waitForSelector('body[data-ready="1"]');
}
const main = () => page.locator('main');
const button = (name) => page.getByRole('button', { name, exact: false });
const radio = (name) => page.getByRole('radio', { name, exact: false });
const link = (name) => page.getByRole('link', { name, exact: false });
async function expectText(text) {
  await main().getByText(text, { exact: false }).first().waitFor({ state: 'visible', timeout: 5000 });
}
async function choosePhoto(id) {
  await page.locator('#' + id).setInputFiles({ name: 'photo.png', mimeType: 'image/png', buffer: PHOTO });
  await page.locator(`[data-photo="${id}"].filled`).waitFor();
}
async function findWithCode(number, code, nickname, testCity) {
  await open(`#/found?n=${number}`);
  await page.fill('#code', code);
  await button('Find them').click();
  await page.locator('#hello').waitFor();
  await page.locator('#hello .close').click();
  await link('I just found them').click();
  await button(testCity).click();
  await page.fill('#nickname', nickname);
  await button('Log my find').click();
  await expectText('Logged! Enjoy your time together.');
}

test('find, leave, find again and hand on, with the app’s rules', async () => {
  await open('#/');
  await page.evaluate(() => { localStorage.clear(); sessionStorage.clear(); });
  await page.waitForSelector('.preview-banner');

  // A Companion's page without their code: no way to log a find, only "scan their code".
  await open('#/c/07');
  assert.equal(await link('I just found them').count(), 0);
  assert.equal(await link('Pass them on').count(), 0);
  await link('Found them? Scan their code').click();
  await page.waitForURL(/#\/found\?n=07/);
  assert.equal(await page.inputValue('#number'), '07');

  // A wrong code is turned away, in red.
  await page.fill('#code', 'WXYZ');
  await button('Find them').click();
  await expectText('That code doesn’t match #07');
  assert.ok(await page.locator('[data-field="code"].has-error').isVisible());

  // The right code opens their page with the hello card, and now a find can be logged.
  await page.fill('#code', 'kcvt');
  await button('Find them').click();
  await page.locator('#hello').waitFor();
  await page.locator('#hello .close').click();
  await link('I just found them').click();
  await page.waitForURL(/#\/c\/07\/found/);
  await button('Aurora, CO').click();
  await expectText('Aurora, CO');
  await page.fill('#nickname', 'Robin');
  await button('Log my find').click();
  await expectText('Logged! Enjoy your time together.');

  // Their page shows the find, and the pass-on button (only for the person holding them).
  await open('#/c/07');
  await expectText('Found by Robin');
  assert.equal(await link('I just found them').count(), 0);
  await link('Pass them on').click();
  await page.waitForURL(/#\/c\/07\/pass-on/);

  // Leaving them somewhere while still in Aurora: the 5-mile rule, with the fix list.
  await radio('Leaving them somewhere').click();
  await button('Aurora, CO').click();
  await expectText('You’re still close to where you found them');
  await button('Send them on their way').click();
  await expectText('Almost there! Please fix these first:');
  assert.ok(await page.locator('[data-field="where"].has-error').isVisible());
  assert.ok(await page.locator('[data-field="hint"].has-error').isVisible());
  assert.ok(await page.locator('[data-field="photo"].has-error').isVisible());
  assert.match(await page.locator('.fix-list').innerText(), /5 miles/);
  assert.match(await page.locator('.fix-list').innerText(), /Please add a photo\./);

  // In Boulder (about 20 miles away) with a hint and a photo. A swear word in the chapter is blocked.
  await button('Boulder, CO').click();
  assert.equal(await page.locator('[data-field="where"].has-error').count(), 0);
  await page.fill('#hint', 'Bookshelf by the window at Bean Café');
  await choosePhoto('photo');
  await page.fill('#chapter', 'What a sh1tty, fun road trip');
  await button('Send them on their way').click();
  await expectText('Please keep it kind. Some words aren’t allowed here.');
  assert.ok(await page.locator('[data-field="chapter"].has-error').isVisible());
  await page.fill('#chapter', 'We drove up into the mountains together.');
  await button('Send them on their way').click();
  await page.waitForURL(/#\/c\/07\/sent/);
  await expectText('Thank you! They’re on their way.');
  await expectText('Greetings from Boulder, CO!');

  // The journey says "Left by", with the hint; passing on again is blocked.
  await open('#/c/07');
  await expectText('Left by Robin');
  await expectText('Bookshelf by the window at Bean Café');
  assert.equal(await link('Pass them on').count(), 0);
  await open('#/c/07/pass-on');
  await expectText('Find #07 first');
  await open('#/c/07/story');
  await expectText('We drove up into the mountains together.');
  assert.ok(await page.locator('.chapter img').first().isVisible(), 'their photo shows on the story');

  // Find them again and hand them to someone right where they were found: fine anywhere.
  await findWithCode('07', 'KCVT', 'Robin', 'Denver, CO');
  await open('#/c/07/found');
  await expectText('#07 is already with you');
  await open('#/c/07/pass-on');
  await button('Denver, CO').click();
  await choosePhoto('photo');
  await button('Send them on their way').click();
  await page.waitForURL(/#\/c\/07\/sent/);
  await open('#/c/07');
  await expectText('Passed on by Robin');

  // Companions in Your Care is empty again; the Passport has stamps.
  await open('#/care');
  await expectText('No Companions in your care right now.');
  await open('#/passport');
  await expectText('Passed on #07');
});

test('a wish of "die" gets the 988 note; a typed wish is kept as typed', async () => {
  await findWithCode('3', 'MHE6', 'Robin', 'Aurora, CO');
  await open('#/c/3/pass-on');
  await button('Aurora, CO').click();
  await choosePhoto('photo');
  await radio('Yes, we did it!').click();
  await button('Send them on their way').click();
  await expectText('Please add a photo of the wish coming true.');
  await choosePhoto('wishPhoto');
  await button('Send them on their way').click();
  await page.waitForURL(/#\/c\/3\/wish/);
  await expectText('You made my wish come true!');
  await page.fill('#wish', 'die');
  await button('Set their next wish').click();
  await expectText('988');
  assert.ok(await page.locator('[data-field="wish"].has-error').isVisible());
  await page.fill('#wish', 'see a volcano');
  await button('Set their next wish').click();
  await page.waitForURL(/#\/c\/3\/sent/);
  await open('#/c/3');
  await expectText('I want to see a volcano.');
});

test('five wrong codes pause code checks for 10 minutes', async () => {
  await open('#/found?n=12');
  for (let i = 0; i < 5; i++) {
    await page.fill('#code', 'AAAA');
    await button('Find them').click();
    await page.locator('[data-field="code"].has-error').waitFor();
  }
  await expectText('Too many tries. Please wait 10 minutes and try again.');
  await page.fill('#code', 'TH3M'); // even the right code waits
  await button('Find them').click();
  await expectText('Too many tries.');
});
