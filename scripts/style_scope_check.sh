#!/usr/bin/env bash
set -euo pipefail

failed=0

check_home_class_scope() {
  local allowed_file="pages/index.md"
  local match

  while IFS= read -r match; do
    local file="${match%%:*}"
    if [[ "${file}" != "${allowed_file}" ]]; then
      echo "[fail] home-* class found outside ${allowed_file}: ${match}"
      failed=$((failed + 1))
    fi
  done < <(rg -n --pcre2 'class=\"[^\"]*home-[a-z0-9_-]+' pages _layouts _includes || true)
}

check_home_section_scope() {
  local allowed_file="pages/index.md"
  local match

  while IFS= read -r match; do
    local file="${match%%:*}"
    if [[ "${file}" != "${allowed_file}" ]]; then
      echo "[fail] home-section usage outside ${allowed_file}: ${match}"
      failed=$((failed + 1))
    fi
  done < <(rg -n 'home-section' pages _layouts _includes || true)
}

check_home_class_scope
check_home_section_scope

if [[ "${failed}" -gt 0 ]]; then
  echo "[fail] style scope check failed (${failed} issues)"
  exit 1
fi

echo "[pass] style scope check"
