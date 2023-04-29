---
title: Istio Ingress Gateway (3)  
version: v1.0  
description: istio in action 4장 실습3  
date: 2022-12-26 20:00:00 +09:00  
layout: post  
toc: 5  
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

Istio는 TCP 트래픽도 다룰 수 있습니다 (지난 실습2에서 이어집니다)

<!--more-->

## TCP traffic

- Istio 는 plain TCP를 다룰 수 있음.
- 즉, database (like mongoDB), mq (like kafka) 등을 expose 할 수 있음
- 단, plain TCP 를 다룰 때는 어떤 protocol 인지 Istio가 알 수 없으므로
- retries, request 레벨 circuit breaking, complex routing .. 등 context를 이해해야 하는 기능들은 사용할 수 없음

### Expose TCP Ports

- TCP 기반 서비스 ( [go-echo](https://github.com/cjimti/go-echo) )를 하나 띄우고
- telnet 등의 TCP 클라이언트와 통신을 해봅시다

echo 서버(go-echo) 기동 - [echo.yaml](https://github.com/istioinaction/book-source-code/blob/master/ch4/echo.yaml)

```bash
kubectl apply -f ch4/echo.yaml -n istioinaction

## 확인
# kubectl get po -n istioinaction
NAME                                   READY   STATUS    RESTARTS       AGE
catalog-5c7f8f8447-sq2rt               1/1     Running   1 (8m2s ago)   12h
tcp-echo-deployment-857b6f8f65-z7kwd   1/1     Running   0              31s
webapp-8dc87795-wrr28                  1/1     Running   1 (8m2s ago)   12h
```

istio-ingressgateway 의 tcp 포트 확인

```bash
kubectl get svc istio-ingressgateway -n istio-system \
-o jsonpath='{.spec.ports[?(@.name=="tcp")]}'

{
  "name": "tcp",
  "nodePort": 30090,
  "port": 31400,
  "protocol": "TCP",
  "targetPort": 31400
}
```

[*gateway-tcp.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/gateway-tcp.yaml) - Ingress Gateway에서 오픈할 Gateway 스펙입니다.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: echo-tcp-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 31400
      name: tcp-echo
      protocol: TCP
    hosts:
    - "*"
```

Gateway 스펙을 적용합니다

```bash
kubectl apply -f ch4/gateway-tcp.yaml -n istioinaction

## 확인
# kubectl get gw -n istioinaction

NAME                AGE
coolstore-gateway   12h
echo-tcp-gateway    39s

```

[*echo-vs.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/echo-vs.yaml) - gw로 부터 echo 서비스로 라우팅하기 위한 VirtualService 스펙입니다.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tcp-echo-vs-from-gw
spec:
  hosts:
  - "*"
  gateways:
  - echo-tcp-gateway     # <-- Which gateway
  tcp:
  - match:
    - port: 31400   # <-- Match on the port
    route:
    - destination:
        host: tcp-echo-service   # <-- Where to route
        port:
          number: 2701
```

VirtualService 스펙을 적용합니다

```bash
kubectl apply -f ch4/echo-vs.yaml -n istioinaction

## 확인
# kubectl get vs -n istioinaction

NAME                  GATEWAYS                HOSTS                          AGE
catalog-vs-from-gw    ["coolstore-gateway"]   ["catalog.istioinaction.io"]   12h
tcp-echo-vs-from-gw   ["echo-tcp-gateway"]    ["*"]                          3s
webapp-vs-from-gw     ["coolstore-gateway"]   ["webapp.istioinaction.io"]    12h
```

호출 테스트

```bash
telnet localhost 31400

Trying ::1...
Connected to localhost.
Escape character is '^]'.
Welcome, you are connected to node minikube.
Running on Pod tcp-echo-deployment-857b6f8f65-z7kwd.
In namespace istioinaction.
With IP address 172.17.0.12.
Service default.
hello Sam    # <-- type here
hello Sam    # <-- echo here
```

- 참고: telnet 이 설치돼 있지 않은 경우 설치해주세요 (아래는 macOS 설치예시)
    
    ```bash
    brew install telnet
    ```
    
- telnet 종료하기
    
    *세션종료*  `Ctrl + ]`  *> 텔넷 종료*  `quit`
    

### SNI passthrough

- [SNI, Server Name Indication - TLS 확장 표준](https://namu.wiki/w/SNI) *(출처: 나무위키)*
    
    > *이 기술이 나오게 된 큰 이유는 하나의 웹서버가 여러 웹사이트를 서비스하면서 인증서 인증에 문제가 생겼기 때문이다. 기존까지는 대상 서버의 IP 주소와 도메인이 1:1 대응 관계라서 서버의 인증서 제공에 문제가 없었지만, 여러 도메인을 하나의 IP 주소로 연결하는 서비스가 대중화되면서 보낼 인증서를 특정하지 못하게 되었다. 이 때문에 클라이언트가 사이트에 접속하면서 도메인 정보를 보내도록 변경한 것이다.*
    > 
    > 
    > *이 SNI를 사용하게 되면 하나의 웹 서버에서 여러 도메인의 웹사이트를 서비스하는 경우에도 인증서를 사용한 HTTPS를 활성화시킬 수 있다.*
    > 
- HTTPS는 헤더정보를 비롯한 모든 메시지가 암호화 됨
- 따라서, TLS 핸드쉐이크가 맺어지기 전까지 Host 헤더를 볼 방법이 없음
- 클라이언트가 서버에게 어떤 도메인(Server Name)을 사용할지 알려줄 방법이 필요
- 클라이언트가 “Client Hello” 패킷에 “TLS Extension 헤더에 SNI extension 정보를 실어서 보냄
- gw에서 SNI헤더를 검사하여 backend로 라우트함
- “pass through” - 커넥션은 gw가 아닌 “**실제 서비스에서 처리**”함
- 이는 gw의 문을 더 넓게 (swath) 여는 것으로
- DB, MQ, 캐시 등과 같은 TLS 기반의 TCP 서비스 뿐만아니라 레거시앱 까지도 처리가능하다

앱1 배포 - [*simple-tls-server-1.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/sni/simple-tls-service-1.yaml)

- TLS 인증을 직접 처리하는 앱 배포. (gw는 route 만 처리, pass through )

```bash
kubectl apply -f ch4/sni/simple-tls-service-1.yaml -n istioinaction

# kubectl get po -n istioinaction
NAME                                    READY   STATUS    
simple-tls-service-1-6697498cdf-vg74p   1/1     Running 
```

기존 Gateway 명세(echo-tcp-gateway) 제거

- istio-ingressgateway의 동일한 port (31400, TCP)를 사용하므로 제거함

```bash
kubectl delete gateway echo-tcp-gateway -n istioinaction
```

신규 Gateway 명세 - [*passthrough-sni-gateway.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/sni/passthrough-sni-gateway.yaml)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: sni-passthrough-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 31400                       # ❶ 포트 오픈
      name: tcp-sni
      protocol: TLS
    hosts:
    - "simple-sni-1.istioinaction.io"     # ❷ 호스트
    tls:
      mode: PASSTHROUGH                   # ❸ GW 통과

```

Gateway 적용

```bash
kubectl apply -f ch4/sni/passthrough-sni-gateway.yaml -n istioinaction

# kubectl get gw -n istioinaction
NAME                      AGE
coolstore-gateway         15h
sni-passthrough-gateway   1s

```

VirtualService 명세 - [*passthrough-sni-vs-1.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/sni/passthrough-sni-vs-1.yaml)

- gw 31400포트로 온 "simple-sni-1.istioinaction.io" 호스트 요청을 앱(destination)으로 route 함

```yaml
# vi ch4/sni/passthrough-sni-vs-1.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-sni-1-vs
spec:
  hosts:
  - "simple-sni-1.istioinaction.io"
  gateways:
  - sni-passthrough-gateway
  tls:
  - match:
    - port: 31400
      sniHosts:
      - simple-sni-1.istioinaction.io
    route:
    - destination:
        host: simple-tls-service-1
        port:
          number: 80
```

VirtualService 적용

```bash
kubectl apply -f ch4/sni/passthrough-sni-vs-1.yaml -n istioinaction
```

호출테스트1

```bash
curl https://simple-sni-1.istioinaction.io:31400/ \
 --cacert ch4/sni/simple-sni-1/2_intermediate/certs/ca-chain.cert.pem \
 --resolve simple-sni-1.istioinaction.io:31400:127.0.0.1

{
  "name": "simple-tls-service-1",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "172.17.0.13"
  ],
  "start_time": "2022-12-25T04:46:26.006282",
  "end_time": "2022-12-25T04:46:26.012223",
  "duration": "5.941ms",
  "body": "Hello from simple-tls-service-1!!!",
  "code": 200
}
```

앱2 배포 - [*simple-tls-service-2.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/sni/simple-tls-service-2.yaml)

```bash
kubectl apply -f ch4/sni/simple-tls-service-2.yaml -n istioinaction
```

Gateway 명세 전/후 비교

- tcp-sni-2 추가
    
    ![스크린샷 2022-12-25 오후 1.54.01.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.54.01.png)
    

Gateway 적용

```bash
kubectl apply -f ch4/sni/passthrough-sni-gateway-both.yaml -n istioinaction
```

VirtualService 명세 - [*passthrough-sni-vs-2.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/sni/passthrough-sni-vs-2.yaml)

```yaml
# vi ch4/sni/passthrough-sni-vs-2.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-sni-2-vs
spec:
  hosts:
  - "simple-sni-2.istioinaction.io"
  gateways:
  - sni-passthrough-gateway
  tls:
  - match:
    - port: 31400
      sniHosts:
      - simple-sni-2.istioinaction.io
    route:
    - destination:
        host: simple-tls-service-2
        port:
          number: 80
```

VirtualService 적용

```bash
kubectl apply -f ch4/sni/passthrough-sni-vs-2.yaml -n istioinaction
```

호출테스트2

```bash
curl https://simple-sni-2.istioinaction.io:31400 \
--cacert ch4/sni/simple-sni-2/2_intermediate/certs/ca-chain.cert.pem \
--resolve simple-sni-2.istioinaction.io:31400:127.0.0.1

{
  "name": "simple-tls-service-2",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "172.17.0.14"
  ],
  "start_time": "2022-12-25T05:00:47.389416",
  "end_time": "2022-12-25T05:00:47.395685",
  "duration": "6.269ms",
  "body": "Hello from simple-tls-service-2!!!",
  "code": 200
}
```