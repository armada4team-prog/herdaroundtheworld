// Leaflet maps with OpenStreetMap tiles (softened to sit with The Herd's colours).
import { t, esc } from './ui.js';

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
  });
  map.attributionControl.setPrefix(false);
  if (interactive) L.control.zoom({ position: 'bottomright' }).addTo(map);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
  }).addTo(map);
  return map;
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
