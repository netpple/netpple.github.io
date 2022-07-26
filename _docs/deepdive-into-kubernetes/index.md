---
title: 쿠버네티스 딥다이브
date: 2022-05-20 07:25:00 +09:00
tags:
 - kubernetes
 - container
 - apiserver
 - scheduler
 - controller
 - kubelet
 - etcd
 - kubeproxy
description: 목차 안내
rightpanel: true
---

# 쿠버네티스 딥다이브 


## 시작하며 ..
쿠버네티스 deep dive  분석스터디를 시작해 보려합니다.
아래와 같은 "당찬" 목표를 가지고 있습니다 :-)

쿠버네티스를 코드레벨에서  deep 하게 이해하고 실무에 활용
- 클러스터 운영 및 장애 응대에 활용
- 익스텐션 포인트(오퍼레이터, 커스텀 스케쥴러, API서버 익스텐션 등)를 이해하고 개발에 활용
- "대용량" 클러스터 운영 역량 확보

## 목차

{% assign docs = site.docs | where:'label', '쿠버네티스 딥다이브' %}

{% for post in docs %}
### [{{ post.title }}]({{ post.url }})

![{{ post.image }}]({{ post.image }}){:width="200"}{:.align-left}

<span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
{% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
<span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>  
{{ post. description }}


{% endfor %}