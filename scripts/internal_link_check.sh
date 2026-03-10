#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
SITE_DIR="${2:-_site}"

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "[fail] site directory not found: ${SITE_DIR}"
  exit 1
fi

mapfile -t paths < <(
  rg -o --no-filename '(href|src)="/[^"#?]*"' "${SITE_DIR}" -g '*.html' \
    | sed -E 's/^(href|src)=\"|\"$//g' \
    | sort -u
)

if [[ "${#paths[@]}" -eq 0 ]]; then
  echo "[fail] no internal links found in ${SITE_DIR}"
  exit 1
fi

total=0
redirects=0
failed=0

for path in "${paths[@]}"; do
  total=$((total + 1))
  code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}${path}")"

  case "${code}" in
    200)
      ;;
    301|302|307|308)
      final_code="$(curl -s -L -o /dev/null -w '%{http_code}' "${BASE_URL}${path}")"
      if [[ "${final_code}" == "200" ]]; then
        redirects=$((redirects + 1))
      else
        echo "[fail] ${path} redirect final status ${final_code}"
        failed=$((failed + 1))
      fi
      ;;
    *)
      echo "[fail] ${path} returned ${code}"
      failed=$((failed + 1))
      ;;
  esac
done

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] internal link check failed (${failed}/${total})"
  exit 1
fi

echo "[pass] internal link check: ${total} paths (redirects: ${redirects})"
