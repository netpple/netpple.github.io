#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="${1:-_site}"
HUB_FILE="${SITE_DIR}/docs/index.html"

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "[fail] site directory not found: ${SITE_DIR}"
  exit 1
fi

if [[ ! -f "${HUB_FILE}" ]]; then
  echo "[fail] series hub file not found: ${HUB_FILE}"
  exit 1
fi

clean_file="$(mktemp)"
perl -0777 -pe 's{<script\b[^>]*>.*?</script>}{}gsi' "${HUB_FILE}" > "${clean_file}"

for heading in "Series Navigation" "Recently Updated" "Series Index"; do
  if ! grep -Fq "${heading}" "${clean_file}"; then
    rm -f "${clean_file}"
    echo "[fail] series hub is missing heading: ${heading}"
    exit 1
  fi
done

if ! grep -Eq 'href="/search/"' "${clean_file}"; then
  rm -f "${clean_file}"
  echo "[fail] series hub is missing the Search shortcut"
  exit 1
fi

chip_targets="$(
  (grep -Eo 'href="#series-[^"]+"' "${clean_file}" || true) \
    | sed -E 's/^href="#|"$//g' \
    | sort -u
)"
section_ids="$(
  (grep -Eo 'id="series-[^"]+"' "${clean_file}" || true) \
    | sed -E 's/^id="|"$//g' \
    | sort -u
)"

chip_count="$(printf '%s\n' "${chip_targets}" | sed '/^$/d' | wc -l | tr -d ' ')"
section_count="$(printf '%s\n' "${section_ids}" | sed '/^$/d' | wc -l | tr -d ' ')"
recent_card_count="$(
  (grep -o 'class="entry-card entry-card--doc"' "${clean_file}" || true) | wc -l | tr -d ' '
)"
track_card_count="$(
  (grep -o 'class="track-card"' "${clean_file}" || true) | wc -l | tr -d ' '
)"

if [[ "${chip_count}" != "5" ]]; then
  rm -f "${clean_file}"
  echo "[fail] series hub expected 5 quick-jump chips but got ${chip_count}"
  exit 1
fi

if [[ "${section_count}" != "5" ]]; then
  rm -f "${clean_file}"
  echo "[fail] series hub expected 5 index sections but got ${section_count}"
  exit 1
fi

if [[ "${recent_card_count}" != "8" ]]; then
  rm -f "${clean_file}"
  echo "[fail] series hub expected 8 recent entry cards but got ${recent_card_count}"
  exit 1
fi

if [[ "${track_card_count}" != "5" ]]; then
  rm -f "${clean_file}"
  echo "[fail] series hub expected 5 track cards but got ${track_card_count}"
  exit 1
fi

if [[ "${chip_targets}" != "${section_ids}" ]]; then
  rm -f "${clean_file}"
  echo "[fail] series hub quick-jump targets do not match series section ids"
  echo "[info] chip targets:"
  printf '%s\n' "${chip_targets}" | sed 's/^/  - /'
  echo "[info] section ids:"
  printf '%s\n' "${section_ids}" | sed 's/^/  - /'
  exit 1
fi

rm -f "${clean_file}"
echo "[pass] series hub consistency check"
