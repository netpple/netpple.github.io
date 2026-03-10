---
layout: null
excluded_in_search: true
---
(function () {
	function getQueryVariable(variable) {
		var query = window.location.search.substring(1),
			vars = query.split("&");

		for (var i = 0; i < vars.length; i++) {
			var pair = vars[i].split("=");

			if (pair[0] === variable) {
				return decodeURIComponent((pair[1] || "").replace(/\+/g, "%20")).trim();
			}
		}

		return "";
	}

	function normalizeQuery(text) {
		return (text || "").trim();
	}

	function splitQueryParts(query) {
		return normalizeQuery(query).split(/\s+/).filter(function (part) {
			return part.length > 0;
		});
	}

	function escapeRegExp(text) {
		return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	}

	function getPreview(query, content, previewLength) {
		content = content || "";
		previewLength = previewLength || Math.min(220, Math.max(80, content.length));

		var parts = splitQueryParts(query),
			normalizedQuery = normalizeQuery(query),
			match = normalizedQuery ? content.toLowerCase().indexOf(normalizedQuery.toLowerCase()) : -1,
			matchLength = normalizedQuery.length,
			preview;

		// Find a relevant location in content
		for (var i = 0; i < parts.length; i++) {
			if (match >= 0) {
				break;
			}

			match = content.toLowerCase().indexOf(parts[i].toLowerCase());
			matchLength = parts[i].length;
		}

		// Create preview
		if (match >= 0) {
			var start = Math.max(0, Math.floor(match - (previewLength / 2))),
				end = start > 0 ? Math.min(content.length, Math.ceil(match + matchLength + (previewLength / 2))) : Math.min(content.length, previewLength);

			preview = content.substring(start, end).trim();

			if (start > 0) {
				preview = "..." + preview;
			}

			if (end < content.length) {
				preview = preview + "...";
			}

			// Highlight query parts
			if (parts.length) {
				preview = preview.replace(new RegExp("(" + parts.map(escapeRegExp).join("|") + ")", "gi"), "<strong>$1</strong>");
			}
		} else {
			// Use start of content if no match found
			preview = content.substring(0, previewLength).trim() + (content.length > previewLength ? "..." : "");
		}

		return preview;
	}

	function searchSafely(query) {
		var normalizedQuery = normalizeQuery(query);
		if (!normalizedQuery) {
			return [];
		}

		try {
			return window.index.search(normalizedQuery);
		} catch (error) {
			// Fall back to an explicit term query for special-char/parse-error cases.
			var parts = splitQueryParts(normalizedQuery);
			if (!parts.length) {
				return [];
			}
			try {
				return window.index.query(function (q) {
					parts.forEach(function (term) {
						q.term(term.toLowerCase(), {
							presence: lunr.Query.presence.REQUIRED,
							wildcard: lunr.Query.wildcard.TRAILING
						});
					});
				});
			} catch (fallbackError) {
				return [];
			}
		}
	}

	function displaySearchResults(results, query) {
		var searchResultsEl = document.getElementById("search-results"),
			searchProcessEl = document.getElementById("search-process"),
			renderedCount = 0;

		if (!searchResultsEl || !searchProcessEl) {
			return;
		}

		if (!normalizeQuery(query)) {
			searchResultsEl.innerHTML = "";
			searchResultsEl.style.display = "none";
			searchProcessEl.innerText = "Type";
			return;
		}

		if (results.length) {
			var resultsHTML = "";
			results.forEach(function (result) {
				var item = window.data[result.ref];
				var contentPreview;
				var titlePreview;

				if (item && item.title) {
					contentPreview = getPreview(query, item.content, 170);
					titlePreview = getPreview(query, item.title);
					resultsHTML += "<li><h4><a href='{{ site.baseurl }}" + (item.url || "").trim() + "'>" + titlePreview + "</a></h4><p><small>" + contentPreview + "</small></p></li>";
					renderedCount += 1;
				}
			});

			if (renderedCount > 0) {
				searchResultsEl.innerHTML = resultsHTML;
				searchResultsEl.style.display = "grid";
				searchProcessEl.innerText = "Showing";
			} else {
				searchResultsEl.innerHTML = "";
				searchResultsEl.style.display = "none";
				searchProcessEl.innerText = "No";
			}
		} else {
			searchResultsEl.innerHTML = "";
			searchResultsEl.style.display = "none";
			searchProcessEl.innerText = "No";
		}
	}

	window.index = lunr(function () {
		this.field("id");
		this.field("title", {boost: 10});
		this.field("categories");
		this.field("url");
		this.field("content");
	});

	var query = normalizeQuery(getQueryVariable("q")),
		searchQueryContainerEl = document.getElementById("search-query-container"),
		searchQueryEl = document.getElementById("search-query"),
		results;

	if (searchQueryEl) {
		searchQueryEl.innerText = query;
	}
	if (searchQueryContainerEl && query !== "") {
		searchQueryContainerEl.style.display = "inline";
	}

	for (var key in window.data) {
		if (Object.prototype.hasOwnProperty.call(window.data, key)) {
			window.index.add(window.data[key]);
		}
	}

	results = searchSafely(query);
	displaySearchResults(results, query); // Hand the results off to be displayed
})();
