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
  # Ignore inline script payload blocks to avoid false positives from embedded JSON text.
  perl -0777 -pe 's{<script\b[^>]*>.*?</script>}{}gsi' "${html_file}" > "${clean_file}"

  duplicates="$(
    (grep -o 'id="[^"]\+"' "${clean_file}" || true) \
      | sed -E 's/^id="|"$//g' \
      | sort \
      | uniq -d
  )"
  rm -f "${clean_file}"

  if [[ -n "${duplicates}" ]]; then
    echo "[fail] duplicate ids in ${html_file}"
    echo "${duplicates}" | sed 's/^/       - /'
    failed=$((failed + 1))
  fi
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] html id uniqueness check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] html id uniqueness check: ${total} html pages"
