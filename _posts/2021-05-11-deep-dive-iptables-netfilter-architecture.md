---
title: A Deep Dive into Iptables and Netfilter Architecture
version: v1.0
description: netfilter와 iptables를 이해하기에 좋은 자료입니다.
date: 2021-05-11 21:25 +09:00
categories: network
badges:
- type: info
  tag: 번역
rightpanel: true
---
<!--more-->
원문: [https://www.digitalocean.com/community/tutorials/a-deep-dive-into-iptables-and-netfilter-architecture](https://www.digitalocean.com/community/tutorials/a-deep-dive-into-iptables-and-netfilter-architecture){:target="_blank"}    
번역: [https://www.kangtaeho.com/66?fbclid=IwAR3nWnRib_t6l4npxG6az5iyyZe616wj1YapGlvvSUUBP-zPFyQf7V4i888](https://www.kangtaeho.com/66?fbclid=IwAR3nWnRib_t6l4npxG6az5iyyZe616wj1YapGlvvSUUBP-zPFyQf7V4i888){:target="_blank"}

### What are IPTables and Netfilter?  
iptables는 방화벽 소프트웨어이고 커널의 네트웍 스택에서 netfilter hook과 상호작용하는 방식으로 동작합니다.  
모든 네트웍 패킷은 스택을 통과할 때 넷필터 훅들을 트리거 하는데, 이러한 훅들을 등록한 프로그램들이 주요지점에서
트래픽과 상호작용하도록 허용합니다.<!--more--> 
iptables와 연관된 커널모듈들은 트랙픽이 방화벽규칙을 준수하는지 확인하기 위하여 이 훅들에 등록됩니다.

#### iptables
- basic firewall software
- works by interacting /w the packet filtering hooks in the kernel's n/w stack  


#### netfilter
- these kernel hooks are known as the netfilter framework

```
iptables는 firewall 이고 firewall rule이 존재
traffic에 대하여 이 rule들을 점검하는데 ..
netfilter hook에 (firewall 관련한) kernel modules들을 등록해두고
traffic이 지나갈때 상호작용
```

--- 

### Netfilter hooks
#### netfilter hooks
1. NF_IP_PRE_ROUTING : incoming 트래픽을 라우팅 하기 전에 트리거
2. NF_IP_LOCAL_IN : incoming 패킷의 목적지가 "로컬" 라우팅 이후 트리거
3. NF_IP_FORWARD : incoming 패킷이 다른 호스트로 포워딩되는 경우로 해당 호스트로 라우팅 이후 트리거
4. NF_IP_LOCAL_OUT : 로컬에서 생성된 Outbound 트래픽에 의해 트리거
5. NF_IP_POST_ROUTING : 라우팅 이후 Outbound or 포워딩 트래픽에 의해 트리거  
   
#### 훅 트리거 및 커널모듈 처리 과정
1. 위의 5가지 hook에 "커널모듈"을 등록하고
2. 모듈들은 hook이 트리거 되었을 때 호출 순서를 결정하기 위한 "priority number(우선순위)"를 제공해야 함
3. hook이 트리거 되면 각 모듈들은 차례로 호출되고
4. 각 모듈은 패킷에 무엇을 처리해야 하는지 표시한 이후에 netfilter 프레임웍에 "결정" (decision)을 반환합니다.

--- 
### iptables "tables와 chains"

#### tables (define general aim of the rules)
- Organize its rules : (general) 룰을 구성한다.
- 룰 분류 : 어떠한 결정(nat or filter)을 하느냐?
  Classify rules according to the type of decisions they are used to make
    - nat (Network Address Translation) table : 패킷의 네트웍주소변환(nat)을 다루는 경우
    - filter table : 패킷을 목적지로 전송허용 여부를 결정하는 경우
- 각 테이블 내의 규칙들은 분리된 chains로 더 조직화(organized) 된다
  

#### chains (determine when rules will be evaluated)
- 직접적으로 해당 chain을 트리거하는 netfilter hook을 나타냄
- Chain은 "언제 룰을 평가(evaluate)"하는 지를 결정함
- Built-in Chains (associated /w NetFilter Hooks)
    1. PREROUTING : triggered by the NF_IP_PRE_ROUTING hook
    2. INPUT : triggered by the NF_IP_LOCAL_IN hook
    3. FORWARD : triggered by the NF_IP_FORWARD hook
    4. OUTPUT : triggered by the NF_IP_LOCAL_OUT hook
    5. POSTROUTING : triggered by the NF_IP_POST_ROUTING hook
- 즉, "Chain"은 패킷의 전송경로에서 "룰이 어떤 위치에서 평가될지를 제어"합니다.  (built-in chain 종류별로 등록될 nf hook 이 정해져 있으므로)
- 각 테이블은 여러개의 체인들을 가질 수 있으므로, 패킷 프로세싱의 여러 위치(points)에서 영향을 미칠 수 있다.
- 어떤 유형의 결정은 네트웍 스택 상의 어떤 포인트에서만 의미가 있는데,  모든 테이블이 각각의 커널훅에 등록된 체인을 가지지 못할 수도 있다.


--- 
### Which Tables are Available?
These represent distinct sets of rules, organized by area of concern, for evaluating packets.
패킷을 평가하기 위한 고려해야할 영역으로 구성된 명확한 룰셋을 나타냅니다.
- The Filter Table : 필터링. 패킷의 전송여부를 결정
- The NAT Table : NAT패킷의 src, dst address의 수정/방법 여부를 결정. 패킷이 network으로 direct access가 불가능한 경우에 주로 사용
- The Mangle Table : IP 헤더변조 (TTL값 조정, 네트웍 홉 수 조정 등). 네트웍 추가 처리를 위한 내부커널 "표시"를 마킹.
- The Raw Table : connection tracking을 위한 패킷 마킹 메커니즘 제공
- The Security Table : 패킷에 SELinux 보안 context 마킹하는데 사용


--- 
### Which Chains are Implemented in Each Table?
![deep-dive-iptables-netfilter-architecture-table.png](/assets/img/deep-dive-iptables-netfilter-architecture-table.png)  
위의 표에서 각 table 열(raw, mangle, nat, ...)에 대하여 왼쪽에서 오른쪽 방향로 chain 이 평가됨
그리고 (넷필터 훅 별로 평가되는) chain column(PREROUTING, INPUT, ...)은 위에서 아래 방향으로 평가됨
DNAT : 패킷의 목적지 주소 변조
SNAT : 패킷의 출발지 주소 변조

```
packet --(trigger)--> nf hook --(trigger)--> chain
```

위의 표에서 packet이 넷필터 hook을 트리거 하면 nf hook에 등록된 chain의 처리순서는 top-to-bottom 입니다.
The hooks(columns) that a packet will trigger depend on whether it is an incoming or outgoing packet, the routing decisions that are made, and whether the packet passes filtering criteria.

#### Chain Traversal Order (체인 순회 순서)  
- packet의 경로는 넷필터 훅을 왼쪽에서 오른쪽 방향으로 통과하고, 각 hook 에서 테이블 우선순위( 위에서 아래) 로 평가된다.
- "패킷이 트리거하는 후크 (열)는 들어오는 패킷인지 나가는 패킷인지, 라우팅 결정을 내리고 패킷이 필터링 기준을 통과하는지 여부에 따라 다릅니다."
- incoming packet  목적지가 로컬호스트 :  PERROUTING --> INPUT
    1. PREROUTING : raw --> mangle --> nat tables 순서로 평가됨
    2. INPUT : mangle --> filter --> security --> nat 순서로 평가됨
- incoming packet  목적지가 다른호스트 :  PREROUTING --> FORWARD --> POSTROUTING
- 내부에서 생성된 packet : OUTPUT --> POSTROUTING


--- 
### IPTables Rules
- Rules are placed within a specific chain of a specific table. ( Rule 은 table과 chain matrix에 대해서 정의되네)
- As each chain is called, the packet in question will be checked against each rule within the chain in order. (패킷은 순서대로 체인 내의 각 룰에 대해 체크된다)
- Each rule has a matching component and an action(or target) component.

#### matching
```
룰에서 매칭은 어떤 기준을 충족하는지 패킷을 조사하는 것이지.. 
무엇을 조사하고 어떤 기준을 만족하는지 결정해서 action(targets)으로 연결하기 위한 것이다.  
The matching portion of a rule specifies the criteria(기준) that a packet must meet in order for the associated action to be executed.  
패킷이 반드시 "순서대로 충족"해야 하는 룰의 매칭 기준  --> Targes(Actions) 실행  
matching system : 매우 유연(flexible)하고 확장성있다.
``` 
- Rules can be constructed to match by
  - protocol type
  - destination or source address
  - destination or source port
  - destination or source network
  - input or output interface
  - headers
  - connection state among other criteria


#### targets (action)  

패킷이 룰의 매칭 기준을 충족하면 트리거 된다.   
타겟은 일반적으로 2 카테고리로 나누어진다.

##### Terminating targets  
액션을 수행하고 평가를 종료함. nf hook에 제어를 리턴함.   
"리턴값"에 따라 훅은 패킷의 드롭 여부를 결정함  

##### Non-terminating targets  
액션을 수행하고  평가를 계속함. 
각 체인이 결과적으로 종료 결정을 해야 하더라도 몇 몇 non-terminating targets은 사전에 실행될 수 있다.  

##### 주요 Target 예
- ACCEPT : 허용
- DROP : 호출처가 목적지 존재여부를 알 수 없게 조용히 drop.
- REJECT : DROP과 비슷하나 호출처에 응답을 줌
- LOG
- RETURN
              
##### Target Availabilty (사용여부?가용성?)
"Context" (문맥, 상황) 에 따라서 다르다.  
예를 들어, 테이블과 체인 타입이 가용한 타겟을 지정하거나 
룰 안에서 "activated extensions"이나 "matching clauses"에 따라서
Target Availability에 영향을 줄 수 있습니다.

##### Rule 주요 설정
- -A : append , 해당 chain 끝 행에 룰 추가
- -I [chain] [number] : insert , 해당 [chain] [number] 행에 룰을 삽입
- -D : delete , 행 번호를 지정하여 룰 삭제
- -R : replace , 행 번호를 지정하여 룰 치환
- -F : flush , 해당 체인의 모든 룰 삭제
- -L : list , 룰 리스트 출력
- -P : policy , 기본(default)정책 설정. 체인의 모든 룰에 매칭되지 않으면 적용
- -p : protocol , (tcp, udp, icmp 등)
- -s : source ip , 지정 안하면 any ip
- -d : destination ip , 지정 안하면 any ip
- --sport : source port
- --dport : destination port
- -i : input interface
- -o : output interface


---
### Jumping to User-Defined Chains
#### jump target
-  non-terminating target의 특별한 부류
- 평가를 다른 체인으로 이동시키는 action 이다.
- (호출한) 기존 체인의 심플 확장
- -j : jump ,  jumping 으로 이동할 chain 지정

#### built-in chains
intimately tied to the nf hooks that called them

#### user-defined chains
chain created by users for organizational purposes (* NOT registered /w nf hook)  
- rules can be placed
- can ONLY be reached by "Jumping" from a rule
- act as "simple extensions" of the chain which called them
    - rule list 의 끝에 도달하거나 매칭 룰에 의해 [RETRUN target]이 활성화 되면 evaluation이  호출 체인으로 반환된다.
- Evaluation은 additional user-defined chanins로 jump 할 수 있다.

이러한 구조(user-defined chains)는 greater organization을 가능하게 하고 more robust branching을 위해 필요한 프레임웍을 제공한다.


---
### IPTables and Connection Tracking
- Connection Tracking System : netfilter framework의 상위(top)에 구현. raw table과 connection state matching 기준에 대해 논의할 때 소개됨.
- Connection Tracking은 iptables가 "연결 중인 컨텍스트에서 보이는 패킷에 대해서 결정"하도록 한다.
- Connection Tracking System은 iptables에 "stateful operations"을 제공한다.
- Connection Tracking은 packets이 network stack에 들어오자(enter) 마자 적용된다.
- raw table chains과 basic sanity checks (기본적인 온전성 검사) 는 "패킷을 커넥션과 연관 짓기 전에 패킷에 대해 수행"되는 유일한 로직이다.
- 시스템은 existing connection set에 대하여 각 패킷을 체크하고 필요하면 커넥션 상태를 업데이트하고 필요하면 새로운 커넥션을 추가한다.
- "raw chains (중 하나)에서 [NOTRACK target]으로 mark된" 패킷은 connection tracking routines을 bypass 한다.


#### Available States
Connections tracked by the connection tracking system will be in one of the following states:
CTS로 트래킹되는 커넥션들은 다음 states 들을 가진다.
- NEW : When a packet arriveds that is not associated with an existing connection, but is not invalid as a first packet, a new connection will be added to the system with this label. This happens for both connection-aware protocols like TCP and for connectionless like UDP.
  패킷이 도착했을 때 기존 커넥션과 연관되지 않고, "first" packet으로 문제가 없드면 새로운 커넥션이 "NEW" 레이블로 추가된다.  연결지향 프로토콜인 TCP와 UDP같은 커넥션리스 프로토콜에서 일어난다.
- ESTABLISHED : A connection is changed from NEW to ESTABLISHED when it receives a valid response in the opposite direction. For TCP connections, this means a SYN/ACK and for UDP and ICMP traffic, this means a response where source and destination of the original packet are switched.
- RELATED : Packets that are not part of an existing connection, but are associated with a connection already in the system are labeled "RELATED".  This could mean a helper connection, as is the case with FTP data transmission connections, or it could be ICMP responses to connection attemps by other protocols.
- INVALID : Packets can be marked INVALID if they are not associated with an existing connection and aren't appropriate for opening a new connection, if they cannot be identified, or if they aren't routable among other reasons.
  NEW도 아니고  RELATED도 아닌 상태로 식별되지도 않고 여러 다른 이유로 라우팅도 할 수 없는 상태임
- UNTRACKED (NOTRACK?) :  Packets can be marked as UNTRACKED if they've been targeted in a raw table chain to bypass tracking.
  트래킹을 bypass하기 위해서 raw table 에서 타게팅 되면 UNTRACKED로 표시될 수 있다.
- SNAT :  A virtual state set when the source address has been altered by NAT operations. This is used by the connection tracking system so that it knows to change the source addresses back in reply packets.
  소스 주소 변조 시 설정되는 가상상태. CTS에 의해 사용되는데 응답 패킷이 도착했을 때 소스주소를 원래대로 되돌려 놓기 위함
- DNAT :  A virtual state set when the destination address has been altered by NAT operations. This is used by the connection tracking system so that it knows to change the destination address back when routing reply packets.
  목적지 주소 변조 시 설정되는 가상상태. CTS에 의해 사용되고 응답 패킷이 도착했을 때 목적지 주소를 원래대로 되돌려 놓기 위함

The state tracked in the connection tracking system allow administrators to craft rules that target specific points in a connection's lifetime.
CTS에서 트래킹되는 "State"는 "커넥션 라이프타임의 특정 포인트를 타케팅하는  rule"을 만들 수 있다.
This provides the functionality needed for more thorough and secure rules.
이것은 보다 철저하고 안전한 룰들에 필요한 기능을 제공한다.


## Conclusion

netfilter (packet filtering framework)와 iptables (firewall) 은 리눅스 서버에서 가장 기본적인 firewall 솔루션 들이다.
The netfilter kernel hooks are close enough to the networking stack to provide powerful control over packets as they are processed by the system.
넷필터 커널훅은 시스템에서 처리될 때 패킷들을 파워풀하게 제어할 수 있도록 네트웍 스택에 충분히 가까이 있다.
The iptables leverages these capabilities to provide a flexible, extensible method of communicating policy requirements to the kernel.


---
### iptables 사용예
```
$ iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE
```
-t :  nat 테이블에서
-A : POSTROUTING (chain)에 Rule 추가
-s : source ip 대역이 192.168.1.0/24  인 경우에
-j : MASQUERADE (chain) 으로 jumping

```
iptables -L | grep policy
Chain INPUT (policy ACCEPT)
Chain FORWARD (policy DROP)
Chain OUTPUT (policy ACCEPT)
```
로컬 NF_IP_LOCAL_IN, NF_IP_LOCAL_OUT 홉을 통과하는 패킷을 허용한다.
NF_IP_FORWARD 다른 호스트(네임스페이스)로 FORWARD를 허용하지 않는다.
ㄴ net namespace 간에도 허용되지 않음

```
iptables --policy FORWARD ACCEPT
. . .
Chain FORWARD (policy ACCEPT)
```
FORWARD (chain)의 (기본 Policy) Target( or action)은 ACCEPT

```
iptables -A INPUT -s 10.10.10.10 -j DROP
```
-A INPUT (chain) 에 (룰을 추가하라)
-s 10.10.10.10 ~  해당 IP 로 부터 오는 packet 들은  모두
-j DROP (chain) 으로 jump 해라 ~ (all blocked)

```
iptables -A INPUT -p tcp --dport ssh -s 10.10.10.10 -j DROP
```
-A INPUT (chain) 에 (룰을 추가하라)
-p tcp  프로토콜에
--dport ssh 목적지 포트로
-s 10.10.10.10 ip로 부터오는 패킷들은
-j DROP (chain) 으로 jump 해라 ~ (all blocked)

```
iptables -A INPUT -p tcp --dport ssh -j DROP
```
* SSH 포트로 오는 패킷들은  모두 DROP 하라

"서버가 10.10.10.10 ip에 대해 ssh 서버로만 동작하게 하고 싶다. 즉, ..."
서버  <--(ssh 연결)-- 10.10.10.10  (O)
서버  --(ssh 연결)--> 10.10.10.10 (X)
```
iptables -A INPUT -p tcp --dport ssh -s 10.10.10.10 -m state --state NEW,ESTABLISHED -j ACCEPT
```
-A INPUT 에 대해서  (룰을 추가한다)
-p tcp 프로토콜이고
--dport ssh 목적지 포트로
-s 10.10.10.10 에서 오는 패킷들에 대해
-m state 상태를 체크하고
--state NEW, ESTABLISH 상태인 경우에
-j ACCEPT (chain)으로 jump 해라

```
iptables -A OUTPUT -p tcp --sport 22 -d 10.10.10.10 -m state --state ESTABLISHED -j ACCEPT
```
-A OUTPUT 에 대새서 (룰을 추가한다)
-p tcp 프로토콜이고
--sport 소스포트가 22이며
-d 10.10.10.10 목적지 ip로 향하는 패킷들에 대해
-m state 상태를 체크하고
--state ESTABLISHED 상태이면
-j ACCEPT (chain)으로 jump 해라


### Quiz

Q1) 출발지 주소가 192.168.0.111 인 모든 포트 접속 차단
```
iptables -A INPUT -s 192.168.0.111 -j DROP
```

Q2) 목적지 포트가 3838 이고 tcp 프로토콜인 패킷 거부
```
iptables -A INPUT -p tcp --dport 3838 -j DROP
```

