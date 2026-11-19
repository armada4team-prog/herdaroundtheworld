// Passport (TPassport design; phone: TPhonePassport): every Companion you found or passed on and
// every wish you granted, from this browser. Stamps are yours to keep.
import { state, mine, companion, journal, account } from '../data.js';
import { mountSignIn } from '../signin.js';
import { t, esc, icons, blob, share } from '../ui.js';
import { tr, lang } from '../i18n.js';
import { cleanNumber } from '../../../shared/rules.js';
import { countryOf } from '../model.js';

const palettes = [
  { bg: '#DDF0E8', ring: '#5B7869', ink: '#2F4A3D' },
  { bg: '#FBE4E2', ring: '#D98C86', ink: '#6B3F3A' },
  { bg: '#E7ECE5', ring: '#6E8B7D', ink: '#3F5A4C' },
];
const wishPalette = { bg: '#F9EBB5', ring: '#E0B94A', ink: '#5A4C1E' };

const month = (iso) => {
  try { return new Date(iso).toLocaleDateString(lang(), { month: 'short' }); } catch (e) { return ''; }
};

function stampHtml(s, tilt = 0) {
  if (s.empty) return `<div class="stamp empty"><span class="ring" aria-hidden="true"><b>?</b><small>${t('Next')}</small></span><span>${t(s.label)}</span></div>`;
  return `<div class="stamp"><span class="ring" aria-hidden="true" style="background:${s.p.bg};border-color:${s.p.ring};color:${s.p.ink};transform:rotate(${tilt}deg)"><b>${esc(tr(s.big))}</b><small>${esc(tr(s.small))}</small></span><span>${esc(s.label)}</span></div>`;
}

export function passportData() {
  const m = mine();
  const stamps = [];
  let i = 0;
  let handedOne = false;
  const carried = new Set();
  let milesCarried = 0;
  const all = journal();
  for (const j of all) {
    if (j.type === 'found') carried.add(cleanNumber(j.number));
    if (j.type === 'passedOn' || j.type === 'left') {
      milesCarried += j.miles || 0;
      stamps.push({ big: '#' + j.number, small: String(j.city || '').split(',')[0], label: tr(`Passed on #${j.number}`) + ' · ' + month(j.date), p: palettes[i++ % palettes.length] });
      if (j.type === 'passedOn' && !handedOne) { handedOne = true; stamps.push({ big: '1st', small: 'Hand-off', label: tr('Handed one to a stranger'), p: palettes[2] }); }
    }
    if (j.type === 'wish') stamps.push({ big: 'Wish', small: 'Granted', label: j.wish ? tr(`Helped #${j.number} ${j.wish}`) : `${tr('Wish granted')} · #${j.number}`, p: wishPalette });
  }
  // Your herd: everyone else who carried the same Companions.
  const herd = new Set();
  const countries = new Set();
  for (const n of carried) {
    const c = companion(n);
    if (!c) continue;
    for (const s of c.stops) {
      if (s.byName && s.byName !== m.nickname && s.kind !== 'made') { herd.add(s.byName); countries.add(countryOf(s.city)); }
    }
  }
  return { m, all, stamps: stamps.reverse(), carried: carried.size, milesCarried, herd: herd.size, countries: countries.size };
}

