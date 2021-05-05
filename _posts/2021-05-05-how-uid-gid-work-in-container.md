---
title: Understanding how uid and gid work in Docker containers
version: v0.1
description: User namespace와 컨테이너의 UID/GID 동작을 이해하기 좋은 글입니다. 
date: 2021-05-05 17:55 +09:00
categories: container
badges:
- type: info
  tag: 번역
rightpanel: false
---
원문 : [https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf](https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf){:target="_blank"}


프로세스와 호스트 사이의 UID/GID 매핑은 Secure 측면에서 중요합니다.  
UID, GID space는 커널이 관리하는데요. 파일의 권한 확인은 UID, GID를 검사하여 판단합니다.    
컨테이너는 호스트의 커널(Single kernel)을 공유합니다.<!--more-->
따라서 동일한 커널 아래서 Same UID는 Same User를 의미합니다.  
하지만, Username은 커널 요소가 아닙니다.(Not part of kernel)
Username은 외부툴이 관리하는 요소입니다. (managed by external tools, /etc/passwd, LDAP, Kerberos, ...)

[참고 : 리눅스 퍼미션, 권한(chmod,chown,umask)](http://blog.naver.com/PostView.nhn?blogId=geonil87&logNo=221022779618){:target="_blank"}  
![how-uid-gid-work-in-container-drwx.png](/assets/img/how-uid-gid-work-in-container-drwx.png){:width="400px"}    
(2)소유자 권한 (3)그룹 권한 (4) 그 외 사용자
* (1) d (directory) ~ c (특수파일), b (블럭구조 특수파일), l (심볼릭링크), - (일반파일)
* (참고) 특수권한 : s (SetUID, SetGID, 파일소유자, 그룹소유자 권한으로 실행), t (Sticky Bit, 공유디렉토리로 사용)
- SetUID : 일시적으로 파일 실행권한을 부여하고자 하는 경우 ~ "소유자"의 실행권한을 부여
- SetGID : 일시적으로 파일 실행권한을 부여하고자 하는 경우 ~ "그룹"의 실행권한을 부여


---
### (실습1) Simple Docker Run
1. 일반유저로 도커 컨테이너를 실행해 본다. docker CLI를 일반유저(vagrant)로 사용하기 위해서는 아래와 같이 권한추가가 필요
```
$ sudo usermod -aG docker vagrant
```

2. 컨테이너(test)를 실행한다.
```
$ docker run --name test --rm -d ubuntu:latest sleep infinity
```

3. 컨테이너(test)의 UID/GID정보를 확인한다.
```
$ docker exec test id
```

4. 호스트 프로세스 (UID) 확인 (컨테이너의 UID와 비교해본다.)
```
$ ps aux | grep sleep
```


---
### (실습2) Dockerfile /w a defined user
1. 호스트 UID 확인
```
$ echo $UID
```

2. Dockerfile 작성
```
FROM ubuntu:latest
RUN useradd -r -u 1000 appuser
USER appuser
ENTRYPOINT ["sleep", "infinity"]
```

3. docker build
```
$ docker build -t defineduser .
```

4. 컨테이너 실행
```
$ docker run --name test2 --rm -d defineduser
```

5. 호스트 프로세스(UID) 확인
```
$ ps aux | grep "sleep infinity"
```

6. 컨테이너 UID 비교 (test, test2)
```
$ docker exec test id
$ docker exec test2 id
```


---
### (실습3) How to control the access a container has
1. 컨테이너 실행 (* 실행옵션으로 UID 설정)
```
$ docker run --rm --name test3 -d --user 1000 ubuntu:latest sleep infinity
```

2. 호스트 프로세스 (UID) 확인
```
$ ps aux | grep "sleep infinity"
```

3. 컨테이너 UID 확인
```
$ docker exec -it test3 /bin/bash
I have no name!@84f436065c90:/$
I have no name!@84f436065c90:/$ id
```


---
### (실습4) User overriding
1. 컨테이너 실행 (* defineduser 이미지를 사용하고 --user flag를 root(0)로 설정)
```
$ docker run --rm --name test4 --user 0 -d defineduser
```

2. 호스트 프로세스 (UID) 확인
```
$ ps aux | grep "sleep infinity"
```

3. 컨테이너 UID 확인
```
$ docker exec test4 id
```

