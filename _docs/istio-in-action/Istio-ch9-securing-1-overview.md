---
title: Istio Securing (1)  
version: v1.2  
description: istio in action 9장  
date: 2023-04-21 14:00:00 +09:00  
layout: post  
toc: 11  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
histories:
- date: 2022-12-24 22:00:00 +09:00
  description: 최초 등록
---
9장에서는 마이크로서비스 환경에서 Istio 가 제공하는 Secure 통신에 대해 다룹니다.  
인증을 통해 신원을 확인하고 확인된 신원에 대하여 권한을 확인하는 방법을 살펴봅니다

<!--more-->

# 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 9장

## 다룰 내용

- 4장에서 "트래픽 보안"과 "트래픽 인가"에 대해서 다루었습니다
- 이번 장에서는 보다 자세히 서비스 메시 환경에서 “투명하게 보안태세를 강화”하는 방법에 대해 다룹니다
- Istio 의 보안 메커니즘 - *서비스 간 인증, 유저 인증의 구현, 접근 제어* - 에 대해 설명합니다 

## 용어

- ID - identity "신원", "고유식별정보"
- authn - authentication “인증”
- authz - authorization “인가”, "권한 부여"
- authentication server - 인증서버
- sa - service account
- Control-plane : 정책설정/라우팅/인증/보안 등 시스템 동작방식을 결정하는 제어기능을 담당
- Data-plane : 분산환경에서 데이터 전송, 로드밸런싱 등 실제 데이터 흐름 처리를 담당 
- Security posture - 보안태세
  - 조직의 전반적인 사이버 보안 능력을 의미합니다   
  - 사이버 위협을 얼마나 잘 예견하고, 방지하고, 대응할 수 있는지를 의미합니다 
  - 방화벽, 침입탐지시스템, 인증/권한 프로토콜, 암호화 등 모든 보안 지침들을 포함합니다  
  - 새로운 기술과 함께 오는 취약점과 위험에 대한 이해와 악의적인 행위에 대한 감지와 방어 능력을 필요로 합니다 
  - 네트웍, 데이터, 시스템을 안전하게 보호할 수 있는 적합한 사람과 절차, 기술을 가진 조직을 필요로 합니다 
- SPIFFE, Secure Production Identity Framework For Everyone
  - 분산환경에서 보편적인 Identity (식별) 컨트롤 플레인을 제공하는 표준 프레임웍
  - CNCF 프로젝트로 Kubernetes, AWS/GCP/Azure, Istio, Consul 등에서 구현
  - 표준 구현체로 SPIRE 가 있음
- SVID, SPIFFE Verifiable Identity Document - SPIFFE 인증서 (X.509 준수)
- mTLS (mutual TLS) - client-server 간 상호 인증 방식
- CR, Custom Resource - 쿠버네티스의 사용자 정의 리소스 (명세)
- JWT, Json Web Token - 서버에 클라이언트 인증을 제공하는 간결한 클레임 표현
- JWKS, JSON Web Key Set - JWK (공개키) 모음. JWKS 에는 하나이상의 JWK 가 포함되며, 이중 JWT의 식별자와 일치하는 JWK 로 검증함

