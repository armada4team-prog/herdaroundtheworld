// "You made my wish come true!" (TWish design): the traveler who granted the wish picks the next one.
import { companion, send, wishTokenFor, mine, updateMine } from '../data.js';
import { t, esc, badge, blob, pill, errorNote } from '../ui.js';
import { tr } from '../i18n.js';
import { checkWish, cleanNumber } from '../../../shared/rules.js';
import { displayName } from '../model.js';
import { outOfOrder, busy } from '../forms.js';
import { notFound } from './companion.js';

const ideas = [
  'I want to ride a train.',
  'I want to meet a dog.',
  'I want to see snow.',
  'I want to go to a concert.',
  'I want to visit a library.',
  'I want to watch a sunrise.',
];

export async function render({ params, root, go }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  const name = displayName(c);
  document.title = `${tr('Wish granted')} · ${tr('Herd Around the World')}`;
  const wishToken = wishTokenFor(c.number);
  if (!wishToken) {
    root.innerHTML = outOfOrder({
      c, title: 'Only the traveler who granted their wish can choose the next one.',
      message: `“I want to ${c.wish}.”`, button: 'See their journey', href: `#/c/${c.number}`,
    });
    return;
  }
  const journal = mine().journal.filter((j) => j.type === 'wish' && cleanNumber(j.number) === cleanNumber(c.number));
  const grantedWish = journal.length ? journal[journal.length - 1].wish : c.wish;
  let pick = ideas[0];
  const nickname = mine().nickname;

  root.innerHTML = `<section class="form-body"><div class="narrow">
    <div class="wish-hero">
      ${blob('#DDF0E8', 'b-br')}
      ${badge(c, 130, { waving: true, happy: true })}
      ${pill(`★ Wish granted · Companion #${c.number}`, 'white')}
      <h1 class="script h-sm">${t('You made my wish come true!')}</h1>
      <p style="color:var(--ink)">${t(`“I wanted to ${grantedWish}.” Thanks to you, ${name} finally did. Everyone following them will hear the news.`)}</p>
    </div>
    <div class="card pink">
      <p class="eyebrow" style="color:var(--pink-ink)">${t('Your new stamp')}</p>
      <h2 class="chunky" style="font-size:26px;color:var(--pink-ink)">${t('Wish Granted')}</h2>
      <p>${t(`A special stamp for your Passport, added after a quick look at your photo. Everyone following ${name} will see you made it happen.`)}</p>
    </div>
    <div>
      <h2 class="chunky" style="font-size:22px;color:var(--sage-dark)">${t('You get to choose their next wish')}</h2>
      <p>${t('It goes on their page for the next traveler to try.')}</p>
    </div>
    <div class="wish-ideas" role="group" aria-label="${t('Wish ideas')}">
      ${ideas.map((i) => `<button type="button" class="wish-idea" aria-pressed="${i === pick}" data-idea="${esc(i)}">${t(i)}</button>`).join('')}
    </div>
    <div class="field" data-field="wish">
      <label for="wish">${t('Or write your own')}</label>
      <div class="wish-input"><span aria-hidden="true">${t('I want to')}</span><input id="wish" maxlength="50" placeholder="…" autocomplete="off" aria-describedby="wish-err"><span class="muted" id="wish-count">0/50</span></div>
      <div class="err-slot" id="wish-err"></div>
      <p class="help">${t('Keep it kind, safe and doable. Wishes are checked automatically, and The Herd takes a quick look.')}</p>
    </div>
    <div class="card">
      <p class="eyebrow">${t('On their page')}</p>
      <p class="script" style="font-size:26px" id="next-wish"></p>
      <p style="font-size:14px">${t(`Wish chosen by ${nickname || 'you'}, who granted their last one.`)}</p>
    </div>
    <button type="button" class="btn block" id="submit">${t('Set their next wish →')}</button>
  </div></section>`;

  const input = root.querySelector('#wish');
  const field = root.querySelector('[data-field="wish"]');
  const chosen = () => (input.value.trim() ? `I want to ${input.value.trim()}.` : pick);
  const setErr = (msg) => {
    field.classList.toggle('has-error', !!msg);
    field.querySelector('.err-slot').innerHTML = msg ? errorNote(msg) : '';
    input.setAttribute('aria-invalid', String(!!msg));
  };
  const update = () => {
    root.querySelector('#next-wish').textContent = tr(`Next wish: “${chosen()}”`);
    root.querySelector('#wish-count').textContent = `${input.value.length}/50`;
    root.querySelectorAll('.wish-idea').forEach((b) => b.setAttribute('aria-pressed', String(!input.value.trim() && b.dataset.idea === pick)));
  };
  root.querySelectorAll('.wish-idea').forEach((b) => b.addEventListener('click', () => { pick = b.dataset.idea; input.value = ''; setErr(null); update(); }));
  input.addEventListener('input', () => { setErr(null); update(); });
  update();

  const button = root.querySelector('#submit');
  button.addEventListener('click', async () => {
    if (input.value.trim()) {
      const error = checkWish(input.value.trim());
      if (error) { setErr(error); input.focus(); field.scrollIntoView({ block: 'center', behavior: 'smooth' }); return; }
    }
    busy(button, true);
    // The wish they typed (or picked) goes on the Companion's page, as typed.
    const res = await send('herdWish', { number: c.number, wishToken, wish: chosen() });
    busy(button, false);
    if (!res.ok) { setErr(res.message); input.focus(); return; }
    updateMine((m) => { delete m.wishTokens[cleanNumber(c.number)]; });
    go(`/c/${c.number}/sent`, { replace: true });
  });
}
