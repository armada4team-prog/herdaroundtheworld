// Companions in Your Care: the ones you've logged finding on this device and haven't passed on yet
// (and any whose next wish you get to choose).
import { companion, mine, account } from '../data.js';
import { openSignInSheet } from '../signin.js';
import { t, esc, badge, blob, icons } from '../ui.js';
import { tr, lang } from '../i18n.js';
import { label } from '../model.js';

export async function render({ root }) {
  document.title = `${tr('Companions in Your Care')} · ${tr('Herd Around the World')}`;
  const m = mine();
  const held = Object.entries(m.holds).map(([n, h]) => ({ c: companion(n), h })).filter((x) => x.c);
  const wishes = Object.keys(m.wishTokens).map((n) => companion(n)).filter(Boolean);
  const date = (iso) => { try { return new Date(iso).toLocaleDateString(lang(), { month: 'short', day: 'numeric' }); } catch (e) { return ''; } };

  root.innerHTML = `
  <section class="page-hero">
    ${blob('#F9EBB5', 'b-tr2')}
    <div class="wrap">
      <p class="eyebrow big">${t('Herd Around the World')}</p>
      <h1 class="script h-lg">${t('Companions in Your Care')}</h1>
      <p style="font-size:18px;max-width:680px">${t('The Companions you’ve found and are carrying now. When you’re ready, pass them on so the next traveler can find them.')}</p>
    </div>
  </section>
  <section class="section" style="padding-top:0"><div class="wrap">
    ${wishes.map((c) => `<div class="card butter" style="display:flex;gap:14px;align-items:center;flex-wrap:wrap;margin-bottom:16px">${icons.star}<p style="flex:1">${t(`You granted ${label(c)}’s wish! Choose their next one.`)}</p><a class="btn" href="#/c/${esc(c.number)}/wish">${t('Set their next wish →')}</a></div>`).join('')}
    ${held.length ? `<div class="care-list">${held.map(({ c, h }) => `<article class="care-card frame">
        <div class="top">${badge(c, 80, { waving: true, happy: true })}<div><h3>${esc(label(c))}</h3>
          <p class="muted">${t(`Found in ${h.city}`)}${h.date ? ' · ' + esc(date(h.date)) : ''}</p></div></div>
        <p style="font-size:14px">${t('Leaving them somewhere? Take them at least 5 miles from here first. Handing them to someone is fine anywhere.')}</p>
        <a class="btn" href="#/c/${esc(c.number)}/pass-on">${t('Pass them on')}</a>
        <a class="btn outline" href="#/c/${esc(c.number)}">${t('Open their page')}</a>
      </article>`).join('')}</div>`
      : `<div class="card" style="max-width:640px;padding:26px"><h2 class="chunky" style="font-size:22px">${t('No Companions in your care right now.')}</h2>
          <p>${t('Found one? Scan the code on their bottom, or type their number and find code.')}</p>
          <p style="margin-top:14px"><a class="btn" href="#/found">${t('Found a Companion')}</a></p></div>`}
    <div class="card care-account" style="margin-top:24px">
      ${account()
        ? `<p>${icons.check}<span>${t(`Signed in as ${account().email}`)}. ${t('This list follows you to every device.')}</span></p>
           <button type="button" class="btn outline small-btn" id="care-account">${t('Your sign-in')}</button>`
        : `<p>${icons.lock}<span>${t('This list is saved in this browser on this device.')} ${t('Sign up or sign in (optional and free) to see it on any phone or computer.')}</span></p>
           <button type="button" class="btn soft small-btn" id="care-account">${t('Sign up or sign in')}</button>`}
    </div>
  </div></section>`;
  root.querySelector('#care-account').addEventListener('click', () => openSignInSheet());
}
