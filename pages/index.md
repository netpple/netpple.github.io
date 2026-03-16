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
{% assign series_count = 0 %}
{% if istio_series_entries.size > 0 %}{% assign series_count = series_count | plus: 1 %}{% endif %}
{% if container_series_entries.size > 0 %}{% assign series_count = series_count | plus: 1 %}{% endif %}
{% if kubernetes_series_entries.size > 0 %}{% assign series_count = series_count | plus: 1 %}{% endif %}
{% if data_series_entries.size > 0 %}{% assign series_count = series_count | plus: 1 %}{% endif %}
{% if querypie_series_entries.size > 0 %}{% assign series_count = series_count | plus: 1 %}{% endif %}
{% assign all_updates = posts | concat: site.docs %}
{% assign latest_entry = all_updates | sort: "date" | reverse | first %}
{% assign now_unix = site.time | date: "%s" | plus: 0 %}
{% assign recent_updates = 0 %}
{% for item in all_updates %}
  {% if item.date %}
    {% assign item_unix = item.date | date: "%s" | plus: 0 %}
    {% assign age_seconds = now_unix | minus: item_unix %}
    {% if age_seconds >= 0 and age_seconds <= 31536000 %}
      {% assign recent_updates = recent_updates | plus: 1 %}
    {% endif %}
  {% endif %}
{% endfor %}
{% assign featured_post_install = posts | where: "title", "DIY! k8s 1.26 설치하기" | first %}
{% assign featured_post_etcd = posts | where: "title", "What is etcd" | first %}
{% assign featured_series_istio = site.docs | where: "title", "Istio IN ACTION" | first %}
{% assign featured_series_container = site.docs | where: "title", "도커 없이 컨테이너 만들기" | first %}
{% assign querypie_entry_count = querypie_series_entries | size %}
{% assign querypie_entry_label = "Series entries" %}
{% if querypie_entry_count == 1 %}
  {% assign querypie_entry_label = "Series entry" %}
{% endif %}

