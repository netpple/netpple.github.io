---
title: 6편.오버레이 네트워크(1)
version: v1.0
label: 도커 없이 컨테이너 만들기
description: 분산환경에서 컨테이너 간의 통신은 어떻게 이루어 지는 것일까요? 3,4편에서는 호스트 안에 가상네트워크를 만들어보았습니다. 6편에서는 이를 바탕으로 분산환경에서 호스트 간에 가상 네트워크로 통신이 가능하도록 만들어 봅니다. 이 방법은 실제 쿠버네티스 flannel 등의 CNI에서 사용하고 있는 vxlan 기반의 오버레이 네트워크 구성을 다룹니다.     
date: 2021-05-11 22:38:00 +09:00
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-6.png
badges:
- type: light
  tag: new
histories:
- date: 2021-05-11 22:38:00 +09:00
  description: 최초 등록
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vQq7lW_ddzlHo3j0azsgcSj3ab9MZqVIMbtQA0xRWp14qLpR8kC3TYt1fv_jvwXsuBlYrxVSlyPCnTb/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/10JRQpeRHKhrl_FS-IWyCENRF9mjedXlxZbX8o0MEoFk/edit?usp=sharing){:target="_blank"}

### 환경 구성
git: [https://github.com/netpple/make-container-without-docker/tree/overlay-nw](https://github.com/netpple/make-container-without-docker/tree/overlay-nw){:target="_blank"}

Git clone
```bash
$ git clone https://github.com/netpple/make-container-without-docker.git
```

VM 생성
```bash
$ cd make-container-without-docker
$ git checkout overlay-nw
$ vagrant up
```

VM 확인
```bash
$ vagrant status
```

VM 접속
```bash
### 터미널#1 접속
$ vagrant ssh ubuntu1804

### 터미널#2 접속
$ vagrant ssh ubuntu1804-2

```