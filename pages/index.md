---
layout: page
title: Netpple Engineering Archive
permalink: /
description: 클라우드 네이티브와 분산 시스템 운영 경험을 정리한 기술 아카이브
---
{% assign posts = site.posts | where_exp: "post", "post.excluded_in_search != true" %}
{% assign istio_series_entries = site.docs | where: "label", "istio in action" %}
{% assign container_series_entries = site.docs | where: "label", "도커 없이 컨테이너 만들기" %}
{% assign kubernetes_series_entries = site.docs | where: "label", "쿠버네티스 딥다이브" %}
{% assign data_series_entries = site.docs | where: "label", "데이터중심 애플리케이션" %}
{% assign querypie_series_entries = site.docs | where: "label", "쿼리파이 핸즈온" %}
{% assign series_entries = istio_series_entries | concat: container_series_entries | concat: kubernetes_series_entries | concat: data_series_entries | concat: querypie_series_entries %}

<section class="home-hero">
  <p class="home-hero__eyebrow">Tech Journal</p>
  <h1 class="home-hero__title">클라우드 네이티브와 분산 시스템 운영 지식을 구조적으로 기록합니다.</h1>
  <p class="home-hero__description">
    실무에서 검증한 Kubernetes, Container, Istio, 플랫폼 운영 경험을 시리즈와 포스트 형식으로 정리한 아카이브입니다.
    빠른 탐색과 높은 가독성을 중심으로 전체 정보 구조를 재구성했습니다.
  </p>
  <div class="home-hero__actions button-row">
    <a class="button button--primary" href="{{ site.baseurl }}/docs/">시리즈 허브 보기</a>
    <a class="button button--ghost" href="{{ site.baseurl }}/news/">최신 포스트 보기</a>
  </div>
  <div class="home-stats">
    <div class="home-stats__item">
      <p class="home-stats__label">Posts</p>
      <p class="home-stats__value">{{ posts | size }}</p>
    </div>
    <div class="home-stats__item">
      <p class="home-stats__label">Series entries</p>
      <p class="home-stats__value">{{ series_entries | size }}</p>
    </div>
    <div class="home-stats__item">
      <p class="home-stats__label">Since</p>
      <p class="home-stats__value">2021</p>
    </div>
  </div>
</section>

<section class="home-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Latest Posts</p>
    <h2 class="section-heading__title">최근 포스트</h2>
    <p class="section-heading__description">운영 이슈 해결 사례와 기술 실험 기록을 최신 순으로 확인할 수 있습니다.</p>
  </div>
  <div class="entry-grid home-posts-grid">
    {% for post in posts limit:3 %}
      <article class="entry-card">
        <div class="entry-card__meta">
          <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
          {% if post.categories %}<span class="badge badge-secondary">{{ post.categories | join: ", " }}</span>{% endif %}
          <span class="badge">{{ post.version | default: "v1.0" }}</span>
        </div>
        <h3 class="entry-card__title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h3>
        <p class="entry-card__excerpt">{{ post.content | split: "<!--more-->" | first | strip_html | strip_newlines | truncate: 140 }}</p>
        <a class="entry-card__cta" href="{{ post.url | prepend: site.baseurl }}">자세히 보기 →</a>
      </article>
    {% endfor %}
  </div>
</section>

<section class="home-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Featured Series</p>
    <h2 class="section-heading__title">주요 시리즈</h2>
    <p class="section-heading__description">학습 경로 중심으로 시리즈 엔트리를 묶어 접근성을 높였습니다.</p>
  </div>
  <div class="series-grid home-series-grid">
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/istio-in-action/">Istio IN ACTION</a></h3>
      <p class="series-card__description">서비스 메시 핵심 개념부터 보안, 트래픽 제어, 문제 해결까지 단계적으로 정리한 시리즈입니다.</p>
      <div class="series-card__foot">
        {% assign latest = istio_series_entries | sort: "date" | reverse | first %}
        <span>{{ istio_series_entries | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/make-container-without-docker/">도커 없이 컨테이너 만들기</a></h3>
      <p class="series-card__description">컨테이너 인터널과 리눅스 네임스페이스를 실습 중심으로 깊게 다룬 콘텐츠입니다.</p>
      <div class="series-card__foot">
        <span>{{ container_series_entries | size }} entries</span>
        {% assign latest = container_series_entries | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">쿠버네티스 딥다이브</a></h3>
      <p class="series-card__description">쿠버네티스 구성 요소를 운영 관점에서 분석하고 디버깅 포인트를 정리했습니다.</p>
      <div class="series-card__foot">
        <span>{{ kubernetes_series_entries | size }} entries</span>
        {% assign latest = kubernetes_series_entries | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
  </div>
</section>

<section class="home-section">
  <div class="home-about-panel">
    <div>
      <h2 class="home-about-panel__title">About Sam</h2>
      <p class="home-about-panel__text">
        대용량 분산 시스템과 클라우드 플랫폼 구축/운영 경험을 바탕으로, 기술 선택의 배경과 실무 적용 과정을
        재사용 가능한 형태로 기록합니다.
      </p>
      <div class="button-row button-row--offset">
        <a class="button button--primary" href="{{ site.baseurl }}/about/">프로필 보기</a>
      </div>
    </div>
    <div class="home-about-panel__meta">
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Core Domains</p>
        <p class="home-about-panel__meta-value">Security · Search · Cloud · SRE</p>
      </div>
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Current Focus</p>
        <p class="home-about-panel__meta-value">Cloud Native Architecture & Platform Engineering</p>
      </div>
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Contact</p>
        <p class="home-about-panel__meta-value">{{ site.email }}</p>
      </div>
    </div>
  </div>
</section>
