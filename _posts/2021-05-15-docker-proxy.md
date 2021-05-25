---
title: docker-proxy
version: v1.0
description: docker-proxy란 무엇이고 왜쓰는가? iptables로도 충분할 것 같은데.. 왜 굳이 프로세스를 띄워서 사용할까요
date: 2021-05-15 08:32 +09:00
categories: container
rightpanel: true
---
### docker-proxy란?

- userland-proxy : userspace에서 동작하는 프록시 서버
    - 도커에서 옵션으로 껐다 켰다 할 수 있음 (default는 사용)
- container port 외부 노출 ~ port binding
- 외부 -> 컨테이너
- docker-proxy가 프록시 역할
    - 외부client --> [docker-proxy] --> 컨테이너

### 동작

- 컨테이너 기동 시 port binding 설정을 하면
- docker-proxy 프로세스가 같이 뜨는데
- binding한 (host) port를 물고 뜸
- 이 후 호스트의 해당 port로 오는 요청은
- docker-proxy가 받아서 컨테이너로 전달함
- 기타
    - docker-proxy는 포트 바인딩 개수 만큼 생성됨
    - docker-proxy를 kill 해도 된다 ㅋ (iptables DNAT)

### 왜쓰는가?

- NAT를 쓸 수 없는 경우를 대비

### 도커 옵션

- -userland-proxy=true(default) | false

```bash
$ vi sudo /etc/systemd/system/docker.service

[Service]

ExecStart=

ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375 --userns-remap=default --userland-proxy=false
```

### 참고

- [https://bluese05.tistory.com/53](https://bluese05.tistory.com/53)