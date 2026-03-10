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

    function closeMenu() {
      nav.classList.remove("is-open");
      toggle.setAttribute("aria-expanded", "false");
    }

    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
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
        closeMenu();
      }
    });
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

  document.addEventListener("DOMContentLoaded", function () {
    initNavigation();
    buildToc();
    initSearchShortcut();
  });
})();
