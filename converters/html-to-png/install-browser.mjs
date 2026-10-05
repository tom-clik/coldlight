import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const result = spawnSync(process.execPath, [
  fileURLToPath(new URL('./node_modules/playwright/cli.js', import.meta.url)),
  'install', 'chromium', ...process.argv.slice(2)
], { stdio:'inherit', windowsHide:true, env: { ...process.env,
  PLAYWRIGHT_BROWSERS_PATH: process.env.PLAYWRIGHT_BROWSERS_PATH ?? fileURLToPath(new URL('./.browsers', import.meta.url)) } });
if (result.error) console.error(result.error.message);
process.exitCode = result.status ?? 1;
