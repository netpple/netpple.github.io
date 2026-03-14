---
title: Posts
permalink: /news/
description: netpple 기술 블로그 포스트 목록
---

{% assign posts = site.posts | where_exp: "post", "post.excluded_in_search != true" %}

<div class="section-heading">
  <p class="section-heading__kicker">Latest First</p>
  <h2 class="section-heading__title">모든 포스트</h2>
  <p class="section-heading__description">문제 해결 과정, 운영 노하우, 학습 기록을 시간순으로 확인할 수 있습니다.</p>
</div>

<div class="entry-grid">
  {% for post in posts %}
    <article class="entry-card entry-card--news">
      <div class="entry-card__meta">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
        {% if post.categories %}<span class="badge badge-secondary">{{ post.categories | join: ", " }}</span>{% endif %}
        <span class="badge">{{ post.version | default: "v1.0" }}</span>
        {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
      </div>
      <h3 class="entry-card__title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h3>
      <p class="entry-card__excerpt">{{ post.content | split: "<!--more-->" | first | strip_html | strip_newlines | truncate: 170 }}</p>
      <a class="entry-card__cta" href="{{ post.url | prepend: site.baseurl }}">Read post →</a>
    </article>
  {% endfor %}
</div>

<p class="section-note">이전 포스트는 <a href="{{ site.baseurl }}/archive/">Posts Archive</a>에서 연도별로 볼 수 있습니다.</p>
