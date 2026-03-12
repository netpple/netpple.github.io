#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
SITE_DIR="${2:-_site}"
FULL_SITE_OVERFLOW="${FULL_SITE_OVERFLOW:-false}"
OVERFLOW_MAX_ROUTES="${OVERFLOW_MAX_ROUTES:-0}"

if [[ "${FULL_SITE_OVERFLOW}" == "true" ]]; then
  OVERFLOW_TIMEOUT_MS="${OVERFLOW_TIMEOUT_MS:-60000}"
  OVERFLOW_RETRIES="${OVERFLOW_RETRIES:-3}"
else
  OVERFLOW_TIMEOUT_MS="${OVERFLOW_TIMEOUT_MS:-30000}"
  OVERFLOW_RETRIES="${OVERFLOW_RETRIES:-2}"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for responsive overflow checks"
  exit 1
fi

node_script="$(mktemp)"
routes_file="$(mktemp)"
trap 'rm -f "${node_script}" "${routes_file}"' EXIT

playwright_bin="$(npx --yes -p playwright -c 'which playwright')"
playwright_node_modules="$(cd "$(dirname "${playwright_bin}")/.." && pwd)"

default_routes=(
  "/"
  "/news/"
  "/docs/"
  "/about/"
  "/search/?q=kubernetes"
  "/2023/c-for-beginner-hongongc/"
  "/docs/istio-in-action/"
  "/docs/istio-in-action/Istio-ch11-performance"
  "/docs/querypie-handson/multiple-kubernetes-with-querypie-kac"
)

to_route_from_html_file() {
  local html_file="$1"
  local rel
  rel="${html_file#${SITE_DIR}/}"

  if [[ "${rel}" == "index.html" ]]; then
    printf '/\n'
    return
  fi

  if [[ "${rel}" == */index.html ]]; then
    printf '/%s/\n' "${rel%/index.html}"
    return
  fi

  printf '/%s\n' "${rel}"
}

build_full_routes() {
  if [[ ! -d "${SITE_DIR}" ]]; then
    echo "[fail] site directory not found: ${SITE_DIR}"
    exit 1
  fi

  mapfile -t generated_routes < <(
    find "${SITE_DIR}" -name '*.html' -type f | sort \
      | while IFS= read -r html_file; do
          to_route_from_html_file "${html_file}"
        done \
      | sort -u
  )

  if [[ "${#generated_routes[@]}" -eq 0 ]]; then
    echo "[fail] no html routes found in ${SITE_DIR}"
    exit 1
  fi

  {
    for route in "${generated_routes[@]}"; do
      printf '%s\n' "${route}"
    done
    # Search results view needs explicit query for realistic content layout checks.
    printf '/search/?q=kubernetes\n'
  } | sort -u > "${routes_file}"
}

build_default_routes() {
  printf '%s\n' "${default_routes[@]}" > "${routes_file}"
}

if [[ "${FULL_SITE_OVERFLOW}" == "true" ]]; then
  build_full_routes
else
  build_default_routes
fi

if [[ "${OVERFLOW_MAX_ROUTES}" =~ ^[0-9]+$ ]] && [[ "${OVERFLOW_MAX_ROUTES}" -gt 0 ]]; then
  tmp_routes_file="$(mktemp)"
  head -n "${OVERFLOW_MAX_ROUTES}" "${routes_file}" > "${tmp_routes_file}"
  mv "${tmp_routes_file}" "${routes_file}"
fi

route_count="$(wc -l < "${routes_file}" | tr -d ' ')"
echo "[overflow] base url: ${BASE_URL}"
echo "[overflow] mode: FULL_SITE_OVERFLOW=${FULL_SITE_OVERFLOW}, routes=${route_count}"
echo "[overflow] navigation: timeout=${OVERFLOW_TIMEOUT_MS}ms retries=${OVERFLOW_RETRIES}"

cat > "${node_script}" <<'NODE'
const { chromium } = require('playwright');
const fs = require('fs');

const baseUrl = process.argv[2];
const routesFile = process.argv[3];
const timeoutMs = Number.parseInt(process.argv[4] || '30000', 10);
const retryLimit = Number.parseInt(process.argv[5] || '2', 10);
const routes = fs
  .readFileSync(routesFile, 'utf8')
  .split(/\r?\n/)
  .map((value) => value.trim())
  .filter((value) => value.length > 0);

const viewports = [
  { name: 'desktop', width: 1366, height: 900 },
  { name: 'tablet', width: 1024, height: 768 },
  { name: 'mobile-max', width: 760, height: 900 },
  { name: 'mobile', width: 390, height: 844 },
];

const hasHorizontalOverflow = (metrics) => metrics.scrollWidth > metrics.viewportWidth + 1;

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;
  let failed = false;

  try {
    for (const route of routes) {
      for (const viewport of viewports) {
        const context = await browser.newContext({
          viewport: { width: viewport.width, height: viewport.height },
        });
        const page = await context.newPage();

        try {
          let response;
          let navigationError;
          for (let attempt = 1; attempt <= retryLimit; attempt += 1) {
            try {
              response = await page.goto(`${baseUrl}${route}`, {
                waitUntil: 'domcontentloaded',
                timeout: timeoutMs,
              });
              navigationError = null;
              break;
            } catch (error) {
              navigationError = error;
              if (attempt < retryLimit) {
                console.warn(
                  `[warn] ${route} @ ${viewport.name} retrying after navigation error: ${error.message}`
                );
                await page.waitForTimeout(400);
              }
            }
          }
          if (navigationError) {
            throw navigationError;
          }
          if (!response || !response.ok()) {
            const status = response ? response.status() : 'no-response';
            throw new Error(`navigation status ${status}`);
          }

          await page.waitForTimeout(500);
          const metrics = await page.evaluate(() => {
            const doc = document.documentElement;
            const body = document.body;
            const scrollWidth = Math.max(
              doc ? doc.scrollWidth : 0,
              body ? body.scrollWidth : 0
            );
            const viewportWidth = window.innerWidth || 0;
            return { scrollWidth, viewportWidth };
          });

          if (hasHorizontalOverflow(metrics)) {
            failed = true;
            console.error(
              `[fail] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) has horizontal overflow (${metrics.scrollWidth} > ${metrics.viewportWidth})`
            );
          } else {
            console.log(
              `[ok] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) no horizontal overflow`
            );
          }
        } catch (error) {
          failed = true;
          console.error(
            `[fail] ${route} @ ${viewport.name} (${viewport.width},${viewport.height}) check error: ${error.message}`
          );
        } finally {
          checks += 1;
          await context.close();
        }
      }
    }
  } finally {
    await browser.close();
  }

  if (failed) {
    process.exitCode = 1;
    return;
  }

  console.log(`[pass] responsive overflow check: ${checks} assertions`);
})();
NODE

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}" "${routes_file}" "${OVERFLOW_TIMEOUT_MS}" "${OVERFLOW_RETRIES}"
