---
layout: page
title: Welcome to Netpple
permalink: /
---
## 새로운 글 
{% if site.posts.size > 0 %}
<div class="section-index">
    <hr class="panel-line">
    {% for post in site.posts %}
    <div class="entry">
    <h5><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}
        <span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
        {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
        </a> <span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>
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

{% if site.docs.size > 0 %}
{% assign docs = site.docs | where:'label', '도커 없이 컨테이너 만들기' %}

<div class="section-index">
    <hr class="panel-line">
    {% for post in docs reversed  %}
    <div class="entry">
    <p><a href="{{ post.url | prepend: site.baseurl }}"><img src="{{ post.image }}" width="100%"/></a></p>
    <h5><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}
        <span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
        {% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
        </a> <span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>
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