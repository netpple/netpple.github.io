---
title: 도커 없이 컨테이너 만들기 3편
version: v1.3
description: 네트워크 네임스페이스를 이해하기 위한 네트워크 기초 개념들을 다루고 네트워크 네임스페이 실습과 함께 컨테이너 환경에서의 가상 네트워크 구축이 어떻게 이루어지는지를 학습합니다.
date: 2021-04-29 11:41:00 +09:00
oriurl: /docs/make-container-without-docker/network-namespace-1
categories: 도커 없이 컨테이너 만들기
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-3.png
badges:
- type: info
  tag: updated
histories:
- date: 2021-05-03 21:35:00 +09:00
  description: 실습 안내페이지 업데이트  
---

서비스 운영 중에 네트웍 장애를 만나면 곤란하곤 하는데요. 컨테이너는 가상 네트웍을 기반으로 하고 있고 이 위에서 컨테이너 간의
통신이 어떻게 이루어지는지를 잘 이해하고 있으면 개발과 운영에 많은 도움이 됩니다.

![/docs/assets/img/make-container-without-docker-intro-3.png](/docs/assets/img/make-container-without-docker-intro-3.png){:width="30%"}