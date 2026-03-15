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
  matches="$(
    perl -0ne '
      while (/<a\b[^>]*href="(\/[^"#?]*\/index(?:\.html)?(?:[?#][^"]*)?)"/gsi) {
        print "$1\n";
      }
    ' "${html_file}" | sort -u
  )"

  if [[ -n "${matches}" ]]; then
    echo "[fail] ${html_file}"
    while IFS= read -r match; do
      [[ -n "${match}" ]] || continue
      echo "       internal canonical-link regression: ${match}"
    done <<< "${matches}"
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] internal canonical link check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] internal canonical link check: ${total} html pages"
