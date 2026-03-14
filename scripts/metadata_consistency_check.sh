#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:-_site}"

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "[fail] site directory not found: ${SITE_DIR}"
  exit 1
fi

failed=0
total=0

while IFS= read -r html_file; do
  total=$((total + 1))
  clean_file="$(mktemp)"
  # Ignore script payload blocks to avoid false positives from embedded JSON text.
  perl -0777 -pe 's{<script\b[^>]*>.*?</script>}{}gsi' "${html_file}" > "${clean_file}"

  title_count="$(grep -c '<title>' "${clean_file}" || true)"
  desc_count="$(grep -c 'meta name="description"' "${clean_file}" || true)"
  canonical_count="$(grep -c 'rel="canonical"' "${clean_file}" || true)"
  og_url_count="$(grep -c 'property="og:url"' "${clean_file}" || true)"
  og_title_count="$(grep -c 'property="og:title"' "${clean_file}" || true)"
  og_type_count="$(grep -c 'property="og:type"' "${clean_file}" || true)"
  og_type_article_count="$(grep -c 'property="og:type" content="article"' "${clean_file}" || true)"
  og_type_website_count="$(grep -c 'property="og:type" content="website"' "${clean_file}" || true)"
  twitter_title_count="$(grep -c 'name="twitter:title"' "${clean_file}" || true)"
  iframe_missing_title_count="$(
    perl -0777 -ne 'while (/<iframe\b(?![^>]*\btitle=)[^>]*>/gsi) { $count += 1 } END { print $count || 0 }' "${clean_file}"
  )"

  expected_og_type="website"
  if grep -Eq '<p class="article-header__eyebrow">(Post|Series entry)</p>' "${clean_file}"; then
    expected_og_type="article"
  fi
  rm -f "${clean_file}"

  actual_og_type="missing"
  if [[ "${og_type_article_count}" == "1" ]]; then
    actual_og_type="article"
  elif [[ "${og_type_website_count}" == "1" ]]; then
    actual_og_type="website"
  fi

  if [[ "${title_count}" != "1" || "${desc_count}" != "1" || "${canonical_count}" != "1" || "${og_url_count}" != "1" || "${og_title_count}" != "1" || "${og_type_count}" != "1" || "${twitter_title_count}" != "1" || "${actual_og_type}" != "${expected_og_type}" || "${iframe_missing_title_count}" != "0" ]]; then
    echo "[fail] ${html_file}"
    echo "       title=${title_count} desc=${desc_count} canonical=${canonical_count} og_url=${og_url_count} og_title=${og_title_count} og_type=${actual_og_type}/${expected_og_type} og_type_count=${og_type_count} twitter_title=${twitter_title_count} iframe_missing_title=${iframe_missing_title_count}"
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] metadata consistency check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] metadata consistency check: ${total} html pages"
