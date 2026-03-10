PREVIEW_NAME ?= sam7-manual-preview
PREVIEW_PORT ?= 4012
PREVIEW_URL ?= http://127.0.0.1:$(PREVIEW_PORT)
PREVIEW_IMAGE ?= jekyll/jekyll:4.2.0

.PHONY: preview-up preview-build preview-smoke preview-verify preview-down preview-recreate

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

preview-verify: preview-build preview-smoke

preview-down:
	@docker rm -f $(PREVIEW_NAME) >/dev/null 2>&1 || true
	@echo "stopped $(PREVIEW_NAME)"

preview-recreate: preview-down preview-up
