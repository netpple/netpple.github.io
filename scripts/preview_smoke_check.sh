#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:4012}"
READY_RETRIES="${PREVIEW_SMOKE_READY_RETRIES:-12}"
READY_DELAY_SECONDS="${PREVIEW_SMOKE_READY_DELAY_SECONDS:-1}"

routes=(
  "/"
  "/news/"
  "/docs/"
  "/about/"
  "/archive/"
  "/tags/"
  "/search/"
)

search_query_routes=(
  "/search/?q=kubernetes"
  "/search/?q=%28"
  "/search/?q="
)

sample_post="/2023/c-for-beginner-hongongc/"
sample_series="/docs/istio-in-action"
sample_series_entry="/docs/istio-in-action/Istio-ch11-performance"
sample_data_series_entry="/docs/data-intensive-application-design/5-replication"
sample_series_entry_hands_on="/docs/querypie-handson/multiple-kubernetes-with-querypie-kac"
key_nav_paths=(
  "/2023/c-for-beginner-hongongc/"
  "/2023/k8s-1.26-install/"
  "/docs/istio-in-action/"
  "/docs/make-container-without-docker/"
  "/docs/deepdive-into-kubernetes/"
  "/docs/data-intensive-application-design/"
  "/docs/querypie-handson/multiple-kubernetes-with-querypie-kac"
  "/docs/istio-in-action/Istio-ch11-performance"
)

fail() {
  echo "[fail] $1"
  exit 1
}

wait_for_preview_ready() {
  local attempt
  local body_file
  local http_code

  body_file="$(mktemp)"

  for (( attempt = 1; attempt <= READY_RETRIES; attempt++ )); do
    http_code="$(
      curl -sS -o "${body_file}" -w "%{http_code}" "${BASE_URL}/" || true
    )"

    if [[ "${http_code}" == "200" ]] && grep -Eiq 'netpple|김삼영|기술 블로그' "${body_file}"; then
      rm -f "${body_file}"
      echo "[ok] preview ready after ${attempt} attempt(s)"
      return 0
    fi

    if (( attempt < READY_RETRIES )); then
      sleep "${READY_DELAY_SECONDS}"
    fi
  done

  rm -f "${body_file}"
  fail "preview did not become ready at ${BASE_URL}/ after ${READY_RETRIES} attempt(s)"
}

assert_route_layout() {
  local route="$1"
  local html_file
  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  grep -q 'class="skip-link"' "${html_file}" || fail "${route} is missing skip-link"
  grep -q 'data-nav-toggle' "${html_file}" || fail "${route} is missing nav toggle"
  grep -q 'aria-label="Open navigation menu"' "${html_file}" || fail "${route} is missing nav toggle aria-label"
  grep -q 'aria-label="Primary"' "${html_file}" || fail "${route} is missing nav aria-label"
  grep -q 'id="main-content"' "${html_file}" || fail "${route} is missing #main-content"
  grep -q 'class="site-footer"' "${html_file}" || fail "${route} is missing site footer"
  rm -f "${html_file}"
}

assert_nav_not_contains() {
  local route="$1"
  local pattern="$2"
  local description="$3"
  local html_file
  local nav_file

  html_file="$(mktemp)"
  nav_file="$(mktemp)"

  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  awk '
    /<nav class="gnb"/ { in_nav=1 }
    in_nav { print }
    /<\/nav>/ {
      if (in_nav) {
        exit
      }
    }
  ' "${html_file}" > "${nav_file}"

  if grep -Eiq "${pattern}" "${nav_file}"; then
    rm -f "${html_file}" "${nav_file}"
    fail "${route} nav has ${description}"
  fi

  rm -f "${html_file}" "${nav_file}"
  echo "[ok] ${route} nav has no ${description}"
}

assert_footer_contains() {
  local route="$1"
  local pattern="$2"
  local description="$3"
  local html_file
  local footer_file

  html_file="$(mktemp)"
  footer_file="$(mktemp)"

  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  awk '
    /<footer class="site-footer">/ { in_footer=1 }
    in_footer { print }
    /<\/footer>/ {
      if (in_footer) {
        exit
      }
    }
  ' "${html_file}" > "${footer_file}"

  if ! grep -Eiq "${pattern}" "${footer_file}"; then
    rm -f "${html_file}" "${footer_file}"
    fail "${route} footer is missing ${description}"
  fi

  rm -f "${html_file}" "${footer_file}"
  echo "[ok] ${route} footer has ${description}"
}

