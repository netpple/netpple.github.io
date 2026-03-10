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
  # Ignore script payload blocks to avoid false positives from embedded JSON/script text.
  perl -0777 -pe 's{<script\b[^>]*>.*?</script>}{}gsi' "${html_file}" > "${clean_file}"

  skip_count="$(grep -c 'class="skip-link"' "${clean_file}" || true)"
  header_count="$(grep -c '<header class="site-header">' "${clean_file}" || true)"
  main_count="$(grep -c '<main class="site-main" id="main-content"' "${clean_file}" || true)"
  footer_count="$(grep -c '<footer class="site-footer">' "${clean_file}" || true)"
  h1_count="$(
    (grep -o '<h1' "${clean_file}" || true) | wc -l | tr -d ' '
  )"

  nav_block="$(
    awk '
      /<nav class="gnb"/ { in_nav=1 }
      in_nav { print }
      /<\/nav>/ {
        if (in_nav) {
          exit
        }
      }
    ' "${clean_file}"
  )"

  active_nav_count="$(printf '%s' "${nav_block}" | grep -c 'gnb__link is-active' || true)"
  aria_current_count="$(printf '%s' "${nav_block}" | grep -c 'aria-current="page"' || true)"
  rm -f "${clean_file}"

  if [[ "${skip_count}" != "1" || "${header_count}" != "1" || "${main_count}" != "1" || "${footer_count}" != "1" || "${h1_count}" != "1" || "${active_nav_count}" != "1" || "${aria_current_count}" != "1" ]]; then
    echo "[fail] ${html_file}"
    echo "       skip=${skip_count} header=${header_count} main=${main_count} footer=${footer_count} h1=${h1_count} active_nav=${active_nav_count} aria_current=${aria_current_count}"
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] layout consistency check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] layout consistency check: ${total} html pages"
