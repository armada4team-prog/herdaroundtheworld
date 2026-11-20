// Leaflet maps with OpenStreetMap tiles (softened to sit with The Herd's colours).
import { t, esc } from './ui.js';
import { asset } from './env.js';

export const hasLeaflet = () => typeof window.L !== 'undefined';

/** Makes a map in `el`, or shows a friendly note if the map library couldn't load. */
export function makeMap(el, { interactive = true, center = [30, -30], zoom = 2, minZoom = 1 } = {}) {
  if (!hasLeaflet()) {
    el.innerHTML = `<div class="map-fallback"><p>${t('The map couldn’t load right now. The list still works.')}</p></div>`;
    return null;
  }
  const L = window.L;
  const map = L.map(el, {
    center, zoom, minZoom, maxZoom: 14, worldCopyJump: true, zoomSnap: 0.25,
    zoomControl: false, dragging: interactive, scrollWheelZoom: false,
    doubleClickZoom: interactive, boxZoom: interactive, keyboard: interactive, touchZoom: interactive,
    attributionControl: true,
    // Animated zooms can finish after a page has moved on and its map is gone (a Leaflet error), so zoom without the animation.
    zoomAnimation: false,
  });
  map.attributionControl.setPrefix(false);
  if (interactive) L.control.zoom({ position: 'bottomright' }).addTo(map);
  // A simple world outline drawn by the site itself (land and sea in The Herd's colours). It shows
  // right away and stays as a backup if the detailed street map can't load.
  map.createPane('land');
  map.getPane('land').style.zIndex = 150;
  worldLand().then((geo) => {
    if (geo) L.geoJSON(geo, { pane: 'land', interactive: false, style: { color: '#C9BBA9', weight: 1, fillColor: '#F3EBDF', fillOpacity: 1 } }).addTo(map);
  });
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    // If a tile can't load, show nothing (the world outline underneath still shows).
    errorTileUrl: 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  }).addTo(map);
  return map;
}

let landPromise = null;
/** The world outline (Natural Earth, public domain), loaded once. */
function worldLand() {
  landPromise ??= fetch(asset('data/world-land.json')).then((r) => (r.ok ? r.json() : null)).catch(() => null);
  return landPromise;
}

/** A round dot marker. */
export function dot(latlng, { color = '5B7869', size = 14, faded = false, selected = false, label = '', onClick = null } = {}) {
  const L = window.L;
  const icon = L.divIcon({
    className: '',
    html: `<span class="herd-dot${faded ? ' faded' : ''}${selected ? ' sel' : ''}" style="display:block;width:${size}px;height:${size}px;background:#${esc(color)}"></span>`,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
  const m = L.marker(latlng, { icon, keyboard: !!onClick && !faded, interactive: !!onClick && !faded, title: label, alt: label, riseOnHover: true });
  if (onClick && !faded) m.on('click', onClick);
  return m;
}

export function fit(map, points, { maxZoom = 6, padding = [40, 40] } = {}) {
  if (!map || !points.length) return;
  if (points.length === 1) { map.setView(points[0], Math.min(maxZoom, 5)); return; }
  map.fitBounds(window.L.latLngBounds(points), { padding, maxZoom });
}
