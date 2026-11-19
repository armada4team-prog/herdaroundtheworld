// "Found a Companion": type their number and the 4-letter find code printed under it (the app's
// Scan tab, typing panel). A number alone only opens their page; the code unlocks logging a find.
import { companion, checkFindCode, setUnlocked } from '../data.js';
import { t, esc, icons, errorNote, figure, blob } from '../ui.js';
import { tr } from '../i18n.js';
import { cleanFindCode } from '../../../shared/rules.js';

export async function render({ query, root, go }) {
  document.title = `${tr('Found a Companion?')} · ${tr('Herd Around the World')}`;
  const n = query.get('n') || '';
  root.innerHTML = `
  <section class="form-hero">
    ${blob('#F9EBB5', 'b-tr')}
    <div class="narrow">
      <span class="badge" style="width:92px;height:92px;background:#DDF0E8">${figure({ glaze: 'A8DCC9', size: 50, waving: true, happy: true })}</span>
      <div>
        <h1 class="script">${t('Found a Companion?')}</h1>
        <p style="margin-top:6px">${t('Flip them over and point your camera at the code on their bottom.')}</p>
      </div>
    </div>
  </section>
  <section class="form-body"><div class="narrow">
    <form class="card" id="find-form" novalidate style="border-radius:24px;padding:20px">
      <h2 class="chunky" style="font-size:22px">${t('Type their number')}</h2>
      <p style="font-size:14px">${t('It’s printed on their bottom, under the code: “No. 07”.')}</p>
      <div class="field" data-field="number">
        <label class="sr-only" for="number">${t('Companion number')}</label>
        <div class="code-row"><span class="no" aria-hidden="true">${t('No.')}</span>
          <input id="number" inputmode="numeric" autocomplete="off" placeholder="07" value="${esc(n)}" maxlength="4" aria-describedby="number-err"></div>
        <div class="err-slot" id="number-err"></div>
      </div>
      <div class="field" data-field="code">
        <label class="chunky" for="code" style="font-size:16px">${t('Their find code')}</label>
        <div class="code-row"><input id="code" autocomplete="off" autocapitalize="characters" spellcheck="false" placeholder="KX4P" maxlength="6" aria-describedby="code-help code-err"></div>
        <p class="help" id="code-help">${t('The 4 letters printed under their number. You need it to log a find. Leave it empty to just look at their page.')}</p>
        <div class="err-slot" id="code-err"></div>
      </div>
      <button class="btn block" type="submit" id="go">${t('Find them →')}</button>
      <p class="muted">${t('Scanning the code with your phone’s camera opens their page with the code filled in.')}</p>
    </form>
  </div></section>`;

  const form = root.querySelector('#find-form');
  const numberEl = root.querySelector('#number');
  const codeEl = root.querySelector('#code');
  const mark = (name, msg) => {
    const field = form.querySelector(`[data-field="${name}"]`);
    field.classList.toggle('has-error', !!msg);
    field.querySelector('.err-slot').innerHTML = msg ? errorNote(msg) : '';
    (name === 'number' ? numberEl : codeEl).setAttribute('aria-invalid', String(!!msg));
  };
  numberEl.addEventListener('input', () => mark('number', null));
  codeEl.addEventListener('input', () => { codeEl.value = codeEl.value.toUpperCase(); mark('code', null); });
  if (n) codeEl.focus(); else numberEl.focus();

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const c = companion(numberEl.value);
    if (!c) {
      mark('number', 'We couldn’t find that number. Check their bottom and try again.');
      numberEl.focus();
      return;
    }
    const code = cleanFindCode(codeEl.value);
    if (!code) { go(`/c/${c.number}`); return; } // just looking at their page
    const button = root.querySelector('#go');
    button.disabled = true;
    const res = await checkFindCode(c.number, code);
    button.disabled = false;
    if (res.result === 'right') {
      setUnlocked(c.number, code);
      go(`/c/${c.number}?hello=1`);
      return;
    }
    if (res.result === 'tooManyTries') mark('code', 'Too many tries. Please wait 10 minutes and try again.');
    else if (res.result === 'wrong') mark('code', `That code doesn’t match #${c.number}. Check the letters under their number.`);
    else mark('number', res.message || 'Something went wrong on our side. Please try again in a minute.');
    codeEl.focus();
  });
}
