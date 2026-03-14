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

search_query_routes=(
  "/search/?q=kubernetes"
  "/search/?q=%28"
  "/search/?q="
)

sample_post="/2023/c-for-beginner-hongongc/"
sample_series="/docs/istio-in-action"
sample_series_entry="/docs/istio-in-action/Istio-ch11-performance"
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
assert_route_contains "/" 'home-hero|home-stats|home-series-grid' "home redesign markers"
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
assert_route_contains "/about/" 'section-heading__kicker\">Interests|chip-row' "about redesign markers"
assert_route_contains "/search/" 'search-panel|id=\"search-input\"' "search ui markers"
assert_route_not_contains "/tags/" 'class="tag-nav__link" href="#"' "empty tag navigation links"

echo "[smoke] checking IA terminology markers"
assert_route_contains "/" '>\s*Posts\s*<' "Posts IA label"
assert_route_contains "/" '>\s*Series\s*<' "Series IA label"
assert_route_contains "/" 'home-stats__label\">Series entries<' "Series entry home stat label"
assert_route_not_contains "/" 'home-stats__label\">Series<' "ambiguous Series home stat label"
assert_route_not_contains "/" '>\s*News\s*<' "legacy News IA label"
assert_route_not_contains "/" '>\s*Docs\s*<' "legacy Docs IA label"
assert_nav_not_contains "/" '>\s*GitHub\s*<' "top-nav GitHub link"
assert_footer_contains "/" '>\s*GitHub\s*<' "footer GitHub link"
assert_route_contains "/news/" 'page-intro__title\">Posts<|<h1[^>]*>Posts</h1>' "Posts page title"
assert_route_contains "/docs/" 'page-intro__title\">Series<|<h1[^>]*>Series</h1>' "Series page title"
assert_route_contains "/news/" 'property="og:type" content="website"' "Posts list og:type"
assert_route_not_contains "/news/" 'property="og:type" content="article"' "Posts list not using article og:type"
assert_route_contains "/docs/" 'property="og:type" content="website"' "Series hub og:type"
assert_route_not_contains "/docs/" 'property="og:type" content="article"' "Series hub not using article og:type"
assert_route_not_contains "/search/" '"url":\s*"/docs/[^"]*/index"' "search index uses canonical series urls"
assert_route_not_contains "/search/" '"id":\s*""' "search index empty document ids"
assert_route_contains "${sample_post}" 'article-header__eyebrow\">Post<' "Post detail eyebrow"
assert_route_contains "${sample_post}" 'property="og:type" content="article"' "Post detail og:type"
assert_route_not_contains "${sample_post}" 'property="og:type" content="website"' "Post detail not using website og:type"
assert_route_contains "${sample_series}" 'article-header__eyebrow\">Series<' "Series landing eyebrow"
assert_route_not_contains "${sample_series}" 'article-header__eyebrow\">Series entry<' "Series landing not mislabeled as Series entry"
assert_route_contains "${sample_series}" 'property="og:type" content="website"' "Series landing og:type"
assert_route_not_contains "${sample_series}" 'property="og:type" content="article"' "Series landing not using article og:type"
assert_route_not_contains "${sample_series}" 'rel="canonical" href="[^"]*/index"' "Series landing canonical without /index"
assert_route_not_contains "${sample_series}" 'property="og:url" content="[^"]*/index"' "Series landing og:url without /index"
assert_route_contains "${sample_series_entry}" 'article-header__eyebrow\">Series entry<' "Series entry detail eyebrow"
assert_route_contains "${sample_series_entry}" 'property="og:type" content="article"' "Series entry detail og:type"
assert_route_not_contains "${sample_series_entry}" 'property="og:type" content="website"' "Series entry detail not using website og:type"

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
