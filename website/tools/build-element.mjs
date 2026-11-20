// Builds website/dist/herd-around-the-world.js: the whole website (all JS modules, the shared
// rules and the CSS) in one file, for The Herd's Wix site as a Custom Element
// (Tag Name: herd-around-the-world).
// Run from the repository root:  node website/tools/build-element.mjs
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdirSync, statSync } from 'node:fs';

const ESBUILD = 'esbuild@0.24.2'; // pinned
const here = dirname(fileURLToPath(import.meta.url));
const website = join(here, '..');
const out = join(website, 'dist', 'herd-around-the-world.js');
mkdirSync(dirname(out), { recursive: true });

execFileSync('npx', [
  '--yes', ESBUILD,
  join(website, 'js', 'element.js'),
  '--bundle',
  '--format=iife',
  '--target=es2020,safari14',
  '--loader:.css=text',
  '--minify',
  '--legal-comments=none',
  '--log-level=warning',
  // import.meta.url is only used by the standalone site; the element sets its own data folder.
  '--define:import.meta.url=undefined',
  '--banner:js=/* Herd Around the World · The Herd · <herd-around-the-world> custom element */',
  `--outfile=${out}`,
], { stdio: 'inherit' });

console.log(`built ${out} (${Math.round(statSync(out).size / 1024)} KB)`);
