---
title: Announcements
permalink: /announcements/
description: 사이트 공지와 주요 업데이트를 모아보는 안내 페이지
hide_page_intro: true
---

{% assign sorted_announcements = site.announcements | where_exp: "announcement", "announcement.published != false" | sort: "date" | reverse %}
{% assign has_active_announcements = false %}
{% assign primary_announcement = nil %}
{% for announcement in sorted_announcements %}
  {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
    {% assign has_active_announcements = true %}
    {% if primary_announcement == nil and announcement.pinned %}
      {% assign primary_announcement = announcement %}
    {% endif %}
  {% endif %}
{% endfor %}
{% if primary_announcement == nil %}
  {% for announcement in sorted_announcements %}
    {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
      {% assign primary_announcement = announcement %}
      {% break %}
    {% endif %}
  {% endfor %}
{% endif %}
{% assign has_secondary_announcements = false %}
{% if primary_announcement %}
  {% for announcement in sorted_announcements %}
    {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
      {% if announcement.url != primary_announcement.url %}
        {% assign has_secondary_announcements = true %}
        {% break %}
      {% endif %}
    {% endif %}
  {% endfor %}
{% endif %}

<div class="section-heading">
  <p class="section-heading__kicker">Updates</p>
  <h1 class="section-heading__title">{{ page.title }}</h1>
  <p class="section-heading__description">{{ page.description }}</p>
</div>

<p class="section-note announcement-page__policy">Home에는 pinned 공지 1건을 우선 노출하고, 여기에서는 현재 활성 상태인 공지를 모두 확인할 수 있습니다.</p>

{% if has_active_announcements %}
  {% assign primary_cta_url = primary_announcement.cta_url | default: primary_announcement.url %}
  {% if primary_cta_url contains "://" %}
    {% assign primary_cta_href = primary_cta_url %}
  {% else %}
    {% assign primary_cta_href = primary_cta_url | prepend: site.baseurl %}
  {% endif %}
  <div class="entry-grid announcement-grid">
    <article class="entry-card entry-card--feature">
      <div class="entry-card__meta">
        <time datetime="{{ primary_announcement.date | date_to_xmlschema }}">{{ primary_announcement.date | date: "%Y.%m.%d" }}</time>
        {% if primary_announcement.pinned %}<span class="badge">Pinned</span>{% endif %}
        <span class="badge badge-secondary">Announcement</span>
      </div>
      <div class="announcement-feature">
        <div class="announcement-feature__copy">
          <h2 class="entry-card__title announcement-feature__title"><a href="{{ primary_announcement.url | prepend: site.baseurl }}">{{ primary_announcement.title }}</a></h2>
          <p class="entry-card__excerpt announcement-feature__excerpt">{{ primary_announcement.summary }}</p>
        </div>
        <div class="announcement-feature__actions">
          <a class="button button--primary" href="{{ primary_cta_href }}"{% if primary_cta_url contains "://" %} target="_blank" rel="noreferrer noopener"{% endif %}>
            {{ primary_announcement.cta_label | default: "공지 보기" }}
          </a>
          {% if primary_announcement.pinned %}
            <p class="announcement-feature__hint">현재 Home에도 함께 노출 중인 공지입니다.</p>
          {% endif %}
        </div>
      </div>
    </article>
  </div>
  {% if has_secondary_announcements %}
<div class="section-heading announcement-page__secondary-heading">
  <p class="section-heading__kicker">More Updates</p>
  <h2 class="section-heading__title">추가 공지</h2>
  <p class="section-heading__description">현재 활성 상태인 다른 공지들도 함께 확인할 수 있습니다.</p>
</div>
<div class="entry-grid">
  {% for announcement in sorted_announcements %}
    {% if announcement.expires_at == nil or announcement.expires_at > site.time %}
      {% if announcement.url == primary_announcement.url %}
        {% continue %}
      {% endif %}
      {% assign announcement_cta_url = announcement.cta_url | default: announcement.url %}
      {% if announcement_cta_url contains "://" %}
        {% assign announcement_cta_href = announcement_cta_url %}
      {% else %}
        {% assign announcement_cta_href = announcement_cta_url | prepend: site.baseurl %}
      {% endif %}
      <article class="entry-card entry-card--list">
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
  {% endif %}
{% else %}
  <p class="section-note">현재 노출 중인 공지가 없습니다. Home은 기존 탐색 흐름을 그대로 유지합니다.</p>
{% endif %}
