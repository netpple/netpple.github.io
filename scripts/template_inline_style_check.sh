#!/usr/bin/env bash
set -euo pipefail

template_files=(
  "_layouts/default.html"
  "_layouts/page.html"
  "_layouts/post.html"
  "_includes/head.html"
  "_includes/header.html"
  "_includes/footer.html"
  "pages/index.md"
  "pages/news.md"
  "pages/docs.md"
  "pages/about.md"
  "pages/archive.md"
  "pages/tags.html"
  "pages/search.html"
)

failed=0

while IFS= read -r match; do
  # Allowed exception: GTM noscript iframe inline style.
  if [[ "${match}" == *"googletagmanager.com/ns.html"* ]] && [[ "${match}" == *"display:none;visibility:hidden"* ]]; then
    continue
  fi

  echo "[fail] inline style detected in core template/page: ${match}"
  failed=$((failed + 1))
done < <(rg -n 'style="' "${template_files[@]}" || true)

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] template inline style check failed (${failed} issues)"
  exit 1
fi

echo "[pass] template inline style check"
