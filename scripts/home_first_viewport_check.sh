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

      const title = rect('.home-hero__title');
      const hero = rect('.home-hero');
      const stats = rect('.home-stats');
      const announcement = rect('.home-announcement');
      const featured = rect('.home-featured-panel') || rect('.home-hero__quickstart') || rect('.home-hero__featured');
      const featuredCards = document.querySelectorAll('.home-feature-card').length;
      const announcementTitle = rect('.home-announcement__title');

      return {
        title,
        hero,
        stats,
        announcement,
        announcementTitle,
        featured,
        featuredCards,
        viewportHeight: window.innerHeight,
      };
    });

    if (!result.title || !result.hero || !result.stats || !result.featured) {
      fail(`${viewport.name} is missing required home hero sections`);
    }
    if (result.featuredCards < 2) {
      fail(`${viewport.name} expected at least 2 home feature cards but got ${result.featuredCards}`);
    }

    if (result.stats.bottom > result.viewportHeight) {
      fail(`${viewport.name} stats fall below first viewport (${Math.round(result.stats.bottom)} > ${result.viewportHeight})`);
    }

    if (result.announcement) {
      if (result.announcement.top >= result.featured.top) {
        fail(`${viewport.name} announcement is not placed before Start Here`);
      }
      if (result.announcement.height >= result.hero.height) {
        fail(`${viewport.name} announcement is not visually smaller than hero (${Math.round(result.announcement.height)} >= ${Math.round(result.hero.height)})`);
      }
      if (result.announcementTitle && result.announcementTitle.bottom > result.viewportHeight) {
        fail(`${viewport.name} announcement title falls below first viewport (${Math.round(result.announcementTitle.bottom)} > ${result.viewportHeight})`);
      }
      console.log(
        `[ok] ${viewport.name} first viewport: stats=${Math.round(result.stats.bottom)} announcement=${Math.round(result.announcement.bottom)} featuredTop=${Math.round(result.featured.top)} viewport=${result.viewportHeight}`
      );
    } else {
      if (result.featured.top <= result.stats.bottom) {
        fail(`${viewport.name} Start Here overlaps the hero/stats flow when no announcement is active`);
      }
      if (result.featured.bottom > result.viewportHeight) {
        fail(`${viewport.name} Start Here falls below first viewport when no announcement is active (${Math.round(result.featured.bottom)} > ${result.viewportHeight})`);
      }
      console.log(
        `[ok] ${viewport.name} first viewport without announcement: stats=${Math.round(result.stats.bottom)} featured=${Math.round(result.featured.bottom)} viewport=${result.viewportHeight}`
      );
    }

    await page.close();
  }

  await browser.close();
  console.log('[pass] home first viewport check');
})().catch((error) => {
  fail(error.message);
});
EOF

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
