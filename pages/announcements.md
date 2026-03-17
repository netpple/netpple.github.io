---
title: Announcements
permalink: /announcements/
description: 사이트 공지와 주요 업데이트를 모아보는 안내 페이지
---

{% assign sorted_announcements = site.announcements | where_exp: "announcement", "announcement.published != false" | sort: "date" | reverse %}
{% assign has_active_announcements = false %}
{% for announcement in sorted_announcements %}
  {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
    {% assign has_active_announcements = true %}
    {% break %}
  {% endif %}
{% endfor %}

<div class="section-heading">
  <p class="section-heading__kicker">Updates</p>
  <h2 class="section-heading__title">현재 노출 중인 공지</h2>
  <p class="section-heading__description">Home에는 pinned 공지 1건을 우선 노출하고, 여기에서는 활성 공지 전체를 확인할 수 있습니다.</p>
</div>

{% if has_active_announcements %}
  <div class="entry-grid">
    {% for announcement in sorted_announcements %}
      {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
        {% assign announcement_cta_url = announcement.cta_url | default: announcement.url %}
        {% if announcement_cta_url contains "://" %}
          {% assign announcement_cta_href = announcement_cta_url %}
        {% else %}
          {% assign announcement_cta_href = announcement_cta_url | prepend: site.baseurl %}
        {% endif %}
        <article class="entry-card entry-card--full">
          <div class="entry-card__meta">
            <time datetime="{{ announcement.date | date_to_xmlschema }}">{{ announcement.date | date: "%Y.%m.%d" }}</time>
            {% if announcement.pinned %}<span class="badge">Pinned</span>{% endif %}
            <span class="badge badge-secondary">Announcement</span>
          </div>
          <h3 class="entry-card__title"><a href="{{ announcement.url | prepend: site.baseurl }}">{{ announcement.title }}</a></h3>
          <p class="entry-card__excerpt">{{ announcement.summary }}</p>
          <a class="entry-card__cta" href="{{ announcement_cta_href }}"{% if announcement_cta_url contains "://" %} target="_blank" rel="noreferrer noopener"{% endif %}>
            {{ announcement.cta_label | default: "공지 보기" }}
          </a>
        </article>
      {% endif %}
    {% endfor %}
  </div>
{% else %}
  <p class="section-note">현재 노출 중인 공지가 없습니다. Home은 기존 탐색 흐름을 그대로 유지합니다.</p>
{% endif %}

<p class="section-note">`published: false` 또는 지난 `expires_at` 값을 가진 공지는 Home과 이 목록에서 자동으로 숨겨집니다.</p>
