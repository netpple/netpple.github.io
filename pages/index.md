---
layout: page
title: Welcome to Netpple
permalink: /
---
#### 공지
*(6/2) NEW 👍🏻 [Istio Performance](/docs/istio-in-action/Istio-ch11-performance){:target="_blank"}*  


## 새로운 글 
{% if site.posts.size > 0 %}
{% assign posts = site.posts | where_exp:'post', 'post.excluded_in_search != true' %}
<div class="section-index">
    <hr class="panel-line">
    {% for post in posts limit:3 %}
    <p>
    <span class="post-title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></span>
    <span class="post-date">{{ post.date | date: "%y/%m/%d %H:%m" }}</span>
    {{ post.content | split:'<!--more-->' | first }}
    </p>
    {% endfor %}
</div>
{% endif %}

{% if site.docs.size > 0 %}
## Istio IN ACTION
{% assign docs = site.docs | where_exp:'post', 'post.label == "istio in action"'%}
<div class="section-index">
    <hr class="panel-line">
    {%assign count = 0 %}
    {% for post in docs reversed %}
        {% if count >= 3 %}
            {% break %}
        {% endif %}
        {% assign count = count | plus: 1 %}
    <p>
        <span class="post-title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}
            <span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
            {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}</a>
        </span>
        <span class="post-date">{{ post.date | date: "%y/%m/%d %H:%m" }}</span>
        {{ post.content | split:'<!--more-->' | first }}
    </p>
    {% endfor %}
</div>

## 도커 없이 컨테이너 만들기
{% assign docs = site.docs | where:'label', '도커 없이 컨테이너 만들기' %}
<div class="section-index">
    <hr class="panel-line">
    {%assign count = 0 %}
    {% for post in docs reversed %}
        {% if count >= 1 %}
            {% break %}
        {% endif %}
        {% assign count = count | plus: 1 %}    <div class="entry">
    <p><a href="{{ post.url | prepend: site.baseurl }}"><img src="{{ post.image }}" width="100%"/></a></p>
    <h5><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}
        <span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
        {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
        </a> 
    </h5>
    <p>
    {{ post.description }}<br/>
    {% if post.histories %}{% for history in post.histories %}
        <span>- {{ history.description }}</span>
        <span class="post-date" style="font-style: italic;">{{ history.date | date: "%m/%d %H:%m, %Y" }}</span><br/>
    {% endfor %}{% endif %}
    </p>
    </div>{% endfor %}
</div>

## 쿠버네티스 딥다이브
{% assign docs = site.docs | where:'label', '쿠버네티스 딥다이브' %}
<div class="section-index">
    <hr class="panel-line">
    {%assign count = 0 %}
    {% for post in docs reversed %}
        {% if count >= 1 %}
            {% break %}
        {% endif %}
        {% assign count = count | plus: 1 %}    
    <div class="entry">
        <p><a href="{{ post.url | prepend: site.baseurl }}"><img src="{{ post.image }}" width="100%"/></a></p>
        <h5><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}
            <span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
            {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
            </a> <span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%M, %Y" }}</span>
        </h5>
        <p>
        {{ post.description }}<br/>
        {% if post.histories %}{% for history in post.histories %}
            <span>- {{ history.description }}</span>
            <span class="post-date" style="font-style: italic;">{{ history.date | date: "%m/%d %H:%m, %Y" }}</span><br/>
        {% endfor %}{% endif %}
        </p>
    </div>{% endfor %}
</div>
{% endif %}

