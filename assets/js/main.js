---
exclude_in_search: true
layout: null
---
(function () {
  "use strict";

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
  }

  function ensureHeadingId(heading) {
    if (heading.id) {
      return heading.id;
    }
    var slug = heading.textContent
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9가-힣\s-]/g, "")
      .replace(/\s+/g, "-");
    heading.id = slug || "section";
    return heading.id;
  }

  function appendHeadingAnchors(container) {
    container.querySelectorAll("h2, h3, h4").forEach(function (heading) {
      var id = ensureHeadingId(heading);
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

    appendHeadingAnchors(container);
    var headings = container.querySelectorAll("h2, h3");
    if (!headings.length) {
      toc.classList.add("is-empty");
      return;
    }

    var linksById = [];
    headings.forEach(function (heading) {
      var id = ensureHeadingId(heading);
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
