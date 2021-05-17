---
title: 도커 없이 컨테이너 만들기
date: 2021-04-20 07:25:00 +09:00
tags: 
 - container
 - namespace
 - cgroup
 - chroot
 - pivot_root 
 - overlayfs
 - overlaynw
description: 목차 및 실습환경 구성안내
rightpanel: true
---

# 도커 없이 컨테이너 만들기


## 시작하며 ..

지난 2년간 카카오 검색시스템의 클라우드 전환을 준비하면서 컨테이너 기술 관련하여 학습하고 교육했던 내용들을 정리하였습니다.  
검색은 massive한 데이터와 트래픽을 다루는 대용량 분산처리 시스템인만큼 서비스 도입을 위해서는 컨테이너 인터널과 네트워킹,
오케스트레이션에 대한 깊이 있는 이해가 필수적으로 수반되어야 하였습니다.    
컨테이너를 좀 더 깊이 이해하고 실전에 활용할 수 있도록 컨테이너 관련 내용과 더불어 필요한 배경지식과 실습을 포함하였습니다.  
컨테이너에 관심있으시거나 시작해보려고 하시는 분들, 그리고 deep~하게 파보고 싶은 분들 모두 도움이 되시리라 생각됩니다

## 목차

{% assign docs = site.docs | where:'label', '도커 없이 컨테이너 만들기' %}

{% for post in docs %}
### [{{ post.title }}]({{ post.url }})

![{{ post.image }}]({{ post.image }}){:width="200"}{:.align-left}

<span class="badge badge-info">{{ post.version | default: "v1.0" }}</span>
{% if post.badges %}{% for badge in post.badges %}<span class="badge badge-{{ badge.type }}">{{ badge.tag }}</span>{% endfor %}{% endif %}
<span class="post-date" style="font-style: italic;">{{ post.date | date: "%m/%d %H:%m, %Y" }}</span>  
{{ post. description }}


{% endfor %}

### 8편 Pid namespace

준비 중입니다

### 9편 User namespace

준비 중입니다

### 10편 RunC

준비 중입니다

## 실습 환경

### 사전 준비 

- 맥 환경에서 VirtualBox + Vagrant 기반으로 테스트되고 준비되었습니다.
  - 맥 이외의 OS(윈도우,우분투,...)도 괜찮습니다만 원활한 실습을 위해서 "Vagrant" 사용은 권장드립니다
    
  - 혹시, Vagrant 사용이 어려운 분들은 우분투 18.04버전 환경을 준비하고 "실습환경 구성"의 Vagrantfile을 참고하여 필요한 프로그램들을 설치해주세요
  

### 환경 구성

Git clone
```bash
$ git clone https://github.com/netpple/make-container-without-docker.git
```

VM 생성
```bash
$ cd make-container-without-docker
$ vagrant up
```

VM 상태
```bash
$ vagrant status
Current machine states:

ubuntu1804                running (virtualbox)
```

VM 접속
```bash
$ vagrant ssh ubuntu1804

vagrant@ubuntu1804:~$
```

참고 (Vagrant 명령어)
```bash
# VM 중지와 재개
$ vagrant suspend
$ vagrant resume
# VM 종료와 기동
$ vagrant halt
$ vagrant up
# VM 재기동
$ vagrant reload
# VM 재설정/기동
$ vagrant reload --provision
```

### 실습 계정
실습은 root로 진행합니다
```shell
vagrant@ubuntu1804:~$ sudo -Es
root@ubuntu1804:~#
```

모든 준비가 끝났습니다. 이제 즐겨볼까요 :-)