assert_active_nav() {
  local route="$1"
  local expected="$2"
  local html_file
  local nav_file
  local active_count
  local aria_current_count
  local actual

  html_file="$(mktemp)"
  nav_file="$(mktemp)"

  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  awk '
    /<nav class="gnb"/ { in_nav=1 }
    in_nav { print }
    /<\/nav>/ {
      if (in_nav) {
        exit
      }
    }
  ' "${html_file}" > "${nav_file}"

  if [[ ! -s "${nav_file}" ]]; then
    rm -f "${html_file}" "${nav_file}"
    fail "${route} has no gnb nav block"
  fi

  active_count="$(grep -c 'gnb__link is-active' "${nav_file}" || true)"
  if [[ "${active_count}" != "1" ]]; then
    rm -f "${html_file}" "${nav_file}"
    fail "${route} expected exactly 1 active nav link but got ${active_count}"
  fi

  aria_current_count="$(grep -c 'aria-current="page"' "${nav_file}" || true)"
  if [[ "${aria_current_count}" != "1" ]]; then
    rm -f "${html_file}" "${nav_file}"
    fail "${route} expected exactly 1 aria-current nav link but got ${aria_current_count}"
  fi

  actual="$(
    grep 'gnb__link is-active' "${nav_file}" \
      | head -n 1 \
      | sed -E 's/.*href=\"([^\"]*)\".*/\1/'
  )"

  rm -f "${html_file}" "${nav_file}"

  if [[ "${actual}" != "${expected}" ]]; then
    fail "${route} expected active nav ${expected} but got '${actual}'"
  fi
  echo "[ok] ${route} active nav -> ${actual}"
}

assert_no_active_nav() {
  local route="$1"
  local html_file
  local nav_file
  local active_count
  local aria_current_count

  html_file="$(mktemp)"
  nav_file="$(mktemp)"

  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  awk '
    /<nav class="gnb"/ { in_nav=1 }
    in_nav { print }
    /<\/nav>/ {
      if (in_nav) {
        exit
      }
    }
  ' "${html_file}" > "${nav_file}"

  if [[ ! -s "${nav_file}" ]]; then
    rm -f "${html_file}" "${nav_file}"
    fail "${route} has no gnb nav block"
  fi

  active_count="$(grep -c 'gnb__link is-active' "${nav_file}" || true)"
  aria_current_count="$(grep -c 'aria-current="page"' "${nav_file}" || true)"

  rm -f "${html_file}" "${nav_file}"

  if [[ "${active_count}" != "0" ]]; then
    fail "${route} expected no active nav link but got ${active_count}"
  fi
  if [[ "${aria_current_count}" != "0" ]]; then
    fail "${route} expected no aria-current nav link but got ${aria_current_count}"
  fi
  echo "[ok] ${route} has no active nav link"
}

assert_article_content_heading_hierarchy() {
  local route="$1"
  local html_file
  local section_file
  html_file="$(mktemp)"
  section_file="$(mktemp)"

  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  awk '
    /data-article-content/ { in_block=1; next }
    /<aside class="article-toc"/ { in_block=0 }
    in_block { print }
  ' "${html_file}" > "${section_file}"

  if grep -q '<h1' "${section_file}"; then
    fail "${route} has <h1> inside article content"
  fi
  grep -Eq '<h2|<h3' "${section_file}" || fail "${route} has no h2/h3 heading in article content"

  rm -f "${html_file}" "${section_file}"
  echo "[ok] ${route} article content heading hierarchy"
}

assert_route_reachable() {
  local route="$1"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}${route}")"
  if [[ "${code}" != "200" ]]; then
    fail "${route} returned ${code} in internal navigation check"
  fi
  echo "[ok] ${route} reachable"
}

assert_route_contains() {
  local route="$1"
  local pattern="$2"
  local description="$3"
  local html_file

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  if ! grep -Eiq "${pattern}" "${html_file}"; then
    rm -f "${html_file}"
    fail "${route} missing ${description}"
  fi
  rm -f "${html_file}"
  echo "[ok] ${route} ${description}"
}

assert_route_not_contains() {
  local route="$1"
  local pattern="$2"
  local description="$3"
  local html_file

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  if grep -Eiq "${pattern}" "${html_file}"; then
    rm -f "${html_file}"
    fail "${route} has ${description}"
  fi
  rm -f "${html_file}"
  echo "[ok] ${route} no ${description}"
}

