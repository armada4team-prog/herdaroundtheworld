// World map (TMap design; phone: TPhoneMap): one dot per Companion. Tapping a bubble highlights
// those Companions (the rest become small faded dots), zooms to fit them and fills the list.
// Tapping a dot (or a row) shows their card and their journey.
import { state, companion, mine } from '../data.js';
import { t, esc, icons, badge, pill } from '../ui.js';
import { tr } from '../i18n.js';
import { milesBetween } from '../../../shared/rules.js';
import { filters, matches, label, current, stopCount, mostActive, daysAgo, formatThousands } from '../model.js';
import { makeMap, dot } from '../maps.js';
import { devicePoint } from '../here.js';

const WORLD = window.matchMedia('(max-width: 640px)').matches ? { center: [30, -30], zoom: 1 } : { center: [28, -15], zoom: 2 };
const isPhone = () => window.matchMedia('(max-width: 640px)').matches;

export async function render({ root, query }) {
  document.title = `${tr('Map')} · ${tr('Herd Around the World')}`;
  let filter = 'all';
  let selected = null;
  let listOpen = true;
  let me = null;
  let locating = false;
  const following = mine().following;

  const lookup = (id) => `<form class="lookup" data-lookup novalidate>
      <label for="${id}">${t('Look up a Companion by number')}</label>
      <div class="row"><div class="hash-input">${icons.search}<input id="${id}" inputmode="numeric" maxlength="4" placeholder="${esc(tr('Find a Companion: #07'))}" autocomplete="off"></div>
      <button class="btn" type="submit" style="min-height:50px;padding:0 22px">${t('Go')}</button></div>
      <div class="lookup-err"></div>
    </form>`;

  root.innerHTML = `<section class="map-page">
    <div class="wrap page-top" style="padding-top:40px">
      <div class="map-head">
        <div><p class="eyebrow big">${t('Companions')}</p><h1 class="script h-lg">${t('Where the Companions are')}</h1>
        <p style="font-size:18px">${t(`${state.companions.length} Companions out in the world. Tap a pin to see where they’ve been.`)}</p></div>
        ${lookup('lookup-desk')}
      </div>
    </div>
    <div class="wrap map-wrap" style="padding-bottom:60px">
      <div class="map-layout">
        <div class="map-overlay">
          <div class="phone-only">${lookup('lookup-phone')}</div>
          <div class="filters" role="group" aria-label="${t('Show on the map')}">
            ${filters.map((f) => `<button type="button" class="filter" data-filter="${f.id}" aria-pressed="${f.id === filter}" style="background:#${f.bg};color:#${f.fg}">${f.dot ? `<i class="dot" style="background:#${f.dot}"></i>` : ''}${t(f.label)}</button>`).join('')}
          </div>
        </div>
        <div class="map-box">
          <div class="map-el" id="world-map" role="region" aria-label="${t('World map')}"></div>
          <div class="map-tools" id="map-tools"></div>
          <div id="dot-card-slot"></div>
        </div>
        <div class="list-panel" id="list-panel"></div>
      </div>
    </div>
  </section>`;

  const map = makeMap(root.querySelector('#world-map'), { interactive: true, ...WORLD });
  const layer = map ? window.L.layerGroup().addTo(map) : null;

  const milesAway = (c) => (me && current(c) ? Math.round(milesBetween(me.latitude, me.longitude, current(c).latitude, current(c).longitude)) : 0);

  /** What the list shows for the chosen bubble: a heading, the Companions, and a note per row. */
  function listFor() {
    if (filter === 'all') return { title: 'Most active', items: mostActive(state.companions), note: (c) => `${stopCount(c)} stops`, count: state.companions.length };
    if (filter === 'nearMe') {
      const near = state.companions.filter((c) => current(c)).sort((a, b) => milesAway(a) - milesAway(b));
      const items = me ? near.slice(0, 15) : [];
      return { title: 'Near me', items, note: (c) => `${formatThousands(milesAway(c))} mi away`, count: items.length };
    }
    const items = state.companions.filter((c) => matches(c, filter, following)).sort((a, b) => daysAgo(a.lastMoved) - daysAgo(b.lastMoved));
    return { title: filters.find((f) => f.id === filter).label, items, note: (c) => c.lastMoved, count: items.length };
  }

  function drawList() {
    const { title, items, note, count } = listFor();
    const panel = root.querySelector('#list-panel');
    panel.classList.toggle('closed', !listOpen);
    panel.hidden = !!selected && isPhone();
    let body;
    if (!items.length) {
      body = `<p class="list-empty">${t(filter !== 'nearMe' ? 'None right now.' : locating ? 'Finding your location…' : 'Turn on location to see the Companions nearest you.')}</p>`;
    } else {
      body = `<ol style="list-style:none;margin:0;padding:0">${items.map((c, i) => `<li><button type="button" class="list-row" data-pick="${esc(c.number)}" aria-current="${selected === c.number}">
        <span class="rank">${i + 1}</span>
        <span class="num" style="background:#${esc(c.blob)}">#${esc(c.number)}</span>
        <span style="flex:1;min-width:0"><span class="city">${esc(current(c)?.city || '')}</span><span class="note">${esc(tr(note(c)))}</span></span>
        ${c.isOriginal ? pill('Original', 'pink small') : ''}
      </button></li>`).join('')}</ol>`;
    }
    panel.innerHTML = `<button type="button" class="list-head" id="list-head" aria-expanded="${listOpen}" aria-controls="list-body" aria-label="${t(listOpen ? 'Hide the list to see the whole map' : 'Show the list')}">
        <span class="grabber" aria-hidden="true"></span>
        <span class="script">${t(title)}</span><span class="count">${t(`${count} Companions`)}</span>
        <span class="chev" aria-hidden="true">${icons.chevronDown}</span>
      </button>
      <div class="list-body" id="list-body">${body}</div>`;
    const head = panel.querySelector('#list-head');
    head.addEventListener('click', () => { listOpen = !listOpen; drawList(); panel.querySelector('#list-head').focus(); });
    let startY = null;
    head.addEventListener('touchstart', (e) => { startY = e.touches[0].clientY; }, { passive: true });
    head.addEventListener('touchend', (e) => {
      if (startY == null) return;
      const dy = e.changedTouches[0].clientY - startY;
      startY = null;
      if (dy > 40 && listOpen) { listOpen = false; drawList(); }
      if (dy < -40 && !listOpen) { listOpen = true; drawList(); }
    });
    panel.querySelectorAll('[data-pick]').forEach((b) => b.addEventListener('click', () => select(companion(b.dataset.pick))));
  }

  function drawTools(visibleCount) {
    root.querySelector('#map-tools').innerHTML = `${selected ? `<button type="button" class="pill" id="whole-world">${t('Whole world')}</button>` : ''}${pill(`${visibleCount} Companions`, '')}`;
    root.querySelector('#whole-world')?.addEventListener('click', () => { selected = null; drawAll(); if (map) map.setView(WORLD.center, WORLD.zoom); });
  }

  function drawCard() {
    const slot = root.querySelector('#dot-card-slot');
    const c = selected ? companion(selected) : null;
    if (!c) { slot.innerHTML = ''; return; }
    const cur = current(c);
    slot.innerHTML = `<div class="dot-card" role="dialog" aria-labelledby="dot-card-title">
      <button type="button" class="circle-btn close" aria-label="${t('Close')}">${icons.close}</button>
      <div class="top">${badge(c, 56)}<div style="min-width:0;padding-right:30px">
        <h3 id="dot-card-title">${esc(label(c))}</h3>
        <p class="meta">${esc([cur?.city, tr(c.lastMoved)].filter(Boolean).join(' · '))}</p>
      </div></div>
      ${cur && cur.place ? `<p class="hint">${icons.pin.replace('class="ic"', 'class="ic" style="width:15px;height:15px;vertical-align:-2px"')} “${esc(cur.place)}”</p>` : ''}
      <p class="wish">${icons.star.replace('class="ic"', 'class="ic" style="width:14px;height:14px;vertical-align:-2px"')} ${t(`Wish: ${c.wish}`)}</p>
      <p class="meta">${t(`${stopCount(c)} stops so far`)}</p>
      <div class="map-legend" style="position:static;padding:0;background:none"><span><i class="dot" style="background:#${esc(c.accent)};opacity:.6"></i>${t('Where they’ve been')}</span><span><i class="dot" style="background:#${esc(c.accent)}"></i>${t(`Where #${c.number} is now`)}</span></div>
      <a class="btn block" href="#/c/${esc(c.number)}">${t('Open their page')}</a>
    </div>`;
    slot.querySelector('.close').addEventListener('click', () => { selected = null; drawAll(); });
  }

  function drawMarkers() {
    const visible = state.companions.filter((c) => matches(c, filter, following));
    const others = filter === 'all' || filter === 'nearMe' ? [] : state.companions.filter((c) => !matches(c, filter, following));
    drawTools(visible.length);
    if (!layer) return;
    layer.clearLayers();
    const L = window.L;
    const sel = selected ? companion(selected) : null;
    if (sel) {
      L.polyline(sel.stops.map((s) => [s.latitude, s.longitude]), { color: '#' + sel.accent, weight: 3, opacity: 0.8, dashArray: '2 8', lineCap: 'round' }).addTo(layer);
      sel.stops.slice(0, -1).forEach((s) => dot([s.latitude, s.longitude], { color: sel.accent, size: 10, label: s.city }).setOpacity(0.6).addTo(layer));
    }
    for (const c of others) {
      const cur = current(c);
      if (cur) dot([cur.latitude, cur.longitude], { size: 8, faded: true }).addTo(layer);
    }
    if (me && filter === 'nearMe') {
      L.marker([me.latitude, me.longitude], { icon: L.divIcon({ className: '', html: '<span class="me-dot" style="display:block"></span>', iconSize: [16, 16] }), title: tr('You are here'), keyboard: false }).addTo(layer);
    }
    for (const c of visible) {
      const cur = current(c);
      if (!cur) continue;
      const size = c.number === selected ? 20 : others.length ? 16 : 13;
      dot([cur.latitude, cur.longitude], {
        color: c.accent, size, selected: c.number === selected,
        label: tr(`Companion #${c.number}, ${cur.city}`), onClick: () => select(c),
      }).addTo(layer);
    }
  }

  function drawAll() { drawMarkers(); drawList(); drawCard(); }

  function padding() {
    return isPhone() ? { paddingTopLeft: [30, 140], paddingBottomRight: [30, listOpen ? 330 : 90] } : { padding: [50, 50] };
  }

  function select(c) {
    if (!c) return;
    selected = c.number;
    drawAll();
    if (!map) return;
    const pts = c.stops.map((s) => [s.latitude, s.longitude]);
    if (pts.length > 1) map.fitBounds(window.L.latLngBounds(pts), { ...padding(), ...(isPhone() ? { paddingBottomRight: [30, 300] } : {}), maxZoom: 7 });
    else if (pts.length) map.setView(pts[0], 6);
  }

  function fitTo(list) {
    if (!map) return;
    const pts = list.map(current).filter(Boolean).map((s) => [s.latitude, s.longitude]);
    if (filter === 'all' || !pts.length) map.setView(WORLD.center, WORLD.zoom);
    else if (pts.length === 1) map.setView(pts[0], 4);
    else map.fitBounds(window.L.latLngBounds(pts), { ...padding(), maxZoom: 5 });
  }

  async function chooseFilter(id) {
    filter = id;
    selected = null;
    listOpen = true;
    root.querySelectorAll('[data-filter]').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.filter === id)));
    if (id !== 'nearMe') {
      drawAll();
      fitTo(state.companions.filter((c) => matches(c, id, following)));
      return;
    }
    if (!me) {
      locating = true;
      drawAll();
      try { me = await devicePoint(); } catch (e) { me = null; }
      locating = false;
    }
    drawAll();
    if (me && filter === 'nearMe' && map) map.setView([me.latitude, me.longitude], 4);
  }

  root.querySelectorAll('[data-filter]').forEach((b) => b.addEventListener('click', () => chooseFilter(b.dataset.filter)));
  root.querySelectorAll('[data-lookup]').forEach((form) => form.addEventListener('submit', (e) => {
    e.preventDefault();
    const input = form.querySelector('input');
    const c = companion(input.value);
    const err = form.querySelector('.lookup-err');
    if (!c) {
      err.innerHTML = `<p class="error-note" role="alert" style="margin-top:6px">${icons.error}<span>${t('We couldn’t find that number. Check their bottom and try again.')}</span></p>`;
      return;
    }
    err.innerHTML = '';
    input.value = '';
    input.blur();
    select(c);
  }));

  drawAll();
  const start = query.get('c');
  if (start && companion(start)) select(companion(start));
  const onResize = () => { if (map) map.invalidateSize(); };
  window.addEventListener('resize', onResize);
  return () => { window.removeEventListener('resize', onResize); if (map) map.remove(); };
}
