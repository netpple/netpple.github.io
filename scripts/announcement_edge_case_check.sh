#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-$PWD}"
PREVIEW_IMAGE="${PREVIEW_IMAGE:-jekyll/jekyll:4.2.0}"
BUNDLE_DIR="${WORKDIR}/vendor/bundle"

if [[ ! -d "${WORKDIR}/_announcements" ]]; then
  echo "[fail] announcements directory not found under ${WORKDIR}"
  exit 1
fi

if [[ ! -d "${BUNDLE_DIR}" ]]; then
  echo "[fail] bundle directory not found: ${BUNDLE_DIR}"
  exit 1
fi

tmp_root="$(mktemp -d /tmp/sam13-ann-edges-XXXXXX)"
trap 'rm -rf "${tmp_root}"' EXIT

build_temp_site() {
  local source_dir="$1"
  local dest_dir="$2"
  docker run --rm \
    -e BUNDLE_PATH=/usr/local/bundle \
    -v "${source_dir}:/srv/jekyll" \
    -v "${BUNDLE_DIR}:/usr/local/bundle" \
    "${PREVIEW_IMAGE}" \
    bash -lc "bundle exec jekyll build -d ${dest_dir}" >/dev/null
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Eiq "${pattern}" "${file}"; then
    echo "[fail] ${description}"
    echo "       file: ${file}"
    exit 1
  fi
  echo "[ok] ${description}"
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  if grep -Eiq "${pattern}" "${file}"; then
    echo "[fail] ${description}"
    echo "       file: ${file}"
    exit 1
  fi
  echo "[ok] ${description}"
}

echo "[edge] case 1: hidden and expired announcements stay hidden"
hidden_dir="${tmp_root}/hidden"
rsync -a --exclude '.git' "${WORKDIR}/" "${hidden_dir}/" >/dev/null
cat > "${hidden_dir}/_announcements/hidden-unpublished.md" <<'EOF'
---
title: 비공개 공지 테스트
summary: 이 공지는 published false 상태라 노출되면 안 됩니다.
date: 2026-03-18 09:00:00 +0900
cta_label: 숨김 공지 보기
cta_url: /announcements/hidden-unpublished/
pinned: false
published: false
---

validation only
EOF
cat > "${hidden_dir}/_announcements/hidden-expired.md" <<'EOF'
---
title: 만료 공지 테스트
summary: 이 공지는 만료됐기 때문에 노출되면 안 됩니다.
date: 2026-03-16 09:00:00 +0900
expires_at: 2026-03-16 23:59:59 +0900
cta_label: 만료 공지 보기
cta_url: /announcements/hidden-expired/
pinned: false
published: true
---

validation only
EOF
build_temp_site "${hidden_dir}" "_site_edge_hidden"

hidden_home="${hidden_dir}/_site_edge_hidden/index.html"
hidden_archive="${hidden_dir}/_site_edge_hidden/announcements/index.html"
hidden_search="${hidden_dir}/_site_edge_hidden/search/index.html"

assert_contains "${hidden_home}" '블로그 리뉴얼 안내' "active announcement still renders on Home"
assert_contains "${hidden_archive}" '블로그 리뉴얼 안내' "active announcement still renders in archive"
assert_not_contains "${hidden_home}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off Home"
assert_not_contains "${hidden_archive}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off archive"
assert_not_contains "${hidden_search}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off search"

echo "[edge] case 2: no active announcements removes Home slot and shows archive empty state"
none_dir="${tmp_root}/none"
rsync -a --exclude '.git' "${WORKDIR}/" "${none_dir}/" >/dev/null
perl -0pi -e 's/published: true/published: false/' "${none_dir}/_announcements/blog-renewal.md"
build_temp_site "${none_dir}" "_site_edge_none"

none_home="${none_dir}/_site_edge_none/index.html"
none_archive="${none_dir}/_site_edge_none/announcements/index.html"
none_search="${none_dir}/_site_edge_none/search/index.html"

assert_not_contains "${none_home}" 'home-announcement' "Home announcement block disappears when no active announcements exist"
assert_contains "${none_home}" 'Start Here' "Home still flows directly into Start Here"
assert_contains "${none_archive}" '현재 노출 중인 공지가 없습니다' "archive shows empty-state message when no announcements are active"
assert_not_contains "${none_search}" '블로그 리뉴얼 안내' "inactive announcements drop out of search data"

echo "[pass] announcement edge case check"
