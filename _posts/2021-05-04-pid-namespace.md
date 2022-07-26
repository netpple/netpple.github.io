---
title: The Curious Case of Pid Namespaces
version: v1.0
description: pid namespace 관련하여 좋은 글이 있어 번역/정리 해보았습니다.
date: 2021-05-04 21:55 +09:00
categories: container
badges:
- type: info
  tag: 번역
rightpanel: false
---
<!--more-->
원문: [The Curious Case of Pid Namespaces](https://hackernoon.com/the-curious-case-of-pid-namespaces-1ce86b6bc900){:target="_blank"}


### pid?
- process identifier
- unique
- from 1 (kernel pid == 0)
- tree-like structure
- tracking process ~ parent <--> child 


<!--more-->


### pid namespace?
- pid number space
- "isolation" ~ unique view for application 
- unshare (syscall) ~ fork(required)
- (forked) child process becomes pid 1 and has "2 pids"
  - process can have multiple “nested” process trees
- its own process tree ~ separate view of process hierarchy


### pid 1 (init process) in a namespace
1. signal 처리를 해줘야 함
2. reaping (zombie, orphan) 처리를 해줘야 함
3. pid1 dies, pid namespace dies ~ container lifecycle


### Docker "Mistake" - entrypoint as pid 1
도커는 entrypoint (or cmd)에 명시된 프로세스를 "pid 1"로 실행합니다.  
이는 예기치 못한 동작 발생이 가능한데요   
"pid 1"로 동작하도록 디자인된 프로그램이 아닐 가능성이 높기 때문입니다. 
- signal 처리가 고려되지 않음
- orphan process 처리가 고려되지 않음  
  (도커는 "이 문제" (init process 이슈) 에 대해서 손을 놨음 (pretty hands-off))

#### workaround 
컨테이너에 "특별한 init process"를 두는 방법
- more complexity
- scrifices benefit of dependency isolation


### Rkt "Solution" - systemd as pid 1
"사용자가 실행하는 프로세스가 init process가 아니라고 가정"  
- systemd 가 pid 1이 되고 사용자 프로세스를 pid 2로 실행   
- rkt (2014, CoreOS)

single 프로세스에서 systemd와 같은 advanced init system은 과하다  
하지만 "container builder"가 pid namespace나 init process의 의미를 이해하기를 기대한 것은 실수다.

### A Simpler Alternative - Second Fork
#### "Container Spawner"
"simple init" 구현체
- Container Spawner를 pid1로 fork하고, Container Spawner가 container process를 fork (실행)
- signal handler 처리 : child (container process) 에게 signal을 전달
- repaing zombies (,orphans) : container process의 종료상태 수집하고 컨테이너 시스템에 전달

예) docker-init (docker 1.13+) "--init-flag"로 simple init process 사용 가능  

![/assets/img/pid-namespace-docker-init-flag-example.png](/assets/img/pid-namespace-docker-init-flag-example.png)


### Multiple Containers in a Pod
관련 프로세스를 함께 실행 vs 프로세스 의존성 격리
```
 the idea of Pod 
~ Pod is a set of related containers that share some namespaces.
```

#### rkt Pod vs k8s Pod
##### rkt
every namespace is shared (except file namespace)
- Processes can signal each other in the Pod
- Container has init process and it is easy to create multiple processes

##### k8s
supports pods. but it doesn't share pid namespaces  
(관련 프로세스를 컨테이너로 Pod안에 모아 놓기는 하지만 pid namespace를 share하지는 않음)
- Process cannot signal each other in the pod
- Each container has the "init problem" (because continer process is "pid 1")


### Adding a Containers to a Pod  


#### Sandbox
a small box filled with sand for children to play in  
![/assets/img/pid-namespace-sandbox.jpeg](/assets/img/pid-namespace-sandbox.jpeg)


#### the Concept of a Pod Sandbox
- 리소스 할당을 미리 할 수 있음
- 기존 Pod에 컨테이너를 추가할 수 있음
- rkt : pod's systemd
- k8s: pause container 


