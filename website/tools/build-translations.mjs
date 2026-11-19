// Turns the app's translations (lib/translations.dart) into website/js/translations.js.
// Run from the repository root:  node website/tools/build-translations.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const dart = readFileSync(join(root, 'lib', 'translations.dart'), 'utf8');

const out = {};
let lang = null;
for (const line of dart.split('\n')) {
  const head = line.match(/^  '([a-z]{2})': \{/);
  if (head) { lang = head[1]; out[lang] = {}; continue; }
  const entry = line.match(/^    '((?:[^'\\]|\\.)*)': '((?:[^'\\]|\\.)*)',\s*$/);
  if (lang && entry) {
    const un = (s) => s.replace(/\\(.)/g, '$1');
    out[lang][un(entry[1])] = un(entry[2]);
  }
}
const counts = Object.entries(out).map(([k, v]) => `${k}: ${Object.keys(v).length}`).join(', ');
writeFileSync(
  join(here, '..', 'js', 'translations.js'),
  '// Made from lib/translations.dart by website/tools/build-translations.mjs. Do not edit by hand:\n' +
    '// change the app\'s file and run the script again. Website-only text is in translations-web.js.\n' +
    'export const appTranslations = ' + JSON.stringify(out, null, 1) + ';\n',
);
console.log('translations.js written (' + counts + ')');