Q3) localhost 접속 허가
```
iptables -A INPUT -i lo -j ACCESPT

참고) iptables --policy INPUT ACCEPT (X) localhost 뿐만 아니라 모든 (ip) 접속 허용임
```
-i : interface를 뜻함. lo 는 약자로 localhost 임

Q4) ESTABLISH와 RELATED 상태 접속 허가
```
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Q5) Null 패킷 차단
```
iptables -A INPUT -p tcp --tcp-flags ALL NONE  -j DROP
```
ALL (모든 플래그) 를 조사하여 NONE이 있으면 DROP하라
--tcp-flags [mask] [comp]
- mask : 검사할 플래그, comp: 필터링할 값

Q6) 11.11.11.0/24 대역으로 가는 패킷은 FORWARD를 허용하시오
```
iptables -A FORWARD -d 11.11.11.0/24 -j ACCEPT
```

Q7) br0 interface에 대하여 in/out FORWARD 허용
```
-A FORWARD -i br0 -j ACCEPT
-A FORWARD -o br0 -j ACCEPT
```

### 사례
k8s Service : https://ssup2.github.io/theory_analysis/Kubernetes_Service_Proxy/


### references
- [Iptables 위키 : https://itwiki.kr/w/%EB%A6%AC%EB%88%85%EC%8A%A4_iptables](https://itwiki.kr/w/%EB%A6%AC%EB%88%85%EC%8A%A4_iptables){:target="_blank"}
- [iptables 정리 : https://mozzihacker.tistory.com/25](https://mozzihacker.tistory.com/25){:target="_blank"}
- [iptables flow : http://www.adminsehow.com/2011/09/iptables-packet-traverse-map/](http://www.adminsehow.com/2011/09/iptables-packet-traverse-map/){:target="_blank"}
- [effective firewall policy : https://www.digitalocean.com/community/tutorials/how-to-choose-an-effective-firewall-policy-to-secure-your-servers](https://www.digitalocean.com/community/tutorials/how-to-choose-an-effective-firewall-policy-to-secure-your-servers){:target="_blank"}
- [firewall test (nmap, tcpdump) : https://www.digitalocean.com/community/tutorials/how-to-test-your-firewall-configuration-with-nmap-and-tcpdump](https://www.digitalocean.com/community/tutorials/how-to-test-your-firewall-configuration-with-nmap-and-tcpdump){:target="_blank"}
- [리눅스 방화벽 설정 : https://m.blog.naver.com/PostView.nhn?blogId=fjrzlgnlwns&logNo=207490010&proxyReferer=https:%2F%2Fwww.google.com%2F](https://m.blog.naver.com/PostView.nhn?blogId=fjrzlgnlwns&logNo=207490010&proxyReferer=https:%2F%2Fwww.google.com%2F){:target="_blank"}
- [도커 네트워크 : https://www.joinc.co.kr/w/man/12/docker/InfrastructureForDocker/network](https://www.joinc.co.kr/w/man/12/docker/InfrastructureForDocker/network){:target="_blank"}