---
layout: page
title: Series
permalink: /docs/
description: 주제별 시리즈와 엔트리를 빠르게 탐색할 수 있는 허브
---

{% assign all_series_pages = site.docs | sort: "date" | reverse %}
{% assign series_groups = "series-istio|series-container|series-kubernetes|series-data|series-querypie" | split: "|" %}
{% assign istio_series_entries = site.docs | where: "label", "istio in action" | sort: "date" | reverse %}
{% assign container_series_entries = site.docs | where: "label", "도커 없이 컨테이너 만들기" | sort: "date" | reverse %}
{% assign kubernetes_series_entries = site.docs | where: "label", "쿠버네티스 딥다이브" | sort: "date" | reverse %}
{% assign data_series_entries = site.docs | where: "label", "데이터중심 애플리케이션" | sort: "date" | reverse %}
{% assign querypie_series_entries = site.docs | where: "label", "쿼리파이 핸즈온" | sort: "date" | reverse %}
{% assign series_entries = istio_series_entries | concat: container_series_entries | concat: kubernetes_series_entries | concat: data_series_entries | concat: querypie_series_entries | sort: "date" | reverse %}
{% assign querypie_entry_count = querypie_series_entries | size %}
{% assign querypie_entry_label = "entries" %}
{% if querypie_entry_count == 1 %}
  {% assign querypie_entry_label = "entry" %}
{% endif %}

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Series Navigation</p>
    <h2 class="section-heading__title">시리즈 빠른 이동</h2>
    <p class="section-heading__description">총 {{ all_series_pages | size }}개 페이지를 {{ series_groups | size }}개 Series 묶음별로 재정리했고, 그 안에서 {{ series_entries | size }}개 Series entries를 빠르게 이동할 수 있도록 구성했습니다.</p>
  </div>
  <div class="chip-row">
    <a class="chip" href="#series-istio">Istio IN ACTION · {{ istio_series_entries | size }} entries</a>
    <a class="chip" href="#series-container">도커 없이 컨테이너 만들기 · {{ container_series_entries | size }} entries</a>
    <a class="chip" href="#series-kubernetes">쿠버네티스 딥다이브 · {{ kubernetes_series_entries | size }} entries</a>
    <a class="chip" href="#series-data">데이터 중심 애플리케이션 설계 · {{ data_series_entries | size }} entries</a>
    <a class="chip" href="#series-querypie">쿼리파이 핸즈온 · {{ querypie_entry_count }} {{ querypie_entry_label }}</a>
  </div>
