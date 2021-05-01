---
title: 도커 없이 컨테이너 만들기  
tags: 
 - container
 - namespace
 - cgroup
 - chroot
 - pivot_root 
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

### [1편.컨테이너 인터널 (1)](container-internal-1)

![/docs/assets/img/make-container-without-docker-intro-1.png](/docs/assets/img/make-container-without-docker-intro-1.png){:width="200"}{:.align-left}

컨테이너란 무엇일까요? 마법 상자를 열어 보도록 하겠습니다.제가 처음 도커를 접했을 때는 "vmware, virtualbox 와 뭐가 다르지?" 
vmware처럼 OS이미지도 있었고 터미널 환경에서 동작하는 모습 역시 똑같아 보였거든요.그렇게 시작하게 되었습니다. 
도커는 무엇이고 컨테이너는 무엇인지 실체가 궁금하더라구요


### [2편.컨테이너 인터널 (2)](container-internal-2)

![/docs/assets/img/make-container-without-docker-intro-2.png](/docs/assets/img/make-container-without-docker-intro-2.png){:width="200"}{:.align-left}

컨테이너의 발전과정을 살펴봅니다. 컨테이너가 신기술, 유행 같은 것이라고 생각했었는데, 나름 역사와 사연이 많은 친구네요 :-)  
chroot로 시작하여 지금의 컨테이너로 성장하기까지 어떤 문제들이 있었고 그러한 문제들을 어떻게 해결하여 왔는지를 다뤄봅니다.


### [3편.네트워크 네임스페이스 (1)](network-namespace-1)

![/docs/assets/img/make-container-without-docker-intro-3.png](/docs/assets/img/make-container-without-docker-intro-3.png){:width="200"}{:.align-left}

서비스 운영 중에 네트웍 장애를 만나면 곤란하곤 하는데요.     
컨테이너는 가상 네트웍을 기반으로 하고 있고 이 위에서 컨테이너 간의 통신이 어떻게 이루어지는지를 잘 이해하고 있으면 개발과 운영에 많은 도움이 됩니다.  
network namespace 3,4편 그리고 overlay network 7,8편에서 다룰 예정입니다.


### 4편 network namespace (2)

준비 중입니다 

### 5편 Mount Namespace

준비 중입니다

### 6편 Overlay Filesystem

준비 중입니다

### 7편 Overlay Network (1)

준비 중입니다

### 8편 Overlay Network (2)

준비 중입니다

### 9편 Pid namespace

준비 중입니다

### 10편 User namespace

준비 중입니다

### 11편 RunC

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