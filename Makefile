PREVIEW_NAME ?= sam7-manual-preview
PREVIEW_PORT ?= 4012
PREVIEW_URL ?= http://127.0.0.1:$(PREVIEW_PORT)

.PHONY: preview-up preview-build preview-smoke preview-down

preview-up:
	docker run -d --name $(PREVIEW_NAME) -p $(PREVIEW_PORT):4000 -v "$$PWD":/srv/jekyll jekyll/jekyll:4.2.0 jekyll serve --host 0.0.0.0 --port 4000 --watch

preview-build:
	docker exec $(PREVIEW_NAME) jekyll build

preview-smoke:
	scripts/preview_smoke_check.sh $(PREVIEW_URL)

preview-down:
	docker rm -f $(PREVIEW_NAME)
