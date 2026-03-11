#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
SITE_DIR="${2:-_site}"
FULL_SITE_RUNTIME="${FULL_SITE_RUNTIME:-false}"
RUNTIME_MAX_ROUTES="${RUNTIME_MAX_ROUTES:-0}"
RUNTIME_TIMEOUT_MS="${RUNTIME_TIMEOUT_MS:-30000}"

if ! command -v npx >/dev/null 2>&1; then
  echo "[fail] npx is required for runtime console checks"
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
  "/archive/"
  "/tags/"
  "/search/?q=kubernetes"
  "/2023/c-for-beginner-hongongc/"
  "/2021/how-uid-gid-work-in-container/"
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
    # Search results view needs explicit query for realistic runtime checks.
    printf '/search/?q=kubernetes\n'
  } | sort -u > "${routes_file}"
}

build_default_routes() {
  printf '%s\n' "${default_routes[@]}" > "${routes_file}"
}

if [[ "${FULL_SITE_RUNTIME}" == "true" ]]; then
  build_full_routes
else
  build_default_routes
fi

if [[ "${RUNTIME_MAX_ROUTES}" =~ ^[0-9]+$ ]] && [[ "${RUNTIME_MAX_ROUTES}" -gt 0 ]]; then
  tmp_routes_file="$(mktemp)"
  head -n "${RUNTIME_MAX_ROUTES}" "${routes_file}" > "${tmp_routes_file}"
  mv "${tmp_routes_file}" "${routes_file}"
fi

route_count="$(wc -l < "${routes_file}" | tr -d ' ')"
echo "[runtime] base url: ${BASE_URL}"
echo "[runtime] mode: FULL_SITE_RUNTIME=${FULL_SITE_RUNTIME}, routes=${route_count}"
echo "[runtime] timeout: ${RUNTIME_TIMEOUT_MS}ms"

cat > "${node_script}" <<'NODE'
const { chromium } = require('playwright');
const fs = require('fs');

const baseUrl = process.argv[2];
const routesFile = process.argv[3];
const timeoutMs = Number.parseInt(process.argv[4] || '30000', 10);
const routes = fs
  .readFileSync(routesFile, 'utf8')
  .split(/\r?\n/)
  .map((value) => value.trim())
  .filter((value) => value.length > 0);

function isIgnorableConsoleError(message) {
  const normalized = (message || '').toLowerCase();
  if (normalized.includes('failed to load resource')) {
    return true;
  }
  return normalized.includes('google-analytics.com')
    || normalized.includes('googletagmanager.com');
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  let checks = 0;
  let failed = false;

  try {
    for (const route of routes) {
      const context = await browser.newContext({ viewport: { width: 1366, height: 900 } });
      const page = await context.newPage();
      const errors = [];

      page.on('pageerror', (error) => {
        errors.push(`pageerror: ${error.message}`);
      });

      page.on('console', (msg) => {
        if (msg.type() !== 'error') {
          return;
        }
        const text = msg.text();
        if (isIgnorableConsoleError(text)) {
          return;
        }
        errors.push(`console.error: ${text}`);
      });

      page.on('requestfailed', (request) => {
        const url = request.url();
        if (!url.startsWith(baseUrl)) {
          return;
        }
        const failure = request.failure();
        const message = failure && failure.errorText ? failure.errorText : 'unknown';
        errors.push(`requestfailed: ${url} (${message})`);
      });

      page.on('response', (response) => {
        const url = response.url();
        if (!url.startsWith(baseUrl)) {
          return;
        }
        const status = response.status();
        if (status >= 400) {
          errors.push(`response: ${url} (${status})`);
        }
      });

      try {
        let response;
        let navigationError;
        for (let attempt = 1; attempt <= 2; attempt += 1) {
          try {
            response = await page.goto(`${baseUrl}${route}`, {
              waitUntil: 'domcontentloaded',
              timeout: timeoutMs,
            });
            navigationError = null;
            break;
          } catch (error) {
            navigationError = error;
            if (attempt < 2) {
              console.warn(`[warn] ${route} retrying after navigation error: ${error.message}`);
              await page.waitForTimeout(400);
            }
          }
        }
        if (navigationError) {
          throw navigationError;
        }
        if (!response || !response.ok()) {
          const status = response ? response.status() : 'no-response';
          errors.push(`navigation status ${status}`);
        }
        await page.waitForTimeout(400);

        if (errors.length) {
          failed = true;
          console.error(`[fail] ${route} runtime console check: ${errors.slice(0, 3).join(' | ')}`);
        } else {
          checks += 1;
          console.log(`[ok] ${route} runtime console check`);
        }
      } catch (error) {
        failed = true;
        console.error(`[fail] ${route} runtime console check: ${error.message}`);
      } finally {
        await context.close();
      }
    }
  } finally {
    await browser.close();
  }

  if (failed) {
    process.exitCode = 1;
    return;
  }

  console.log(`[pass] runtime console check: ${checks} assertions`);
})();
NODE

NODE_PATH="${playwright_node_modules}" node "${node_script}" "${BASE_URL}" "${routes_file}" "${RUNTIME_TIMEOUT_MS}"