</section>

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Series Explorer</p>
    <h2 class="section-heading__title">전체 Series entries 탐색</h2>
    <p class="section-heading__description">제목, 시리즈명, 설명 기준으로 필터링하고 최신 업데이트, 제목, 시리즈명 순으로 정렬할 수 있습니다.</p>
  </div>
  <div class="series-explorer" data-series-explorer>
    <div class="series-explorer__controls">
      <label class="series-explorer__control" for="series-entry-filter">
        <span class="series-explorer__label">Filter</span>
        <input id="series-entry-filter" class="search-input series-explorer__input" type="search" placeholder="Series entries 제목, 시리즈명, 설명 검색" autocomplete="off" aria-controls="series-entry-list" data-series-explorer-filter>
      </label>
      <label class="series-explorer__control series-explorer__control--select" for="series-entry-sort">
        <span class="series-explorer__label">Sort</span>
        <select id="series-entry-sort" class="series-explorer__select" aria-controls="series-entry-list" data-series-explorer-sort>
          <option value="latest">최신 업데이트 순</option>
          <option value="title">제목순</option>
          <option value="series">시리즈명순</option>
        </select>
      </label>
    </div>
    <div class="chip-row chip-row--offset series-explorer__presets" role="toolbar" aria-label="Series Explorer presets">
      <button type="button" class="chip chip--button is-active" aria-pressed="true" aria-controls="series-entry-list" data-series-explorer-preset="">전체 · {{ series_entries | size }} entries</button>
      <button type="button" class="chip chip--button" aria-pressed="false" aria-controls="series-entry-list" data-series-explorer-preset="Istio IN ACTION" data-series-explorer-preset-aliases="istio in action">Istio IN ACTION · {{ istio_series_entries | size }} entries</button>
      <button type="button" class="chip chip--button" aria-pressed="false" aria-controls="series-entry-list" data-series-explorer-preset="도커 없이 컨테이너 만들기">도커 없이 컨테이너 만들기 · {{ container_series_entries | size }} entries</button>
      <button type="button" class="chip chip--button" aria-pressed="false" aria-controls="series-entry-list" data-series-explorer-preset="쿠버네티스 딥다이브">쿠버네티스 딥다이브 · {{ kubernetes_series_entries | size }} entries</button>
      <button type="button" class="chip chip--button" aria-pressed="false" aria-controls="series-entry-list" data-series-explorer-preset="데이터 중심 애플리케이션 설계" data-series-explorer-preset-aliases="데이터중심 애플리케이션">데이터 중심 애플리케이션 설계 · {{ data_series_entries | size }} entries</button>
      <button type="button" class="chip chip--button" aria-pressed="false" aria-controls="series-entry-list" data-series-explorer-preset="쿼리파이 핸즈온">쿼리파이 핸즈온 · {{ querypie_entry_count }} {{ querypie_entry_label }}</button>
    </div>
    <p class="series-explorer__status" role="status" aria-live="polite" data-series-explorer-status>총 {{ series_entries | size }}개 Series entries</p>
    <div id="series-entry-list" class="series-explorer__list" data-series-explorer-list>
      {% for series_entry in series_entries %}
        {% assign series_entry_summary = series_entry.description | default: "" | strip %}
        {% if series_entry_summary == "" %}
          {% assign series_entry_summary = series_entry.content | split: "<!--more-->" | first | strip_html | strip_newlines | strip %}
        {% endif %}
        {% assign series_entry_label = series_entry.label | default: '' | strip %}
        {% assign series_entry_label_display = series_entry_label %}
        {% if series_entry_label_display == 'istio in action' %}
          {% assign series_entry_label_display = 'Istio IN ACTION' %}
        {% elsif series_entry_label_display == '데이터중심 애플리케이션' %}
          {% assign series_entry_label_display = '데이터 중심 애플리케이션 설계' %}
        {% endif %}
        {% assign series_entry_summary_display = series_entry_summary | replace: 'istio in action', 'Istio IN ACTION' | replace: '데이터중심 애플리케이션', '데이터 중심 애플리케이션 설계' %}
        <article
          class="series-explorer__item"
          data-series-explorer-item
          data-series-entry-title="{{ series_entry.title | strip | escape }}"
          data-series-entry-series="{{ series_entry_label_display | escape }}"
          data-series-entry-date="{{ series_entry.date | date: '%s' }}"
          data-series-entry-search="{{ series_entry.title | append: ' ' | append: series_entry_label | append: ' ' | append: series_entry_label_display | append: ' ' | append: series_entry_summary | append: ' ' | append: series_entry_summary_display | strip_html | strip_newlines | strip | escape }}"
        >
          <div class="series-explorer__item-meta">
            {% if series_entry_label_display != '' %}<span class="badge badge-secondary">{{ series_entry_label_display }}</span>{% endif %}
            {% if series_entry.date %}<time datetime="{{ series_entry.date | date_to_xmlschema }}">{{ series_entry.date | date: "%Y.%m.%d" }}</time>{% endif %}
            <span class="badge">{{ series_entry.version | default: "v1.0" }}</span>
          </div>
          <h3 class="series-explorer__item-title"><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a></h3>
          <p class="series-explorer__item-summary">{{ series_entry_summary_display | truncate: 140 }}</p>
        </article>
      {% endfor %}
    </div>
    <p class="series-explorer__empty" hidden data-series-explorer-empty>조건에 맞는 Series entries가 없습니다. 검색어를 줄이거나 정렬 기준을 바꿔보세요.</p>
  </div>
</section>

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Recently Updated</p>
    <h2 class="section-heading__title">최근 업데이트된 시리즈 엔트리</h2>
    <p class="section-heading__description">최근 정리한 엔트리를 먼저 확인한 뒤 필요한 시리즈로 바로 이동할 수 있습니다.</p>
  </div>
  <div class="entry-grid">
    {% for series_entry in series_entries limit: 8 %}
      {% assign series_entry_label = series_entry.label | default: '' | strip %}
      {% assign series_entry_label_display = series_entry_label %}
      {% if series_entry_label_display == 'istio in action' %}
        {% assign series_entry_label_display = 'Istio IN ACTION' %}
      {% elsif series_entry_label_display == '데이터중심 애플리케이션' %}
        {% assign series_entry_label_display = '데이터 중심 애플리케이션 설계' %}
      {% endif %}
      {% assign series_entry_excerpt = series_entry.description | default: '' | strip_html | strip_newlines %}
      {% if series_entry_excerpt == "" %}
        {% assign series_entry_excerpt = series_entry.content | split: "<!--more-->" | first | strip_html | strip_newlines %}
      {% endif %}
      {% assign series_entry_excerpt_display = series_entry_excerpt | replace: 'istio in action', 'Istio IN ACTION' | replace: '데이터중심 애플리케이션', '데이터 중심 애플리케이션 설계' %}
      <article class="entry-card entry-card--list">
        <div class="entry-card__meta">
          {% if series_entry_label_display != '' %}<span class="badge badge-secondary">{{ series_entry_label_display }}</span>{% endif %}
          {% if series_entry.date %}<time datetime="{{ series_entry.date | date_to_xmlschema }}">{{ series_entry.date | date: "%Y.%m.%d" }}</time>{% endif %}
          <span class="badge">{{ series_entry.version | default: "v1.0" }}</span>
        </div>
        <h3 class="entry-card__title"><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a></h3>
        <p class="entry-card__excerpt">{{ series_entry_excerpt_display | truncate: 170 }}</p>
        <a class="entry-card__cta" href="{{ series_entry.url | prepend: site.baseurl }}">엔트리 열기 →</a>
      </article>
    {% endfor %}
  </div>
