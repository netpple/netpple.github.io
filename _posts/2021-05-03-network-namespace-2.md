---
title: 도커 없이 컨테이너 만들기 4편
description: 3편에 이어서 네트워크 네임스페이스를 외부 네트워크와 통신이 가능하도록 구성해 봅니다. 그리고 3,4편에서 다룬 내용을 바탕으로 도커 컨테이너의 네트워크 구성과 비교해 봅니다. 
date: 2021-05-03 17:15:00 +09:00
oriurl: /docs/make-container-without-docker/network-namespace-2
categories: 도커 없이 컨테이너 만들기
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-4.png
badges:
- type: info
  tag: info-badge
---

서비스 운영 중에 네트웍 장애를 만나면 곤란하곤 하는데요. 컨테이너는 가상 네트웍을 기반으로 하고 있고 이 위에서 컨테이너 간의
통신이 어떻게 이루어지는지를 잘 이해하고 있으면 개발과 운영에 많은 도움이 됩니다.

![/docs/assets/img/make-container-without-docker-intro-3.png](/docs/assets/img/make-container-without-docker-intro-3.png){:width="30%"}