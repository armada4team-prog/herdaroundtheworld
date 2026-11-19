// Home: "Find one. Carry one. Watch them go." (TMain design, without anything for sale).
import { state, companion, isFollowing, toggleFollow } from '../data.js';
import { t, esc, icons, figure, blob, pill } from '../ui.js';
import { tr } from '../i18n.js';
import { label, current, stopCount, miles, daysAgo, formatThousands, countryOf, byLine } from '../model.js';
import { makeMap, dot, hasLeaflet } from '../maps.js';

const steps = [
  { title: 'Find one', blob: '#F6D3D3', icon: 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm10 2-4.35-4.35', body: 'Spot a little clay Companion on a shelf, a windowsill or a café table. They’re waiting for you.' },
  { title: 'Meet them', blob: '#DDF0E8', icon: 'M3 7V4h3M18 4h3v3M21 17v3h-3M6 20H3v-3M8 8h3v3H8zM13 13h3v3h-3zM13 8h3M8 16h3', body: 'Flip them over and scan the QR code. Learn their number, their story and everywhere they’ve been.' },
  { title: 'Travel together', blob: '#F9EBB5', icon: 'M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21Zm0-9a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z', body: 'Carry them along, then leave them somewhere new and log the spot. Help their wish come true if you can.' },
  { title: 'Follow their story', blob: '#FBE4E2', icon: 'M7 20c0-6 2-10 5-12M12 8c1-3 4-5 8-5 0 4-2 7-6 7M12 8C11 5 8 3 4 3c0 4 2 7 6 7', body: 'Remember their number or get an email each time they move. See who they meet next.' },
];
const tints = ['#DDF0E8', '#FBE4E2', '#F9F1D6'];

function sightings() {
  const all = [];
  for (const c of state.companions) {
    c.stops.forEach((s, i) => { if (i > 0 && s.chapter) all.push({ c, s }); });
  }
  all.sort((a, b) => daysAgo(a.s.when) - daysAgo(b.s.when));
  return all.slice(0, 3);
}

function originalCard(c) {
  const cur = current(c);
  const following = isFollowing(c.number);
  return `<article class="original frame">
    <div class="art" style="background:#${esc(c.blob)}">${figure({ glaze: c.glaze, size: 110, number: c.number, label: tr(`Original number ${c.number}`) })}</div>
    <h3>${esc(label(c))}</h3>
    <p class="meta">${t(`Last seen in ${cur ? cur.city : 'Aurora, CO'} · ${stopCount(c)} stops`)}</p>
    <p class="wish">${icons.star}${t(c.wishGranted ? `Wish granted: ${c.wish}` : `Wish: ${c.wish}`)}</p>
    <p style="display:flex;gap:10px;flex-wrap:wrap;align-items:center">
      <a class="text-link" href="#/c/${c.number}">${t('Open their page')}</a>
      <button type="button" class="switch" role="switch" aria-checked="${following}" data-follow="${esc(c.number)}"><span class="track" aria-hidden="true"></span><span>${t('Follow them')}</span></button>
    </p>
  </article>`;
}

export async function render({ root, go }) {
  document.title = `${tr('Herd Around the World')} · The Herd`;
  const list = state.companions;
  const totalMiles = list.reduce((sum, c) => sum + miles(c), 0);
  const cities = new Set(), countries = new Set();
  for (const c of list) for (const s of c.stops) { if (s.city) { cities.add(s.city); countries.add(countryOf(s.city)); } }
  const originals = list.filter((c) => c.isOriginal).sort((a, b) => Number(a.number) - Number(b.number));

  root.innerHTML = `
  <section class="hero">
    ${blob('#F6D3D3', 'b-left')}${blob('#F9EBB5', 'b-left2')}${blob('#DCDDD6', 'b-bottom')}
    <div class="wrap">
      <div>
        <p class="eyebrow big">${t('Children of the clay')}</p>
        <h1 class="script h-xl" style="margin:18px 0 22px">${t('Find one.')}<br>${t('Carry one.')}<br>${t('Watch them go.')}</h1>
        <p class="lead" style="font-size:20px;max-width:520px">${t('Companions are tiny travelers handmade by The Herd and sent out into the world. Each one has a number and a QR code on the bottom. Carry one for a while, leave them somewhere new, and every traveler they meet becomes part of their story.')}</p>
        <form id="find" style="margin-top:28px" novalidate>
          <label for="find-number" class="field-label" style="display:block;margin-bottom:10px">${t('Found a Companion? Enter their number')}</label>
          <div class="find-box">
            <div class="hash-input"><b aria-hidden="true">#</b><input id="find-number" inputmode="numeric" maxlength="4" placeholder="07" autocomplete="off" aria-describedby="find-err"></div>
            <button class="btn soft" type="submit" style="color:var(--mint-ink)">${t('Find them →')}</button>
          </div>
          <div id="find-err" style="margin-top:8px"></div>
          <p class="muted" style="margin-top:12px;font-size:15px">${t('Or flip them over and scan the code with your phone camera.')}<br>${t('Already carried one?')} <a href="#/passport">${t('See your Passport')}</a></p>
        </form>
      </div>
      <div class="hero-art" aria-hidden="true">
        ${blob('#E7ECE5', 'fill')}
        <div class="hero-pin"></div>
        <svg class="route" viewBox="0 0 460 460"><path d="M70 330 C140 260 190 300 240 230 S 340 140 390 110" stroke="#6E8B7D" stroke-width="3" stroke-dasharray="2 11" stroke-linecap="round" fill="none"/><circle cx="390" cy="110" r="10" fill="#5B7869"/><circle cx="240" cy="230" r="7" fill="#6E8B7D"/></svg>
        <div class="hero-figs">${figure({ glaze: 'A8DCC9', size: 100 })}${figure({ glaze: 'F4C7C3', size: 136 })}${figure({ glaze: 'F6E3A1', size: 100 })}</div>
      </div>
    </div>
  </section>

  <section class="section">
    <div class="wrap">
      <h2 class="section-title">${t('How it works')}</h2>
      <ol class="how" style="list-style:none;padding:0">
        ${steps.map((s) => `<li><div class="icon" style="background:${s.blob}"><svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"><path d="${s.icon}"/></svg></div><h3>${t(s.title)}</h3><p>${t(s.body)}</p></li>`).join('')}
      </ol>
    </div>
  </section>

  <section class="section" style="padding-top:0">
    <div class="wrap">
      <div style="display:flex;flex-wrap:wrap;gap:16px 24px;align-items:center">
        <h2 class="script h-md">${t('Latest sightings')}</h2>
        <div class="pills">${pill(`${formatThousands(totalMiles)} miles traveled together`, 'butter')}${pill(`${cities.size} cities`, 'mint')}${pill(`${countries.size} countries`, 'pink')}</div>
      </div>
      <div class="sightings">
        ${sightings().map(({ c, s }, i) => `<a class="sighting frame" href="#/c/${c.number}">
          <div class="photo-ph" style="background:${tints[i % 3]}">${s.photo ? `<img src="${esc(s.photo)}" alt="${t('Traveler’s photo')}">` : t('Finder’s photo')}</div>
          <h3>${t(s.kind === 'passedOn' ? `#${c.number} was handed on in ${s.city}` : `#${c.number} arrived in ${s.city}`)}</h3>
          <p>“${esc(s.chapter)}” ${esc([byLine(s), s.when].filter(Boolean).map(tr).join(', '))}</p>
        </a>`).join('')}
      </div>
    </div>
  </section>

  <section class="wrap" style="padding-bottom:10px">
    <div class="stamp-banner">
      <div class="dash-stamp" aria-hidden="true"><b>#07</b><small>${t('Passed on')}</small></div>
      <div style="flex:1"><h2 class="script">${t('Pass a Companion on, collect a stamp')}</h2>
        <p style="font-size:17px;margin-top:6px">${t('Every Companion you find and pass on adds a stamp to your Passport. Grant their wish and you earn a special Wish Granted stamp too.')}</p></div>
      <a class="btn" href="#/found">${t('Log a sighting')}</a>
    </div>
  </section>

  <section class="section">
    <div class="wrap">
      <div style="display:flex;flex-wrap:wrap;gap:16px;justify-content:space-between;align-items:flex-end">
        <div><h2 class="script h-md">${t('Where they are now')}</h2><p style="font-size:18px">${t('Every pin is a Companion’s last approved stop.')}</p></div>
        <a class="text-link" href="#/map">${t('Open the full map')}</a>
      </div>
      <div class="mini-map"><div class="map-el" id="mini-map"></div>
        <div class="map-legend"><span><i class="dot" style="background:#D98C86"></i>${t('Originals #0–5')}</span><span><i class="dot" style="background:#5B7869"></i>${t('Companions')}</span></div>
      </div>
    </div>
  </section>

  <section class="section beige">
    <div class="wrap">
      <p class="eyebrow center" style="font-size:18px">${t('The first six')}</p>
      <h2 class="script h-md center">${t('Meet the Originals')}</h2>
      <p class="center" style="max-width:640px;margin:10px auto 0;font-size:18px">${t('Companions #0 to #5 started it all. Each one left the studio with a friend of The Herd. If you find one, you’re holding a little bit of history.')}</p>
      <div class="originals">${originals.map(originalCard).join('')}</div>
    </div>
  </section>

  <section class="section">
    <div class="wrap">
      <h2 class="script h-md center">${t('How to pass one on')}</h2>
      <p class="center" style="font-size:19px">${t('Somewhere they’ll be found, loved and sent on their way.')}</p>
      <div class="best card"><span class="script">${t('Best of all: hand them on')}</span><span style="font-size:18px">${t('Give your Companion to a fellow traveler: a new friend, a host, someone heading somewhere fun. It’s the most personal way to send them on.')}</span></div>
      <div class="pass-grid">
        <div class="card mint"><h3 class="chunky" style="font-size:28px">${t('Or leave them somewhere')}</h3><ul>
          ${['Café windowsills and bookshelves', 'Hostel and hotel lobbies', 'Bookstores and Little Free Libraries', 'Train station waiting areas, with a staff member’s okay', 'Anywhere you’d love to be found'].map((x) => `<li>${t(x)}</li>`).join('')}
        </ul><p style="margin-top:14px;font-size:15px">${t('At least 5 miles from where you found them, with a hint so the next traveler can find them.')}</p></div>
        <div class="card pink"><h3 class="chunky" style="font-size:28px;color:var(--pink-ink)">${t('Please don’t')}</h3><ul>
          ${['Airport security areas or gates. Unattended objects cause alarm', 'Trails, parks and wild places. Leave no trace', 'Private property without permission', 'Anywhere they could fall, break or block a path'].map((x) => `<li>${t(x)}</li>`).join('')}
        </ul></div>
      </div>
    </div>
  </section>

  <section class="section" style="padding-top:0">
    <div class="wrap" style="display:flex;flex-wrap:wrap;gap:20px;align-items:flex-end;justify-content:space-between">
      <div><h2 class="script h-md">${t('Companions on Instagram')}</h2>
        <p style="font-size:18px">${t('Mention @growtheherdstudio in your story, or add us as a collaborator on your post, and we’ll share it with the whole herd.')}</p></div>
      <a class="btn" href="https://www.instagram.com/growtheherdstudio/" rel="noopener">${t('Follow @growtheherdstudio')}</a>
    </div>
  </section>`;

  const form = root.querySelector('#find');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const input = root.querySelector('#find-number');
    const c = companion(input.value);
    const err = root.querySelector('#find-err');
    if (!c) {
      err.innerHTML = `<p class="error-note" role="alert">${icons.error}<span>${t('We couldn’t find that number. Check their bottom and try again.')}</span></p>`;
      input.closest('.hash-input').style.borderColor = 'var(--error)';
      return;
    }
    go(`/c/${c.number}`); // a number alone shows their page; logging a find needs their code
  });
  root.querySelector('#find-number').addEventListener('input', (e) => { root.querySelector('#find-err').innerHTML = ''; e.target.closest('.hash-input').style.borderColor = ''; });
  root.querySelectorAll('[data-follow]').forEach((b) => b.addEventListener('click', () => {
    toggleFollow(b.dataset.follow);
    b.setAttribute('aria-checked', String(isFollowing(b.dataset.follow)));
  }));

  const map = makeMap(root.querySelector('#mini-map'), { interactive: false, center: [25, -20], zoom: 2 });
  if (map && hasLeaflet()) {
    for (const c of list) {
      const cur = current(c);
      if (!cur) continue;
      dot([cur.latitude, cur.longitude], { color: c.isOriginal ? 'D98C86' : '5B7869', size: 16, label: label(c), onClick: () => go(`/c/${c.number}`) }).addTo(map);
    }
  }
  return () => { if (map) map.remove(); };
}
