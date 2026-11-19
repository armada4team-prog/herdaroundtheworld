// Builds website/data/sample.json (the preview data) from the app's sample data.
// Usage: node website/tools/build-sample.mjs path/to/sample.json
// sample.json is the app's 52 sample Companions with their stops and find codes; the number of
// travelers, "moved this week" and the sample chat are read from lib/sample_data.dart / app_state.dart.
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const companions = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const dart = readFileSync(join(root, 'lib', 'sample_data.dart'), 'utf8');

const extra = {};
for (const block of dart.split(/Companion\(/).slice(1)) {
  const number = block.match(/number: "([^"]+)"/)?.[1];
  if (!number) continue;
  extra[number] = {
    movedThisWeek: /movedThisWeek: true/.test(block),
    travelers: Number(block.match(/travelers: (\d+)/)?.[1] ?? 1),
  };
}
for (const c of companions) Object.assign(c, extra[c.number] ?? { movedThisWeek: false, travelers: 1 });

const chats = {
  '07': [
    { author: 'The Herd · made them in Aurora, CO', message: 'Welcome to #07’s chat! Everyone who carries them can talk here. Say hi to the travelers before you.', herd: true },
    { author: '[TRAVELER 2] · Traveler 4 · Boise, ID', message: 'I miss this little one already! Where are they headed next?' },
    { author: 'Sam R. · Traveler 5 · Moab, UT', message: 'They loved the arches. Somewhere with mountains, please!' },
  ],
};
writeFileSync(join(here, '..', 'data', 'sample.json'), JSON.stringify({ companions, chats }, null, 1) + '\n');
console.log('sample.json written with', companions.length, 'Companions');