#### rkt Pod
pod's systemd with no running units and then communicates with pod's systemd to start new apps on demand    
elegant but attack vector : because init process(systemd) has additional privileges
- 호스트 파일시스템에 대한 접근권한을 가짐
- 모든 권한을 가지고 있음 : "새로운 컨테이너"를 실행하기 위해서 필요한 권한Set을 미리 알 수 없기 때문임
- pod의 systemd가 pod내 모든 프로세스에서 보임


#### non-sandbox model
init process start child processes and then drop privileges


### Sandbox and Pid namespace
init, sandbox, pid namespace를 다루는 몇가지 방법들이 있고 각각이 장단점들이 있습니다. 

#### Types
1. Pid namespaces are not created along with the sandbox. each container gets its own pid namespaces.
![/assets/img/pid-namespace-type-1.png](/assets/img/pid-namespace-type-1.png)
- 잇점 : simple.
- 단점: 프로세스 간 signal X. init process가 없음(signal handling x, reaping zombie x)  


2. Pid namespaces are not created along with the sandbox. the pid namespace is created when the first container is started in the sandbox.
![/assets/img/pid-namespace-type-2.png](/assets/img/pid-namespace-type-2.png)
- 잇점: 프로세스간 signal O
- 단점: 첫번째 프로세스(pid 1)가 pod의 master. pid 1이 죽으면 pod 내 모든 프로세스들이 종료됨

3. Pid namespaces are created along with the sandbox. The sandbox includes a smart init process which can be used to start other processes.  
Rkt sandbox model 임.
![/assets/img/pid-namespace-type-3.png](/assets/img/pid-namespace-type-3.png)
- 잇점: Elegant init
- 단점: Too privileged --> security attack vectors  


4. Pid namespaces are created along with the sandbox. The sandbox includes a simple init process which only handles signals and reaps zombies.
![/assets/img/pid-namespace-type-4.png](/assets/img/pid-namespace-type-4.png)
- 잇점: 권한관리나 호스트 파일시스템에 접근할 필요없음 (init 프로세스가 새로운 컨테이너를 실행하지 않음)
- 단점: Broken process tree  


5. The pid namespace and init are exactly the same as option four + Daemonize (parent exits)
![/assets/img/pid-namespace-type-5-1.png](/assets/img/pid-namespace-type-5-1.png)
![/assets/img/pid-namespace-type-5-2.png](/assets/img/pid-namespace-type-5-2.png)
- 잇점: 4의 장점을 취하면서 Broken tree  이슈를 해결
- 단점: 모니터링 어려움 (프로세스 데몬화. pid로 해당 프로세스를 추적해야 함 )


### K8S Pause Container
- Not share Pid namespace  (Type 1)


## Conclusion
1. rkt의 "seprate init" 접근법이 도커 보다 낫다.
2. rkt의 접근법의 단점으로 보안문제를 지적
  - "뒤늦게 추가되는 컨테이너들"을 실행하기 위해  init process (systemd)가 과도한 권한을 가지고 있고 이점이 공격요소가 될 수 있다고 앞에서 언급함.
3. 대안으로 systemd 대신에 signal handling과 zombie reaping만 해주는 "Simple Init"을 두자는 것이고
4. 보안을 위해 container proecess의 실행은 init process가 아닌  sandbox 바깥의 container spawner에게 맞기자는 것임.
5. 그렇게 함으로써 init의 권한을 최소화하면서 위에서 언급한 필요한 기능만 유지하고
6. 동시에 동일한 pid namespace 안에서 동적인 컨테이너 프로세스 실행이 가능해짐


### references
- [man page - pid namespace](https://man7.org/linux/man-pages/man7/pid_namespaces.7.html){:target="_blank"}
- [A Tutorial for Isolating Your System with Linux Namespaces](https://lwn.net/Articles/259217/
  https://www.toptal.com/linux/separation-anxiety-isolating-your-system-with-linux-namespaces){:target="_blank"}
- [pid namespace](https://sonseungha.tistory.com/519?fbclid=IwAR3Q0hz1gdB8Vc_0Wu_IvQal7YyInh6YmGrKaTcC68VqYAWYWt5vygJj35k){:target="_blank"}
- [Docker and the PID1 zombie reaping problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/){:target="_blank"}
- [The Curious Case of Pid Namespaces](https://hackernoon.com/the-curious-case-of-pid-namespaces-1ce86b6bc900){:target="_blank"}