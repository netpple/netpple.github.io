---
title: Istio Securing (2)  
version: v1.0  
description: istio in action 9장  
date: 2023-04-21 14:50:00 +09:00  
categories: network
badges:
- type: info  
  tag: 교육  
  rightpanel: true
---

서비스 혹은 피어 간에 서로를 알아 보는 방법, "상호 인증" `Mutual Authentication` 에 대해서 알아보고 이를 "자동화" 하는 방법에 대해서 살펴봅니다

그리고 Istio 에서 제공하는 "서비스-to-서비스 인증" 방법에 대해서 설명하고 실습으로 확인해 봅니다 

<!--more-->

# 9.2 Auto mTLS

*Mutual Authentication*

- 사이드카 프록시가 주입된 서비스 간 통신에 기본적으로 트래픽 암호화와 상호 인증이 적용됩니다 
- 인증서 발급과 갱신은 자동화 중요합니다 (휴먼 에러가 많기 때문)
- Istio는 인증서 발급/갱신 자동화를 제공합니다

`Istio CA`에서 발급한 SVID 인증서를 사용하여 워크로드들 간에 상호 인증합니다  
![스크린샷 2023-02-11 오후 6.56.13.png](/assets/img/Istio-ch9-securing-2-auto_mTLS/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-11_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_6.56.13.png)

*Secure by default*

- 기본적으로는 대부분 안전합니다만
- 보다 안전하게 만들 필요가 있습니다

*for more secure*

- 첫째, mTLS 만 허용하도록 설정합니다
- 둘째, 인증된 서비스에 대하여는 
    - "최소 권한"의 원칙을 준수할 것 
    - 개별 "서비스 단위의 정책"을 세울 것
    - 기능에 필요한 "최소한의 접근"만 허용할 것 

이러한 원칙이 중요한 이유는 인증서가 잘못된 곳에 유출이 되더라도 피해범위를 해당 인증서 ID에 접근이 허용된 최소한의 서비스들로 국한 되기 때문입니다 
    

## 9.2.1 실습 환경