assert_route_not_contains_case_sensitive() {
  local route="$1"
  local pattern="$2"
  local description="$3"
  local html_file

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  if grep -Eq "${pattern}" "${html_file}"; then
    rm -f "${html_file}"
    fail "${route} has ${description}"
  fi
  rm -f "${html_file}"
  echo "[ok] ${route} no ${description}"
}

assert_route_pattern_count() {
  local route="$1"
  local pattern="$2"
  local expected="$3"
  local description="$4"
  local html_file
  local actual

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  actual="$(
    (grep -Eo "${pattern}" "${html_file}" || true) | wc -l | tr -d ' '
  )"
  rm -f "${html_file}"

  if [[ "${actual}" != "${expected}" ]]; then
    fail "${route} expected ${expected} ${description} but got ${actual}"
  fi

  echo "[ok] ${route} ${description} -> ${actual}"
}

assert_route_pattern_min_count() {
  local route="$1"
  local pattern="$2"
  local minimum="$3"
  local description="$4"
  local html_file
  local actual

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}${route}" > "${html_file}"
  actual="$(
    (grep -Eo "${pattern}" "${html_file}" || true) | wc -l | tr -d ' '
  )"
  rm -f "${html_file}"

  if [[ "${actual}" -lt "${minimum}" ]]; then
    fail "${route} expected at least ${minimum} ${description} but got ${actual}"
  fi

  echo "[ok] ${route} ${description} -> ${actual}"
}

assert_home_series_count_matches_docs() {
  local html_file
  local expected
  local actual

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}/" > "${html_file}"

  expected="$(
    find _docs -mindepth 2 -maxdepth 2 -type f -name '*.md' -print \
      | sed -E 's#^_docs/([^/]+)/.*#\1#' \
      | sort -u \
      | wc -l \
      | tr -d ' '
  )"

  actual="$(
    awk '
      /<p class="home-stats__label">Series<\/p>/ { capture=1; next }
      capture && /<p class="home-stats__value">/ {
        line = $0
        sub(/^.*<p class="home-stats__value">/, "", line)
        sub(/<\/p>.*$/, "", line)
        print line
        exit
      }
    ' "${html_file}"
  )"

  rm -f "${html_file}"

  if [[ -z "${actual}" ]]; then
    fail "/ missing rendered Series home stat value"
  fi

  if [[ "${actual}" != "${expected}" ]]; then
    fail "/ expected Series home stat ${expected} from docs groups but got ${actual}"
  fi

  echo "[ok] / Series home stat value -> ${actual}"
}

assert_home_feature_cards() {
  local html_file
  local card_count
  local post_count
  local series_count
  local summary_count
  local cta_count

  html_file="$(mktemp)"
  curl -fsSL "${BASE_URL}/" > "${html_file}"

  card_count="$(
    (grep -o 'class="home-feature-card"' "${html_file}" || true) | wc -l | tr -d ' '
  )"
  post_count="$(
    (grep -o '추천 포스트' "${html_file}" || true) | wc -l | tr -d ' '
  )"
  series_count="$(
    (grep -o '추천 시리즈' "${html_file}" || true) | wc -l | tr -d ' '
  )"
  summary_count="$(
    (grep -o 'class="home-feature-card__summary"' "${html_file}" || true) | wc -l | tr -d ' '
  )"
  cta_count="$(
    (grep -Eo '>(포스트 보기|시리즈 보기) →<' "${html_file}" || true) | wc -l | tr -d ' '
  )"

  rm -f "${html_file}"

  [[ "${card_count}" == "2" ]] || fail "/ expected 2 home feature cards but got ${card_count}"
  [[ "${post_count}" == "1" ]] || fail "/ expected 1 recommended post card but got ${post_count}"
  [[ "${series_count}" == "1" ]] || fail "/ expected 1 recommended series card but got ${series_count}"
  [[ "${summary_count}" == "2" ]] || fail "/ expected 2 feature-card summary lines but got ${summary_count}"
  [[ "${cta_count}" == "2" ]] || fail "/ expected 2 feature-card CTA labels but got ${cta_count}"

  echo "[ok] / home feature cards -> cards=${card_count}, posts=${post_count}, series=${series_count}"
}

