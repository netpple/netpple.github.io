PREVIEW_NAME ?= netpple-preview-sam11
PREVIEW_PORT ?= 4012
PREVIEW_URL ?= http://127.0.0.1:$(PREVIEW_PORT)
PREVIEW_IMAGE ?= jekyll/jekyll:4.2.0

.PHONY: preview-up preview-build preview-smoke preview-responsive preview-overflow preview-overflow-full preview-nav preview-runtime preview-runtime-full preview-a11y preview-linkcheck preview-structure preview-style-scope preview-inline-style preview-ids preview-meta preview-terms preview-format preview-headings preview-series-hub preview-resources preview-verify preview-verify-full preview-down preview-recreate preview-info

preview-up:
	@if docker ps --format '{{.Names}}' | grep -qx '$(PREVIEW_NAME)'; then \
		echo "$(PREVIEW_NAME) is already running"; \
	elif docker ps -a --format '{{.Names}}' | grep -qx '$(PREVIEW_NAME)'; then \
		echo "starting existing $(PREVIEW_NAME) container"; \
		docker start $(PREVIEW_NAME) >/dev/null; \
	else \
		mkdir -p "$$PWD/vendor/bundle"; \
		docker run -d --name $(PREVIEW_NAME) -p $(PREVIEW_PORT):4000 -v "$$PWD":/srv/jekyll -v "$$PWD/vendor/bundle":/usr/local/bundle $(PREVIEW_IMAGE) sh -lc 'bundle install && bundle exec jekyll serve --host 0.0.0.0 --port 4000 --watch' >/dev/null; \
		echo "started $(PREVIEW_NAME) on $(PREVIEW_URL)"; \
	fi

preview-build:
	docker exec $(PREVIEW_NAME) sh -lc 'bundle exec jekyll build'

preview-smoke:
	scripts/preview_smoke_check.sh $(PREVIEW_URL)

preview-responsive:
	scripts/responsive_smoke_check.sh $(PREVIEW_URL)

preview-overflow:
	scripts/responsive_overflow_check.sh $(PREVIEW_URL)

preview-overflow-full:
	FULL_SITE_OVERFLOW=true scripts/responsive_overflow_check.sh $(PREVIEW_URL)

preview-nav:
	scripts/nav_consistency_check.sh $(PREVIEW_URL)

preview-runtime:
	scripts/runtime_console_check.sh $(PREVIEW_URL)

preview-runtime-full:
	FULL_SITE_RUNTIME=true scripts/runtime_console_check.sh $(PREVIEW_URL)

preview-a11y:
	scripts/accessibility_smoke_check.sh $(PREVIEW_URL)

preview-linkcheck:
	scripts/internal_link_check.sh $(PREVIEW_URL)

preview-structure:
	scripts/layout_consistency_check.sh _site

preview-style-scope:
	bash scripts/style_scope_check.sh

preview-inline-style:
	bash scripts/template_inline_style_check.sh

preview-ids:
	scripts/html_id_uniqueness_check.sh _site

preview-meta:
	scripts/metadata_consistency_check.sh _site

preview-terms:
	scripts/source_terminology_check.sh

preview-format:
	scripts/source_format_check.sh

preview-headings:
	scripts/article_heading_hierarchy_check.sh _site

preview-series-hub:
	scripts/series_hub_consistency_check.sh _site

preview-resources:
	scripts/resource_loading_check.sh _site

preview-verify: preview-build preview-smoke preview-responsive preview-overflow preview-nav preview-runtime preview-a11y preview-linkcheck preview-structure preview-style-scope preview-inline-style preview-ids preview-meta preview-terms preview-format preview-headings preview-series-hub preview-resources

preview-verify-full: preview-verify preview-overflow-full preview-runtime-full

preview-down:
	@docker rm -f $(PREVIEW_NAME) >/dev/null 2>&1 || true
	@echo "stopped $(PREVIEW_NAME)"

preview-recreate: preview-down preview-up

preview-info:
	@echo "Preview URL: $(PREVIEW_URL)"
	@if docker ps --format '{{.Names}}' | grep -qx '$(PREVIEW_NAME)'; then \
		echo "Preview container status: running ($(PREVIEW_NAME))"; \
	else \
		echo "Preview container status: not running ($(PREVIEW_NAME)); run make preview-up"; \
	fi
	@echo "Viewport matrix: desktop-min(961), desktop(1366), tablet(1024), mobile-break(960), tablet-min(761), mobile-max(760), mobile(390)"
	@if [ -d test-results/responsive-check ] && [ "$$(ls -A test-results/responsive-check 2>/dev/null)" ]; then \
		latest="$$(ls -1 test-results/responsive-check | tail -n 1)"; \
		count="$$(find "test-results/responsive-check/$$latest" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"; \
		echo "Latest responsive artifacts: test-results/responsive-check/$$latest"; \
		echo "Latest responsive artifacts count: $$count"; \
	else \
		echo "Latest responsive artifacts: (none; run KEEP_RESPONSIVE_ARTIFACTS=true make preview-responsive)"; \
	fi
	@echo "Quick start: make preview-up"
	@echo "Build + smoke: make preview-verify"
	@echo "Comprehensive full-site verify: make preview-verify-full"
	@echo "Responsive smoke only: make preview-responsive"
	@echo "Responsive overflow only: make preview-overflow"
	@echo "Responsive overflow full-site: make preview-overflow-full"
	@echo "Nav consistency only: make preview-nav"
	@echo "Runtime console only: make preview-runtime"
	@echo "Runtime console full-site: make preview-runtime-full"
	@echo "Accessibility smoke only: make preview-a11y"
	@echo "Link check only (strict): make preview-linkcheck"
	@echo "Link check relaxed: ALLOW_REDIRECTS=true make preview-linkcheck"
	@echo "Structure check only: make preview-structure"
	@echo "Style scope check only: make preview-style-scope"
	@echo "Inline-style check only: make preview-inline-style"
	@echo "ID uniqueness only: make preview-ids"
	@echo "Metadata check only: make preview-meta"
	@echo "Source terminology check only: make preview-terms"
	@echo "Source format check only: make preview-format"
	@echo "Article heading check only: make preview-headings"
	@echo "Series hub static check only: make preview-series-hub"
	@echo "Resource loading check only: make preview-resources"
	@echo "Stop preview: make preview-down"
	@echo "Visual checkpoints:"
	@echo "  1) Hero typography/spacing + CTA alignment"
	@echo "  2) GNB alignment, hover/active, mobile toggle-close"
	@echo "  3) Posts/Series card rhythm + footer spacing"
	@echo "  4) Post/Series entry detail TOC + code/table/image readability"
