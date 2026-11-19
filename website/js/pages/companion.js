// One page per Companion (TGuy design, phone: the app's Companion screen). A QR scan opens it
// with the hello card on top (THello design).
import { companion, isHolding, unlockedCode, setUnlocked, checkFindCode, isFollowing, toggleFollow, chatFor } from '../data.js';
import { t, esc, icons, figure, badge, blob, pill, share } from '../ui.js';
import { tr } from '../i18n.js';
import { displayName, label, current, wishSentence, stopCount, miles, byLine, statusLabels, formatThousands } from '../model.js';
import { makeMap, dot, fit, hasLeaflet } from '../maps.js';

export function notFound(number) {
  return `<div class="narrow out-of-order"><h1 class="script">${t('Hmm, who’s that?')}</h1>
    <p class="lead">${t(`We couldn’t find #${number}. Check the number on their bottom and try again.`)}</p>
    <a class="btn" href="#/found">${t('Found a Companion')}</a></div>`;
}

export function wishCard(c) {
  return `<div class="wish-card">${icons.star}<div>
    <p class="eyebrow">${t(c.wishGranted ? 'Their wish · granted!' : 'Their wish · not granted yet')}</p>
    <p class="script">${t(`“${wishSentence(c)}”`)}</p>
    ${c.wishGranted ? '' : `<p style="font-size:14px">${t('Can you help? Whoever grants it chooses their next wish and earns a Wish Granted stamp.')}</p>`}
  </div></div>`;
}

export function stopMeta(stop, isNow) {
  return [isNow ? 'Now' : null, stop.place, byLine(stop), stop.when].filter(Boolean).map((x) => tr(x)).join(' · ');
}

function helloCard(c) {
  const cur = current(c);
  return `<div class="hello-overlay" id="hello" role="dialog" aria-modal="true" aria-labelledby="hello-title">
    <div class="hello">
      ${blob('#F6D3D3', 'b-tl')}${blob('#F9EBB5', 'b-br')}
      <button type="button" class="circle-btn close" data-close aria-label="${t('Close')}">${icons.close}</button>
      ${badge(c, 104, { waving: true, happy: true })}
      <p class="eyebrow">${t(`Art in Transit · No. ${c.number}`)}</p>
      <h2 class="script" id="hello-title">${t(`Hi, I’m ${displayName(c)}!`)}</h2>
      <p>${esc(c.blurb)}</p>
      <div class="my-wish">${icons.star}<div><p class="eyebrow" style="color:var(--butter-ink)">${t('My wish')}</p><p class="script">${t(`“${wishSentence(c)}”`)}</p></div></div>
      <div class="pills" style="justify-content:center">${pill(`${stopCount(c)} stops`, 'beige')}${cur ? pill(`Last seen in ${cur.city}`, 'beige') : ''}</div>
      <div class="how-card">
        <p class="eyebrow">${t('How this works')}</p>
        <div class="numbered"><span class="n">1</span><p>${t('Take me along for a while, and help my wish come true if you can!')}</p></div>
        <div class="numbered"><span class="n">2</span><p>${t('Leave me somewhere new for someone else to find.')}</p></div>
        <div class="numbered"><span class="n">3</span><p>${t('Log the spot and add your chapter to my story.')}</p></div>
        <p class="card pink" style="padding:10px;font-size:14px">${t('Log where you leave me and earn a stamp in your Passport.')}</p>
      </div>
      <button type="button" class="btn block" data-close>${t('See where I’ve been ↓')}</button>
      <p class="muted">${t('You’ve found a piece of ')}<b>${t('Art in Transit')}</b>${t(', a traveling art project by The Herd. No app, no sign-up, no cost.')}</p>
    </div>
  </div>`;
}

export async function render({ params, query, root, go }) {
  const number = params[0];
  const c = companion(number);
  if (!c) { root.innerHTML = notFound(number); return; }
  document.title = `${label(c)} · ${tr('Herd Around the World')}`;

  // A QR link (?k=CODE) unlocks logging a find, once the code checks out.
  const k = query.get('k');
  let showHello = query.get('hello') === '1' || !!k;
  if (k) {
    const res = await checkFindCode(c.number, k);
    if (res.result === 'right') setUnlocked(c.number, k);
    go(`/c/${number}${showHello ? '?hello=1' : ''}`, { replace: true });
    return;
  }

  const retired = c.status === 'retired';
  const holding = isHolding(c.number);
  const unlocked = !!unlockedCode(c.number);
  const cur = current(c);
  const chapters = c.stops.filter((s) => s.chapter).length + 1;
  const chat = await chatFor(c.number);
  const lastChat = chat.length ? chat[chat.length - 1].message : 'Say hi to the travelers before you.';

  let mainButton = '';
  if (!retired) {
    if (unlocked) mainButton = `<a class="btn" href="#/c/${c.number}/found">${t('I just found them')} ${icons.arrow}</a>`;
    else if (!holding) mainButton = `<a class="btn" href="#/found?n=${encodeURIComponent(c.number)}">${t('Found them? Scan their code')}</a>`;
    if (holding) mainButton += `<a class="btn soft" href="#/c/${c.number}/pass-on">${t('Pass them on')}</a>`;
  }

  root.innerHTML = `
  <section class="guy-hero">
    ${blob('#F6D3D3', 'b-left')}
    <div class="wrap">
      <div class="guy-art">${blob('#' + c.blob, 'fill')}${c.profilePhoto ? `<img src="${esc(c.profilePhoto)}" alt="${t(`Companion #${c.number}`)}">` : figure({ glaze: c.glaze, size: 200, waving: false, label: tr(`Companion #${c.number}`) })}</div>
      <div>
        <p class="eyebrow big">${t(`Companion #${c.number}`)}</p>
        <h1 class="script guy-name">${esc(displayName(c))}</h1>
        <div class="pills">
          ${pill(statusLabels[c.status] || c.status, retired ? 'retired' : 'mint')}
          ${cur ? `<span class="pill white">${icons.pin}${t(`Last seen in ${cur.city}`)}</span>` : ''}
          ${pill(`${stopCount(c)} stops`, 'white')}
          ${pill(`${formatThousands(miles(c))} miles`, 'butter')}
          ${pill(`${c.travelers} travelers`, 'white')}
        </div>
        <div style="margin-top:18px">${wishCard(c)}</div>
        <div class="actions" style="margin-top:20px">
          ${mainButton}
          <a class="btn soft" href="#/c/${c.number}/chat">${t('Traveler chat')}</a>
          <button type="button" class="btn outline" id="share">${icons.share}<span>${t('Share')}</span></button>
        </div>
        <div class="follow-card" style="margin-top:18px">
          <button type="button" class="switch" role="switch" id="follow" aria-checked="${isFollowing(c.number)}"><span class="track" aria-hidden="true"></span><span>${t(`Follow #${c.number}`)}</span></button>
          <span class="muted">${t('Companions you follow show up under Following on the map.')}</span>
        </div>
      </div>
    </div>
  </section>
  <section class="section" style="padding-top:60px">
    <div class="wrap">
      <h2 class="script h-md">${t('Where they’ve been')}</h2>
      <div class="journey-map" id="journey-map"></div>
      <p class="muted" style="margin-top:8px;display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap"><span>${t(`Live · updated ${c.lastMoved}`)}</span><a href="#/map">${t('World map →')}</a></p>
      <ol class="stops" reversed>
        ${c.stops.map((s, i) => ({ s, i })).reverse().map(({ s, i }) => {
          const isNow = i === c.stops.length - 1;
          return `<li class="stop${isNow ? ' now' : ''}"><span class="n" aria-hidden="true">${i + 1}</span><div><p class="city">${esc(s.city)}</p><p class="meta">${esc(stopMeta(s, isNow))}</p></div></li>`;
        }).join('')}
      </ol>
      <div class="pills" style="margin-top:26px;align-items:center">
        <a class="btn" href="#/c/${c.number}/story">${t(`Their story · ${chapters} chapters`)}</a>
        <a class="btn outline" href="#/c/${c.number}/chat">${t(`Traveler chat · ${c.travelers} travelers`)}</a>
      </div>
      <p class="muted" style="margin-top:10px">${t('Read every traveler’s chapter and the chat')} · “${esc(lastChat)}”</p>
      <div style="display:flex;justify-content:space-between;flex-wrap:wrap;margin-top:16px">
        <button type="button" class="link-btn" id="about">${t(`About #${c.number}`)}</button>
        ${retired ? '' : `<a class="link-btn" href="#/c/${c.number}/something-happened">${t('Something happened to them?')}</a>`}
      </div>
    </div>
  </section>
  <div id="hello-slot"></div>`;

  root.querySelector('#share').addEventListener('click', (e) =>
    share(`Follow Companion #${c.number} around the world with The Herd:`, `https://theherdstudio.com/c/${c.number}`, e.currentTarget));
  root.querySelector('#follow').addEventListener('click', (e) => {
    toggleFollow(c.number);
    e.currentTarget.setAttribute('aria-checked', String(isFollowing(c.number)));
  });

  const slot = root.querySelector('#hello-slot');
  let lastFocus = null;
  function openHello() {
    lastFocus = document.activeElement;
    slot.innerHTML = helloCard(c);
    const overlay = slot.querySelector('#hello');
    overlay.querySelectorAll('[data-close]').forEach((b) => b.addEventListener('click', closeHello));
    overlay.addEventListener('click', (e) => { if (e.target === overlay) closeHello(); });
    overlay.addEventListener('keydown', (e) => { if (e.key === 'Escape') closeHello(); });
    document.body.style.overflow = 'hidden';
    overlay.querySelector('.close').focus();
  }
  function closeHello() {
    slot.innerHTML = '';
    document.body.style.overflow = '';
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }
  root.querySelector('#about').addEventListener('click', openHello);
  if (showHello) openHello();

  // Their journey on the map.
  let map = null;
  const el = root.querySelector('#journey-map');
  map = makeMap(el, { interactive: true });
  if (map && hasLeaflet()) {
    const L = window.L;
    const pts = c.stops.map((s) => [s.latitude, s.longitude]);
    L.polyline(pts, { color: '#5B7869', weight: 3, dashArray: '2 8', lineCap: 'round' }).addTo(map);
    c.stops.forEach((s, i) => {
      const isNow = i === c.stops.length - 1;
      const m = dot([s.latitude, s.longitude], { color: isNow ? 'D98C86' : '5B7869', size: isNow ? 22 : 14, label: s.city });
      m.addTo(map);
      const text = s.city + (i === 0 ? ' · ' + tr('start') : isNow ? ' · ' + tr('now') : '');
      const phone = window.matchMedia('(max-width: 640px)').matches;
      m.bindTooltip(esc(text), { permanent: !phone || i === 0 || isNow, direction: 'right', className: 'journey-label', offset: [8, 0] });
    });
    fit(map, pts, { maxZoom: 7, padding: [60, 60] });
  }
  return () => { document.body.style.overflow = ''; if (map) map.remove(); };
}
