// Rules for Herd Around the World, shared by the website and the Wix checker
// (wix/backend/http-functions.js is built from this file by tool/build_wix_backend.py).
// They match the app's rules in lib/validation.dart: when you change one, change both.

const blockedWords = new Set([
  // Swearing
  'fuck', 'fucks', 'fucker', 'fuckers', 'fucking', 'fucked', 'fck', 'fuk', 'fuq', 'fking', 'fkn', 'wtf', 'stfu',
  'shit', 'shits', 'shitty', 'shite', 'bullshit', 'sht',
  'bitch', 'bitches', 'bitchy', 'btch',
  'cunt', 'cunts', 'twat', 'twats', 'prick', 'pricks', 'wanker', 'wankers', 'bollocks',
  'ass', 'asses', 'asshole', 'assholes', 'arse', 'arsehole', 'jackass', 'dumbass', 'badass',
  'dick', 'dicks', 'dickhead', 'cock', 'cocks', 'pussy', 'pussies', 'bastard', 'bastards',
  'motherfucker', 'motherfucking', 'mf', 'mofo', 'piss', 'pissed', 'crap', 'douche', 'douchebag',
  // Sexual or gross
  'sex', 'sexy', 'porn', 'porno', 'nude', 'nudes', 'naked', 'boob', 'boobs', 'tits', 'titties', 'penis', 'vagina',
  'dildo', 'cum', 'jizz', 'horny', 'blowjob', 'handjob', 'orgasm', 'masturbate', 'erection', 'anal', 'milf',
  'poop', 'vomit', 'puke', 'diarrhea', 'semen', 'genitals',
  // Hateful
  'nazi', 'nazis', 'hitler', 'heil', 'kkk',
  // Harm
  'kys', 'suicide', 'rape', 'raped', 'rapist', 'molest', 'pedo', 'pedophile', 'terrorist', 'gore', 'murder', 'murdered',
]);

const blockedStarts = [
  'fuck', 'shit', 'bitch', 'cunt', 'whore', 'slut', 'motherf', 'nigg', 'nigga', 'niga', 'fagg', 'faggot', 'retard',
  'spic', 'chink', 'kike', 'wetback', 'tranny', 'dyke', 'gook', 'beaner', 'raghead', 'towelhead', 'coon', 'pornh',
  'xxx', 'dickh', 'cocks', 'pussi', 'asshol',
];

const blockedPhrases = ['kill yourself', 'kill your self', 'kill myself', 'go die', 'hope you die', 'blow job', 'hand job', 'son of a bitch'];

const selfHarmPhrases = [
  'want to die', 'wanna die', 'wish i was dead', 'wish i were dead', 'kill myself', 'kill my self', 'end my life',
  'take my life', 'suicide', 'suicidal', 'hurt myself', 'harm myself', 'cut myself', 'self harm', 'not be alive',
];

const harmfulWishWords = new Set([
  'die', 'dies', 'dying', 'kill', 'kills', 'killing', 'murder', 'suicide', 'suicidal', 'hurt', 'harm', 'shoot', 'stab',
  'bomb', 'gun', 'guns', 'weapon', 'weapons', 'poison', 'overdose', 'drug', 'drugs', 'steal', 'rob', 'punch', 'fight',
  'beat', 'drown', 'hang', 'blood', 'torture', 'attack',
]);

