# Netpple Engineering Archive

`netpple.github.io` is a Jekyll-based engineering archive focused on cloud
native infrastructure, distributed systems, platform engineering, and
operations.

The current site is organized around two primary content surfaces:

- `Posts` for dated operational notes and technical write-ups
- `Series` for long-form learning paths and grouped reference material

Primary routes:

- `/` Home
- `/news/` Posts
- `/docs/` Series Hub
- `/about/` About
- `/search/` Search
- `/tags/` Tags

## What This Repo Contains

This repository is no longer a generic `docsy-jekyll` starter. It has been
reworked into a custom site with:

- a compact Home first screen with 2 key stats and 2 representative entry
  points
- a `Posts / Series` IA replacing the older `News / Docs` wording
- a `Series Hub` at `/docs/` with quick jumps, filter/sort, and recent update
  sections
- a streamlined About page focused on career history, talks, and public writing
- footer-level site metadata including a visits badge

## Repository Layout

- `_posts/`: dated post content
- `_docs/`: series landing pages and series entries
- `pages/`: route-level pages such as Home, Posts, Series, About, Search, Tags
- `_data/navigation.yml`: top-level navigation labels and routes
- `_data/toc.yml`: docs/sidebar structure
- `_includes/`, `_layouts/`: shared templates and page shells
- `assets/css/`: site styles, including `home.css` for the homepage only
- `assets/js/`: client-side behavior such as search and Series Explorer
- `scripts/`: preview and regression checks
- `Makefile`: Docker-based preview and validation entry points

## Content Conventions

- Use `Posts` and `Series` consistently in UI copy, metadata, and navigation.
- Treat `/news/` as the Posts landing page.
- Treat `/docs/` as the Series Hub, not a generic docs list.
- Keep series landing pages and series entries distinct in copy and metadata.
- Keep About centered on profile credibility:
  career history, role context, talks, and external profile links.
- Avoid regressing internal canonical links to `/index` or `/index.html`
  variants.

## Local Preview

The preferred local workflow uses Docker and the provided `Makefile`.

```bash
# start or reuse the preview container
make preview-up

# rebuild generated output inside the running container
make preview-build

# recreate the preview container from scratch
make preview-recreate

# stop preview
make preview-down
```

Default preview URL:

```text
http://127.0.0.1:4012
```

You can override the container name or port when needed:

```bash
PREVIEW_NAME=netpple-preview PREVIEW_PORT=4012 make preview-recreate
```

## Validation

Run the standard integrated check set:

```bash
make preview-verify
```

Run the broader verification set:

```bash
make preview-verify-full
```

Useful focused targets:

```bash
make preview-smoke
make preview-responsive
make preview-home-fold
make preview-overflow
make preview-nav
make preview-runtime
make preview-a11y
make preview-linkcheck
make preview-canonical-links
make preview-structure
make preview-style-scope
make preview-inline-style
make preview-ids
make preview-meta
make preview-terms
make preview-format
make preview-headings
make preview-series-hub
make preview-series-explorer
make preview-resources
make preview-sitemap
make preview-info
```

The current checks cover:

- route availability for core pages and search variants
- Home first-screen layout and recommendation structure
- responsive rendering and overflow regression checks
- nav behavior and active-state consistency
- runtime console stability
- accessibility smoke checks
- internal link and canonical-link regressions
- metadata, heading hierarchy, ID uniqueness, terminology, and sitemap checks
- Series Hub and Series Explorer behavior

## Updating Content

Typical content updates happen in one of these places:

- add a new post: `_posts/`
- add or edit a series entry: `_docs/<series-slug>/`
- adjust landing copy or structure: `pages/`
- adjust global IA or navigation: `_data/navigation.yml`, `_data/toc.yml`
- adjust visual layout or responsive behavior: `assets/css/`, `assets/js/`

When changing Home, Series Hub, or About, run at least:

```bash
make preview-build
make preview-smoke
```

For IA or metadata changes, also run:

```bash
make preview-canonical-links
make preview-meta
make preview-terms
```

## Announcement Content Flow

Homepage updates are managed through the `_announcements` collection.

- Required front matter: `title`, `summary`, `date`, `cta_label`, `cta_url`, `pinned`, `published`
- Optional front matter: `description`, `expires_at`, `excluded_in_search`
- Site timezone: dates are rendered in `Asia/Seoul`, so `date` and `expires_at` values should be authored in Korea time
- Home rendering rules: show one active pinned announcement first, then up to two newer active items as secondary links
- Visibility rules: items with `published: false` or an `expires_at` earlier than the build time are hidden from Home, archive, and search
- Archive path: `/announcements/`
- Detail path: each announcement is published at `/announcements/<slug>/` and shows its own date, pinned badge, and archive backlink automatically
- Validation path: `scripts/announcement_content_check.sh _announcements` verifies required fields, boolean flags, date parsing, and CTA URL shape before preview/release checks

## Deployment Notes

GitHub Pages publishes from the repository's `master` branch.

Live site:

```text
https://netpple.github.io/
```
