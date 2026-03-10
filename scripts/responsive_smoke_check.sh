#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
KEEP_ARTIFACTS="${KEEP_RESPONSIVE_ARTIFACTS:-false}"

routes=(
  "/"
  "/news/"
  "/docs/"
  "/about/"
  "/search/?q=kubernetes"
  "/2023/c-for-beginner-hongongc/"
  "/docs/istio-in-action/"
)

viewports=(
  "desktop:1366,900"
  "tablet:1024,768"
  "mobile:390,844"
)

sanitize_route() {
  local route="$1"
  route="${route#/}"
  route="${route//\//-}"
  route="${route//\?/-}"
  route="${route//\=/-}"
  route="${route//&/-}"
  [[ -z "${route}" ]] && route="home"
  printf '%s\n' "${route}"
}

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for responsive smoke checks"
  exit 1
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

echo "[responsive] base url: ${BASE_URL}"
echo "[responsive] running viewport screenshot checks"

count=0
for route in "${routes[@]}"; do
  route_key="$(sanitize_route "${route}")"
  for vp in "${viewports[@]}"; do
    name="${vp%%:*}"
    size="${vp##*:}"
    out="${tmpdir}/${route_key}-${name}.png"

    npx --yes playwright screenshot \
      --browser chromium \
      --viewport-size "${size}" \
      --wait-for-timeout 500 \
      --full-page \
      "${BASE_URL}${route}" \
      "${out}" >/dev/null

    if [[ ! -s "${out}" ]]; then
      echo "[fail] empty screenshot: route=${route} viewport=${name}"
      exit 1
    fi
    count=$((count + 1))
    echo "[ok] ${route} @ ${name} (${size})"
  done
done

if [[ "${KEEP_ARTIFACTS}" == "true" ]]; then
  target_dir="test-results/responsive-check/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${target_dir}"
  cp -f "${tmpdir}"/*.png "${target_dir}/"
  echo "[responsive] artifacts saved: ${target_dir}"
fi

echo "[pass] responsive smoke check: ${count} screenshots"
