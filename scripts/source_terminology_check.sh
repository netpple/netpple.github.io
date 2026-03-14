#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a targets=(
  "${ROOT_DIR}/README.md"
  "${ROOT_DIR}/Makefile"
  "${ROOT_DIR}/docs/sam-10-gnb-proposals.md"
  "${ROOT_DIR}/_data"
  "${ROOT_DIR}/assets/css"
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

internal_matches="$(
  rg -n '\b(is_docs_detail|related_docs|sorted_docs|istio_docs|docker_docs|kube_docs|ddd_docs|querypie_docs|sample_doc|sample_doc_detail|sample_doc_hands_on)\b|page-news|page-docs|page-doc-detail|home-news-grid' "${targets[@]}" || true
)"

if [[ -n "${internal_matches}" ]]; then
  echo "[fail] legacy internal IA identifiers remain in source files"
  printf '%s\n' "${internal_matches}"
  exit 1
fi

echo "[pass] source terminology check"
