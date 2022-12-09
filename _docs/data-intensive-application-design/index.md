---
title: 데이터 중심 애플리케이션을 읽고 
date: 2022-05-20 07:25:00 +09:00
tags:
 - replication
 - partitioning
 - consistency
 - consensus
 - transaction
 - distributedsystem
description: 목차 안내  
image: https://netpple.github.io/docs/assets/img/data-intensive-application-design-1.png  
rightpanel: true
---

# 데이터 중심 애플리케이션 

![https://netpple.github.io/docs/assets/img/data-intensive-application-design-1.png](https://netpple.github.io/docs/assets/img/data-intensive-application-design-1.png){:width="400"}


## 시작하며 ..
지난 6개월 간 "데이터 중심 애플리케이션"의 Part2 "분산데이터" 스터디 했던 내용들을 정리하였습니다.  

- 책이 어렵다 보니 진도 빼기 보다는 확실한 이해를 목표로 하였는데요.  
- 그럼에도 아직 부족함을 느낍니다.  
- 많이들 아시는 유명한 책이고 공부하는 분들도 많으실 것 같은데요.   
- 이해하시는데 도움이 될 것 같아 정리한 내용을 공유합니다. 
- 정리한 내용 중 이상한 부분이 있거나 공부하다가 궁금하신 분들은 코멘트 남겨주시면 함께 얘기나눠보시죠.  

## 목차
### Part2. 분산 데이터
{% assign docs = site.docs | where:'label', '데이터중심 애플리케이션' %}

{% for post in docs %}
### [{{ post.title }}]({{ post.url }})
{% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %} 
{{ post. description }}
<span class="post-date" style="font-style: italic; color: #999999">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>


{% endfor %}