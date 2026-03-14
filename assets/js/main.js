---
exclude_in_search: true
layout: null
---
(function () {
  "use strict";

  function slugifyHeadingText(text) {
    return text
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9가-힣\s-]/g, "")
      .replace(/\s+/g, "-");
  }

  function collectUsedIds(container) {
    var usedIds = new Set();
    container.querySelectorAll("[id]").forEach(function (node) {
      if (node.id) {
        usedIds.add(node.id);
      }
    });
    return usedIds;
  }

  function initNavigation() {
    var nav = document.querySelector("[data-nav]");
    var toggle = document.querySelector("[data-nav-toggle]");
    if (!nav || !toggle) {
      return;
    }

    function syncMenuA11y(open) {
      var isMobile = window.innerWidth <= 960;
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      toggle.setAttribute("aria-label", open ? "Close navigation menu" : "Open navigation menu");
      nav.setAttribute("aria-hidden", isMobile && !open ? "true" : "false");
    }

    function closeMenu() {
      nav.classList.remove("is-open");
      syncMenuA11y(false);
    }

    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("is-open");
      syncMenuA11y(open);
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") {
        closeMenu();
      }
    });

    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", closeMenu);
    });

    document.addEventListener("click", function (event) {
      if (!nav.classList.contains("is-open")) {
        return;
      }
      if (!nav.contains(event.target) && !toggle.contains(event.target)) {
        closeMenu();
      }
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 960) {
        nav.classList.remove("is-open");
      }
      syncMenuA11y(nav.classList.contains("is-open"));
    });

    syncMenuA11y(nav.classList.contains("is-open"));
  }

  function ensureHeadingId(heading, usedIds) {
    if (heading.id) {
      usedIds.add(heading.id);
      return heading.id;
    }
    var base = slugifyHeadingText(heading.textContent) || "section";
    var slug = base;
    var suffix = 2;

    while (usedIds.has(slug)) {
      slug = base + "-" + suffix;
      suffix += 1;
    }

    heading.id = slug;
    usedIds.add(slug);
    return slug;
  }

  function appendHeadingAnchors(container, usedIds) {
    container.querySelectorAll("h2, h3, h4").forEach(function (heading) {
      var id = ensureHeadingId(heading, usedIds);
      if (heading.querySelector(".header-anchor")) {
        return;
      }
      var anchor = document.createElement("a");
      anchor.className = "header-anchor";
      anchor.href = "#" + id;
      anchor.setAttribute("aria-label", "Copy heading link");
      anchor.textContent = "#";
      heading.appendChild(anchor);
    });
  }

  function normalizeArticleHeadings(container) {
    container.querySelectorAll("h1").forEach(function (heading) {
      var replacement = document.createElement("h2");

      Array.prototype.slice.call(heading.attributes).forEach(function (attr) {
        replacement.setAttribute(attr.name, attr.value);
      });

      while (heading.firstChild) {
        replacement.appendChild(heading.firstChild);
      }

      heading.parentNode.replaceChild(replacement, heading);
    });
  }

  function activateCurrentTocItem(linksById, activeId) {
    linksById.forEach(function (link) {
      link.classList.toggle("is-current", link.getAttribute("href") === "#" + activeId);
    });
  }

  function bindTocObserver(container, linksById) {
    if (!("IntersectionObserver" in window) || !linksById.length) {
      return;
    }

    var visibleHeadings = new Set();
    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            visibleHeadings.add(entry.target.id);
          } else {
            visibleHeadings.delete(entry.target.id);
          }
        });

        if (visibleHeadings.size === 0) {
          return;
        }
        var latest = Array.from(visibleHeadings).pop();
        activateCurrentTocItem(linksById, latest);
      },
      { rootMargin: "-28% 0px -62% 0px", threshold: [0, 1] }
    );

    container.querySelectorAll("h2[id], h3[id]").forEach(function (heading) {
      observer.observe(heading);
    });
  }

  function buildToc() {
    var container = document.querySelector("[data-article-content]");
    var toc = document.querySelector("[data-article-toc]");
    var tocList = toc ? toc.querySelector("[data-toc-list]") : null;
    if (!container || !toc || !tocList) {
      return;
    }

    // Keep one top-level page heading and normalize content heading hierarchy.
    normalizeArticleHeadings(container);

    var usedIds = collectUsedIds(container);
    appendHeadingAnchors(container, usedIds);
    var headings = container.querySelectorAll("h2, h3");
    if (!headings.length) {
      toc.classList.add("is-empty");
      return;
    }

    var linksById = [];
    headings.forEach(function (heading) {
      var id = ensureHeadingId(heading, usedIds);
      var item = document.createElement("li");
      item.className = "article-toc__item " + (heading.tagName.toLowerCase() === "h3" ? "article-toc__item--depth-3" : "");

      var link = document.createElement("a");
      link.href = "#" + id;
      link.textContent = heading.textContent.replace("#", "").trim();
      item.appendChild(link);
      tocList.appendChild(item);
      linksById.push(link);
    });

    bindTocObserver(container, linksById);
  }

  function initSearchShortcut() {
    document.querySelectorAll(".td-search-input[data-search-jump], .js-search-input").forEach(function (input) {
      input.addEventListener("keydown", function (event) {
        if (event.key !== "Enter") {
          return;
        }
        event.preventDefault();
        var query = (input.value || "").trim();
        if (!query) {
          return;
        }
        window.location.href = "{{ site.baseurl }}/search/?q=" + encodeURIComponent(query);
      });
    });
  }

  function normalizeText(text) {
    return (text || "").toLowerCase().replace(/\s+/g, " ").trim();
  }

  function compareText(left, right) {
    return left.localeCompare(right, "ko", { sensitivity: "base", numeric: true });
  }

  function initSeriesExplorer() {
    var explorer = document.querySelector("[data-series-explorer]");
    if (!explorer) {
      return;
    }

    var filterInput = explorer.querySelector("[data-series-explorer-filter]");
    var sortSelect = explorer.querySelector("[data-series-explorer-sort]");
    var status = explorer.querySelector("[data-series-explorer-status]");
    var emptyState = explorer.querySelector("[data-series-explorer-empty]");
    var list = explorer.querySelector("[data-series-explorer-list]");
    var presetButtons = Array.prototype.slice.call(explorer.querySelectorAll("[data-series-explorer-preset]"));
    var items = list ? Array.prototype.slice.call(list.querySelectorAll("[data-series-explorer-item]")) : [];

    if (!filterInput || !sortSelect || !status || !emptyState || !list || !items.length) {
      return;
    }

    function sortItems(visibleItems, sortValue) {
      return visibleItems.sort(function (leftItem, rightItem) {
        var leftTitle = leftItem.getAttribute("data-series-entry-title") || "";
        var rightTitle = rightItem.getAttribute("data-series-entry-title") || "";
        var leftSeries = leftItem.getAttribute("data-series-entry-series") || "";
        var rightSeries = rightItem.getAttribute("data-series-entry-series") || "";
        var leftDate = parseInt(leftItem.getAttribute("data-series-entry-date") || "0", 10);
        var rightDate = parseInt(rightItem.getAttribute("data-series-entry-date") || "0", 10);

        if (sortValue === "title") {
          return compareText(leftTitle, rightTitle) || rightDate - leftDate;
        }

        if (sortValue === "series") {
          return compareText(leftSeries, rightSeries) || rightDate - leftDate || compareText(leftTitle, rightTitle);
        }

        return rightDate - leftDate || compareText(leftSeries, rightSeries) || compareText(leftTitle, rightTitle);
      });
    }

    function updateStatus(visibleCount, query, sortValue) {
      var sortLabels = {
        latest: "최신 업데이트 순",
        title: "제목순",
        series: "시리즈명순"
      };
      var parts = ["총 " + visibleCount + "개 Series entry"];

      if (query) {
        parts.push('"' + query + '" 필터 적용');
      }

      parts.push(sortLabels[sortValue] || sortValue);
      status.textContent = parts.join(" · ");
    }

    function syncPresetButtons(query) {
      var normalizedQuery = normalizeText(query);

      presetButtons.forEach(function (button) {
        var presetValue = normalizeText(button.getAttribute("data-series-explorer-preset"));
        var isActive = normalizedQuery === presetValue || (!normalizedQuery && !presetValue);

        button.classList.toggle("is-active", isActive);
        button.setAttribute("aria-pressed", isActive ? "true" : "false");
      });
    }

    function applySeriesExplorerState() {
      var query = normalizeText(filterInput.value);
      var sortValue = sortSelect.value || "latest";
      var visibleItems = [];

      items.forEach(function (item) {
        var haystack = normalizeText(item.getAttribute("data-series-entry-search"));
        var matches = !query || haystack.indexOf(query) !== -1;

        item.hidden = !matches;
        if (matches) {
          visibleItems.push(item);
        }
      });

      sortItems(visibleItems, sortValue).forEach(function (item) {
        item.hidden = false;
        list.appendChild(item);
      });

      emptyState.hidden = visibleItems.length !== 0;
      updateStatus(visibleItems.length, filterInput.value.trim(), sortValue);
      syncPresetButtons(filterInput.value);
    }

    filterInput.addEventListener("input", applySeriesExplorerState);
    sortSelect.addEventListener("change", applySeriesExplorerState);
    presetButtons.forEach(function (button) {
      button.addEventListener("click", function () {
        filterInput.value = button.getAttribute("data-series-explorer-preset") || "";
        applySeriesExplorerState();
      });
    });
    applySeriesExplorerState();
  }

  function hardenBlankTargetLinks() {
    document.querySelectorAll('a[target="_blank"]').forEach(function (link) {
      var relValue = (link.getAttribute("rel") || "").trim();
      var relTokens = relValue ? relValue.split(/\s+/) : [];

      if (relTokens.indexOf("noreferrer") === -1) {
        relTokens.push("noreferrer");
      }
      if (relTokens.indexOf("noopener") === -1) {
        relTokens.push("noopener");
      }

      link.setAttribute("rel", relTokens.join(" ").trim());
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    hardenBlankTargetLinks();
    initNavigation();
    buildToc();
    initSearchShortcut();
    initSeriesExplorer();
  });
})();