const leet = { '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '8': 'b', '@': 'a', '$': 's', '!': 'i', '|': 'l', '+': 't' };

export const selfHarmMessage =
  'Please choose different words. If you’re going through a hard time, you’re not alone: in the US you can call or text 988 any time to talk to someone.';

function clean(text) {
  return [...String(text).toLowerCase()].map((ch) => leet[ch] ?? ch).join('');
}

/** "fuuuuck" → "fuck" */
function squash(word) {
  return word.replace(/(.)\1{2,}/g, '$1');
}

function isBlockedWord(word) {
  if (!word) return false;
  const forms = new Set([word, squash(word), word.replace(/(.)\1+/g, '$1')]);
  for (const w of forms) {
    if (blockedWords.has(w)) return true;
    if (blockedStarts.some((s) => w.startsWith(s))) return true;
  }
  return false;
}

function spacedWords(text) {
  return ' ' + clean(text).replace(/[^a-z ]+/g, ' ').replace(/\s+/g, ' ').trim() + ' ';
}

export function containsBlockedLanguage(text) {
  const cleaned = clean(text);
  const words = cleaned.split(/[^a-z]+/).filter(Boolean);
  if (words.some(isBlockedWord)) return true;
  const spaced = cleaned.replace(/[^a-z ]+/g, ' ').replace(/\s+/g, ' ');
  if (blockedPhrases.some((p) => spaced.includes(p))) return true;
  // Runs of single letters: "f u c k", "f.u.c.k"
  let run = '';
  for (const w of [...words, '']) {
    if (w.length === 1) {
      run += w;
    } else {
      if (run.length >= 3 && isBlockedWord(run)) return true;
      run = '';
    }
  }
  return false;
}

export function mentionsSelfHarm(text) {
  const spaced = spacedWords(text);
  return selfHarmPhrases.some((p) => spaced.includes(' ' + p + ' '));
}

const linkRe = /(https?:\/\/|www\.|\b[a-z0-9-]+\.(com|net|org|io|co|app|xyz|info|biz|ly|me|gg)\b)/i;
const emailRe = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i;
const phoneRe = /\+?\d[\d\s().-]{7,}\d/;

/** Text other people will see. Returns a friendly message, or null if it's fine. */
export function checkPublicText(text, maxLength) {
  const t = String(text ?? '').trim();
  if (maxLength && t.length > maxLength) return `Please keep it under ${maxLength} characters.`;
  if (mentionsSelfHarm(t)) return selfHarmMessage;
  if (containsBlockedLanguage(t)) return 'Please keep it kind. Some words aren’t allowed here.';
  if (linkRe.test(t)) return 'Links can’t be added here.';
  if (emailRe.test(t) || phoneRe.test(t)) return 'Please don’t share phone numbers, emails or addresses.';
  return null;
}

export function checkNickname(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add a name or nickname.';
  if (t.length < 2) return 'Please use at least 2 letters.';
  if (!/[A-Za-zÀ-ÿЀ-ӿ぀-ヿ一-鿿]/.test(t)) return 'Please use letters in your nickname.';
  return checkPublicText(t, 30);
}

/** A wish (what comes after "I want to"). */
export function checkWish(text) {
  if (mentionsSelfHarm('I want to ' + text)) return selfHarmMessage;
  const general = checkPublicText(text, 50);
  if (general) return general;
  const words = spacedWords(text).trim().split(' ');
  if (words.some((w) => harmfulWishWords.has(w) || harmfulWishWords.has(squash(w)))) {
    return 'Wishes need to be kind and safe for the Companion and the next traveler. Please try different words.';
  }
  return null;
}

/** The hint for where a Companion was left: required, kind, no street address. */
export function checkHint(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add a hint so the next person can find them.';
  if (/\d+\s+\w+\s+(st|street|ave|avenue|rd|road|blvd|boulevard|ln|lane|dr|drive|way|ct|court|pl|place)\b/i.test(t)) {
    return 'Please describe the spot instead of giving a street address.';
  }
  return checkPublicText(t, 120);
}

/** A typed place for "something happened": "City, State" or "City, Country". */
export function checkPlaceFormat(text) {
  const t = String(text ?? '').trim();
  if (!t) return 'Please add the city and state or country.';
  if (/\d/.test(t)) return 'Just the city and state or country, please. No street addresses.';
  const parts = t.split(',').map((p) => p.trim()).filter(Boolean);
  if (parts.length < 2) return 'Please write it as City, State (or City, Country). For example: Santa Fe, NM';
  if (parts.length > 3) return 'Just the city and state or country, please.';
  if (!parts.every((p) => /^[A-Za-zÀ-ÖØ-öø-ÿĀ-žḀ-ỿ .'’-]{2,60}$/.test(p))) return 'Please use only letters for the city and state or country.';
  if (containsBlockedLanguage(t)) return 'Please enter a real place.';
  return null;
}

export function isEmail(text) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(String(text ?? '').trim());
}

/** Chat messages: contact details are hidden instead of refused. */
export function hideContactDetails(text) {
  return String(text)
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '[hidden]')
    .replace(/\+?\d[\d\s().-]{7,}\d/g, '[hidden]');
}

/** "07", "7" and "No. 7" are the same Companion. */
export function cleanNumber(raw) {
  const digits = String(raw ?? '').replace(/\D/g, '');
  const trimmed = digits.replace(/^0+/, '');
  return trimmed || (digits ? '0' : '');
}

export function cleanFindCode(typed) {
  return String(typed ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '');
}

/** Miles between two map points. */
export function milesBetween(lat1, lng1, lat2, lng2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 3958.8 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/** Map dots are blurred: about 10 km ("just the city") or about 100 m (a public place). */
export function blur(value, exactish) {
  return Number(Number(value).toFixed(exactish ? 3 : 1));
}

export const minMilesToLeave = 5;
