---
layout: default
title: Hello, World
permalink: /
homepage: true
comments: false
---

<div class="home-shell">
  <section class="home-hero">
    <p class="home-kicker">NETPPLE ENGINEERING ARCHIVE</p>
    <h1>Hello, World.</h1>
    <p class="home-lead">
      김삼영의 기술 블로그입니다. Kubernetes, Istio, Container Internals를 실무 기준으로 기록하고
      GitHub Pages + Jekyll 구조를 유지해 앞으로도 계속 무료로 운영합니다.
    </p>
    <div class="home-cta">
      <a class="home-btn home-btn-primary" href="{{ site.baseurl }}/news/">최신 글 보기</a>
      <a class="home-btn home-btn-ghost" href="{{ site.baseurl }}/docs/istio-in-action/">학습 트랙 시작</a>
    </div>
    <dl class="home-stats">
      <div>
        <dt>운영 시작</dt>
        <dd>2021</dd>
      </div>
      <div>
        <dt>발행 글</dt>
        <dd>{{ site.posts.size }}+</dd>
      </div>
      <div>
        <dt>배포</dt>
        <dd>GitHub Pages</dd>
      </div>
    </dl>
  </section>

  <section class="home-section">
    <div class="home-section-head">
      <p class="home-section-label">Quick Start</p>
      <h2>지금 바로 읽을 수 있는 추천 경로</h2>
    </div>
    <div class="home-card-grid">
      <a class="home-card" href="{{ site.baseurl }}/news/">
        <p class="home-card-kicker">Latest</p>
        <h3>최근 기술 글 모아보기</h3>
        <p>최신 포스트를 날짜 순으로 빠르게 훑을 수 있습니다.</p>
      </a>
      <a class="home-card" href="{{ site.baseurl }}/docs/make-container-without-docker/">
        <p class="home-card-kicker">Core Concepts</p>
        <h3>도커 없이 컨테이너 만들기</h3>
        <p>리눅스 커널 기능으로 컨테이너 원리를 단계별로 정리한 시리즈입니다.</p>
      </a>
      <a class="home-card" href="{{ site.baseurl }}/about/">
        <p class="home-card-kicker">Profile</p>
        <h3>작성자와 운영 방향</h3>
        <p>블로그 운영 원칙, 실무 경험, 발표/활동 이력을 확인할 수 있습니다.</p>
      </a>
    </div>
  </section>

  {% assign latest_posts = site.posts | where_exp:'post', 'post.excluded_in_search != true' %}
  {% if latest_posts.size > 0 %}
  <section class="home-section">
    <div class="home-section-head">
      <p class="home-section-label">New Posts</p>
      <h2>최근 업데이트</h2>
    </div>
    <div class="home-list">
      {% for post in latest_posts limit:4 %}
      <article class="home-list-item">
        <p class="home-list-date">{{ post.date | date: "%Y.%m.%d" }}</p>
        <h3><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h3>
        <p>{{ post.description | default: post.content | strip_html | truncate: 160 }}</p>
      </article>
      {% endfor %}
    </div>
  </section>
  {% endif %}

  <section class="home-section">
    <div class="home-section-head">
      <p class="home-section-label">Learning Tracks</p>
      <h2>깊게 학습할 수 있는 시리즈</h2>
    </div>
    <div class="home-track-grid">
      <a class="home-track" href="{{ site.baseurl }}/docs/istio-in-action/">
        <h3>Istio IN ACTION</h3>
        <p>서비스 메시 아키텍처와 운영 패턴을 실습 중심으로 학습합니다.</p>
      </a>
      <a class="home-track" href="{{ site.baseurl }}/docs/make-container-without-docker/">
        <h3>도커 없이 컨테이너 만들기</h3>
        <p>컨테이너 런타임의 핵심 원리를 커널 레벨에서 이해할 수 있습니다.</p>
      </a>
      <a class="home-track" href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">
        <h3>쿠버네티스 딥다이브</h3>
        <p>제어 플레인부터 노드 컴포넌트까지 구조를 깊이 있게 다룹니다.</p>
      </a>
    </div>
  </section>

  <section class="home-section home-freeops">
    <h2>계속 무료로 운영합니다</h2>
    <ul class="home-free-list">
      <li>정적 사이트(GitHub Pages) 기반으로 호스팅 비용 없이 운영</li>
      <li>Jekyll 단일 저장소로 유지보수 복잡도를 낮춰 콘텐츠 생산에 집중</li>
      <li>광고/유료 멤버십/로그인 없이 누구나 접근 가능한 공개 기술 아카이브 유지</li>
    </ul>
    <p class="home-free-note">
      운영 구조를 단순하게 유지해 더 오래, 안정적으로 지식을 공유하겠습니다.
    </p>
  </section>
</div>
