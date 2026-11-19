// Traveler chat (TChat / TGuy designs): one conversation per Companion. Messages stay in the
// language they were written in. Phone numbers and emails are hidden by the checker.
import { companion, chatFor, send, mine, updateMine } from '../data.js';
import { t, esc, icons } from '../ui.js';
import { tr } from '../i18n.js';
import { checkNickname, checkPublicText } from '../../../shared/rules.js';
import { displayName } from '../model.js';
import { textField, setError, bindTyping, showProblems, busy } from '../forms.js';
import { notFound } from './companion.js';

function bubble(m) {
  const cls = m.mine ? ' mine' : '';
  const kind = m.herd ? ' herd' : '';
  return `<li class="bubble-wrap${cls}"><p class="bubble-who">${esc(m.author)}${m.when ? ' · ' + esc(tr(m.when)) : ''}</p><p class="bubble${kind}">${esc(m.message)}</p></li>`;
}

export async function render({ params, root }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  document.title = `${tr(`Travelers of #${c.number}`)} · ${tr('Herd Around the World')}`;
  const messages = await chatFor(c.number);

  root.innerHTML = `<section class="section sage" style="padding-top:50px"><div class="wrap chat-grid">
    <div>
      <p><a href="#/c/${c.number}" class="link-btn">${icons.back}${t(`Back to #${c.number}`)}</a></p>
      <h1 class="script h-md">${t(`Travelers of #${c.number}`)}</h1>
      <p>${t(`${c.travelers} travelers · everyone who’s carried ${displayName(c)}`)}</p>
      <p class="lock-note" style="margin-top:12px">${icons.lock}<span>${t('Be kind. Phone numbers, emails and addresses are hidden automatically.')}</span></p>
      <ul class="bubbles" id="bubbles" style="list-style:none;padding:0" aria-live="polite">
        ${messages.length ? messages.map(bubble).join('') : `<li class="muted">${t('Say hi to the travelers before you.')}</li>`}
      </ul>
    </div>
    <form class="join" id="chat-form" novalidate>
      <h2>${t('Join the conversation')}</h2>
      ${textField({ id: 'author', label: 'Your name or nickname *', max: 30, value: mine().nickname, autocomplete: 'nickname' })}
      ${textField({ id: 'message', label: 'Your note *', placeholder: `Message the travelers of #${c.number}`, max: 500, multiline: true, counter: true })}
      <p class="card pink" style="font-size:14px">${t('Be kind. Phone numbers, emails and addresses are hidden automatically.')}</p>
      <div id="fix"></div>
      <button class="btn block" type="submit" id="send">${t('Send')} ${icons.arrow}</button>
    </form>
  </div></section>`;

  const form = root.querySelector('#chat-form');
  const fix = root.querySelector('#fix');
  bindTyping(root);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const author = root.querySelector('#author').value.trim();
    const message = root.querySelector('#message').value.trim();
    const errors = {
      author: checkNickname(author),
      message: message ? checkPublicText(message, 500) : 'Please write a message.',
    };
    setError(root, 'author', errors.author);
    setError(root, 'message', errors.message);
    const problems = Object.values(errors).filter(Boolean);
    if (problems.length) { showProblems(root, fix, problems); return; }
    fix.innerHTML = '';
    const button = root.querySelector('#send');
    busy(button, true);
    const res = await send('herdChat', { number: c.number, author, message });
    busy(button, false);
    if (!res.ok) {
      if (res.field === 'author' || res.field === 'message') setError(root, res.field, res.message);
      showProblems(root, fix, [res.message]);
      return;
    }
    updateMine((m) => { m.nickname = author; });
    const list = root.querySelector('#bubbles');
    list.querySelector('.muted')?.remove();
    list.insertAdjacentHTML('beforeend', bubble({ author, message: res.message || message, mine: true, when: 'Just now' }));
    root.querySelector('#message').value = '';
    root.querySelector('[data-counter="message"]').textContent = '0/500';
  });
}