</section>

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Series Index</p>
    <h2 class="section-heading__title">시리즈별 엔트리 인덱스</h2>
    <p class="section-heading__description">시리즈 랜딩과 개별 엔트리를 한 화면에서 탐색할 수 있도록 구조를 재정렬했습니다.</p>
  </div>
  <div class="series-grid">
    {% assign latest = istio_series_entries | first %}
    <article id="series-istio" class="series-card">
      <div class="series-card__foot">
        <span>{{ istio_series_entries | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/istio-in-action/">Istio IN ACTION</a></h3>
      <p class="series-card__description">서비스 메시 핵심 개념부터 보안, 트래픽 제어, 관측성, 트러블슈팅까지 단계적으로 따라갈 수 있는 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for series_entry in istio_series_entries %}
          <li><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a>{% if series_entry.date %} · {{ series_entry.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/istio-in-action/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = container_series_entries | first %}
    <article id="series-container" class="series-card">
      <div class="series-card__foot">
        <span>{{ container_series_entries | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/make-container-without-docker/">도커 없이 컨테이너 만들기</a></h3>
      <p class="series-card__description">네임스페이스, cgroup, 파일시스템, 네트워크를 실습 흐름에 맞춰 정리한 깊이 있는 컨테이너 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for series_entry in container_series_entries %}
          <li><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a>{% if series_entry.date %} · {{ series_entry.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/make-container-without-docker/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = kubernetes_series_entries | first %}
    <article id="series-kubernetes" class="series-card">
      <div class="series-card__foot">
        <span>{{ kubernetes_series_entries | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">쿠버네티스 딥다이브</a></h3>
      <p class="series-card__description">핵심 컴포넌트 동작 원리와 운영 디버깅 포인트를 빠르게 순회할 수 있도록 구성한 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for series_entry in kubernetes_series_entries %}
          <li><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a>{% if series_entry.date %} · {{ series_entry.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = data_series_entries | first %}
    <article id="series-data" class="series-card">
      <div class="series-card__foot">
        <span>{{ data_series_entries | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/data-intensive-application-design/">데이터 중심 애플리케이션 설계</a></h3>
      <p class="series-card__description">복제, 파티셔닝, 트랜잭션, 분산 시스템 합의를 운영 관점으로 연결해 읽을 수 있는 학습 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for series_entry in data_series_entries %}
          <li><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a>{% if series_entry.date %} · {{ series_entry.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/data-intensive-application-design/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = querypie_series_entries | first %}
    <article id="series-querypie" class="series-card">
      <div class="series-card__foot">
        <span>{{ querypie_entry_count }} {{ querypie_entry_label }}</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/querypie-handson/multiple-kubernetes-with-querypie-kac/">쿼리파이 핸즈온</a></h3>
      <p class="series-card__description">여러 Kubernetes 클러스터를 QueryPie KAC로 연결하는 실습형 엔트리를 별도 시리즈로 분리해 탐색성을 높였습니다.</p>
      <ol class="entry-card__list">
        {% for series_entry in querypie_series_entries %}
          <li><a href="{{ series_entry.url | prepend: site.baseurl }}">{{ series_entry.title }}</a>{% if series_entry.date %} · {{ series_entry.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/querypie-handson/multiple-kubernetes-with-querypie-kac/">엔트리 바로 보기 →</a>
    </article>
  </div>
</section>

<p class="section-note">제목이나 키워드 기준의 빠른 탐색은 <a href="{{ site.baseurl }}/search/">Search</a>에서 바로 수행할 수 있습니다.</p>
