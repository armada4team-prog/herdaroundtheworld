// Builds worker/dist/worker.js: the checker (shared/rules.js + wix/backend/handlers.src.js, joined
// into wix/backend/http-functions.js) with Velo's modules swapped for the REST stand-ins in
// worker/src/adapters, in one ES module for Cloudflare Workers.
// Run from anywhere:  node worker/build.mjs   (wrangler runs it too, see wrangler.toml)
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdirSync, statSync } from 'node:fs';

const ESBUILD = 'esbuild@0.24.2'; // pinned
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const out = join(here, 'dist', 'worker.js');
mkdirSync(dirname(out), { recursive: true });

// Rejoin the rules and the checker first, so the Worker always has the latest of both.
execFileSync('python3', [join(root, 'tool', 'build_wix_backend.py')], { stdio: 'inherit' });

execFileSync('npx', [
  '--yes', ESBUILD,
  join('src', 'index.js'),
  '--bundle',
  '--format=esm',
  '--platform=neutral',
  '--target=es2022',
  '--alias:wix-http-functions=./src/adapters/wix-http-functions.js',
  '--alias:wix-data=./src/adapters/wix-data.js',
  '--alias:wix-media-backend=./src/adapters/wix-media-backend.js',
  '--alias:wix-crm-backend=./src/adapters/wix-crm-backend.js',
  '--alias:crypto=./src/adapters/crypto.js',
  '--inject:./src/adapters/buffer.js',
  '--legal-comments=none',
  '--log-level=warning',
  '--banner:js=// Herd Around the World checker for Cloudflare Workers. Built by worker/build.mjs: do not edit.',
  `--outfile=${out}`,
], { stdio: 'inherit', cwd: here });

console.log(`built ${out} (${Math.round(statSync(out).size / 1024)} KB)`);