첫째, 👉🏻 *먼저, “[실습 초기화](/2023/Istio-ch9-securing-1-overview/#실습-초기화){:target="_black"}” 후 진행해 주세요*  
둘째, 실습 환경 구성하기

```bash
## 실습 코드 경로에서 실행합니다
# cd book-source-code

## catalog와 webapp 배포
kubectl apply -f services/catalog/kubernetes/catalog.yaml
kubectl apply -f services/webapp/kubernetes/webapp.yaml

## webapp과 catalog의 gateway, virtualservice 설정
kubectl apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml

## default 네임스페이스에 sleep 앱 배포
kubectl apply -f ch9/sleep.yaml -n default
```

![스크린샷 2023-02-11 오후 9.03.58.png](/assets/img/Istio-ch9-securing-2-auto_mTLS/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-11_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_9.03.58.png)

통신 확인

```bash
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s webapp.istioinaction/api/catalog \
  -o /dev/null -w "%{http_code}\n"

200
```

- *sleep (mesh 밖) → webapp (mesh 안)* 요청이 성공(200)함
- Istio 의 기본설정은 “clear-text” (암호화 되지 않은 평문) 이 허용됩니다
    - 기존 서비스를 mesh로 전환할 때 중단(outages)을 야기하지 않고 점진적으로  service mesh를 채택할 수 있도록 하기 위함
- “clear-text” traffic 은 Istio의 **PeerAuthentication** 리소스(CR)로 차단할 수 있음

## 9.2.2 서비스-to-서비스 인증 

`PeerAuthentication` 피어-to-피어 or 서비스-to-서비스 인증  
❊ `상호 인증` (Mutual Authentication)

*Mutual 인증 모드*
- `STRICT` - 강력하게 Mutual 인증 (mTLS) 요구
- `PERMISSIVE` - 평문 (clear-text) 요청도 허용

*Mutual 인증 Scope*
- `Mesh-wide` : 메시 전체 워크로드 대상
- `Namespace-wide` : 특정 네임스페이스 워크로드 대상 
- `Workload-specific` : Selector 매칭 워크로드 대상

### MESH-WIDE 정책 실습

*mesh-wide 정책 적용하기* 

1. Istio 설치 네임스페이스 (`istio-system`) 에 생성
2. name을 "default"로 지정 `name: "default"`

mTLS `mode: STRICT` 로 설정하여 평문전송을 금지합니다  

```yaml
# cat ch9/meshwide-strict-peer-authn.yaml 
---
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"            # ❶ Mesh-wide 네이밍 "default"
  namespace: "istio-system"  # ❷ Istio 설치 네임스페이스
spec:
  mtls:
    mode: STRICT             # ❸ mutual TLS mode
```

```bash
## 적용
kubectl apply -f ch9/meshwide-strict-peer-authn.yaml \
-n istio-system
```

```bash
## 다시 호출해 보세요 (에러발생)
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s webapp.istioinaction/api/catalog \
  -o /dev/null -w "%{http_code}\n"

000
command terminated with exit code 56
```

- 평문 (clear-text) 요청이 reject (56)되었습니다
- 이로써 STRICT 모드가 전체 (mesh-wide) 적용된 것이 확인되었습니다

STRICT 모드를 기본설정으로 사용하는 것은 좋습니다만, 경우에 따라서는 여러 팀들의 상황이 각기 다를 수 있기 때문에 점진적으로 제한을 늘려가는 방식으로 접근 할 수도 있습니다.

`PERMISSIVE` 모드를 사용하면 암호화된 요청과 평문 요청을 모두 수용할 수 있습니다.

### NAMESPACE-WIDE 정책 실습 

*정책을 istioinaction 네임스페이스에 한정해서 적용해 봅니다*

- mesh-wide policy 를 오버라이딩 하여
- 특정 네임스페이스로 제한된 설정을 할 수 있습니다

(실습) *namespace-wide* PeerAuthentication

- PeerAuthentication 에서 `namespace: "istioinaction"`을 설정합니다
- `mode: PERMISSIVE` 로 설정하여 평문 전송을 허용하는지 살펴봅니다

```bash
kubectl apply -f - <<END
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"             # ❶ only one ns-wide resource exists
  namespace: "istioinaction"  # ❷ namespace to apply the policy
spec:
  mtls:
    mode: PERMISSIVE          # ❸ allows HTTP traffic
END
```

```bash
## 다시 호출해 보세요 (성공)
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s webapp.istioinaction/api/catalog \
  -o /dev/null -w "%{http_code}\n"

200
```

- 평문 (clear-text) 요청이 성공(200)하였습니다
- namespace-wide 설정이 전체(mesh-wide) 설정을 오버라이드 한 것을 확인하였습니다
*PERMISSIVE 모드로 동작 확인*

다음 실습을 위하여 방금 설정한 PeerAuthentication 명세는 제거합니다

```bash
kubectl delete pa default -n istioinaction
```

- *pa,  peerauthentication 를 줄여서 사용할 수 있습니다*

> 이어서 *sleep → webapp* 서비스 간 통신에 한정해서 미인증 트래픽을 허용해 보겠습니다. 이 경우에 catalog 에 대해서는 mesh-wide 설정 (*STRICT mutual authentication*) 이 유지됩니다.
> 

### WORKLOAD-SPECIFIC 정책 실습

*정책을 webapp 에 한정해서 적용해 봅시다*
- PeerAuthentication 에서 “selector” 를 설정합니다
- 이렇게 하면 정책이 selector에 matching 되는 경우에만 적용됩니다

```bash
kubectl apply -f - <<END
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "webapp"
  namespace: "istioinaction"
spec:
  selector:
    matchLabels:
      app: "webapp"  # ❶ 레이블이 매칭되는 경우에만 PERMISSIVE로 동작
  mtls:
    mode: PERMISSIVE
END
```

- *참고: [ch9/workload-permissive-peer-authn.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/workload-permissive-peer-authn.yaml)*

```bash
## 다시 호출해 보세요 (성공)
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s webapp.istioinaction/api/catalog \
  -o /dev/null -w "%{http_code}\n"

200
```
👉🏻 webapp 워크로드에 대한 정책인 *`PERMISSIVE`* 모드 동작 확인
- 평문 (clear-text) 요청이 성공(200)하였습니다
- label 이 매칭되는 경우 `app: webapp` 에 한해서 해당 워크로드 설정이 전체 `mesh-wide` 설정을 오버라이드 합니다  
<br />

*default -> catalog 호출*

```bash
## catalog 를 호출해 보세요 (에러발생)
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s catalog.istioinaction/api/items \
  -o /dev/null -w "%{http_code}\n"

000
command terminated with exit code 56
```
👉🏻 default 에서 catalog 호출 시 mesh-wide 정책인 *`STRICT`* 모드 동작 확인  
![스크린샷 2023-02-12 오전 12.52.42.png](/assets/img/Istio-ch9-securing-2-auto_mTLS/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-12_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.52.42.png)
> PeerAuthentication 적용 - istiod 오퍼레이터가 처리하여 LDS를 이용하여 각 istio-proxy에 적용합니다
> 


### 추가 Mutual 인증 모드

*`STRICT`, `PERMISSIVE` 외 추가로 2가지 모드가 더 있음*
- `UNSET` : 부모 정책 상속
- `DISABLE` : TLS 터널링 끄기. 바로 전송

### tcpdump 를 사용한 서비스 트래픽 도청

> istio-proxy 컨테이너에는 tcpdump 가 제공됨. (네트웍 디버깅 용도)
보안 상 privileged 퍼미션을 요구하며, 기본 설정은 off 임
> 

istio-proxy (sidecar) 의 privileged 퍼미션 설정 (tcpdump 사용을 위함)

```bash
istioctl install -y --set profile=demo \
  --set values.global.proxy.privileged=true
```

pod 재기동 (privileged 적용됨)

```bash
kubectl delete po -l app=webapp -n istioinaction
```

[터미널1] webapp.istio-proxy 컨테이너에서 다음의 tcpdump 명령 실행

```bash
kubectl -n istioinaction exec deploy/webapp -c istio-proxy \
  -- sudo tcpdump -l --immediate-mode -vv -s 0 \
  '(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
```

[터미널2] 터미널 창을 새로 띄워서 “sleep → webapp” 호출

```bash
kubectl -n default exec deploy/sleep -c sleep -- \
  curl -s webapp.istioinaction/api/catalog
```

[터미널1] webapp.istio-proxy 출력 확인 (1) `webapp — sleep` 구간 (**clear-text**)

```
...
webapp-8dc87795-dt55c.http-alt > 172.17.0.1.62735: ...
	HTTP/1.1 200 OK
	content-length: 357
	content-type: application/json; charset=utf-8
	date: Sat, 11 Feb 2023 21:44:45 GMT
	x-envoy-upstream-service-time: 13
	server: istio-envoy
	x-envoy-decorator-operation: webapp.istioinaction.svc.cluster.local:80/*

	[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}] [|http]
```

Malicious users can easily exploit clear-text traffic to get to end user data by intercepting it in any intermediary networking devices. You should always aim to have only encrypted traffic between workloads, as is the case from the webapp to the catalog workload where traffic is mutually authenticated and encrypted.

[터미널1] webapp.istio-proxy 출력 확인 (2) `catalog — webapp` 구간 (encrypted)  
앞서 확인한 `webapp — sleep` 구간 로그 바로 윗줄을 살펴 봅니다

```
172-17-0-8.catalog.istioinaction.svc.cluster.local.3000 > webapp-8dc87795-dt55c.47060: Flags [P.], cksum 0x5f21 (incorrect -> 0xea54), seq 1:1739, ack 1247, win 501, options [nop,nop,TS val 2232219850 ecr 3232395467], length 1738
21:58:06.265382 IP (tos 0x0, ttl 64, id 18187, offset 0, flags [DF], proto TCP (6), length 662)

webapp-8dc87795-dt55c.http-alt > 172.17.0.1.62735: ...
```

실습을 통해서 mTLS 사용시 트래픽이 쌍방 암호화되어 안전하다는 것을 알 수 있습니다.  
반면, 앞에서 http 통신을 허용한 `PERMISSIVE` webapp 구간의 경우 평문 전송을 허용하기 때문에  
악의적인 사용자에게 도청될 위험이 높습니다

지금까지 Mutual 인증에 대하여 살펴 보았습니다

### 워크로드 ID 와 Service Account 연결 확인하기

`SVID` 인증서에는 `SPIFFE ID` 가 있고 `SPIFFE ID`는 워크로드의 Service Account 에 매칭됩니다  

`openssl` 명령을 사용하여 catalog 의 X.509 인증서 내용을 살펴봅시다
```bash
kubectl -n istioinaction exec deploy/webapp -c istio-proxy \
  -- openssl s_client -showcerts \
  -connect catalog.istioinaction.svc.cluster.local:80 \
  -CAfile /var/run/secrets/istio/root-cert.pem | \
  openssl x509 -in /dev/stdin -text -noout
```

출력 확인 : *`URI:spiffe://cluster.local/ns/istioinaction/sa/catalog`*
> SPIFFE ID 확인 : sa/catalog

```
...
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            94:e1:3a:88:ee:a6:c4:7e:04:b4:23:0d:52:93:ce:f5
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=cluster.local
        Validity
            Not Before: Feb 11 21:06:03 2023 GMT
            Not After : Feb 12 21:08:03 2023 GMT
        Subject:
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                ...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            ...
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istioinaction/sa/catalog
         ...
```

이번에는 `openssl verify` 명령으로 X.509 SVID 인증서의 서명을 root CA 인증서로 검증하여 유효한지 확인해 보겠습니다.

```bash
## 1.webapp.istio-proxy 쉘 접속
kubectl -n istioinaction exec -it \
  deploy/webapp -c istio-proxy -- /bin/bash

## 2.webapp.istio-proxy 쉘에서 인증서 검증
openssl verify -CAfile /var/run/secrets/istio/root-cert.pem \
  <(openssl s_client -connect \
  catalog.istioinaction.svc.cluster.local:80 -showcerts 2>/dev/null)

/dev/fd/63: OK
```

지금까지 PeerAuthentication 정책을 사용한 피어 간 인증을 살펴보았는데요    
이는 피어의 "ID"(identity) 를 기반으로 합니다 
- 발급된 ID는 `검증 가능` 하고 트래픽은 안전합니다 👉🏻 인증
- 검증된 ID가 있으면 `접근 제어` 를 할 수 있습니다 👉🏻 인가

이어서 인증된 ID 정보에 기반한 "인가", `Authorization` 에 대해서 살펴 봅니다