#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a targets=(
  "${ROOT_DIR}/README.md"
  "${ROOT_DIR}/Makefile"
  "${ROOT_DIR}/docs/sam-10-gnb-proposals.md"
  "${ROOT_DIR}/_data"
  "${ROOT_DIR}/_includes"
  "${ROOT_DIR}/_layouts"
  "${ROOT_DIR}/pages"
)

matches="$(
  rg -n '\bNews\b|\bDocs\b|\bdocumentation\b|\bDocumentation\b' "${targets[@]}" || true
)"

if [[ -n "${matches}" ]]; then
  echo "[fail] legacy IA terminology remains in source files"
  printf '%s\n' "${matches}"
  exit 1
fi

echo "[pass] source terminology check"
