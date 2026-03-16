#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for home first viewport checks"
  exit 1
fi

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"
node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

cat > "${node_script}" <<'EOF'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];
const viewports = [
  { name: 'desktop-min', width: 961, height: 800 },
  { name: 'tablet', width: 1024, height: 768 },
  { name: 'desktop', width: 1366, height: 900 },
];

function fail(message) {
  console.error(`[fail] ${message}`);
  process.exit(1);
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  for (const viewport of viewports) {
    const page = await browser.newPage({ viewport: { width: viewport.width, height: viewport.height } });
    await page.goto(`${baseUrl}/`, { waitUntil: 'networkidle' });

    const result = await page.evaluate(() => {
      const select = (selector) => document.querySelector(selector);
      const rect = (selector) => {
        const element = select(selector);
        if (!element) return null;
        const box = element.getBoundingClientRect();
        return { top: box.top, bottom: box.bottom, height: box.height };
      };

      const grid = select('.home-hero__grid');
      const title = rect('.home-hero__title');
      const stats = rect('.home-stats');
      const featured = rect('.home-hero__featured');
      const featuredCards = document.querySelectorAll('.home-feature-card').length;
      const gridTemplateColumns = grid ? getComputedStyle(grid).gridTemplateColumns : '';

      return {
        title,
        stats,
        featured,
        featuredCards,
        gridTemplateColumns,
        viewportHeight: window.innerHeight,
      };
    });

    if (!result.title || !result.stats || !result.featured) {
      fail(`${viewport.name} is missing required home hero sections`);
    }
    if (result.featuredCards < 4) {
      fail(`${viewport.name} expected at least 4 home feature cards but got ${result.featuredCards}`);
    }

    const columnCount = (result.gridTemplateColumns.match(/px/g) || []).length;
    if (columnCount < 2) {
      fail(`${viewport.name} expected a two-column home hero but got '${result.gridTemplateColumns}'`);
    }

    if (result.stats.bottom > result.viewportHeight) {
      fail(`${viewport.name} stats fall below first viewport (${Math.round(result.stats.bottom)} > ${result.viewportHeight})`);
    }
    if (result.featured.bottom > result.viewportHeight) {
      fail(`${viewport.name} featured routes fall below first viewport (${Math.round(result.featured.bottom)} > ${result.viewportHeight})`);
    }

    console.log(
      `[ok] ${viewport.name} first viewport: stats=${Math.round(result.stats.bottom)} featured=${Math.round(result.featured.bottom)} viewport=${result.viewportHeight}`
    );

    await page.close();
  }

  await browser.close();
  console.log('[pass] home first viewport check');
})().catch((error) => {
  fail(error.message);
});
EOF

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
