PREVIEW_NAME ?= sam7-manual-preview
PREVIEW_PORT ?= 4012
PREVIEW_URL ?= http://127.0.0.1:$(PREVIEW_PORT)
PREVIEW_IMAGE ?= jekyll/jekyll:4.2.0

.PHONY: preview-up preview-build preview-smoke preview-linkcheck preview-verify preview-down preview-recreate preview-info

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

preview-linkcheck:
	scripts/internal_link_check.sh $(PREVIEW_URL)

preview-verify: preview-build preview-smoke preview-linkcheck

preview-down:
	@docker rm -f $(PREVIEW_NAME) >/dev/null 2>&1 || true
	@echo "stopped $(PREVIEW_NAME)"

preview-recreate: preview-down preview-up

preview-info:
	@echo "Preview URL: $(PREVIEW_URL)"
	@echo "Quick start: make preview-up"
	@echo "Build + smoke: make preview-verify"
	@echo "Link check only: make preview-linkcheck"
	@echo "Stop preview: make preview-down"
	@echo "Visual checkpoints:"
	@echo "  1) Hero typography/spacing + CTA alignment"
	@echo "  2) GNB alignment, hover/active, mobile toggle-close"
	@echo "  3) News/Docs card rhythm + footer spacing"
	@echo "  4) Post/Doc detail TOC + code/table/image readability"
