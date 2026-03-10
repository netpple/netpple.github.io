---
layout: page
title: Documentation
permalink: /docs/
description: 시리즈 중심으로 구성한 기술 문서 허브
---

{% assign sorted_docs = site.docs | sort: "date" | reverse %}
{% assign istio_docs = site.docs | where: "label", "istio in action" %}
{% assign docker_docs = site.docs | where: "label", "도커 없이 컨테이너 만들기" %}
{% assign kube_docs = site.docs | where: "label", "쿠버네티스 딥다이브" %}
{% assign ddd_docs = site.docs | where: "label", "데이터중심 애플리케이션" %}

<section class="home-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Document Tracks</p>
    <h2 class="section-heading__title">핵심 학습 경로</h2>
    <p class="section-heading__description">주제별 시리즈를 먼저 선택한 뒤 상세 문서로 들어가는 구조입니다.</p>
  </div>
  <div class="track-grid">
    <article class="track-card">
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/istio-in-action">Istio IN ACTION</a></h3>
      <p class="track-card__description">서비스 메시 트래픽 제어, 보안, 관측성, 트러블슈팅까지 실습 중심으로 정리했습니다.</p>
      <div class="track-card__foot">
        <span>{{ istio_docs | size }} docs</span>
        {% assign latest = istio_docs | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="track-card">
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/make-container-without-docker">도커 없이 컨테이너 만들기</a></h3>
      <p class="track-card__description">네임스페이스, cgroup, 파일시스템, 네트워크를 이해하기 위한 깊이 있는 자료입니다.</p>
      <div class="track-card__foot">
        <span>{{ docker_docs | size }} docs</span>
        {% assign latest = docker_docs | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="track-card">
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/deepdive-into-kubernetes">쿠버네티스 딥다이브</a></h3>
      <p class="track-card__description">핵심 컴포넌트 동작 원리, 디버깅 전략, 운영 체크포인트를 정리했습니다.</p>
      <div class="track-card__foot">
        <span>{{ kube_docs | size }} docs</span>
        {% assign latest = kube_docs | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
    <article class="track-card">
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/data-intensive-application-design/">데이터 중심 애플리케이션 설계</a></h3>
      <p class="track-card__description">복제, 파티셔닝, 트랜잭션, 분산 시스템 합의를 운영 관점으로 정리한 학습 노트입니다.</p>
      <div class="track-card__foot">
        <span>{{ ddd_docs | size }} docs</span>
        {% assign latest = ddd_docs | sort: "date" | reverse | first %}
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
    </article>
  </div>
</section>

<section>
  <div class="section-heading">
    <p class="section-heading__kicker">All Documentation</p>
    <h2 class="section-heading__title">전체 문서 목록</h2>
  </div>
  <div class="entry-grid">
    {% for post in sorted_docs %}
      <article class="entry-card entry-card--doc">
        <div class="entry-card__meta">
          {% if post.label %}<span class="badge badge-secondary">{{ post.label }}</span>{% endif %}
          {% if post.date %}<time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>{% endif %}
          <span class="badge">{{ post.version | default: "v1.0" }}</span>
        </div>
        <h3 class="entry-card__title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h3>
        <p class="entry-card__excerpt">
          {% if post.description %}
            {{ post.description | strip_html | strip_newlines | truncate: 220 }}
          {% else %}
            {{ post.content | split: "<!--more-->" | first | strip_html | strip_newlines | truncate: 220 }}
          {% endif %}
        </p>
        <a class="entry-card__cta" href="{{ post.url | prepend: site.baseurl }}">문서 보기 →</a>
      </article>
    {% endfor %}
  </div>
</section>
