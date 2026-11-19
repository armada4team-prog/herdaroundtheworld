// "Something happened" (TBroke design): broke, chipped or lost. Every journey deserves an ending.
import { companion, send, mine, updateMine } from '../data.js';
import { t, icons } from '../ui.js';
import { tr } from '../i18n.js';
import { checkPlaceFormat, checkPublicText, checkNickname, isEmail, cleanNumber } from '../../../shared/rules.js';
import { displayName } from '../model.js';
import { formHero, textField, setError, bindTyping, choices, bindChoices, showProblems, busy } from '../forms.js';
import { notFound } from './companion.js';

/** The app checks a typed place exists (OpenStreetMap). If the lookup can't run, the place is allowed. */
async function placeExists(place) {
  try {
    const res = await fetch('https://nominatim.openstreetmap.org/search?format=json&limit=1&q=' + encodeURIComponent(place), { headers: { Accept: 'application/json' } });
    if (!res.ok) return true;
    const list = await res.json();
    return Array.isArray(list) && list.length > 0;
  } catch (e) {
    return true;
  }
}

export async function render({ params, root }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  const name = displayName(c);
  document.title = `${tr('Something happened')} · ${tr('Herd Around the World')}`;
  let what = 'broke';
  let sendHome = true;

  root.innerHTML = `
    ${formHero({ eyebrow: `Companion #${c.number}`, title: `Oh no, did something happen to ${name}?`, c, intro: 'Clay is fragile, and accidents happen on the road. Thank you for letting everyone know. Every journey deserves an ending.' })}
    <section class="form-body"><div class="narrow">
      ${choices('what', 'What happened? *', [
        { value: 'broke', title: 'They broke', detail: 'Their journey ends here.' },
        { value: 'chipped', title: 'They got chipped, but can keep traveling', detail: 'Their journey continues.' },
        { value: 'lost', title: 'They got lost', detail: 'Their journey ends where they were last seen.' },
      ], 'broke')}
      ${textField({ id: 'where', label: 'Where? *', placeholder: 'City, State or Country, like Lisbon, Portugal' })}
      <div id="note-wrap">${textField({ id: 'note', label: 'Write their last chapter', placeholder: 'What happened, and what did they mean to you?', max: 500, multiline: true, counter: true })}</div>
      <div class="card mint" id="pieces">
        <h2 class="chunky" style="font-size:18px;color:var(--mint-ink)">${t('Want to send the pieces home?')}</h2>
        <p style="font-size:14px">${t('If you can, The Herd would love to have them back in the studio. We’ll email you how.')}</p>
        <button type="button" class="switch" role="switch" id="send-home" aria-checked="true"><span class="track" aria-hidden="true"></span><span>${t('Yes, tell me how')}</span></button>
        <div id="email-wrap">${textField({ id: 'email', label: 'Your email', placeholder: 'you@email.com', type: 'email', autocomplete: 'email', inputmode: 'email', help: 'Never shown publicly. Never shared.' })}</div>
      </div>
      ${textField({ id: 'nickname', label: 'Your name or nickname *', placeholder: 'Shown on their page', max: 30, value: mine().nickname, autocomplete: 'nickname' })}
      <p class="card" style="font-size:14px" id="retire-note">${t(`Everyone who followed ${name} will get a note, and their page will show a Retired badge with their whole journey kept safe.`)}</p>
      <div id="fix"></div>
      <button type="button" class="btn block" id="submit">${t('Share their last chapter')}</button>
    </div></section>`;

  const button = root.querySelector('#submit');
  const fix = root.querySelector('#fix');
  const val = (id) => root.querySelector('#' + id).value.trim();
  const setLabel = () => {
    root.querySelector('label[for="note"]').textContent = tr(what === 'chipped' ? 'Add a note (optional)' : 'Write their last chapter');
    root.querySelector('#pieces').hidden = what !== 'broke';
    root.querySelector('#retire-note').hidden = what === 'chipped';
    root.querySelector('#email-wrap').hidden = !sendHome;
    button.textContent = tr(what === 'chipped' ? 'Send the note' : 'Share their last chapter');
  };
  bindChoices(root, 'what', (v) => { what = v; setLabel(); });
  root.querySelector('#send-home').addEventListener('click', (e) => {
    sendHome = !sendHome;
    e.currentTarget.setAttribute('aria-checked', String(sendHome));
    if (!sendHome) setError(root, 'email', null);
    setLabel();
  });
  bindTyping(root);
  setLabel();

  button.addEventListener('click', async () => {
    const wantsEmail = what === 'broke' && sendHome;
    const errors = {
      where: checkPlaceFormat(val('where')),
      note: checkPublicText(val('note'), 500),
      email: wantsEmail && val('email') && !isEmail(val('email')) ? 'Please enter a valid email, or leave it empty.' : null,
      nickname: checkNickname(val('nickname')),
    };
    for (const [k, v] of Object.entries(errors)) setError(root, k, v);
    const problems = Object.values(errors).filter(Boolean);
    if (problems.length) { showProblems(root, fix, problems); return; }
    fix.innerHTML = '';
    busy(button, true);
    if (!(await placeExists(val('where')))) {
      busy(button, false);
      const msg = 'We couldn’t find that place. Check the spelling, like Lisbon, Portugal.';
      setError(root, 'where', msg);
      showProblems(root, fix, [msg]);
      return;
    }
    const res = await send('herdReport', {
      number: c.number, what, city: val('where'), note: val('note'), byName: val('nickname'),
      sendPieces: wantsEmail, email: wantsEmail ? val('email') : '',
    });
    busy(button, false);
    setLabel();
    if (!res.ok) {
      const map = { where: 'where', note: 'note', email: 'email', nickname: 'nickname' };
      if (map[res.field]) setError(root, map[res.field], res.message);
      showProblems(root, fix, [res.message]);
      return;
    }
    updateMine((m) => {
      m.nickname = val('nickname');
      if (what !== 'chipped') delete m.holds[cleanNumber(c.number)];
    });
    root.innerHTML = `<section class="form-body"><div class="narrow center">
      <p style="display:flex;justify-content:center">${icons.heart.replace('class="ic"', 'class="ic" style="width:40px;height:40px"')}</p>
      <h1 class="script h-sm">${t('Thank you for telling us')}</h1>
      <p class="lead">${t(what === 'chipped' ? `We’ve noted the chip. ${name} can keep traveling.` : `Everyone who followed ${name} will get a note, and their journey is kept safe on their page.`)}</p>
      <a class="btn block" href="#/c/${c.number}">${t('Back to their page')}</a>
    </div></section>`;
    root.querySelector('h1').setAttribute('tabindex', '-1');
    root.querySelector('h1').focus();
    window.scrollTo(0, 0);
  });
}
