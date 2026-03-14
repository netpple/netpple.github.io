---
layout: page
title: Series
permalink: /docs/
description: 주제별 시리즈와 엔트리를 빠르게 탐색할 수 있는 허브
---

{% assign sorted_docs = site.docs | sort: "date" | reverse %}
{% assign istio_docs = site.docs | where: "label", "istio in action" | sort: "date" | reverse %}
{% assign docker_docs = site.docs | where: "label", "도커 없이 컨테이너 만들기" | sort: "date" | reverse %}
{% assign kube_docs = site.docs | where: "label", "쿠버네티스 딥다이브" | sort: "date" | reverse %}
{% assign ddd_docs = site.docs | where: "label", "데이터중심 애플리케이션" | sort: "date" | reverse %}
{% assign querypie_docs = site.docs | where: "label", "쿼리파이 핸즈온" | sort: "date" | reverse %}

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Series Navigation</p>
    <h2 class="section-heading__title">시리즈 빠른 이동</h2>
    <p class="section-heading__description">전체 {{ sorted_docs | size }}개 시리즈 엔트리를 주제별로 묶어 빠르게 이동할 수 있도록 정리했습니다.</p>
  </div>
  <div class="chip-row">
    <a class="chip" href="#series-istio">Istio IN ACTION · {{ istio_docs | size }} entries</a>
    <a class="chip" href="#series-container">도커 없이 컨테이너 만들기 · {{ docker_docs | size }} entries</a>
    <a class="chip" href="#series-kubernetes">쿠버네티스 딥다이브 · {{ kube_docs | size }} entries</a>
    <a class="chip" href="#series-data">데이터 중심 애플리케이션 설계 · {{ ddd_docs | size }} entries</a>
    <a class="chip" href="#series-querypie">쿼리파이 핸즈온 · {{ querypie_docs | size }} entry</a>
  </div>
</section>

<section class="page-section">
  <div class="section-heading">
    <p class="section-heading__kicker">Recently Updated</p>
    <h2 class="section-heading__title">최근 업데이트된 시리즈 엔트리</h2>
    <p class="section-heading__description">최근 정리한 엔트리를 먼저 확인한 뒤 필요한 시리즈로 바로 이동할 수 있습니다.</p>
  </div>
  <div class="entry-grid">
    {% for post in sorted_docs limit: 8 %}
      <article class="entry-card entry-card--doc">
        <div class="entry-card__meta">
          {% if post.label %}<span class="badge badge-secondary">{{ post.label | strip }}</span>{% endif %}
          {% if post.date %}<time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>{% endif %}
          <span class="badge">{{ post.version | default: "v1.0" }}</span>
        </div>
        <h3 class="entry-card__title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h3>
        <p class="entry-card__excerpt">
          {% if post.description %}
            {{ post.description | strip_html | strip_newlines | truncate: 170 }}
          {% else %}
            {{ post.content | split: "<!--more-->" | first | strip_html | strip_newlines | truncate: 170 }}
          {% endif %}
        </p>
        <a class="entry-card__cta" href="{{ post.url | prepend: site.baseurl }}">엔트리 열기 →</a>
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
  <div class="track-grid">
    {% assign latest = istio_docs | first %}
    <article id="series-istio" class="track-card">
      <div class="track-card__foot">
        <span>{{ istio_docs | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/istio-in-action/">Istio IN ACTION</a></h3>
      <p class="track-card__description">서비스 메시 핵심 개념부터 보안, 트래픽 제어, 관측성, 트러블슈팅까지 단계적으로 따라갈 수 있는 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for post in istio_docs %}
          <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>{% if post.date %} · {{ post.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/istio-in-action/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = docker_docs | first %}
    <article id="series-container" class="track-card">
      <div class="track-card__foot">
        <span>{{ docker_docs | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/make-container-without-docker/">도커 없이 컨테이너 만들기</a></h3>
      <p class="track-card__description">네임스페이스, cgroup, 파일시스템, 네트워크를 실습 흐름에 맞춰 정리한 깊이 있는 컨테이너 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for post in docker_docs %}
          <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>{% if post.date %} · {{ post.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/make-container-without-docker/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = kube_docs | first %}
    <article id="series-kubernetes" class="track-card">
      <div class="track-card__foot">
        <span>{{ kube_docs | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">쿠버네티스 딥다이브</a></h3>
      <p class="track-card__description">핵심 컴포넌트 동작 원리와 운영 디버깅 포인트를 빠르게 순회할 수 있도록 구성한 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for post in kube_docs %}
          <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>{% if post.date %} · {{ post.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/deepdive-into-kubernetes/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = ddd_docs | first %}
    <article id="series-data" class="track-card">
      <div class="track-card__foot">
        <span>{{ ddd_docs | size }} entries</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/data-intensive-application-design/">데이터 중심 애플리케이션 설계</a></h3>
      <p class="track-card__description">복제, 파티셔닝, 트랜잭션, 분산 시스템 합의를 운영 관점으로 연결해 읽을 수 있는 학습 시리즈입니다.</p>
      <ol class="entry-card__list">
        {% for post in ddd_docs %}
          <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>{% if post.date %} · {{ post.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/data-intensive-application-design/">시리즈 시작점 보기 →</a>
    </article>

    {% assign latest = querypie_docs | first %}
    <article id="series-querypie" class="track-card">
      <div class="track-card__foot">
        <span>{{ querypie_docs | size }} entry</span>
        {% if latest %}<span>Latest: {{ latest.date | date: "%Y.%m.%d" }}</span>{% endif %}
      </div>
      <h3 class="track-card__title"><a href="{{ site.baseurl }}/docs/querypie-handson/multiple-kubernetes-with-querypie-kac/">쿼리파이 핸즈온</a></h3>
      <p class="track-card__description">여러 Kubernetes 클러스터를 QueryPie KAC로 연결하는 실습형 엔트리를 별도 시리즈로 분리해 탐색성을 높였습니다.</p>
      <ol class="entry-card__list">
        {% for post in querypie_docs %}
          <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a>{% if post.date %} · {{ post.date | date: "%Y.%m.%d" }}{% endif %}</li>
        {% endfor %}
      </ol>
      <a class="entry-card__cta" href="{{ site.baseurl }}/docs/querypie-handson/multiple-kubernetes-with-querypie-kac/">엔트리 바로 보기 →</a>
    </article>
  </div>
</section>

<p class="section-note">제목이나 키워드 기준의 빠른 탐색은 <a href="{{ site.baseurl }}/search/">Search</a>에서 바로 수행할 수 있습니다.</p>
