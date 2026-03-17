#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for search interaction checks"
  exit 1
fi

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"
node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

cat > "${node_script}" <<'EOF'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];

function fail(message) {
  console.error(`[fail] ${message}`);
  process.exit(1);
}

async function collectResults(page, query) {
  await page.goto(`${baseUrl}/search/?q=${encodeURIComponent(query)}`, { waitUntil: 'networkidle' });
  return page.$$eval('#search-results li', (els) =>
    els.map((li) => ({
      title: li.querySelector('h4')?.innerText || '',
      href: li.querySelector('a')?.getAttribute('href') || '',
    }))
  );
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });

  const announcementResults = await collectResults(page, 'renewal');
  if (!announcementResults.length) {
    fail('announcement query returned no search results');
  }
  if (announcementResults[0].href !== '/announcements/blog-renewal/') {
    fail(`announcement query top result mismatch: expected /announcements/blog-renewal/, got ${announcementResults[0].href || '(empty)'}`);
  }
  console.log(`[ok] announcement query top result -> ${announcementResults[0].href}`);

  const broadResults = await collectResults(page, 'kubernetes');
  if (!broadResults.length) {
    fail('broad query returned no search results');
  }
  console.log(`[ok] broad query results -> ${broadResults.length}`);

  await browser.close();
  console.log('[pass] search interaction check');
})().catch((error) => {
  fail(error.message);
});
EOF

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}"
