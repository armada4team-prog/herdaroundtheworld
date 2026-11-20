// "Thank you! They're on their way." (TThanks design): postcard, Instagram tips and the new stamp.
import { companion } from '../data.js';
import { t, esc, figure, pill, blob } from '../ui.js';
import { tr } from '../i18n.js';
import { cleanNumber } from '../../../shared/rules.js';
import { current, miles, formatThousands } from '../model.js';
import { notFound } from './companion.js';

function lastPhoto(number) {
  try { return sessionStorage.getItem('herd.lastPhoto.' + cleanNumber(number)); } catch (e) { return null; }
}

function loadImg(src) {
  return new Promise((resolve) => {
    if (!src) { resolve(null); return; }
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => resolve(null);
    img.src = src;
  });
}

/** Draws the postcard as a picture and downloads it. */
async function savePostcard(c, photoUrl) {
  const W = 1200, H = 900;
  const canvas = document.createElement('canvas');
  canvas.width = W; canvas.height = H;
  const g = canvas.getContext('2d');
  g.fillStyle = '#fff'; g.fillRect(0, 0, W, H);
  g.strokeStyle = '#6E8B7D'; g.lineWidth = 8; g.strokeRect(4, 4, W - 8, H - 8);
  g.fillStyle = '#E7ECE5'; g.fillRect(40, 40, W - 80, 600);
  const img = await loadImg(photoUrl);
  if (img) {
    const s = Math.max((W - 80) / img.width, 600 / img.height);
    const w = img.width * s, h = img.height * s;
    g.save(); g.beginPath(); g.rect(40, 40, W - 80, 600); g.clip();
    g.drawImage(img, 40 + (W - 80 - w) / 2, 40 + (600 - h) / 2, w, h); g.restore();
  } else {
    const svg = new Blob([figure({ glaze: c.glaze, size: 240, waving: true, happy: true }).replace('<svg', '<svg xmlns="http://www.w3.org/2000/svg" width="240" height="320"')], { type: 'image/svg+xml' });
    const fig = await loadImg(URL.createObjectURL(svg));
    if (fig) g.drawImage(fig, W / 2 - 120, 300, 240, 320);
  }
  await document.fonts.ready;
  g.fillStyle = '#4F6B5D';
  g.font = '72px "Shadows Into Light Two", cursive';
  g.fillText(tr(`Greetings from ${current(c)?.city || 'the road'}!`), 50, 740);
  g.fillStyle = '#566E62';
  g.font = '30px "Fira Sans", sans-serif';
  g.fillText(tr(`${c.name ? c.name + ' · ' : ''}Companion #${c.number} · Stop ${c.stops.length} · companions.theherdstudio.com`), 50, 810);
  const a = document.createElement('a');
  a.download = `companion-${c.number}-postcard.png`;
  a.href = canvas.toDataURL('image/png');
  document.body.appendChild(a); a.click(); a.remove();
}

export async function render({ params, root }) {
  const c = companion(params[0]);
  if (!c) { root.innerHTML = notFound(params[0]); return; }
  document.title = `${tr('Sent on their way')} · ${tr('Herd Around the World')}`;
  const city = current(c)?.city || '';
  const photo = lastPhoto(c.number) || current(c)?.photo || null;
  const caption = `Companion #${c.number} is in ${city}! Thanks for traveling with me. @growtheherdstudio #TheHerdCompanions`;
  const m = miles(c);

  root.innerHTML = `<section class="form-body" style="position:relative;overflow:hidden">
    ${blob('#F6D3D3', 'b-tl')}
    <div class="narrow" style="position:relative">
      <h1 class="script h-sm center">${t('Thank you! They’re on their way.')}</h1>
      <p class="lead center">${t('Your chapter is on their map now. Photos appear after a quick look, usually within a few days.')}</p>
      ${m > 0 ? `<p class="center">${pill(`★ Milestone: #${c.number} has traveled ${formatThousands(m)} miles!`, 'butter')}</p>` : ''}
      <div class="postcard">
        <div class="pic">
          ${photo ? `<img src="${esc(photo)}" alt="${t('Your photo')}">` : figure({ glaze: c.glaze, size: 90, waving: true, happy: true })}
          ${photo ? '' : `<span class="tag">${pill('Your photo', 'white')}</span>`}
          <span class="mark">#${esc(c.number)}</span>
        </div>
        <p class="script">${t(`Greetings from ${city || 'the road'}!`)}</p>
        <p class="muted">${t(`${c.name ? c.name + ' · ' : ''}Companion #${c.number} · Stop ${c.stops.length} · companions.theherdstudio.com`)}</p>
      </div>
      <div class="two">
        <button type="button" class="btn soft" id="copy">${t('Copy caption')}</button>
        <button type="button" class="btn" id="save">${t('Save postcard')}</button>
      </div>
      <div class="card" style="padding:18px">
        <h2 class="chunky" style="font-size:22px">${t('Share it on Instagram')}</h2>
        <div class="numbered"><span class="n">1</span><p>${t('Posting? Tap Tag people → Invite collaborator → @growtheherdstudio. It shows on both our pages, and it stays yours.')}</p></div>
        <div class="numbered"><span class="n">2</span><p>${t('Story? Mention @growtheherdstudio and we’ll reshare it.')}</p></div>
        <p class="caption-box">${esc(caption)}</p>
      </div>
      <div class="card pink">
        <h2 class="chunky" style="font-size:22px;color:var(--pink-ink)">${t(`New stamp: Passed on #${c.number}`)}</h2>
        <p>${t('Added to your Passport after a quick review.')}</p>
      </div>
      <a class="btn block" href="#/c/${c.number}">${t('See their journey')}</a>
      <p class="center"><a class="link-btn" href="#/passport">${t('See my Passport')}</a></p>
    </div>
  </section>`;

  const copy = root.querySelector('#copy');
  copy.addEventListener('click', async () => {
    try { await navigator.clipboard.writeText(caption); } catch (e) { /* ignore */ }
    copy.textContent = tr('Copied!');
  });
  root.querySelector('#save').addEventListener('click', () => savePostcard(c, photo));
}
