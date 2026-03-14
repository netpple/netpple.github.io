#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a targets=(
  "${ROOT_DIR}/_layouts"
  "${ROOT_DIR}/_includes"
  "${ROOT_DIR}/_posts"
  "${ROOT_DIR}/_docs"
  "${ROOT_DIR}/pages"
)

matches="$(
  rg -n '%H:%m' "${targets[@]}" || true
)"

if [[ -n "${matches}" ]]; then
  echo "[fail] legacy date format token remains in source"
  printf '%s\n' "${matches}"
  exit 1
fi

echo "[pass] source format check"
