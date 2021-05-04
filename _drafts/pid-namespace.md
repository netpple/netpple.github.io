---
title: pid namespace
version: v0.1
description: pid namespace에 대하여 설명합니다.
date: 2021-05-04 21:55 +09:00
categories: container
badges:
- type: info
  tag: 번역
rightpanel: true
---

# pid namespace


## 용어
- (container) init process : pid 1. signal handling, reaping, container lifecycle 등 pid 1 역할을 수행하는 프로세스
- container process : 컨테이너 안에서 구동할 프로그램  (ex) docker의 entrypoint or cmd
- container builder
- container spawner
- pod sandbox
- CRI (Container Runtime Interface)


## pid?
- process identifier
- unique
- from 1 (kernel pid == 0)
- tree-like structure
- tracking process ~ parent <--> child 


## pid namespace?
- pid number space
- "isolation" ~ unique view for application 
- unshare (syscall) ~ fork(required)
- (forked) child process becomes pid 1 and has "2 pids"
- its own process tree ~ separate view of process hierarchy


## pid 1 (init process) in a namespace
1. signal 처리를 해줘야 함
2. reaping (zombie, orphan) 처리를 해줘야 함
3. pid1 dies, pid namespace dies ~ container lifecycle


## Docker "Mistake" ~ entrypoint as pid 1
- 도커는 entrypoint (or cmd)에 명시된 프로세스를 "pid 1"로 실행함.  ( 예기치 못한 동작 발생 가능)
  ~>  "pid 1" 로 동작하도록 디자인된 프로그램이 아니기 때문
- signal 처리가 고려되지 않음
- orphan process 처리가 고려되지 않음
  (도커는 "이 문제" (init process 이슈) 에 대해서 손을 놨음 (pretty hands-off))

(workaround) 컨테이너에 "특별한 init process"를 두는 방법
- more complexity
- scrifices benefit of dependency isolation


## Rkt "Solution" ~ systemd
"사용자가 실행하는 프로세스가 init process가 아니라고 가정"
~ systemd 가 pid 1이 되고 사용자 프로세스를 pid 2로 실행
* rkt (2014, CoreOS)