export async function render({ root }) {
  document.title = `${tr('Passport')} · ${tr('Herd Around the World')}`;
  const { m, all, stamps, carried, milesCarried, herd, countries } = passportData();
  const name = m.nickname ? `${m.nickname}’s travels` : 'Your travels';
  const allStamps = [...stamps, { empty: true, label: 'Your next Companion' }, { empty: true, label: 'Grant another wish' }];
  const tilts = [-6, 5, -3, 4, -2, 3];
  const travels = [...all].reverse().map((j) => {
    const p = j.type === 'wish' ? wishPalette : j.type === 'found' ? palettes[2] : j.type === 'left' ? palettes[1] : palettes[0];
    const title = j.type === 'found' ? `Found #${j.number}` : j.type === 'wish' ? 'Wish granted' : `Passed on #${j.number}`;
    const detail = j.type === 'wish' ? (j.wish ? `Helped #${j.number} ${j.wish}` : `In ${j.city}`) : `In ${j.city}`;
    return `<li class="travel" style="background:${p.bg};color:${p.ink}"><span class="n">#${esc(j.number)}</span><span><b>${t(title)}</b><span>${t(detail)}</span></span><span class="when">${esc(month(j.date))}</span></li>`;
  }).join('');

  root.innerHTML = `
  <section class="page-hero passport-wide">
    ${blob('#DDF0E8', 'b-tr2')}${blob('#DCDDD6', 'b-bottom')}
    <div class="wrap">
      <p class="eyebrow big">${t('My Passport')}</p>
      <h1 class="script h-lg">${t(name)}</h1>
      <p style="font-size:18px;max-width:700px">${t('Every Companion you’ve found or carried, and every wish you’ve granted, in one place.')}</p>
    </div>
  </section>
  <section class="section" style="padding-top:40px">
    <div class="wrap">
      <div class="passport-cover">
        <p class="eyebrow">${t('Herd Around the World · Passport')}</p>
        <h2 class="script" style="color:#fff">${t(name)}</h2>
        <div class="row"><div><b>${carried}</b><small>${t('Companions carried')}</small></div><div><b>${milesCarried}</b><small>${t('Miles carried')}</small></div><div><b>${herd}</b><small>${t('Travelers in your herd')}</small></div></div>
      </div>
      <div class="tiles" style="margin-top:14px">
        <a href="#/map" style="background:var(--mint-soft);color:var(--mint-ink)"><b>${t('Map')}</b><span>${t('Where everyone is')}</span></a>
        <a href="#/found" style="background:var(--pink-soft);color:var(--pink-ink)"><b>${t('Found one?')}</b><span>${t('Log your find')}</span></a>
      </div>
      <div class="card mint signin-card" id="account" style="margin-top:14px"></div>
      <div class="stats passport-wide" style="margin-top:36px">
        <div class="stat frame"><b>${carried}</b><span>${t('Companions carried')}</span></div>
        <div class="stat frame"><b>${milesCarried}</b><span>${t('Miles carried')}</span></div>
        <div class="stat frame"><b>${herd}</b><span>${t('Travelers in your herd')}</span></div>
      </div>
      <div class="passport-grid">
        <div>
          <h2 class="script h-sm">${t('Stamps')}</h2>
          <div class="stamps">${allStamps.map((s, i) => stampHtml(s, s.empty ? 0 : tilts[i % tilts.length])).join('')}</div>
          <div class="card" style="margin-top:24px;padding:22px 24px">
            <h3 class="chunky" style="font-size:20px">${t(`Your herd: ${herd} travelers in ${countries} countries`)}</h3>
            <p>${t('Everyone who carried the same Companions as you. You’re connected, even if you’ve never met.')}</p>
          </div>
          <div class="actions passport-wide" style="margin-top:20px">
            <a class="btn" href="#/map">${t('See the map')}</a>
            <a class="btn soft" href="#/found">${t('Found a Companion?')}</a>
            <button type="button" class="btn outline" id="share">${icons.share}<span>${t('Share')}</span></button>
          </div>
        </div>
        <div class="passport-wide">
          <h2 class="script h-sm">${t('Your travels')}</h2>
          <ul style="list-style:none;padding:0;margin:16px 0 0;display:flex;flex-direction:column;gap:12px">${travels || `<li class="card">${t('Nothing here yet. Find a Companion to start your Passport.')}</li>`}</ul>
          <div class="card butter" style="margin-top:16px;padding:20px 22px">
            <h3 class="chunky" style="font-size:19px;color:var(--butter-ink)">${t('How to earn stamps')}</h3>
            <p>${t('Log a Companion you find, pass one on, or grant a Companion’s wish. Each one adds a stamp, and they’re yours to keep.')}</p>
          </div>
        </div>
      </div>
    </div>
  </section>`;
  root.querySelector('#share').addEventListener('click', (e) =>
    share('I’m part of The Herd’s Companions project! Find one, carry one, watch them go.', 'https://theherdstudio.com', e.currentTarget));
  mountSignIn(root.querySelector('#account'));
  void state; void account;
}
