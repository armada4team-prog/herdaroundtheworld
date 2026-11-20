// Step 1 of 2: "I found them" (TScan design, the app's Found screen). Needs the Companion's find
// code (from the QR link or typed on "Found a Companion") and the device's location.
import { companion, send, isHolding, unlockedCode, setUnlocked, updateMine, mine, withSession, account } from '../data.js';
import { scrollToAppTop } from '../env.js';
import { t, badge } from '../ui.js';
import { tr } from '../i18n.js';
import { checkNickname, cleanNumber } from '../../../shared/rules.js';
import { displayName } from '../model.js';
import { mountHere } from '../here.js';
import { formHero, textField, setError, bindTyping, showProblems, outOfOrder, busy } from '../forms.js';
import { notFound } from './companion.js';

export async function render({ params, root }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  const name = displayName(c);
  document.title = `${tr('I found them')} · ${tr('Herd Around the World')}`;

  if (isHolding(c.number)) {
    root.innerHTML = outOfOrder({
      c, title: `${name} is already with you`,
      message: `You’ve already logged finding ${name}. When you’re ready, pass them on so the next traveler can find them.`,
      button: 'Pass them on →', href: `#/c/${c.number}/pass-on`,
    });
    return;
  }
  const code = unlockedCode(c.number);
  if (!code) {
    root.innerHTML = outOfOrder({
      c, title: `Scan ${name}’s code first`,
      message: `To log a find, scan the code on ${name}’s bottom, or type their number and the 4-letter code printed under it. That’s how we know they’re really with you.`,
      button: 'Type their code →', href: `#/found?n=${encodeURIComponent(c.number)}`,
    });
    return;
  }

  root.innerHTML = `
    ${formHero({ eyebrow: `Step 1 of 2 · Companion #${c.number}`, title: `You found ${name}!`, c })}
    <section class="form-body"><div class="narrow">
      <p class="lead">${t(`Let everyone know ${name} is safe with you. It takes a few seconds. You’ll log where they go next when you pass them on.`)}</p>
      <div>
        <p class="field-label" id="where-label" style="margin-bottom:8px">${t('Where are you? *')}</p>
        <div data-field="where" id="where" role="group" aria-labelledby="where-label"></div>
      </div>
      ${textField({ id: 'nickname', label: 'Your name or nickname *', placeholder: 'Shown on their page', max: 30, value: mine().nickname, autocomplete: 'nickname' })}
      <div id="fix"></div>
      <button type="button" class="btn block" id="submit">${t('Log my find →')}</button>
    </div></section>`;

  let here = null;
  const where = mountHere(root.querySelector('#where'), (place) => {
    here = place;
    if (place) where.setError(null);
  });
  bindTyping(root);
  const button = root.querySelector('#submit');
  const fix = root.querySelector('#fix');

  button.addEventListener('click', async () => {
    const nickname = root.querySelector('#nickname').value.trim();
    const problems = [];
    const whereError = here ? null : 'We need your location to log a find.';
    const nicknameError = checkNickname(nickname);
    where.setError(whereError);
    setError(root, 'nickname', nicknameError);
    if (whereError) problems.push(whereError);
    if (nicknameError) problems.push(nicknameError);
    if (problems.length) { showProblems(root, fix, problems); return; }
    fix.innerHTML = '';
    busy(button, true, t('Logging…'));
    const res = await send('herdFind', withSession({
      number: c.number, code, nickname, city: here.city, latitude: here.latitude, longitude: here.longitude,
    }));
    busy(button, false, t('Log my find →'));
    if (!res.ok) {
      if (res.field === 'code') {
        setUnlocked(c.number, null);
        showProblems(root, fix, [res.message]);
        fix.insertAdjacentHTML('beforeend', `<a class="btn outline block" style="margin-top:12px" href="#/found?n=${encodeURIComponent(c.number)}">${t('Type their code →')}</a>`);
        return;
      }
      if (res.field === 'where') where.setError(res.message);
      else if (res.field === 'nickname') setError(root, 'nickname', res.message);
      showProblems(root, fix, [res.message]);
      return;
    }
    setUnlocked(c.number, null); // each scan logs one find
    updateMine((m) => {
      m.nickname = nickname;
      m.holds[cleanNumber(c.number)] = {
        token: res.holdToken, number: c.number, city: here.city,
        foundLatitude: here.latitude, foundLongitude: here.longitude, date: new Date().toISOString(),
        claimed: !!account(),
      };
      m.journal.push({ type: 'found', number: c.number, city: here.city, date: new Date().toISOString() });
      if (!m.following.includes(cleanNumber(c.number))) m.following.push(cleanNumber(c.number));
    });
    showDone();
  });

  function showDone() {
    root.innerHTML = `<section class="form-body"><div class="narrow center">
      <div style="display:flex;justify-content:center">${badge(c, 120, { waving: true, happy: true })}</div>
      <h1 class="script h-sm">${t('Logged! Enjoy your time together.')}</h1>
      <p class="lead">${t(`Take ${name} along for your trip. When you’re ready, scan them again and tap “I’m passing them on.”`)}</p>
      <p class="lead">${t('Leaving them somewhere? Take them at least 5 miles from here first. Handing them to someone is fine anywhere.')}</p>
      <div class="card" style="text-align:left">
        <h2 class="chunky" style="font-size:18px">${t(`Travel tips from ${name}`)}</h2>
        <div class="numbered"><span class="n">1</span><p>${t('Snap a photo of me somewhere fun. It makes a great chapter.')}</p></div>
        <div class="numbered"><span class="n">2</span><p>${t('Keep me a little while, then send me on. A week or two is perfect.')}</p></div>
      </div>
      <p class="muted">${t('They’re in Companions in Your Care on this device, so you can find them again.')}</p>
      <a class="btn block" href="#/c/${c.number}/pass-on">${t('I’m passing them on now')}</a>
      <a class="btn outline block" href="#/c/${c.number}/story">${t('See their full story')}</a>
    </div></section>`;
    scrollToAppTop();
    root.querySelector('h1').setAttribute('tabindex', '-1');
    root.querySelector('h1').focus();
  }
}
