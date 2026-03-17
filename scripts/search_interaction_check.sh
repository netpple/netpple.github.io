#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
ANNOUNCEMENTS_DIR="${ANNOUNCEMENTS_DIR:-_announcements}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for search interaction checks"
  exit 1
fi

announcement_meta="$(
  ruby - "${ANNOUNCEMENTS_DIR}" <<'RUBY'
require "time"
require "yaml"

announcements_dir = ARGV.fetch(0)
now = Time.now
announcements = Dir.glob(File.join(announcements_dir, "*.md")).map do |path|
  content = File.read(path)
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  next unless match
  data = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: false) || {}
  next if data["published"] == false
  expires_at = data["expires_at"] ? Time.parse(data["expires_at"].to_s) : nil
  next if expires_at && expires_at <= now
  {
    "date" => Time.parse(data["date"].to_s),
    "detail_url" => "/announcements/#{File.basename(path, ".md")}/",
    "pinned" => data["pinned"] == true,
  }
end.compact

primary = announcements.sort_by { |item| item["date"] }.reverse.find { |item| item["pinned"] } ||
  announcements.sort_by { |item| item["date"] }.reverse.first

abort("no active announcement found") unless primary

slug = primary["detail_url"].sub(%r{\A/announcements/}, "").sub(%r{/\z}, "")
query_terms = slug.split(/[^A-Za-z0-9]+/).select { |part| part.length >= 3 }
abort("no searchable announcement query token found") if query_terms.empty?

puts [query_terms.join(" "), primary["detail_url"]].join("\t")
RUBY
)"
IFS=$'\t' read -r active_announcement_query active_announcement_url <<< "${announcement_meta}"

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"
node_script="$(mktemp)"
trap 'rm -f "${node_script}"' EXIT

cat > "${node_script}" <<'EOF'
const { chromium } = require('playwright');

const baseUrl = process.argv[2];
const announcementQuery = process.argv[3];
const announcementUrl = process.argv[4];

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

  const announcementResults = await collectResults(page, announcementQuery);
  if (!announcementResults.length) {
    fail('announcement query returned no search results');
  }
  if (announcementResults[0].href !== announcementUrl) {
    fail(`announcement query top result mismatch: expected ${announcementUrl}, got ${announcementResults[0].href || '(empty)'}`);
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

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}" "${active_announcement_query}" "${active_announcement_url}"
