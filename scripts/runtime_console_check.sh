#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for runtime console checks"
  exit 1
fi

node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"

cat > "${node_script}" <<'NODE'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];
const routes = [
  '/',
  '/news/',
  '/docs/',
  '/about/',
  '/archive/',
  '/tags/',
  '/search/?q=kubernetes',
  '/2023/c-for-beginner-hongongc/',
  '/2021/how-uid-gid-work-in-container/',
  '/docs/istio-in-action/',
  '/docs/istio-in-action/Istio-ch11-performance',
  '/docs/querypie-handson/multiple-kubernetes-with-querypie-kac',
];

function isIgnorableConsoleError(message) {
  const normalized = (message || '').toLowerCase();
  return normalized.includes('google-analytics.com')
    || normalized.includes('googletagmanager.com');
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;

  try {
    for (const route of routes) {
      const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
      const page = await context.newPage();
      const errors = [];

      page.on('pageerror', (error) => {
        errors.push(`pageerror: ${error.message}`);
      });

      page.on('console', (msg) => {
        if (msg.type() !== 'error') {
          return;
        }
        const text = msg.text();
        if (isIgnorableConsoleError(text)) {
          return;
        }
        errors.push(`console.error: ${text}`);
      });

      page.on('requestfailed', (request) => {
        const url = request.url();
        if (!url.startsWith(baseUrl)) {
          return;
        }
        const failure = request.failure();
        const message = failure && failure.errorText ? failure.errorText : 'unknown';
        errors.push(`requestfailed: ${url} (${message})`);
      });

      await page.goto(`${baseUrl}${route}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(200);

      if (errors.length) {
        throw new Error(`${route} -> ${errors.slice(0, 3).join(' | ')}`);
      }

      checks += 1;
      console.log(`[ok] ${route} runtime console check`);
      await context.close();
    }
  } catch (error) {
    console.error(`[fail] runtime console check: ${error.message}`);
    process.exitCode = 1;
    return;
  } finally {
    await browser.close();
  }

  console.log(`[pass] runtime console check: ${checks} assertions`);
})();
NODE

echo "[runtime] base url: ${BASE_URL}"
NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
