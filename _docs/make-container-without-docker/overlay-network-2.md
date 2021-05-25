---
title: 7편.다이내믹 오버레이 네트워크
version: v1.0
label: 도커 없이 컨테이너 만들기
description: 클라우드 위에서 컨테이너에 가상 IP를 부여하고 이러한 가상 IP대역을 기반으로 컨테이너 간에 통신이 어떻게 가능한 것일까요? 동적으로 오버레이 네트워크를 구성해 봅니다. 지난 시간 가상IP 대역을 기반으로 서로 다른 물리노드 간의 통신을 가능하기 위하여 가상 디바이스를 생성하고 ARP cache와 Bridge FDB 정보를 입력해주고, vxlan 기반의 UDP encapsulation과 터널링을 통하여 가상디바이스의 L2정보를 목적지 노드로 전송하여 통신이 되는 것을 확인하였습니다. 이에 대한 내용을 바탕으로 가상네트워크를 추가하고 통신할 때  커널 이벤트를 캐치하여 동적으로 arp, fdb 갱신처리하여 컨테이너 간에 통신이 가능하도록 구성해 봅니다.      
date: 2021-05-17 23:38:00 +09:00
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-7.png
histories:
- date: 2021-05-17 23:38:00 +09:00
  description: 최초 등록
---
<div class="responsive-wrap">
  <iframe src="https://docs.google.com/presentation/d/e/2PACX-1vSEBNIx-9qSsQk43CVTnSYDIZn2_6aznVIOWi0yibWF_FDqKdzQR0brKN6BuzM7SMmpaC4hJLNtGttt/embed?start=false&loop=false&delayms=3000" frameborder="0" width="100%" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>
</div>

[[슬라이드 보기]](https://docs.google.com/presentation/d/10TCStiRnnvF-IBCGx7hNB4na5YI-CSmxWB6HpG9HCrc/edit?usp=sharing){:target="_blank"}

### 환경 구성  

6편과 동일 합니다.   

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