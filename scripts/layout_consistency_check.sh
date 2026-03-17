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
  nav_toggle_count="$(grep -c 'data-nav-toggle' "${clean_file}" || true)"
  nav_toggle_controls_count="$(grep -c 'aria-controls="site-navigation"' "${clean_file}" || true)"
  nav_toggle_label_count="$(grep -c 'aria-label="Open navigation menu"' "${clean_file}" || true)"
  main_count="$(grep -c '<main class="site-main" id="main-content"' "${clean_file}" || true)"
  main_tabindex_count="$(grep -c '<main class="site-main" id="main-content" role="main" tabindex="-1">' "${clean_file}" || true)"
  autofocus_count="$(grep -c 'autofocus' "${clean_file}" || true)"
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
  nav_id_count="$(printf '%s' "${nav_block}" | grep -c 'id="site-navigation"' || true)"
  nav_primary_label_count="$(printf '%s' "${nav_block}" | grep -c 'aria-label="Primary"' || true)"
  nav_aria_hidden_count="$(printf '%s' "${nav_block}" | grep -c 'aria-hidden="false"' || true)"

  header_block="$(
    awk '
      /<header class="site-header">/ { in_header=1 }
      in_header { print }
      /<\/header>/ {
        if (in_header) {
          exit
        }
      }
    ' "${clean_file}"
  )"

  footer_block="$(
    awk '
      /<footer class="site-footer">/ { in_footer=1 }
      in_footer { print }
      /<\/footer>/ {
        if (in_footer) {
          exit
        }
      }
    ' "${clean_file}"
  )"

  header_blank_target_count="$(
    (printf '%s' "${header_block}" | grep -o 'target="_blank"' || true) | wc -l | tr -d ' '
  )"
  header_safe_blank_target_count="$(
    (printf '%s' "${header_block}" | grep -Eo 'target="_blank"[^>]*rel="noreferrer noopener"|rel="noreferrer noopener"[^>]*target="_blank"' || true) | wc -l | tr -d ' '
  )"
  footer_blank_target_count="$(
    (printf '%s' "${footer_block}" | grep -o 'target="_blank"' || true) | wc -l | tr -d ' '
  )"
  footer_safe_blank_target_count="$(
    (printf '%s' "${footer_block}" | grep -Eo 'target="_blank"[^>]*rel="noreferrer noopener"|rel="noreferrer noopener"[^>]*target="_blank"' || true) | wc -l | tr -d ' '
  )"

  home_css_count="$(grep -c '/assets/css/home.css' "${clean_file}" || true)"
  expected_home_css_count="0"
  if [[ "${html_file}" == "${SITE_DIR}/index.html" ]]; then
    expected_home_css_count="1"
  fi
  rm -f "${clean_file}"

  if [[ "${skip_count}" != "1" || "${header_count}" != "1" || "${nav_toggle_count}" != "1" || "${nav_toggle_controls_count}" != "1" || "${nav_toggle_label_count}" != "1" || "${main_count}" != "1" || "${main_tabindex_count}" != "1" || "${autofocus_count}" != "0" || "${footer_count}" != "1" || "${h1_count}" != "1" || "${active_nav_count}" != "1" || "${aria_current_count}" != "1" || "${nav_id_count}" != "1" || "${nav_primary_label_count}" != "1" || "${nav_aria_hidden_count}" != "1" || "${home_css_count}" != "${expected_home_css_count}" || "${header_blank_target_count}" != "${header_safe_blank_target_count}" || "${footer_blank_target_count}" != "${footer_safe_blank_target_count}" ]]; then
    echo "[fail] ${html_file}"
    echo "       skip=${skip_count} header=${header_count} nav_toggle=${nav_toggle_count} nav_controls=${nav_toggle_controls_count} nav_toggle_label=${nav_toggle_label_count} main=${main_count} main_tabindex=${main_tabindex_count} autofocus=${autofocus_count} footer=${footer_count} h1=${h1_count} active_nav=${active_nav_count} aria_current=${aria_current_count} nav_id=${nav_id_count} nav_primary_label=${nav_primary_label_count} nav_aria_hidden=${nav_aria_hidden_count} home_css=${home_css_count}/${expected_home_css_count} header_blank_rel=${header_safe_blank_target_count}/${header_blank_target_count} footer_blank_rel=${footer_safe_blank_target_count}/${footer_blank_target_count}"
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] layout consistency check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] layout consistency check: ${total} html pages"
