// Step 2 of 2: send them on their way (TLeave design, the app's Pass-on screen). Only the person
// holding the Companion can pass them on: hand them to someone (anywhere), or leave them somewhere
// at least 5 miles from where they were found, with a hint for the next traveler and a photo.
import { companion, send, holdFor, mine, updateMine } from '../data.js';
import { t, icons, fixList } from '../ui.js';
import { tr } from '../i18n.js';
import { checkNickname, checkPublicText, checkHint, milesBetween, minMilesToLeave, cleanNumber } from '../../../shared/rules.js';
import { displayName, wishSentence } from '../model.js';
import { mountHere } from '../here.js';
import { formHero, textField, setError, bindTyping, choices, bindChoices, photoField, bindPhoto, showProblems, outOfOrder, busy } from '../forms.js';
import { notFound } from './companion.js';

/** Photos chosen on this page, kept for the postcard on the "sent" page. */
export function rememberPhoto(number, dataUrl) {
  try { sessionStorage.setItem('herd.lastPhoto.' + cleanNumber(number), dataUrl); } catch (e) { /* too big or blocked */ }
}

export async function render({ params, root, go }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  const name = displayName(c);
  document.title = `${tr('Pass them on')} · ${tr('Herd Around the World')}`;
  const hold = holdFor(c.number);
  if (!hold) {
    root.innerHTML = outOfOrder({
      c, title: `Find ${name} first`,
      message: `Every Companion’s journey goes found, then left, then found again. Log that you found ${name} before you pass them on.`,
      button: 'I found them →', href: `#/c/${c.number}/found`,
    });
    return;
  }
  const me = mine();
  let handOn = true;
  let granted = false;
  let photo = null;
  let wishPhoto = null;
  let here = null;
  let triedToSend = false;

  root.innerHTML = `
    ${formHero({ eyebrow: `Step 2 of 2 · Companion #${c.number}`, title: `Send ${name} on their way`, intro: 'Thanks for traveling together. Tell us where they’re headed next.' })}
    <section class="form-body"><div class="narrow">
      ${me.nickname ? `<p class="card mint">${t(`Welcome back, ${me.nickname}! We filled in your details from last time.`)}</p>` : ''}
      ${choices('how', 'How are you passing them on? *', [
        { value: 'hand', title: 'Handing them to someone', badge: 'Most personal', detail: 'Give them to a fellow traveler: a new friend, a host, someone heading somewhere fun. Works anywhere, no distance needed.' },
        { value: 'leave', title: 'Leaving them somewhere', detail: 'A café shelf, a hostel lobby, a little free library. Somewhere they’ll be found, at least 5 miles from where you found them.' },
      ], 'hand')}
      <div>
        <p class="field-label" id="where-label" style="margin-bottom:8px">${t('Where are you? *')}</p>
        <div data-field="where" id="where" role="group" aria-labelledby="where-label"></div>
        <p class="help" style="margin-top:6px">${t('Please never use a home address. We only ever show a place name and city, never a street address.')}</p>
      </div>
      <div id="hint-wrap" hidden>
        ${textField({ id: 'hint', label: 'Where in the city? *', placeholder: 'Like a café on the plaza, or a hostel lobby', max: 120, help: 'This is the hint the next traveler uses to find them, and their dot on the map shows close to this spot. Be specific, like “bookshelf by the window at Bean Café.”' })}
      </div>
      <div>
        ${photoField({ id: 'photo', label: 'Add a photo *', prompt: 'A photo from your time together, or their new spot' })}
        <p class="lock-note" style="margin-top:8px">${icons.lock}<span>${t('We remove the hidden location data from photos, so only the spot you choose above is shared.')}</span></p>
      </div>
      <div>
        ${textField({ id: 'chapter', label: 'Add your chapter to their story', placeholder: 'Where did you go together? Who are you passing them to, and why?', max: 500, multiline: true, counter: true })}
        <p class="help">${t('Keep it kind and family-friendly. Chapters are checked, and The Herd takes a quick look.')}</p>
      </div>
      ${c.wishGranted ? '' : `<div class="card butter" id="wish-section" style="border-radius:18px">
        <p style="display:flex;gap:8px;align-items:center;font-weight:600;color:var(--wish-ink)">${icons.star}${t('Did you grant their wish?')}</p>
        <p class="script" style="font-size:26px;color:var(--wish-ink)">${t(`“${wishSentence(c)}”`)}</p>
        ${choices('granted', '', [
          { value: 'yes', title: 'Yes, we did it!', detail: 'Add a photo of the moment below. You’ll choose their next wish and earn a Wish Granted stamp.' },
          { value: 'no', title: 'Not this time', detail: 'That’s okay. The next traveler can try.' },
        ], 'no')}
        <div id="wish-photo-wrap" hidden>
          ${photoField({ id: 'wishPhoto', label: 'A photo of the wish coming true *', prompt: 'Add the photo', gold: true })}
          <p class="help" style="color:var(--butter-ink)">${t('Required for the Wish Granted stamp. It’s added once we see your photo.')}</p>
        </div>
      </div>`}
      ${textField({ id: 'nickname', label: 'Your name or nickname *', placeholder: 'Shown on their page', max: 30, value: me.nickname, autocomplete: 'nickname' })}
      <p class="card pink" style="font-size:14px">${t('Your sighting shows up right away. Photos and new wishes appear after a quick look, usually within a few days. Your new stamps appear in your Passport after that review.')}</p>
      <div id="fix"></div>
      <button type="button" class="btn block" id="submit">${t('Send them on their way →')}</button>
    </div></section>`;

  const fix = root.querySelector('#fix');
  const hintWrap = root.querySelector('#hint-wrap');

  /** The 5-mile rule: a message if they're still too close to where they found this Companion. */
  function tooClose(place) {
    if (handOn || !place) return null;
    const m = milesBetween(hold.foundLatitude, hold.foundLongitude, place.latitude, place.longitude);
    if (m >= minMilesToLeave) return null;
    if (m < 1) return 'To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re still close to where you found them. (Handing them to someone is fine anywhere.)';
    return `To leave a Companion somewhere, take them at least 5 miles from where you found them. You’re about ${m.toFixed(0)} miles away. (Handing them to someone is fine anywhere.)`;
  }

  // Problems on the form, in the order they appear. A field's problem clears as soon as it's fixed.
  const order = ['where', 'hint', 'photo', 'chapter', 'wishPhoto', 'nickname'];
  const errors = {};
  function setErr(k, msg) {
    errors[k] = msg || null;
    if (k === 'where') { if (where) where.setError(errors.where); } else setError(root, k, errors[k]);
    renderFix();
  }
  function renderFix() {
    const list = order.map((k) => errors[k]).filter(Boolean);
    fix.innerHTML = triedToSend && list.length ? fixList(list) : '';
  }

  let where = null;
  where = mountHere(root.querySelector('#where'), (place) => {
    here = place;
    setErr('where', place ? tooClose(place) : null);
  });

  bindChoices(root, 'how', (v) => {
    handOn = v === 'hand';
    hintWrap.hidden = handOn;
    if (handOn) setErr('hint', null);
    const prompt = root.querySelector('#photo-prompt');
    if (prompt) prompt.textContent = tr(handOn ? 'A photo from your time together, or their new spot' : 'A photo of the spot helps the next traveler find them');
    if (here) setErr('where', tooClose(here));
  });
  if (!c.wishGranted) {
    bindChoices(root, 'granted', (v) => {
      granted = v === 'yes';
      root.querySelector('#wish-photo-wrap').hidden = !granted;
      if (!granted) setErr('wishPhoto', null);
    });
    bindPhoto(root, 'wishPhoto', 'Add the photo', (p) => { wishPhoto = p; setErr('wishPhoto', null); });
  }
  bindPhoto(root, 'photo', '', (p) => { photo = p; setErr('photo', null); });
  bindTyping(root, (input) => { if (order.includes(input.id)) setErr(input.id, null); });

  const val = (id) => root.querySelector('#' + id).value.trim();

  function check() {
    const hint = val('hint');
    errors.where = here ? tooClose(here) : 'We need your location to pass them on.';
    errors.hint = handOn ? null : (hint ? checkHint(hint) : 'Please add a hint so the next person can find them.');
    errors.photo = photo ? null : 'Please add a photo.';
    errors.chapter = checkPublicText(val('chapter'), 500);
    errors.wishPhoto = granted && !wishPhoto ? 'Please add a photo of the wish coming true.' : null;
    errors.nickname = checkNickname(val('nickname'));
    where.setError(errors.where);
    for (const k of order.slice(1)) setError(root, k, errors[k]);
    return order.map((k) => errors[k]).filter(Boolean);
  }

  const button = root.querySelector('#submit');
  button.addEventListener('click', async () => {
    triedToSend = true;
    const problems = check();
    if (problems.length) { showProblems(root, fix, problems); return; }
    fix.innerHTML = '';
    busy(button, true, t('Sending…'));
    const nickname = val('nickname');
    const res = await send('herdPassOn', {
      number: c.number, holdToken: hold.token, handedOn: handOn,
      city: here.city, latitude: here.latitude, longitude: here.longitude,
      hint: handOn ? '' : val('hint'), chapter: val('chapter'), nickname,
      photo: { base64: photo.base64, mimeType: photo.mimeType },
      wishGranted: granted,
      wishPhoto: granted ? { base64: wishPhoto.base64, mimeType: wishPhoto.mimeType } : undefined,
    });
    busy(button, false, t('Send them on their way →'));
    if (!res.ok) {
      const field = order.includes(res.field) ? res.field : null;
      if (field) { errors[field] = res.message; if (field === 'where') where.setError(res.message); else setError(root, field, res.message); }
      showProblems(root, fix, field ? order.map((k) => errors[k]).filter(Boolean) : [res.message]);
      return;
    }
    const n = cleanNumber(c.number);
    rememberPhoto(c.number, photo.dataUrl);
    updateMine((m) => {
      m.nickname = nickname;
      delete m.holds[n];
      if (res.wishToken) m.wishTokens[n] = res.wishToken;
      const miles = milesBetween(hold.foundLatitude, hold.foundLongitude, here.latitude, here.longitude);
      m.journal.push({
        type: handOn ? 'passedOn' : 'left', number: c.number, city: here.city, place: handOn ? null : val('hint'),
        miles: Math.round(miles), date: new Date().toISOString(),
      });
      if (granted) m.journal.push({ type: 'wish', number: c.number, wish: c.wish, city: here.city, date: new Date().toISOString() });
    });
    go(granted ? `/c/${c.number}/wish` : `/c/${c.number}/sent`, { replace: true });
  });
}
