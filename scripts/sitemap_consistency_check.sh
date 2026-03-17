#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:-_site}"
SITEMAP_FILE="${SITE_DIR}/sitemap.xml"

if [[ ! -f "${SITEMAP_FILE}" ]]; then
  echo "[fail] sitemap file not found: ${SITEMAP_FILE}"
  exit 1
fi

expected_patterns=(
  '<loc>https?://[^<]+/</loc>'
  '<loc>https?://[^<]+/docs/</loc>'
  '<loc>https?://[^<]+/news/</loc>'
)

for pattern in "${expected_patterns[@]}"; do
  if ! grep -Eq "${pattern}" "${SITEMAP_FILE}"; then
    echo "[fail] sitemap is missing expected loc pattern: ${pattern}"
    exit 1
  fi
done

if grep -Eq '<loc>(/|docs/|news//)' "${SITEMAP_FILE}"; then
  echo "[fail] sitemap still contains relative or malformed loc values"
  exit 1
fi

if grep -Eq '<loc>https?://[^<]*//[^<]*</loc>' "${SITEMAP_FILE}"; then
  echo "[fail] sitemap contains malformed double-slash loc values"
  exit 1
fi

if grep -Evq '(^\s*$|^\s*(<\?xml|<urlset|</urlset>|<url>|</url>|<lastmod>|<changefreq>|<loc>https?://[^<]+</loc>))' "${SITEMAP_FILE}"; then
  echo "[fail] sitemap contains a non-absolute loc entry"
  exit 1
fi

echo "[pass] sitemap consistency check"