<section class="home-hero">
  <div class="home-hero__grid">
    <div class="home-hero__content">
      <p class="home-hero__eyebrow">Tech Journal</p>
      <h1 class="home-hero__title">클라우드 네이티브와 분산 시스템 운영 지식을 구조적으로 기록합니다.</h1>
      <p class="home-hero__description">
        쿠버네티스, 컨테이너, 서비스 메시, 분산 시스템 운영 경험을 시리즈와 포스트 형식으로 정리한 기술 아카이브입니다.
        첫 방문자도 사이트 규모와 대표 탐색 경로를 한 번에 파악할 수 있도록 핵심 지표와 큐레이션을 함께 제공합니다.
      </p>
      <div class="home-hero__actions button-row">
        <a class="button button--primary" href="{{ site.baseurl }}/docs/">시리즈 허브 보기</a>
        <a class="button button--ghost" href="{{ site.baseurl }}/news/">대표 포스트 보기</a>
      </div>
      <div class="home-stats">
        <div class="home-stats__item">
          <p class="home-stats__label">Posts</p>
          <p class="home-stats__value">{{ posts | size }}</p>
          <p class="home-stats__meta">운영 기록과 기술 메모</p>
        </div>
        <div class="home-stats__item">
          <p class="home-stats__label">Series</p>
          <p class="home-stats__value">{{ series_count }}</p>
          <p class="home-stats__meta">현재 운영 중인 시리즈 묶음</p>
        </div>
        <div class="home-stats__item">
          <p class="home-stats__label">Recent 1Y</p>
          <p class="home-stats__value">{{ recent_updates }}</p>
          <p class="home-stats__meta">최근 1년 내 업데이트</p>
        </div>
        <div class="home-stats__item">
          <p class="home-stats__label">Latest</p>
          <p class="home-stats__value">{% if latest_entry %}{{ latest_entry.date | date: "%Y.%m.%d" }}{% else %}-{% endif %}</p>
          <p class="home-stats__meta">가장 최근 공개된 콘텐츠</p>
        </div>
      </div>
    </div>
    <div class="home-hero__featured">
      <div class="home-featured-heading">
        <p class="home-featured-heading__eyebrow">Recommended Routes</p>
        <h2 class="home-featured-heading__title">바로 둘러볼 콘텐츠</h2>
      </div>
      <div class="home-feature-grid">
        {% if featured_post_install %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge badge-secondary">추천 포스트</span>
              <span>Kubernetes</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ featured_post_install.url | prepend: site.baseurl }}">{{ featured_post_install.title }}</a></h2>
            <p class="home-feature-card__topic">주제: 실습 중심의 쿠버네티스 설치와 운영 환경 구성</p>
            <p class="home-feature-card__reason">직접 클러스터를 올려보며 운영 감각을 확인하기 좋은 대표 입문 포스트입니다.</p>
            <a class="home-feature-card__cta" href="{{ featured_post_install.url | prepend: site.baseurl }}">포스트 보기 →</a>
          </article>
        {% endif %}
        {% if featured_post_etcd %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge badge-secondary">추천 포스트</span>
              <span>Distributed Systems</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ featured_post_etcd.url | prepend: site.baseurl }}">{{ featured_post_etcd.title }}</a></h2>
            <p class="home-feature-card__topic">주제: 쿠버네티스 제어면의 핵심 저장소 이해</p>
            <p class="home-feature-card__reason">분산 시스템 운영 관점에서 왜 etcd가 중요한지 빠르게 잡아주는 기초 글입니다.</p>
            <a class="home-feature-card__cta" href="{{ featured_post_etcd.url | prepend: site.baseurl }}">포스트 보기 →</a>
          </article>
        {% endif %}
        {% if featured_series_istio %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge">추천 시리즈</span>
              <span>Service Mesh</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ featured_series_istio.url | prepend: site.baseurl }}">{{ featured_series_istio.title }}</a></h2>
            <p class="home-feature-card__topic">주제: 트래픽 제어, 관측성, 보안, 트러블슈팅</p>
            <p class="home-feature-card__reason">서비스 메시를 실무 관점으로 단계별 학습할 수 있는 대표 시리즈입니다.</p>
            <a class="home-feature-card__cta" href="{{ featured_series_istio.url | prepend: site.baseurl }}">시리즈 보기 →</a>
          </article>
        {% endif %}
        {% if featured_series_container %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge">추천 시리즈</span>
              <span>Container Internals</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ featured_series_container.url | prepend: site.baseurl }}">{{ featured_series_container.title }}</a></h2>
            <p class="home-feature-card__topic">주제: namespace, filesystem, networking, hands-on</p>
            <p class="home-feature-card__reason">발표와 실습 자료의 기반이 되는 시리즈로 컨테이너 내부 동작을 깊게 다룹니다.</p>
            <a class="home-feature-card__cta" href="{{ featured_series_container.url | prepend: site.baseurl }}">시리즈 보기 →</a>
          </article>
        {% endif %}
      </div>
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
    <p class="section-heading__description">학습 경로 중심으로 시리즈를 묶어 접근성을 높였습니다.</p>
  </div>
  <div class="series-grid home-series-grid">
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/istio-in-action/">Istio IN ACTION</a></h3>
      <p class="series-card__description">서비스 메시 핵심 개념부터 보안, 트래픽 제어, 문제 해결까지 단계적으로 정리한 시리즈입니다.</p>
      <div class="series-card__foot">
        {% assign latest = istio_series_entries | sort: "date" | reverse | first %}
        <span>{{ istio_series_entries | size }} Series entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/make-container-without-docker/">도커 없이 컨테이너 만들기</a></h3>
      <p class="series-card__description">컨테이너 인터널과 리눅스 네임스페이스를 실습 중심으로 깊게 다룬 콘텐츠입니다.</p>
      <div class="series-card__foot">
        {% assign latest = container_series_entries | sort: "date" | reverse | first %}
        <span>{{ container_series_entries | size }} Series entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">쿠버네티스 딥다이브</a></h3>
      <p class="series-card__description">쿠버네티스 구성 요소를 운영 관점에서 분석하고 디버깅 포인트를 정리했습니다.</p>
      <div class="series-card__foot">
        {% assign latest = kubernetes_series_entries | sort: "date" | reverse | first %}
        <span>{{ kubernetes_series_entries | size }} Series entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="series-card">
      <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/data-intensive-application-design/">데이터 중심 애플리케이션 설계</a></h3>
      <p class="series-card__description">복제, 파티셔닝, 트랜잭션, 합의를 운영 관점으로 해석한 학습 노트 시리즈입니다.</p>
      <div class="series-card__foot">
        {% assign latest = data_series_entries | sort: "date" | reverse | first %}
        <span>{{ data_series_entries | size }} Series entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    {% if querypie_series_entries.size > 0 %}
      <article class="series-card">
        <h3 class="series-card__title"><a href="{{ site.baseurl }}/docs/querypie-handson/multiple-kubernetes-with-querypie-kac/">쿼리파이 핸즈온</a></h3>
        <p class="series-card__description">멀티 클러스터 Kubernetes 접근 제어를 실습형으로 정리한 최신 시리즈 엔트리입니다.</p>
        <div class="series-card__foot">
          {% assign latest = querypie_series_entries | sort: "date" | reverse | first %}
          <span>{{ querypie_entry_count }} {{ querypie_entry_label }}</span>
          {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
        </div>
      </article>
    {% endif %}
  </div>
</section>

<section class="home-section">
  <div class="home-about-panel">
    <div>
      <h2 class="home-about-panel__title">About Sam</h2>
      <p class="home-about-panel__text">
        김삼영은 QueryPie CTO로 일하고 있으며, 카카오/카카오엔터프라이즈에서 검색 클라우드와 플랫폼 전환을 이끈 경험을
        바탕으로 운영 지식과 발표 자료를 이 아카이브에 축적하고 있습니다.
      </p>
      <div class="button-row button-row--offset">
        <a class="button button--primary" href="{{ site.baseurl }}/about/">프로필 보기</a>
        <a class="button button--ghost" href="https://www.linkedin.com/in/sam0-kim/" target="_blank" rel="noreferrer noopener">LinkedIn</a>
      </div>
    </div>
    <div class="home-about-panel__meta">
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Current Role</p>
        <p class="home-about-panel__meta-value">QueryPie CTO · 2023 ~ 현재</p>
      </div>
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Career Highlight</p>
        <p class="home-about-panel__meta-value">Kakao / Kakao Enterprise · 2014 ~ 2023</p>
      </div>
      <div class="home-about-panel__meta-item">
        <p class="home-about-panel__meta-label">Talk</p>
        <p class="home-about-panel__meta-value"><a href="https://if.kakao.com/2022/session/104" target="_blank" rel="noreferrer noopener">if(kakao)dev2022 - 도커 없이 컨테이너 만들기</a></p>
      </div>
    </div>
  </div>
</section>
