PREVIEW_NAME ?= sam7-manual-preview
PREVIEW_PORT ?= 4012
PREVIEW_URL ?= http://127.0.0.1:$(PREVIEW_PORT)
PREVIEW_IMAGE ?= jekyll/jekyll:4.2.0

.PHONY: preview-up preview-build preview-smoke preview-responsive preview-overflow preview-overflow-full preview-nav preview-a11y preview-linkcheck preview-structure preview-style-scope preview-inline-style preview-ids preview-meta preview-verify preview-down preview-recreate preview-info

preview-up:
	@if docker ps --format '{{.Names}}' | grep -qx '$(PREVIEW_NAME)'; then \
		echo "$(PREVIEW_NAME) is already running"; \
	elif docker ps -a --format '{{.Names}}' | grep -qx '$(PREVIEW_NAME)'; then \
		echo "starting existing $(PREVIEW_NAME) container"; \
		docker start $(PREVIEW_NAME) >/dev/null; \
	else \
		docker run -d --name $(PREVIEW_NAME) -p $(PREVIEW_PORT):4000 -v "$$PWD":/srv/jekyll $(PREVIEW_IMAGE) jekyll serve --host 0.0.0.0 --port 4000 --watch >/dev/null; \
		echo "started $(PREVIEW_NAME) on $(PREVIEW_URL)"; \
	fi

preview-build:
	docker exec $(PREVIEW_NAME) jekyll build

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

preview-verify: preview-build preview-smoke preview-responsive preview-overflow preview-nav preview-a11y preview-linkcheck preview-structure preview-style-scope preview-inline-style preview-ids preview-meta

preview-down:
	@docker rm -f $(PREVIEW_NAME) >/dev/null 2>&1 || true
	@echo "stopped $(PREVIEW_NAME)"

preview-recreate: preview-down preview-up

preview-info:
	@echo "Preview URL: $(PREVIEW_URL)"
	@echo "Quick start: make preview-up"
	@echo "Build + smoke: make preview-verify"
	@echo "Responsive smoke only: make preview-responsive"
	@echo "Responsive overflow only: make preview-overflow"
	@echo "Responsive overflow full-site: make preview-overflow-full"
	@echo "Nav consistency only: make preview-nav"
	@echo "Accessibility smoke only: make preview-a11y"
	@echo "Link check only (strict): make preview-linkcheck"
	@echo "Link check relaxed: ALLOW_REDIRECTS=true make preview-linkcheck"
	@echo "Structure check only: make preview-structure"
	@echo "Style scope check only: make preview-style-scope"
	@echo "Inline-style check only: make preview-inline-style"
	@echo "ID uniqueness only: make preview-ids"
	@echo "Metadata check only: make preview-meta"
	@echo "Stop preview: make preview-down"
	@echo "Visual checkpoints:"
	@echo "  1) Hero typography/spacing + CTA alignment"
	@echo "  2) GNB alignment, hover/active, mobile toggle-close"
	@echo "  3) News/Docs card rhythm + footer spacing"
	@echo "  4) Post/Doc detail TOC + code/table/image readability"
