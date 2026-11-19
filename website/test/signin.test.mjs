// The optional email sign-in, in preview mode (the code is shown on screen instead of emailed).
// Run from the repository root:  node --test website/test/
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { dirname, join, normalize, extname } from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json' };
const PHOTO = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAEUlEQVR4nGNYceckVsQwtCQAgN+TQWgDodIAAAAASUVORK5CYII=', 'base64');
let server, browser, page, base;

before(async () => {
  server = createServer(async (req, res) => {
    const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname)).replace(/^(\.\.[/\\])+/, '');
    try {
      const body = await readFile(join(root, path));
      res.writeHead(200, { 'Content-Type': types[extname(path)] || 'application/octet-stream' });
      res.end(body);
    } catch (e) { res.writeHead(404); res.end(); }
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}/website/index.html?preview=1`;
  browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await ctx.route(/^https?:\/\/(?!127\.0\.0\.1)/, (route) => (route.request().url().includes('fonts.g') ? route.continue() : route.abort()));
  page = await ctx.newPage();
  page.on('pageerror', (e) => { throw e; });
});
after(async () => { await browser?.close(); server?.close(); });

async function open(hash) {
  if (page.url() === base + hash) await page.reload(); else await page.goto(base + hash);
  await page.waitForSelector('body[data-ready="1"]');
}
const main = () => page.locator('main');
const button = (name, scope = page) => scope.getByRole('button', { name, exact: false });
const expectIn = (scope, text) => scope.getByText(text, { exact: false }).first().waitFor({ state: 'visible', timeout: 5000 });
const db = () => page.evaluate(() => JSON.parse(localStorage.getItem('herd.preview.v1') || '{}'));
/** Another device: forget everything this browser knew, but keep the sign-in. */
async function otherDevice() {
  await page.evaluate(() => { localStorage.removeItem('herd.mine.preview'); sessionStorage.clear(); });
  await page.reload();
  await page.waitForSelector('body[data-ready="1"]');
}

async function find(number, code, testCity) {
  await open(`#/found?n=${number}`);
  await page.fill('#code', code);
  await button('Find them').click();
  await page.locator('#hello').waitFor();
  await page.locator('#hello .close').click();
  await page.getByRole('link', { name: 'I just found them' }).click();
  await button(testCity).click();
  await page.fill('#nickname', 'Robin');
  await button('Log my find').click();
  await expectIn(main(), 'Logged! Enjoy your time together.');
}

async function signIn(email, scope) {
  await scope.locator('input[type="email"]').fill(email);
  await button('Email me a sign-in code', scope).click();
  const note = scope.locator('.preview-code');
  await note.waitFor();
  return (await note.innerText()).match(/\b(\d{6})\b/)[1];
}

test('sign in is optional, carries earlier finds, syncs follows, signs out, deletes', async () => {
  await open('#/');
  await page.evaluate(() => { localStorage.clear(); sessionStorage.clear(); });

  // Without signing in, a find works as always.
  await find('07', 'KCVT', 'Aurora, CO');
  await open('#/care');
  await expectIn(main(), '#07');

  // The header button opens the sheet: bad email, then the code (shown on screen in preview).
  await page.locator('.account-btn.in-bar').click();
  const sheet = page.locator('.sheet');
  await expectIn(sheet, 'Save your Passport');
  await sheet.locator('input[type="email"]').fill('not-an-email');
  await button('Email me a sign-in code', sheet).click();
  await expectIn(sheet, 'Please enter a valid email.');
  assert.ok(await sheet.locator('[data-field="email"].has-error').isVisible());
  const code = await signIn('robin@example.com', sheet);
  await expectIn(sheet, 'Preview: your code is');
  await sheet.locator('.code-input').fill(code === '000000' ? '111111' : '000000');
  await button('Sign in', sheet).click();
  await expectIn(sheet, 'That code isn’t right.');
  assert.ok(await sheet.locator('[data-field="code"].has-error').isVisible());
  await sheet.locator('.code-input').fill(code);
  await button('Sign in', sheet).click();
  await expectIn(sheet, 'Signed in as robin@example.com');
  await sheet.locator('.sheet-close').click();
  await expectIn(page.locator('.account-btn.in-bar'), 'robin@example.com');

  // The find from before signing in came along.
  let d = await db();
  assert.equal(d.holds['7'].travelerId, d.travelers['robin@example.com'].id);

  // On "another device" (nothing stored but the sign-in), the Companion in their care comes back.
  await otherDevice();
  await open('#/care');
  await expectIn(main(), '#07');
  await expectIn(main(), 'Signed in as robin@example.com');

  // Following syncs with the sign-in.
  await open('#/c/3');
  await page.locator('#follow').click();
  await page.waitForFunction(() => (JSON.parse(localStorage.getItem('herd.preview.v1')).travelers['robin@example.com'].following || []).includes('3'));
  await otherDevice();
  await open('#/c/3');
  assert.equal(await page.locator('#follow').getAttribute('aria-checked'), 'true');

  // Passing on works with a find from "another device" (the checker keeps the 5-mile rule).
  await open('#/c/07/pass-on');
  await button('Denver, CO').click();
  await page.locator('#photo').setInputFiles({ name: 'p.png', mimeType: 'image/png', buffer: PHOTO });
  await page.locator('[data-photo="photo"].filled').waitFor();
  await button('Send them on their way').click();
  await page.waitForURL(/#\/c\/07\/sent/);
  await otherDevice();
  await open('#/passport');
  await expectIn(main(), 'Passed on #07');

  // Sign out from the Passport card: back to this browser only, and finding still works.
  await button('Sign out', main()).click();
  await expectIn(main(), 'You’re signed out.');
  await expectIn(page.locator('.account-btn.in-bar'), 'Sign up or sign in');
  await find('12', 'TH3M', 'Boulder, CO');
  await open('#/care');
  await expectIn(main(), '#12');
  await expectIn(main(), 'This list is saved in this browser on this device.');

  // One code a minute for the same email.
  await button('Sign up or sign in', main()).click();
  await page.locator('.sheet input[type="email"]').fill('robin@example.com');
  await button('Email me a sign-in code', page.locator('.sheet')).click();
  await expectIn(page.locator('.sheet'), 'Please wait a minute');
  assert.ok(await page.locator('.sheet [data-field="email"].has-error').isVisible());
  await page.locator('.sheet .sheet-close').click();

  // Sign up with a new email from Care, then delete my data (two steps, in the page).
  await button('Sign up or sign in', main()).click();
  const sheet2 = page.locator('.sheet');
  const code2 = await signIn('sam@example.com', sheet2);
  await sheet2.locator('.code-input').fill(code2);
  await button('Sign in', sheet2).click();
  await expectIn(sheet2, 'Signed in as sam@example.com');
  d = await db();
  assert.equal(d.holds['12'].travelerId, d.travelers['sam@example.com'].id, 'the find from before signing up came along');
  await button('Delete my data', sheet2).click();
  await expectIn(sheet2, 'Delete your email and sign-in from The Herd?');
  await button('Keep it', sheet2).click();
  await expectIn(sheet2, 'Signed in as sam@example.com');
  await button('Delete my data', sheet2).click();
  await button('Yes, delete my data', sheet2).click();
  await expectIn(sheet2, 'Your email and sign-in are deleted.');
  d = await db();
  assert.equal(d.travelers['sam@example.com'], undefined);
  assert.equal(d.holds['12'].travelerId, null);
  await page.locator('.sheet .sheet-close').click();
  await expectIn(page.locator('.account-btn.in-bar'), 'Sign up or sign in');
});
