#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-$PWD}"
PREVIEW_IMAGE="${PREVIEW_IMAGE:-jekyll/jekyll:4.2.0}"
BUNDLE_DIR="${WORKDIR}/vendor/bundle"

announcement_meta="$(
  ruby - "${WORKDIR}/_announcements" <<'RUBY'
require "time"
require "yaml"

announcements_dir = ARGV.fetch(0)
now = Time.now
announcements = Dir.glob(File.join(announcements_dir, "*.md")).map do |path|
  content = File.read(path)
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  next unless match
  data = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: false) || {}
  next if data["published"] == false
  expires_at = data["expires_at"] ? Time.parse(data["expires_at"].to_s) : nil
  next if expires_at && expires_at <= now
  {
    "title" => data["title"].to_s,
    "date" => Time.parse(data["date"].to_s),
    "detail_url" => "/announcements/#{File.basename(path, ".md")}/",
    "path" => path,
    "pinned" => data["pinned"] == true,
  }
end.compact

primary = announcements.sort_by { |item| item["date"] }.reverse.find { |item| item["pinned"] } ||
  announcements.sort_by { |item| item["date"] }.reverse.first

abort("no active announcement found") unless primary

puts [primary["title"], primary["detail_url"]].join("\t")
RUBY
)"
IFS=$'\t' read -r active_announcement_title active_announcement_url <<< "${announcement_meta}"

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

assert_contains "${hidden_home}" "${active_announcement_title}" "active announcement still renders on Home"
assert_contains "${hidden_archive}" "${active_announcement_title}" "active announcement still renders in archive"
assert_contains "${hidden_search}" '"categories": "announcement"' "active announcement stays in search index"
assert_contains "${hidden_search}" "\"url\": \"${active_announcement_url}\"" "active announcement detail url stays in search index"
assert_not_contains "${hidden_home}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off Home"
assert_not_contains "${hidden_archive}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off archive"
assert_not_contains "${hidden_search}" '비공개 공지 테스트|만료 공지 테스트' "hidden/expired announcements stay off search"

echo "[edge] case 2: no active announcements removes Home slot and shows archive empty state"
none_dir="${tmp_root}/none"
rsync -a --exclude '.git' "${WORKDIR}/" "${none_dir}/" >/dev/null
find "${none_dir}/_announcements" -name '*.md' -type f -exec perl -0pi -e 's/published: true/published: false/g' {} +
build_temp_site "${none_dir}" "_site_edge_none"

none_home="${none_dir}/_site_edge_none/index.html"
none_archive="${none_dir}/_site_edge_none/announcements/index.html"
none_search="${none_dir}/_site_edge_none/search/index.html"

assert_not_contains "${none_home}" 'home-announcement__title|home-announcement-list__item' "Home announcement block disappears when no active announcements exist"
assert_contains "${none_home}" 'Start Here' "Home still flows directly into Start Here"
assert_contains "${none_archive}" '현재 노출 중인 공지가 없습니다' "archive shows empty-state message when no announcements are active"
assert_not_contains "${none_search}" '"categories": "announcement"' "inactive announcements drop out of search data"

echo "[edge] case 3: expired pinned announcements do not block active pinned validation"
expired_pinned_dir="${tmp_root}/expired-pinned"
rsync -a --exclude '.git' "${WORKDIR}/" "${expired_pinned_dir}/" >/dev/null
cat > "${expired_pinned_dir}/_announcements/expired-pinned.md" <<'EOF'
---
title: 만료된 pinned 공지 테스트
summary: 이 공지는 pinned 상태지만 만료됐기 때문에 active pinned 중복으로 계산되면 안 됩니다.
date: 2026-03-10 09:00:00 +0900
expires_at: 2026-03-12 23:59:59 +0900
cta_label: 만료 공지 보기
cta_url: /announcements/expired-pinned/
pinned: true
published: true
---

validation only
EOF
"${WORKDIR}/scripts/announcement_content_check.sh" "${expired_pinned_dir}/_announcements" >/dev/null
echo "[ok] expired pinned announcement does not fail active pinned validation"

echo "[edge] case 4: latest active unpinned announcement still appears on Home"
unpinned_dir="${tmp_root}/unpinned"
rsync -a --exclude '.git' "${WORKDIR}/" "${unpinned_dir}/" >/dev/null
find "${unpinned_dir}/_announcements" -name '*.md' -type f -exec perl -0pi -e 's/pinned: true/pinned: false/g' {} +
build_temp_site "${unpinned_dir}" "_site_edge_unpinned"

unpinned_home="${unpinned_dir}/_site_edge_unpinned/index.html"

assert_contains "${unpinned_home}" 'home-announcement__title|Announcement' "Home still renders compact announcement slot when only unpinned announcements exist"
assert_not_contains "${unpinned_home}" '>\s*Pinned\s*<' "Home does not show pinned badge when only unpinned announcements exist"

echo "[pass] announcement edge case check"