## 실습 환경
- minikube (k8s) 및 istio 설치.  참고: [https://netpple.github.io/docs/istio-in-action/Istio-Environment](https://netpple.github.io/docs/istio-in-action/Istio-Environment)
- 실습 네임스페이스 : istioinaction
- 실습 디렉토리 : book-source-code

### 실습 초기화

실습 시 초기화 후 사용하세요

```bash
## 실습 네임스페이스 전환 (istioinaction)
kubectl config set-context --current --namespace=istioinaction

## istioinaction
kubectl delete virtualservice,deployment,service,secret,\
destinationrule,gateway,serviceentry,envoyfilter,configmap,\
authorizationpolicy,peerauthentication -n istioinaction --all

## istio-system
kubectl delete authorizationpolicy,peerauthentication,requestauthentication \
-n istio-system --all

## default namespace
kubectl delete deployment/sleep -n default
kubectl delete service/sleep -n default
```

# 9.1 앱-네트워킹 보안의 필요성

*애플리케이션 보안*
- 리소스 접근에 대한 “인증”과 “인가”
    - 인증 - 클라이언트 혹은 서버의 신원 (ID, identity) 을 “입증”하는 것  
      ”신원” 을 알아야  “권한” 을 적용할 수 있겠죠
    - 인가 - "인증된" 유저의 권한을 검토하고 리소스 접근여부를 결정
- Encryption - 전송 중인 데이터 암호화. 감청 방지

## 9.1.1 서비스-to-서비스 인증  

*SPIFFE - 모두를 위한 안전한 운영 환경 ID 프레임웍*
- Secure Production Identity Framework For Everyone
- 보안을 위해 “서비스 간 인증 방법” 제공
- 서비스 간에 “신뢰” 할 수 있도록 검증 가능한 `SVID (ID document)` 제공 (일종의 주민등록증)
- `SVID`는 X.509 인증서의 일종으로 신뢰할 수 있는 3rd party 발급기관에서 발급하고 검증
- Istio 는 SPIFFE 를 준수하여 인증서 발급 프로세스를 자동화
- Istio 는 SPIFFE 인증서 (`SVID`)를 사용하여 서비스 간 상호인증 (mTLS)

## 9.1.2 End-user 인증  

- 애플리케이션에서 “Private”한 유저 데이터를 저장하고 다루기 위함
- End-user 인증 프로토콜 대부분이 `인증 리다이렉팅` 방식을 사용함
- 유저가 서비스 요청 시 서비스는 “인증서버”로 유저를 리다이렉팅 함
- “인증서버”는 유저 정보를 포함하는 자격증명 (`Credential` - JWT, HTTP Cookie 등) 을 발급함
- 유저는 발급받은 자격증명 을 서비스에 제출함
- 서비스는 유저의 자격증명 을 “인증서버”에 보내 확인함

## 9.1.3 인가 

*인가는 인증 이후에 이루어집니다*
- 호출처가 서버에 자신이 누구 (ID) 인지를 인증하면
- 서버는 호출처의 “ID” 로 수행할 수 있는 오퍼레이션이 무엇인지 확인하고 
- 요청을 허용할지 거절할 지 판단합니다

Istio 는 `인증`(authentication)과 `ID`(identity) 모델을 기반으로   
서비스-to-서비스, 서비스-to-유저 간 잘 세분화된 권한 제어를 제공합니다.

## 9.1.4 모놀리딕과 마이크로서비스의 보안 비교

모놀리딕, 마이크로서비스 모두 서비스-서비스, 서비스-유저 사이에 “인증과 권한”을 필요로 하는 점은 동일합니다.   
하지만 모놀리딕이냐 마이크로서비스냐에 따라 차이가 있습니다.

- 마이크로서비스
    - 커넥션 수 : 모놀리딕 대비 커넥션이 많고
    - 운영 환경 : 동적인 환경을 필요로 함 (클라우드, 컨테이너 오케스트레이션 등)
      쉽게 수 백, 수 천의 서비스로 증가할 수 있어 정적 환경에서 운용하기 어려움

- 모놀리딕
    - 커넥션 수 : 마이크로서비스 대비 커넥션이 적고
    - 운영 환경 : 정적인 환경에서 운용됨   
      *`예) IP로 엔드포인트 식별`*  
        <img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-11_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.34.13.png" width=350 />
        

마이크로서비스 환경에서는 "전통적인 방법" 은 쓰기 어려움   
`예) IP로 엔드포인트 식별`

클라우드, 분산 환경의 특징 - 동적이고 헤테로함
- 서비스가 수 많은 노드 중 어떤 노드에 배포될 지 모름 
- 심지어 서비스가 서로 다른 네트워크에 포함될 수 있음
- 서비스가 서로 다른 클라우드나 on-premise 환경에 걸쳐 있을 수 있음  
  ![스크린샷 2023-02-11 오후 12.57.42.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-11_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.57.42.png)
    
Istio는 동적이고 헤테로한 분산 환경에서 Identity 제공을 위해 “SPIFFE” 를 사용합니다

## 9.1.5 Istio 의 SPIFFE 구현 

`SPIFFE  ID` - RFC 3986 URI 호환 형식

    spiffe://trust-domain/path  
    
- *`trust-domain`* : 발급자
- *`path`* : 식별자 - 워크로드를 식별함 (unique)
- 워크로드 식별을 위한 `path` 를 구성하는 방법은 SPIFFE 구현체가 결정합니다  
- 워크로드 식별을 위한 `path` 를 구성하는 방법으로 Istio 에서는 서비스 어카운트 (`sa`) 정보를 사용합니다
- `SPIFFE ID`는 `SVID` 라는 X.509 인증서에 인코딩 되어 들어갑니다      
- 워크로드의 `SVID`는 Istio 컨트롤플레인에서 생성합니다
- `SVID` 인증서는 서비스 간 통신 보안을 위한 전송 암호화에 사용됩니다 


## 9.1.6 Istio Security 요약  

Istio Security 이해를 위해 istio-proxy (envoy)를 설정하는 오퍼레이터 (istiod) 관점에서 살펴 보겠습니다  

*다음과 같은 커스텀 리소스를 사용하여 프록시에 Security 설정을 합니다*   

- *`PeerAuthentication`* : 서비스-to-서비스 인증 설정, 인가를 위한 피어 정보 추출
- *`RequestAuthentication`* : End-user 인증 설정, 인가를 위한 유저 정보 추출
- *`AuthorizationPolicy`* :  `PeerAuthentication`, `RequestAuthentication` 에서 추출한 피어/유저 정보에 기초하여 권한 판단을 위한 인가 정책을 설정 

![스크린샷 2023-02-11 오후 2.05.57.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-11_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.05.57.png)
  
>9.3 그림은 `PeerAuthentication`과 `RequestAuthentication` 리소스가 요청을 인증하기 위해 어떻게 프록시(`Envoy`)를 설정하는지 보여주며    
>어느 시점에 자격증명 (`SVID` or `JWT`)으로 부터 데이터를 추출하여 `Filter metadata`로 저장하는지를 보여 줍니다  
>`AuthorizationPolicy` 리소스는 커넥션 ID에 기초하여 요청의 허용/거부 여부를 판단합니다 
>

<br />

👉🏻 *[다음편 보기](/docs/istio-in-action/Istio-ch9-securing-2-auto_mTLS)*