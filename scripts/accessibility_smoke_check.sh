#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for accessibility smoke checks"
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
  '/docs/istio-in-action/Istio-ch11-performance',
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;

  try {
    for (const route of routes) {
      const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
      const page = await context.newPage();
      await page.goto(`${baseUrl}${route}`, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await page.waitForTimeout(120);

      const initial = await page.evaluate(() => {
        const skipLink = document.querySelector('.skip-link');
        const main = document.getElementById('main-content');
        if (!skipLink) return { ok: false, reason: 'missing .skip-link' };
        if (!main) return { ok: false, reason: 'missing #main-content' };
        if (skipLink.getAttribute('href') !== '#main-content') {
          return { ok: false, reason: `skip-link href=${skipLink.getAttribute('href')}` };
        }
        if (main.getAttribute('tabindex') !== '-1') {
          return { ok: false, reason: `main tabindex=${main.getAttribute('tabindex')}` };
        }
        return { ok: true };
      });
      if (!initial.ok) {
        throw new Error(`${route} ${initial.reason}`);
      }

      await page.keyboard.press('Tab');
      const focused = await page.evaluate(() => {
        const skipLink = document.querySelector('.skip-link');
        const visible = (() => {
          if (!skipLink) return false;
          const style = getComputedStyle(skipLink);
          const rect = skipLink.getBoundingClientRect();
          return style.display !== 'none'
            && style.visibility !== 'hidden'
            && Number.parseFloat(style.opacity || '1') > 0.05
            && rect.width > 0
            && rect.height > 0
            && rect.top >= 0;
        })();
        return {
          isSkipFocused: document.activeElement === skipLink,
          isSkipVisible: visible,
        };
      });
      if (!focused.isSkipFocused) {
        throw new Error(`${route} skip-link is not first keyboard focus target`);
      }
      if (!focused.isSkipVisible) {
        throw new Error(`${route} skip-link is not visibly exposed on focus`);
      }

      await page.keyboard.press('Enter');
      await page.waitForFunction(() => window.location.hash === '#main-content', null, { timeout: 3000 });
      const postNavigate = await page.evaluate(() => {
        const main = document.getElementById('main-content');
        if (!main) return { ok: false, reason: 'missing #main-content after skip-link activation' };
        if (window.location.hash !== '#main-content') {
          return { ok: false, reason: `location.hash=${window.location.hash}` };
        }
        if (document.activeElement !== main) {
          const active = document.activeElement;
          const label = active ? active.tagName.toLowerCase() : 'null';
          return { ok: false, reason: `active element is ${label}` };
        }
        return { ok: true };
      });
      if (!postNavigate.ok) {
        throw new Error(`${route} ${postNavigate.reason}`);
      }

      console.log(`[ok] ${route} skip-link keyboard flow`);
      checks += 1;
      await context.close();
    }
  } catch (error) {
    console.error(`[fail] accessibility smoke: ${error.message}`);
    process.exitCode = 1;
    return;
  } finally {
    await browser.close();
  }

  console.log(`[pass] accessibility smoke check: ${checks} assertions`);
})();
NODE

echo "[a11y] base url: ${BASE_URL}"
NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