assert_home_stats() {
  local html_file
  local stats_file
  local stats_count

  html_file="$(mktemp)"
  stats_file="$(mktemp)"
  curl -fsSL "${BASE_URL}/" > "${html_file}"

  stats_count="$(
    (grep -o 'class="home-stats__item"' "${html_file}" || true) | wc -l | tr -d ' '
  )"

  if [[ "${stats_count}" != "2" ]]; then
    rm -f "${html_file}" "${stats_file}"
    fail "/ expected 2 home stats but got ${stats_count}"
  fi

  awk '
    /<div class="home-stats">/ { in_stats=1 }
    in_stats { print }
    /<\/div>/ {
      if (in_stats) {
        depth += gsub(/<div/, "&")
        depth -= gsub(/<\/div>/, "&")
        if (depth <= 0) {
          exit
        }
      }
    }
  ' "${html_file}" > "${stats_file}"

  if grep -Eiq '방문자|visitor|visitors|analytics' "${stats_file}"; then
    rm -f "${html_file}" "${stats_file}"
    fail "/ unexpectedly exposes visitor or analytics copy in home stats"
  fi

  rm -f "${html_file}" "${stats_file}"
  echo "[ok] / home stats -> ${stats_count} items without visitor metric"
}

echo "[smoke] base url: ${BASE_URL}"

echo "[smoke] waiting for preview readiness"
wait_for_preview_ready

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

echo "[smoke] checking search route variants"
for route in "${search_query_routes[@]}"; do
  code="$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${route}")"
  if [[ "${code}" != "200" ]]; then
    echo "[fail] ${route} returned ${code}"
    exit 1
  fi
  echo "[ok] ${route} -> ${code}"
done

echo "[smoke] checking common layout markers"
for route in "${routes[@]}"; do
  assert_route_layout "${route}"
done

echo "[smoke] checking key page redesign markers"
assert_route_contains "/" 'home-hero|home-stats|home-featured-panel|home-announcement' "home redesign markers"
assert_home_stats
assert_home_feature_cards
assert_route_not_contains "/" 'home-series-grid|<h2 class="section-heading__title">주요 시리즈</h2>' "legacy home featured series section"
assert_route_contains "/" 'href="/2023/k8s-1.26-install/"' "home featured install post link"
assert_route_contains "/" 'href="/docs/istio-in-action/"' "home featured Istio series link"
assert_route_contains "/announcements/" 'Announcement|현재 노출 중인 공지|entry-card--news' "announcements markers"
assert_route_contains "/news/" 'entry-card--list' "posts list card markers"
assert_route_contains "/docs/" 'series-grid|entry-card--list' "series hub markers"
assert_route_contains "/docs/" 'Series Navigation' "series navigation heading"
assert_route_contains "/docs/" 'Series Explorer' "series explorer heading"
assert_route_contains "/docs/" 'Recently Updated' "series recent updates heading"
assert_route_contains "/docs/" 'Series Index' "series index heading"
assert_route_contains "/docs/" 'href="/search/"' "series hub search shortcut"
assert_route_contains "/docs/" 'data-series-explorer-filter|id="series-entry-filter"' "series explorer filter control"
assert_route_contains "/docs/" 'data-series-explorer-sort|id="series-entry-sort"' "series explorer sort control"
assert_route_pattern_count "/docs/" 'data-series-explorer-preset=' "6" "series explorer preset chips"
assert_route_pattern_count "/docs/" 'data-series-explorer-preset-aliases=' "2" "series explorer preset alias mappings"
assert_route_pattern_count "/docs/" 'class="chip" href="#series-[^"]+"' "5" "series quick-jump chips"
assert_route_pattern_count "/docs/" 'id="series-(istio|container|kubernetes|data|querypie)"' "5" "series index sections"
assert_route_pattern_count "/docs/" 'class="entry-card entry-card--list"' "8" "recent series entry cards"
assert_route_pattern_min_count "/docs/" 'data-series-explorer-item' "20" "series explorer items"
assert_route_not_contains_case_sensitive "/docs/" '>\s*istio in action\s*<' "legacy raw Istio series label on docs hub"
assert_route_not_contains "/docs/" '>\s*데이터중심 애플리케이션\s*<' "legacy raw data series label on docs hub"
assert_route_contains "/about/" 'about-intro|about-evidence-grid' "about redesign markers"
assert_route_contains "/about/" 'QueryPie CTO' "about current role marker"
assert_route_contains "/about/" 'if\(kakao\)dev2022' "about talk credibility marker"
assert_route_contains "/about/" 'linkedin\.com/in/sam0-kim|github\.com/netpple' "about external profile links"
assert_route_not_contains "/about/" '기술스택|기술 스택' "legacy tech-stack section labels"
assert_route_not_contains "/about/" '관심영역|관심 영역' "legacy interest section labels"
assert_route_not_contains "/about/" '>\s*학력\s*<' "legacy education section label"
assert_route_contains "/search/" 'search-panel|id=\"search-input\"' "search ui markers"
assert_route_not_contains "/tags/" 'class="tag-nav__link" href="#"' "empty tag navigation links"

