---
title: Istio IN ACTION
date: 2022-05-20 07:25:00 +09:00
description: 목차 안내
toc: 0
rightpanel: true
image: https://netpple.github.io/docs/assets/img/istio-in-action-book.png
tags:
- istio
- envoy
- kubernetes
- container
---

# {{ page.title }}

## 시작하며 ..
Istio IN ACTION (Christian Posta, Rinor Maloku - 2022 by Manning) 책을 공부하면서 정리한 내용입니다 

istio 를 통한 서비스 메시에 대한 이해와 활용에 초점을 두었습니다 
- 애플리케이션 네트워크 트래픽 제어 
- 애플리케이션 네트워크 탄력적 운용   
- 네트워크 Observability 확보 
- 애플리케이션 네트워크 Securing

<img src="/docs/assets/img/istio-in-action/istio-in-action-book.png" width="320"/>

## 목차

{% assign docs = site.docs | where:'label', 'istio in action' | sort:'toc' %}

{% for post in docs %}
### [{{ post.title }}]({{ post.url }})

![{{ post.image }}]({{ post.image }}){:width="200"}{:.align-left}

<span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
{% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
<span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>  
<b>{{ post. description }}</b>  
{{ post.content | split:'<!--more-->' | first }}
{% endfor %}