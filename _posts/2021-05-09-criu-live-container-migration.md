---
title: Container Live Migration (CRIU)
version: v0.1
description: Container Live Migration
date: 2021-05-09 23:35 +09:00
categories: container
badges:
- type: info
  tag: 번역/요약
- type: light
  tag: new
rightpanel: false
---
원문: [https://access.redhat.com/articles/2455211?extIdCarryOver=true&sc_cid=701f2000001OH6pAAG](https://access.redhat.com/articles/2455211?extIdCarryOver=true&sc_cid=701f2000001OH6pAAG)

# CRIU

CRIU - Checkpoint/Restore in user space  
- 프로세스의 현재 상태를 덤프하고 그대로 복구하는 기술
- 초기에는 in-kernel checkpoint/restore 접근방법을 취했는데 리눅스 커뮤니티 인정을 못받음
- 이후 user space에서 처리하고 최대한 기존 인터페이스를 활용하는 방향으로 선회 
- CRIU에 중요한 인터페이스 중 하나로 "ptrace" 가 있음.
- ptrace를 통해 프로세스를 포착(seize)하고
- 프로세스의 "메모리 페이지"를 이미지 파일로 덤프함
    - /proc/**$PID**/smaps, /proc/**$PID**/mapfiles, /proc/**$PID**/pagemap
    - 덤프를 위한 충분한 스토리지 여유공간도 필요
        - opened files, credentials, registers, task state, . . .
        - checkpoint a process tree (checkpoints each connected child process)
- 프로세스 restore (using Same PID)
    - checkpoint 당시와 동일한 PID를 가져야만 restore 가능

        (다른 프로세스가 이미 해당 PID를 사용 중이면 retore 실패함)

    - why Same PID?
        - parent-child process tree 를 정확히 복원하기 위함
        - re-parent가 불가능하기 때문임
    - 그럼 어떻게 원하는(Same) PID로 fork ?
        - /proc/sys/kernel/ns_last_pid
        - ns_last_pid 값을 조정해서 (privileged 필요) 가능 (But,.. 그리 쉽지 않음)
        - clone3(kernel 5.3+ )와 set_tid(kernel 5.5+) ~ 원하는 pid를 지정가능

Container Migration 관련 참고

- 공식 git : [https://github.com/checkpoint-restore/criu](https://github.com/checkpoint-restore/criu)
- 개요 /요약: [https://www.redhat.com/en/blog/checkpointrestore-container-migration](https://www.redhat.com/en/blog/checkpointrestore-container-migration)
- CRIU (IBM) 소개 장표 : [https://www.slideshare.net/tommylee98229/4-ibm-crui](https://www.slideshare.net/tommylee98229/4-ibm-crui)