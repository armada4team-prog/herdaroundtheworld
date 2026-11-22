// "Where are you?" for finding and passing on a Companion (like the app's HereCard). It uses the
// device's location (city level) instead of a typed place, so a Companion can only be logged where
// the traveler really is. The city comes from OpenStreetMap (Nominatim).
import { t, esc, icons, errorNote } from './ui.js';
import { state } from './data.js';

const usStates = {
  Alabama: 'AL', Alaska: 'AK', Arizona: 'AZ', Arkansas: 'AR', California: 'CA', Colorado: 'CO', Connecticut: 'CT',
  Delaware: 'DE', 'District of Columbia': 'DC', Florida: 'FL', Georgia: 'GA', Hawaii: 'HI', Idaho: 'ID', Illinois: 'IL',
  Indiana: 'IN', Iowa: 'IA', Kansas: 'KS', Kentucky: 'KY', Louisiana: 'LA', Maine: 'ME', Maryland: 'MD',
  Massachusetts: 'MA', Michigan: 'MI', Minnesota: 'MN', Mississippi: 'MS', Missouri: 'MO', Montana: 'MT', Nebraska: 'NE',
  Nevada: 'NV', 'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY', 'North Carolina': 'NC',
  'North Dakota': 'ND', Ohio: 'OH', Oklahoma: 'OK', Oregon: 'OR', Pennsylvania: 'PA', 'Rhode Island': 'RI',
  'South Carolina': 'SC', 'South Dakota': 'SD', Tennessee: 'TN', Texas: 'TX', Utah: 'UT', Vermont: 'VT', Virginia: 'VA',
  Washington: 'WA', 'West Virginia': 'WV', Wisconsin: 'WI', Wyoming: 'WY', 'Puerto Rico': 'PR',
};

/** Test spots for trying the 5-mile rule from a computer (preview only). */
export const testLocations = [
  { city: 'Aurora, CO', latitude: 39.7294, longitude: -104.8319 },
  { city: 'Denver, CO', latitude: 39.7392, longitude: -104.9903 },
  { city: 'Boulder, CO', latitude: 40.015, longitude: -105.2705 },
];

/** "Aurora, CO" or "Lisbon, Portugal" from a point, using OpenStreetMap. */
export async function cityFor(latitude, longitude) {
  const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latitude}&lon=${longitude}&zoom=10&accept-language=en`;
  const res = await fetch(url, { headers: { Accept: 'application/json' } });
  if (!res.ok) throw new Error('geocode ' + res.status);
  const json = await res.json();
  const a = json.address || {};
  const city = a.city || a.town || a.village || a.hamlet || a.municipality || a.suburb || a.county || json.name;
  if (!city) throw new Error('no city');
  if (a.country_code === 'us') {
    const st = usStates[a.state] || (a['ISO3166-2-lvl4'] || '').replace('US-', '');
    return st ? `${city}, ${st}` : city;
  }
  return a.country ? `${city}, ${a.country}` : city;
}

/** Device location: resolves { latitude, longitude } or rejects with a problem name. */
export function devicePoint() {
  return new Promise((resolve, reject) => {
    if (!('geolocation' in navigator)) { reject(new Error('off')); return; }
    navigator.geolocation.getCurrentPosition(
      (p) => resolve({ latitude: p.coords.latitude, longitude: p.coords.longitude }),
      (err) => reject(new Error(err.code === 1 ? 'notAllowed' : err.code === 3 ? 'timeout' : 'unavailable')),
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 },
    );
  });
}

const problemText = {
  off: 'Location is turned off. Turn it on so we can log where you are.',
  notAllowed: 'Please allow location so we can log where you are.',
  unavailable: 'We couldn’t find where you are. Check your signal and try again.',
};

/**
 * Mounts the location card into `el`. onChange(place | null) is called with
 * { city, latitude, longitude } once the city is found (or null while finding / if it can't be found).
 */
export function mountHere(el, onChange) {
  let place = null;
  let error = null;
  let locating = true;
  let problem = null;
  let usingTest = null;
  let gen = 0;

  function draw() {
    const isPreview = state.mode === 'preview';
    let inner;
    if (locating) {
      inner = `<div class="here-row" role="status"><span class="spinner"></span><span>${t('Finding where you are…')}</span></div>`;
    } else if (place) {
      inner = `<div class="here-row">${icons.pin}<span class="here-city" aria-label="${esc(t('You’re in {0}').replace('{0}', place.city))}">${esc(place.city)}</span>
        <button type="button" class="link-btn" data-act="refresh">${t('Refresh')}</button></div>`;
    } else {
      inner = `<p>${t(problemText[problem] || problemText.unavailable)}</p>
        <div class="chips"><button type="button" class="chip" data-act="refresh">${icons.refresh}${t('Try again')}</button></div>`;
    }
    const tests = isPreview
      ? `<div class="test-locations"><span class="muted">${t('Preview only: Use a test location')}</span>
          <div class="chips">${testLocations.map((p, i) => `<button type="button" class="chip${usingTest === i ? ' on' : ''}" data-test="${i}" aria-pressed="${usingTest === i}">${esc(p.city)}</button>`).join('')}</div></div>`
      : '';
    el.className = 'field' + (error ? ' has-error' : '');
    el.innerHTML = `<div class="here">${inner}${tests}</div>
      <p class="help">${t('We use your phone’s location so travelers know where to look. A street address is never written out.')}</p>
      ${error ? errorNote(error) : ''}`;
  }

  async function locate() {
    const mine = ++gen;
    locating = true; problem = null; place = null; usingTest = null;
    draw();
    onChange(null);
    try {
      const point = await devicePoint();
      const city = await cityFor(point.latitude, point.longitude);
      place = { city, ...point };
    } catch (e) {
      problem = problemText[e.message] ? e.message : 'unavailable';
    }
    if (mine !== gen) return;
    locating = false;
    draw();
    onChange(place);
  }

  el.addEventListener('click', (e) => {
    const b = e.target.closest('button');
    if (!b) return;
    if (b.dataset.act === 'refresh') locate();
    if (b.dataset.test != null) {
      gen++;
      usingTest = Number(b.dataset.test);
      place = { ...testLocations[usingTest] };
      locating = false; problem = null;
      draw();
      onChange(place);
    }
  });

  draw();
  locate();
  return {
    setError(text) { error = text || null; draw(); },
    get place() { return place; },
  };
}
