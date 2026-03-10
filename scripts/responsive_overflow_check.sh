#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for responsive overflow checks"
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
  '/search/?q=kubernetes',
  '/2023/c-for-beginner-hongongc/',
  '/docs/istio-in-action/',
];
const viewports = [
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'tablet', width: 1024, height: 768 },
  { name: 'mobile', width: 390, height: 844 },
];

const hasHorizontalOverflow = (metrics) => metrics.scrollWidth > metrics.viewportWidth + 1;

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;
  let failed = false;

  try {
    for (const route of routes) {
      for (const viewport of viewports) {
        const context = await browser.newContext({
          viewport: { width: viewport.width, height: viewport.height },
        });
        const page = await context.newPage();

        try {
          const response = await page.goto(`${baseUrl}${route}`, {
            waitUntil: 'domcontentloaded',
            timeout: 30000,
          });
          if (!response || !response.ok()) {
            const status = response ? response.status() : 'no-response';
            throw new Error(`navigation status ${status}`);
          }

          await page.waitForTimeout(500);
          const metrics = await page.evaluate(() => {
            const doc = document.documentElement;
            const body = document.body;
            const scrollWidth = Math.max(
              doc ? doc.scrollWidth : 0,
              body ? body.scrollWidth : 0
            );
            const viewportWidth = window.innerWidth || 0;
            return { scrollWidth, viewportWidth };
          });

          if (hasHorizontalOverflow(metrics)) {
            failed = true;
            console.error(
              `[fail] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) has horizontal overflow (${metrics.scrollWidth} > ${metrics.viewportWidth})`
            );
          } else {
            console.log(
              `[ok] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) no horizontal overflow`
            );
          }
        } catch (error) {
          failed = true;
          console.error(
            `[fail] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) check error: ${error.message}`
          );
        } finally {
          checks += 1;
          await context.close();
        }
      }
    }
  } finally {
    await browser.close();
  }

  if (failed) {
    process.exitCode = 1;
    return;
  }

  console.log(`[pass] responsive overflow check: ${checks} assertions`);
})();
NODE

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
