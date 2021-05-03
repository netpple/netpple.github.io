---
title: 도커 없이 컨테이너 만들기 1편
date: 2021-04-23 08:25:00 +09:00
description: 컨테이너의 개념을 설명하고 컨테이너의 시작이라 할 수 있는 chroot에 대해 다룹니다.
oriurl: /docs/make-container-without-docker/container-internal-1
categories: 도커 없이 컨테이너 만들기
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-1.png
badges:
- type: info
  tag: info-badge
---

컨테이너란 무엇일까요? 마법 상자를 열어 보도록 하겠습니다.제가 처음 도커를 접했을 때는 "vmware, virtualbox 와 뭐가 다르지?"  
vmware처럼 OS이미지도 있었고 터미널 환경에서 동작하는 모습 역시 똑같아 보였거든요.그렇게 시작하게 되었습니다.  
도커는 무엇이고 컨테이너는 무엇인지 실체가 궁금하더라구요

![/docs/assets/img/make-container-without-docker-intro-1.png](/docs/assets/img/make-container-without-docker-intro-1.png){:width="30%"}