echo "[smoke] checking IA terminology markers"
assert_route_contains "/" '>\s*Posts\s*<' "Posts IA label"
assert_route_contains "/" '>\s*Series\s*<' "Series IA label"
assert_route_contains "/" 'home-stats__label\">Series<' "Series home stat label"
assert_route_contains "/" 'home-stats__meta\">대표 학습 경로로 정리한 시리즈<' "Series home stat helper copy"
assert_home_series_count_matches_docs
assert_route_not_contains "/" '>\s*News\s*<' "legacy News IA label"
assert_route_not_contains "/" '>\s*Docs\s*<' "legacy Docs IA label"
assert_nav_not_contains "/" '>\s*GitHub\s*<' "top-nav GitHub link"
assert_footer_contains "/" '>\s*GitHub\s*<' "footer GitHub link"
assert_route_contains "/news/" 'page-intro__title\">Posts<|<h1[^>]*>Posts</h1>' "Posts page title"
assert_route_contains "/docs/" 'page-intro__title\">Series<|<h1[^>]*>Series</h1>' "Series page title"
assert_route_contains "/docs/" '>\s*[0-9]+\s+Series entr(y|ies)\s*<' "Series entry count copy"
assert_route_not_contains "/docs/" '>\s*[0-9]+\s+entries\s*<' "legacy bare entry count copy"
assert_route_contains "/news/" 'property="og:type" content="website"' "Posts list og:type"
assert_route_not_contains "/news/" 'property="og:type" content="article"' "Posts list not using article og:type"
assert_route_contains "/docs/" 'property="og:type" content="website"' "Series hub og:type"
assert_route_not_contains "/docs/" 'property="og:type" content="article"' "Series hub not using article og:type"
assert_route_contains "/search/" 'Istio IN ACTION 11장' "search index uses friendly Istio series landing descriptions"
assert_route_not_contains_case_sensitive "/search/" 'istio in action 11장' "search index has no raw Istio series landing descriptions"
assert_route_contains "/search/" '데이터 중심 애플리케이션 설계' "search index uses friendly data series label"
assert_route_not_contains "/search/" '데이터중심 애플리케이션' "search index has no raw data series label"
assert_route_not_contains "/search/" '"url":\s*"/docs/[^"]*/index"' "search index uses canonical series urls"
assert_route_not_contains "/search/" '"id":\s*""' "search index empty document ids"
assert_route_not_contains "/search/" '"url":\s*"/assets/' "search index excludes asset pages"
assert_route_not_contains "/search/" '"url":\s*"/[^"]+\.xml"' "search index excludes xml documents"
assert_route_not_contains "/tags/" 'href="/docs/[^"]+/index"' "tag page uses canonical series links"
assert_route_contains "${sample_post}" 'article-header__eyebrow\">Post<' "Post detail eyebrow"
assert_route_contains "${sample_post}" 'property="og:type" content="article"' "Post detail og:type"
assert_route_not_contains "${sample_post}" 'property="og:type" content="website"' "Post detail not using website og:type"
assert_route_contains "${sample_series}" 'article-header__eyebrow\">Series<' "Series landing eyebrow"
assert_route_not_contains "${sample_series}" 'article-header__eyebrow\">Series entry<' "Series landing not mislabeled as Series entry"
assert_route_contains "${sample_series}" 'property="og:type" content="website"' "Series landing og:type"
assert_route_not_contains "${sample_series}" 'property="og:type" content="article"' "Series landing not using article og:type"
assert_route_not_contains "${sample_series}" 'rel="canonical" href="[^"]*/index"' "Series landing canonical without /index"
assert_route_not_contains "${sample_series}" 'property="og:url" content="[^"]*/index"' "Series landing og:url without /index"
assert_route_contains "${sample_series}" '<b>Istio IN ACTION 11장</b>' "Series landing entry descriptions use friendly Istio label"
assert_route_not_contains_case_sensitive "${sample_series}" '<b>istio in action' "Series landing entry descriptions no raw Istio label"
assert_route_contains "${sample_series_entry}" 'article-header__eyebrow\">Series entry<' "Series entry detail eyebrow"
assert_route_contains "${sample_series_entry}" 'property="og:type" content="article"' "Series entry detail og:type"
assert_route_not_contains "${sample_series_entry}" 'property="og:type" content="website"' "Series entry detail not using website og:type"
assert_route_contains "${sample_series_entry}" 'article-header__description\">Istio IN ACTION 11장<' "Series entry description uses friendly Istio label"
assert_route_not_contains_case_sensitive "${sample_series_entry}" 'article-header__description\">istio in action' "Series entry description no raw Istio label"
assert_route_contains "${sample_series_entry}" 'article-series__title\">Istio IN ACTION · Series<' "Series entry related series title uses friendly Istio label"
assert_route_not_contains_case_sensitive "${sample_series_entry}" 'article-series__title\">istio in action' "Series entry related series title no raw Istio label"
assert_route_contains "${sample_data_series_entry}" 'article-series__title\">데이터 중심 애플리케이션 설계 · Series<' "Data series entry related series title uses friendly label"
assert_route_not_contains "${sample_data_series_entry}" 'article-series__title\">데이터중심 애플리케이션' "Data series entry related series title no raw label"

