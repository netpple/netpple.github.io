# Docsy Jekyll Theme

[![CircleCI](https://circleci.com/gh/vsoch/docsy-jekyll/tree/master.svg?style=svg)](https://circleci.com/gh/vsoch/docsy-jekyll/tree/master)
<a href="https://jekyll-themes.com/docsy-jekyll/">
    <img src="https://img.shields.io/badge/featured%20on-JT-red.svg" height="20" alt="Jekyll Themes Shield" >
</a>

![https://raw.githubusercontent.com/vsoch/docsy-jekyll/master/assets/img/docsy-jekyll.png](https://raw.githubusercontent.com/vsoch/docsy-jekyll/master/assets/img/docsy-jekyll.png)

This is a [starter template](https://vsoch.github.com/docsy-jekyll/) for a Docsy jekyll theme, based
on the Beautiful [Docsy](https://github.com/google/docsy) that renders with Hugo. This version is intended for
native deployment on GitHub pages. The original [Apache License](https://github.com/vsoch/docsy-jekyll/blob/master/LICENSE) is included.

## Changes

The site is organized around long-form Series, so while the front page banner
is useful for business or similar, this author (@vsoch) preferred to have
the main site page go directly to the Series view. Posts
are still provided via a feed.

## Usage

### 1. Get the code

You can clone the repository right to where you want to host the site:

```bash
git clone https://github.com/vsoch/docsy-jekyll.git docs
cd docs
```

### 2. Customize

To edit configuration values, customize the [_config.yml](https://github.com/vsoch/docsy-jekyll/blob/master/_config.yml).
To add pages, write them into the [pages](https://github.com/vsoch/docsy-jekyll/blob/master/pages) folder. 
You define urls based on the `permalink` attribute in your pages,
and then add them to the navigation by adding to the content of [_data/toc.myl](https://github.com/vsoch/docsy-jekyll/blob/master/_data/toc.yml).
The top navigation is controlled by [_data/navigation.yml](https://github.com/vsoch/docsy-jekyll/blob/master/_data/navigation.yml)

### 3. Options

Most of the configuration values in the [_config.yml](https://github.com/vsoch/docsy-jekyll/blob/master/_config.yml) are self explanatory,
and for more details, see the [getting started page](https://vsoch.github.io/docsy-jekyll/docs/getting-started)
rendered on the site.

### 4. Serve

Depending on how you installed jekyll:

```bash
jekyll serve
# or
bundle exec jekyll serve
```

### 5. Run as a container in dev or prod

#### Software Dependencies

If you want to run docsy jekyll via a container for development (dev) or production (prod) you can use containers. This approach requires installing [docker-ce](https://docs.docker.com/engine/install/ubuntu/) and [docker-compose](https://docs.docker.com/compose/install/). 

#### Customization

Note that the [docker-compose.yml](docker-compose.yml) file is using the [jekyll/jekyll:3.8](https://hub.docker.com/r/jekyll/jekyll/tags) image. If you want to make your build more reproducible, you can specify a particular version for jekyll (tag). Note that at the development time of writing this guide, the latest was tag 4.0.0,
and it [had a bug](https://github.com/fastai/fastpages/issues/267#issuecomment-620612896) that prevented the server from deploying.

If you are deploying a container to production, you should remove the line to
mount the bundles directory to the host in the docker-compose.yml. Change:

```yaml
    volumes: 
      - "./:/srv/jekyll"
      - "./vendor/bundle:/usr/local/bundle"
      # remove "./vendor/bundle:/usr/local/bundle" volume when deploying in production
```

to:

```yaml
    volumes: 
      - "./:/srv/jekyll"
```

This additional volume is optimal for development so you can cache the bundle dependencies,
but should be removed for production. 

#### Start Container

Once your docker-compose to download the base container and bring up the server:

```bash
docker-compose up -d
```

You can then open your browser to [http://localhost:4000](http://localhost:4000)
to see the server running.

> Node : changes `baseurl: ""` in _config.yml  when you are running in local and prod according to the requirement.

## Local Preview Smoke Check

For local validation of this project revision, run the preview server and smoke checks below:

```bash
# 1) Start/reuse preview server
# (uses ./vendor/bundle cache mount inside Docker)
make preview-up

# 2) Build + smoke checks
make preview-verify

# 2-1) Optional comprehensive full-site verify
# (includes preview-verify + overflow-full + runtime-full)
make preview-verify-full

# 3) Or run smoke checks only
make preview-smoke

# 3-1) Or run responsive viewport screenshot checks only
make preview-responsive

# 3-2) Or run responsive overflow checks only (horizontal overflow fails)
make preview-overflow

# Optional full-site mode (all generated HTML routes in _site)
make preview-overflow-full
# Optional timeout/retry tuning for slower environments:
# OVERFLOW_TIMEOUT_MS=90000 OVERFLOW_RETRIES=4 make preview-overflow-full

# 3-2-1) Or run nav consistency checks only (desktop-min(961)/desktop/tablet/mobile-break(960)/tablet-min(761)/mobile-max/mobile)
make preview-nav

# 3-2-2) Or run accessibility smoke checks only (skip-link keyboard flow)
make preview-a11y

# 3-3) Or run internal link checks only (strict: redirects fail)
make preview-linkcheck
# optional relaxed mode:
ALLOW_REDIRECTS=true make preview-linkcheck

# 3-4) Or run structure consistency checks only
make preview-structure

# 3-5) Or run style scope checks only
make preview-style-scope

# 3-6) Or run inline-style checks only (core templates/pages)
make preview-inline-style

# 3-7) Or run HTML id uniqueness checks only
make preview-ids

# 3-8) Or run metadata consistency checks only
make preview-meta

# 3-9) Or run source terminology checks only
make preview-terms

# 3-10) Or run source format checks only
make preview-format

# 3-11) Or run article heading hierarchy checks only
make preview-headings

# 3-12) Or run Series hub static structure checks only
make preview-series-hub

# 3-13) Or run resource loading checks only
make preview-resources

# 3-14) Or run sitemap consistency checks only
make preview-sitemap

# 3-15) Or run runtime console/pageerror/requestfailed checks only
make preview-runtime

# Optional full-site runtime mode (all generated HTML routes in _site)
make preview-runtime-full
# Optional timeout/retry tuning for slower environments:
# RUNTIME_TIMEOUT_MS=90000 RUNTIME_RETRIES=4 make preview-runtime-full

# optional: print manual visual checkpoints
make preview-info

# 4) Stop preview server after validation
make preview-down
```

Smoke checks cover:
- Homepage content marker
- Core routes HTTP 200 status
- Search route variants (`/search/?q=kubernetes`, `/search/?q=%28`, empty query)
- Key page redesign markers (Home/Posts/Series/About/Search)
- Tags page empty tag navigation guard (no `href="#"` in `.tag-nav__link`)
- Responsive viewport rendering smoke check (`desktop-min(961)/desktop/tablet/tablet-min(761)/mobile-break(960)/mobile-max(760)/mobile` screenshots across core + navigation routes incl. search results + series entry detail routes)
- Responsive layout overflow check (`desktop-min(961)/desktop/tablet/tablet-min(761)/mobile-break(960)/mobile-max(760)/mobile`, core routes + series entry detail routes with horizontal overflow fail; optional `_site` full-route mode)
- Runtime nav consistency check (`desktop-min(961)/desktop/tablet/mobile-break(960)/tablet-min(761)/mobile-max(760)/mobile`, GNB height/alignment/hover/active + route-specific active target mapping + toggle visibility/aria-label transitions, keyboard toggle Enter/Space, resize transition, toggle/Escape/outside-click close behavior, and page-wide `target="_blank"` rel safety)
- Runtime console stability check (core routes console.error/pageerror/requestfailed 없는지 점검, GA/GTM 외부 차단 노이즈 제외)
- Optional full-site runtime console stability check (`_site` 전체 라우트 대상)
- Accessibility smoke check (`desktop`, skip-link first-focus visibility + Enter activation hash 이동 + `#main-content` 포커스 전달)
- Home-only stylesheet loading (`home.css` on `/`, absent on non-home routes)
- Post/Series entry detail template markers
- Navigation active mapping (`/archive/` -> `Posts`)
- Key internal navigation route reachability (Home/Posts/Series 대표 링크)
- Site-wide internal link check from generated `_site` (`href/src`, redirects disallowed by default)
- Site-wide structure consistency check (`skip-link`, nav toggle/nav ARIA markers, header/main/footer, `#main-content` tabindex, no `autofocus`, single h1, single active nav + `aria-current`, header/footer external blank-target rel safety, home.css scope per HTML page)
- Source-level style scope check (home-only `home-*` class usage restricted to `pages/index.md`)
- Source-level core template/page inline-style check (except GTM noscript iframe)
- Site-wide HTML `id` uniqueness check (duplicate IDs fail)
- Site-wide metadata consistency check (`title`, description, canonical, og:url/og:title, twitter:title)
- Source terminology check for maintained IA files (legacy IA label regression guard)
- Source format check for date token regressions (`%H:%m` guard)
- Site-wide article heading hierarchy check (`_site` article content has no embedded `h1` and no heading-level jumps deeper than one level)
- Series hub static consistency check (`_site/docs/index.html` headings, Search shortcut, quick-jump/section count, recent cards, chip-target/section-id match)
- Site-wide resource loading check (Google Fonts preconnect/preload + print-onload stylesheet + noscript fallback, and all local `/assets/js/*.js` scripts stay deferred/async)
- Sitemap consistency check (`sitemap.xml` uses absolute URLs, includes `/`, `/docs/`, `/news/`, and avoids malformed relative or double-slash loc values)
