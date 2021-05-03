---
title: 도커 없이 컨테이너 만들기 2편
description: 1편에 이어 chroot의 탈옥문제를 해결하는 pivot_root를 다루고 남은 문제들을 해결하는 컨테이너의 발전과정에 대해 얘기합니다.
date: 2021-04-27 12:39:00 +09:00
oriurl: /docs/make-container-without-docker/container-internal-2
categories: 도커 없이 컨테이너 만들기
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-2.png
badges:
- type: info
  tag: info-badge
---

컨테이너의 발전과정을 살펴봅니다. 컨테이너가 신기술, 유행 같은 것이라고 생각했었는데, 나름 역사와 사연이 많은 친구네요 :-)  
chroot로 시작하여 지금의 컨테이너로 성장하기까지 어떤 문제들이 있었고 그러한 문제들을 어떻게 해결하여 왔는지를 다뤄봅니다.

![/docs/assets/img/make-container-without-docker-intro-2.png](/docs/assets/img/make-container-without-docker-intro-2.png){:width="30%"}