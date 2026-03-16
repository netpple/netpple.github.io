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
{%- capture series_slug_stream -%}
  {%- for doc in site.docs -%}
    {{- doc.url | split: "/" | slice: 2, 1 | first -}}{%- unless forloop.last -%}|{%- endunless -%}
  {%- endfor -%}
{%- endcapture -%}
{% assign series_count = series_slug_stream | split: "|" | uniq | size %}
{% assign featured_series_istio_url = "/docs/istio-in-action/" %}
{% assign featured_post_install = posts | where: "url", "/2023/k8s-1.26-install/" | first %}

<section class="home-hero">
  <div class="home-hero__content">
    <p class="home-hero__eyebrow">Tech Journal</p>
    <h1 class="home-hero__title">클라우드 네이티브와 분산 시스템 운영 지식을 짧고 선명하게 남깁니다.</h1>
    <p class="home-hero__description">쿠버네티스, 컨테이너, 서비스 메시, 분산 시스템 운영 경험을 Posts와 Series 흐름으로 정리한 기술 아카이브입니다.</p>
    <div class="home-hero__actions button-row">
      <a class="button button--primary" href="{{ site.baseurl }}/docs/">시리즈 허브 보기</a>
      <a class="button button--ghost" href="{{ site.baseurl }}/news/">Posts 둘러보기</a>
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
        <p class="home-stats__meta">대표 학습 경로로 정리한 시리즈</p>
      </div>
    </div>
    <div class="home-hero__quickstart">
      <div class="home-featured-heading">
        <p class="home-featured-heading__eyebrow">Start Here</p>
        <h2 class="home-featured-heading__title">대표 진입점 두 곳만 먼저 보면 됩니다</h2>
      </div>
      <div class="home-feature-grid">
        {% if featured_post_install %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge badge-secondary">추천 포스트</span>
              <span>Kubernetes</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ featured_post_install.url | prepend: site.baseurl }}">{{ featured_post_install.title }}</a></h2>
            <p class="home-feature-card__summary">실습 중심 설치와 운영 환경 구성을 통해 이 아카이브의 실전 톤을 가장 빠르게 파악할 수 있습니다.</p>
            <a class="home-feature-card__cta" href="{{ featured_post_install.url | prepend: site.baseurl }}">포스트 보기 →</a>
          </article>
        {% endif %}
        {% if istio_series_entries.size > 0 %}
          <article class="home-feature-card">
            <div class="home-feature-card__meta">
              <span class="badge">추천 시리즈</span>
              <span>Service Mesh</span>
            </div>
            <h2 class="home-feature-card__title"><a href="{{ site.baseurl }}{{ featured_series_istio_url }}">Istio IN ACTION</a></h2>
            <p class="home-feature-card__summary">트래픽 제어, 관측성, 보안, 트러블슈팅 흐름을 연속적으로 따라갈 수 있는 대표 시리즈입니다.</p>
            <a class="home-feature-card__cta" href="{{ site.baseurl }}{{ featured_series_istio_url }}">시리즈 보기 →</a>
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
    {% for post in posts limit:2 %}
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
        <a class="button button--ghost" href="https://github.com/netpple" target="_blank" rel="noreferrer noopener">GitHub</a>
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
