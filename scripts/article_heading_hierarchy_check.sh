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
  section_file="$(mktemp)"

  perl -0777 -pe 's{<script\b[^>]*>.*?</script>}{}gsi' "${html_file}" > "${clean_file}"

  if ! grep -Eq '<p class="article-header__eyebrow">(Post|Series|Series entry)</p>' "${clean_file}"; then
    rm -f "${clean_file}" "${section_file}"
    continue
  fi

  awk '
    /data-article-content/ { in_block=1; next }
    /<aside class="article-toc"/ { in_block=0 }
    in_block { print }
  ' "${clean_file}" > "${section_file}"

  if grep -q '<h1' "${section_file}"; then
    echo "[fail] ${html_file}"
    echo "       article content still contains <h1>"
    failed=$((failed + 1))
    rm -f "${clean_file}" "${section_file}"
    continue
  fi

  headings="$(
    (grep -Eo '<h[2-4][^>]*>' "${section_file}" || true) \
      | sed -E 's/^<h([2-4]).*/\1/'
  )"

  previous_level=""
  invalid_jump="false"

  while IFS= read -r level; do
    [[ -z "${level}" ]] && continue

    if [[ -z "${previous_level}" ]]; then
      previous_level="${level}"
      continue
    fi

    if (( level > previous_level + 1 )); then
      invalid_jump="true"
      break
    fi

    previous_level="${level}"
  done <<< "${headings}"

  if [[ "${invalid_jump}" == "true" ]]; then
    echo "[fail] ${html_file}"
    echo "       article content has an invalid heading-level jump"
    failed=$((failed + 1))
  fi

  rm -f "${clean_file}" "${section_file}"
done < <(find "${SITE_DIR}" -name '*.html' -type f | sort)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] article heading hierarchy check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] article heading hierarchy check"
