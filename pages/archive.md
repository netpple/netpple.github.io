---
layout: page
title: Posts Archive
permalink: /archive/
description: 연도별 포스트 아카이브
---

{% assign posts = site.posts | where_exp: "post", "post.excluded_in_search != true" %}

<div class="section-heading">
  <p class="section-heading__kicker">Chronological View</p>
  <h2 class="section-heading__title">연도별 포스트 아카이브</h2>
  <p class="section-heading__description">모든 포스트를 연도별로 빠르게 탐색할 수 있습니다.</p>
</div>

{% if posts.size > 0 %}
  <div class="archive-grid">
    {% for post in posts %}
      {% capture this_year %}{{ post.date | date: "%Y" }}{% endcapture %}
      {% capture next_year %}{{ post.previous.date | date: "%Y" }}{% endcapture %}
      {% if forloop.first %}
        <article class="archive-year-card">
          <h3 class="archive-year-card__year" id="{{ this_year }}-ref">{{ this_year }}</h3>
          <ul class="archive-year-card__list">
      {% endif %}
            <li class="archive-year-card__item">
              <time class="archive-year-card__date" datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
              <a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>
            </li>
      {% if forloop.last %}
          </ul>
        </article>
      {% elsif this_year != next_year %}
          </ul>
        </article>
        <article class="archive-year-card">
          <h3 class="archive-year-card__year" id="{{ next_year }}-ref">{{ next_year }}</h3>
          <ul class="archive-year-card__list">
      {% endif %}
    {% endfor %}
  </div>
{% else %}
  <p class="section-note">표시할 아카이브 데이터가 없습니다.</p>
{% endif %}
