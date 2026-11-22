// Their story (TGuy design, "Their story"): the origin story by The Herd, then every traveler's
// chapter, newest first, with their photo once The Herd has taken a quick look.
import { companion, chatFor, state } from '../data.js';
import { t, esc, badge, icons, pill } from '../ui.js';
import { tr } from '../i18n.js';
import { label, byLine } from '../model.js';
import { notFound } from './companion.js';
import { reportLink, bindReports } from '../report.js';

const tints = ['#FBE4E2', '#DDF0E8', '#F9F1D6', '#E7ECE5'];

function chapter(stop, index, isNow) {
  const meta = [byLine(stop), stop.when].filter(Boolean).map((x) => tr(x)).join(' · ');
  const photo = stop.photo
    ? `<div class="photo-ph"><img src="${esc(stop.photo)}" alt="${t('Traveler’s photo')}">${!stop.photoApproved && state.mode === 'preview' ? `<span class="wait-pill">${pill('Waiting for The Herd’s quick look', 'white small')}</span>` : ''}</div>`
    : (stop.chapter ? `<div class="photo-ph" style="background:${tints[index % tints.length]}">${t('Finder’s photo')}</div>` : '');
  const wishPhoto = stop.wishPhoto ? `<div class="photo-ph" style="margin-top:10px"><img src="${esc(stop.wishPhoto)}" alt="${t('A photo of the wish coming true')}"></div>` : '';
  return `<article class="chapter frame${photo ? '' : ' no-photo'}">
    ${photo ? `<div>${photo}${wishPhoto}</div>` : ''}
    <div>
      <div class="head"><span class="n" aria-hidden="true">${index + 1}</span><h3>${esc(stop.city)}</h3>${isNow ? pill('Now', 'mint small') : ''}</div>
      ${meta ? `<p class="meta">${esc(meta)}</p>` : ''}
      ${stop.place ? `<p class="place">${icons.pin.replace('class="ic"', 'class="ic" style="width:15px;height:15px;vertical-align:-2px"')} ${esc(stop.place)}</p>` : ''}
      ${stop.chapter ? `<p class="text">“${esc(stop.chapter)}”</p>` : ''}
      ${reportLink('stop', stop.id)}
    </div>
  </article>`;
}

export async function render({ params, root }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  document.title = `${tr('Their story')} · ${label(c)}`;
  const chat = await chatFor(c.number);
  const lastText = chat.length ? chat[chat.length - 1].message : tr('Say hi to the travelers before you.');
  const list = [];
  for (let i = c.stops.length - 1; i >= 1; i--) list.push(chapter(c.stops[i], i, i === c.stops.length - 1));

  root.innerHTML = `<section class="section" style="padding-top:50px"><div class="wrap">
    <p><a href="#/c/${c.number}" class="link-btn">${icons.back}${t(`Back to #${c.number}`)}</a></p>
    <div style="display:flex;gap:16px;align-items:center;margin-top:8px">
      ${badge(c, 80)}
      <div><p class="eyebrow">${esc(label(c))}</p><h1 class="script h-md">${t('Their story')}</h1></div>
    </div>
    <p style="margin-top:16px">${t('Started by The Herd. Every traveler they meet adds a chapter.')}</p>
    <div class="chapters">
      <div class="origin"><p class="eyebrow" style="color:var(--pink-ink)">${t('Chapter 1 · Their origin story, by The Herd')}</p><p class="script">${esc(c.originStory)}</p></div>
      ${list.join('')}
    </div>
    <a class="card" href="#/c/${c.number}/chat" style="display:flex;gap:14px;align-items:center;margin-top:26px;text-decoration:none;color:inherit">
      <span style="flex:1"><b class="chunky" style="font-size:19px;display:block">${t(`Traveler chat · ${c.travelers} travelers`)}</b><span>“${esc(lastText)}”</span></span>${icons.chevronRight}
    </a>
    ${c.status !== 'retired' ? `<p style="margin-top:10px"><a class="link-btn" href="#/c/${c.number}/something-happened">${t('Something happened to them?')}</a></p>` : ''}
  </div></section>`;
  bindReports(root.firstElementChild, c.number);
}