echo "[smoke] checking source terminology guards"
grep -Eq '^- title: Series$' _data/toc.yml || fail "_data/toc.yml is missing the Series root label"
if grep -Eq '^- title: Documentation$' _data/toc.yml; then
  fail "_data/toc.yml still contains the legacy Documentation root label"
fi

echo "[smoke] checking home-only stylesheet loading"
home_html_file="$(mktemp)"
news_html_file="$(mktemp)"
curl -fsSL "${BASE_URL}/" > "${home_html_file}"
curl -fsSL "${BASE_URL}/news/" > "${news_html_file}"
grep -q 'assets/css/home.css' "${home_html_file}" || fail "/ is missing home.css"
if grep -q 'assets/css/home.css' "${news_html_file}"; then
  rm -f "${home_html_file}" "${news_html_file}"
  fail "/news/ unexpectedly includes home.css"
fi
rm -f "${home_html_file}" "${news_html_file}"

echo "[smoke] checking detail template markers"
curl -fsSL "${BASE_URL}${sample_post}" | grep -Eiq "article-shell|data-article-toc|data-article-content"
curl -fsSL "${BASE_URL}${sample_series}" | grep -Eiq "article-shell|data-article-toc|Series Hub"
curl -fsSL "${BASE_URL}${sample_series_entry}" | grep -Eiq "article-shell|data-article-toc|data-article-content"
curl -fsSL "${BASE_URL}${sample_series_entry_hands_on}" | grep -Eiq "article-shell|data-article-toc|data-article-content"
assert_route_contains "${sample_series}" 'Series Hub' "series detail hub backlink"
assert_route_contains "${sample_series_entry}" 'Series Hub' "series detail hub backlink"
assert_route_contains "${sample_series_entry_hands_on}" 'Series Hub' "series detail hub backlink"
assert_route_not_contains "${sample_series}" 'All Posts' "post-only backlink in series detail"
assert_route_not_contains "${sample_series_entry}" 'All Posts' "post-only backlink in series detail"
assert_route_not_contains "${sample_series_entry_hands_on}" 'All Posts' "post-only backlink in series detail"
assert_route_layout "${sample_post}"
assert_route_layout "${sample_series}"
assert_route_layout "${sample_series_entry}"
assert_route_layout "${sample_series_entry_hands_on}"
assert_article_content_heading_hierarchy "${sample_post}"
assert_article_content_heading_hierarchy "${sample_series}"
assert_article_content_heading_hierarchy "${sample_series_entry}"
assert_article_content_heading_hierarchy "${sample_series_entry_hands_on}"

echo "[smoke] checking key internal navigation links"
for route in "${key_nav_paths[@]}"; do
  assert_route_reachable "${route}"
done

echo "[smoke] checking active nav mapping"
assert_active_nav "/" "/"
assert_active_nav "/news/" "/news/"
assert_active_nav "/docs/" "/docs/"
assert_active_nav "/about/" "/about/"
assert_active_nav "/archive/" "/news/"
assert_no_active_nav "/tags/"
assert_no_active_nav "/search/"
assert_no_active_nav "/search/?q=kubernetes"
assert_active_nav "${sample_post}" "/news/"
assert_active_nav "${sample_series}" "/docs/"
assert_active_nav "${sample_series_entry}" "/docs/"
assert_active_nav "${sample_series_entry_hands_on}" "/docs/"

echo "[pass] preview smoke checks completed"
