#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"

routes=(
  "/"
  "/news/"
  "/docs/"
  "/about/"
  "/archive/"
  "/tags/"
  "/search/"
)

sample_post="/2023/c-for-beginner-hongongc/"
sample_doc="/docs/istio-in-action"

echo "[smoke] base url: ${BASE_URL}"

echo "[smoke] checking homepage content marker"
curl -fsSL "${BASE_URL}/" | grep -Eiq "netpple|김삼영|기술 블로그"

echo "[smoke] checking core route status codes"
for route in "${routes[@]}"; do
  code="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${route}")"
  if [[ "${code}" != "200" ]]; then
    echo "[fail] ${route} returned ${code}"
    exit 1
  fi
  echo "[ok] ${route} -> ${code}"
done

echo "[smoke] checking detail template markers"
curl -fsSL "${BASE_URL}${sample_post}" | grep -Eiq "article-shell|data-article-toc|data-article-content"
curl -fsSL "${BASE_URL}${sample_doc}" | grep -Eiq "article-shell|data-article-toc|Documentation Hub"

echo "[smoke] checking active nav mapping"
archive_active="$(curl -fsSL "${BASE_URL}/archive/" | grep -m1 'gnb__link is-active' | sed -E 's/.*href=\"([^\"]*)\".*/\1/')"
if [[ "${archive_active}" != "/news/" ]]; then
  echo "[fail] /archive/ expected active nav /news/ but got '${archive_active}'"
  exit 1
fi
echo "[ok] /archive/ active nav -> ${archive_active}"

echo "[pass] preview smoke checks completed"
