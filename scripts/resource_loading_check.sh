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

  font_preconnect_count="$(
    perl -0ne 'print scalar(() = /<link\b[^>]*rel="preconnect"[^>]*href="https:\/\/fonts\.googleapis\.com"[^>]*>/gsi)' "${html_file}"
  )"
  font_gstatic_preconnect_count="$(
    perl -0ne 'print scalar(() = /<link\b[^>]*rel="preconnect"[^>]*href="https:\/\/fonts\.gstatic\.com"[^>]*crossorigin[^>]*>/gsi)' "${html_file}"
  )"
  font_preload_count="$(
    perl -0ne 'print scalar(() = /<link\b(?=[^>]*rel="preload")(?=[^>]*href="https:\/\/fonts\.googleapis\.com\/css2\?[^"]+")(?=[^>]*as="style")[^>]*>/gsi)' "${html_file}"
  )"
  font_async_stylesheet_count="$(
    perl -0ne 'print scalar(() = /<link\b(?=[^>]*rel="stylesheet")(?=[^>]*href="https:\/\/fonts\.googleapis\.com\/css2\?[^"]+")(?=[^>]*media="print")(?=[^>]*onload="this\.media='\''all'\''")[^>]*>/gsi)' "${html_file}"
  )"
  font_noscript_count="$(
    perl -0ne 'print scalar(() = /<noscript>\s*<link\b(?=[^>]*rel="stylesheet")(?=[^>]*href="https:\/\/fonts\.googleapis\.com\/css2\?[^"]+")[^>]*>\s*<\/noscript>/gsi)' "${html_file}"
  )"
  blocking_local_script_count="$(
    perl -0ne '
      my $count = 0;
      while (/<script\b[^>]*src="\/assets\/js\/[^"]+"[^>]*>/gsi) {
        my $tag = $&;
        $count++ if $tag !~ /\b(?:defer|async)\b/i;
      }
      print $count;
    ' "${html_file}"
  )"
  main_defer_count="$(
    perl -0ne 'print scalar(() = /<script\b(?=[^>]*src="\/assets\/js\/main\.js")(?=[^>]*\bdefer\b)[^>]*>/gsi)' "${html_file}"
  )"

  if [[ "${font_preconnect_count}" != "1" || "${font_gstatic_preconnect_count}" != "1" || "${font_preload_count}" != "1" || "${font_async_stylesheet_count}" != "1" || "${font_noscript_count}" != "1" || "${blocking_local_script_count}" != "0" || "${main_defer_count}" != "1" ]]; then
    echo "[fail] ${html_file}"
    echo "       font_preconnect=${font_preconnect_count} font_gstatic_preconnect=${font_gstatic_preconnect_count} font_preload=${font_preload_count} font_async_stylesheet=${font_async_stylesheet_count} font_noscript=${font_noscript_count} blocking_local_scripts=${blocking_local_script_count} main_defer=${main_defer_count}"
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] resource loading check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] resource loading check: ${total} html pages"
