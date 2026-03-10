---
layout: default
title: Hello, World
permalink: /
homepage: true
comments: false
---

<section class="home-hero">
  <p class="home-eyebrow">NETPPLE TECH ARCHIVE</p>
  <h1>Hello, World.</h1>
  <p class="home-lead">
    Sam의 기술 노트입니다. Kubernetes, Istio, Container Internals를 실무 관점으로 정리하며
    광고나 유료 멤버십 없이 계속 무료로 운영합니다.
  </p>
  <div class="home-cta">
    <a class="btn btn-primary btn-lg home-btn" href="{{ site.baseurl }}/news/">최신 글 보기</a>
    <a class="btn btn-outline-light btn-lg home-btn" href="{{ site.baseurl }}/docs/istio-in-action">Istio IN ACTION</a>
  </div>
  <div class="home-meta">
    <span>Since 2021</span>
    <span>Jekyll + GitHub Pages</span>
    <span>Always Free</span>
  </div>
</section>

<section class="home-section">
  <h2>지금 바로 시작하기</h2>
  <div class="home-card-grid">
    <a class="home-card" href="{{ site.baseurl }}/news/">
      <p class="home-card-kicker">Posts</p>
      <h3>최신 기술 글 읽기</h3>
      <p>최근 작성한 아티클을 빠르게 확인할 수 있습니다.</p>
    </a>
    <a class="home-card" href="{{ site.baseurl }}/docs/make-container-without-docker">
      <p class="home-card-kicker">Series</p>
      <h3>도커 없이 컨테이너 만들기</h3>
      <p>리눅스 네임스페이스와 컨테이너 내부 구조를 단계별로 설명합니다.</p>
    </a>
    <a class="home-card" href="{{ site.baseurl }}/about">
      <p class="home-card-kicker">About</p>
      <h3>작성자 소개</h3>
      <p>블로그 운영 방향과 활동 정보를 확인할 수 있습니다.</p>
    </a>
  </div>
</section>

{% assign latest_posts = site.posts | where_exp:'post', 'post.excluded_in_search != true' %}
{% if latest_posts.size > 0 %}
<section class="home-section">
  <h2>새로운 글</h2>
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
  <h2>학습 트랙</h2>
  <div class="home-card-grid home-track-grid">
    <a class="home-track" href="{{ site.baseurl }}/docs/istio-in-action">
      <h3>Istio IN ACTION</h3>
      <p>서비스 메시 아키텍처와 운영 패턴을 실습 중심으로 정리한 시리즈입니다.</p>
    </a>
    <a class="home-track" href="{{ site.baseurl }}/docs/make-container-without-docker">
      <h3>도커 없이 컨테이너 만들기</h3>
      <p>컨테이너 런타임의 기본 원리를 커널 레벨로 따라가며 학습합니다.</p>
    </a>
    <a class="home-track" href="{{ site.baseurl }}/docs/deepdive-into-kubernetes">
      <h3>쿠버네티스 딥다이브</h3>
      <p>kube-apiserver부터 kubelet까지 핵심 컴포넌트를 깊게 다룹니다.</p>
    </a>
  </div>
</section>

<section class="home-section home-freeops">
  <h2>계속 무료로 운영합니다</h2>
  <ul class="home-free-list">
    <li>GitHub Pages 기반 정적 배포로 호스팅 비용 없이 운영</li>
    <li>Jekyll 단일 저장소 구조로 콘텐츠 유지보수 단순화</li>
    <li>광고/유료 구독/로그인 없이 누구나 접근 가능한 공개 아카이브</li>
  </ul>
  <p class="home-free-note">
    운영 구조를 복잡하게 키우지 않고, 글 품질과 업데이트 주기에 집중하겠습니다.
  </p>
</section>
