---
title: Istio Ingress Gateway (1)  
version: v1.0  
description: istio in action 4장 실습1  
date: 2022-12-24 22:00:00 +09:00  
layout: page  
toc: 3  
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
Istio의 Ingress Gateway를 실습합니다.  
Istio에서 Ingress Gateway는 외부의 트래픽을 클러스터 내부로 들어오게 하는 문과 같은 역할을 합니다.   
동시에 내부로 들어온 트래픽을 실제 서비스할 Pod로 안내하는 안내자 역할도 수행합니다.  

<!--more-->

약어 abbreviations 

- gw : gateway  ex) ingress gw
- vs : virtual service
- VIP : virtual IP

# 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 챕터4

## 실습환경

(**방법1**) minikube tunnel 을 이용 (**권장**)

minikube 에서 LoadBalancer 타입을 지원. `{EXTERNAL-IP}:{PORT}` 로 접근됨.

```bash
minikube tunnel

## 확인
kubectl get svc istio-ingressgateway -n istio-system

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP PORT
istio-ingressgateway   LoadBalancer   10.108.122.98   127.0.0.1   ..,80:32229/TCP,443:32685 ..
```

(방법2) minikube service 를 이용 (**방법1**이 안될 경우 사용)

> [컨테이너:8080] —(서비스:80) —> [VM:31365] —( ssh 터널링, minikube ) —> [호스트:52738]
> 

```bash
minikube service istio-ingressgateway  -n istio-system

|--------------|----------------------|-------------------|---------------------------|
|  NAMESPACE   |         NAME         |    TARGET PORT    |            URL            |
|--------------|----------------------|-------------------|---------------------------|
| istio-system | istio-ingressgateway | status-port/15021 | http://192.168.49.2:30289 |
|              |                      | http2/80          | http://192.168.49.2:31365 |
|              |                      | https/443         | http://192.168.49.2:31605 |
|              |                      | tcp/31400         | http://192.168.49.2:30503 |
|              |                      | tls/15443         | http://192.168.49.2:32721 |
|--------------|----------------------|-------------------|---------------------------|
🏃  istio-ingressgateway 서비스의 터널을 시작하는 중
|--------------|----------------------|-------------|------------------------|
|  NAMESPACE   |         NAME         | TARGET PORT |          URL           |
|--------------|----------------------|-------------|------------------------|
| istio-system | istio-ingressgateway |             | http://127.0.0.1:52737 |
|              |                      |             | http://127.0.0.1:52738 |
|              |                      |             | http://127.0.0.1:52739 |
|              |                      |             | http://127.0.0.1:52740 |
|              |                      |             | http://127.0.0.1:52741 |
|--------------|----------------------|-------------|------------------------|
```

# Istio Ingress Gateway

## Ingress Gateway 둘러보기

- 클러스터의 관문 역할
- outside → inside traffic의 인입 처리
- Security 가 중요하고
- 인입을 위한 룰 매칭 등을 처리
- 인입 후에는 inside 서비스로 라우팅도 담당

istio-ingressgateway 프로세스 확인

- envoy가 핵심
- pilot-agent 는 envoy 동작을 위한 초기구성 및 환경설정 등을 처리

```bash
kubectl -n istio-system exec \
deploy/istio-ingressgateway -- ps

PID TTY          TIME CMD
      1 ?        00:00:00 pilot-agent
     19 ?        00:00:06 envoy
     41 ?        00:00:00 ps
```

istio-ingressgateway 서비스

- Client에 노출하고자하는 ingress gw Endpoint들을 서비스(VIP or cluster IP)로 묶어서 제공합니다.
- Port : 서비스에서 노출하는 포트
- TargetPort : Ingress gw의 포트
- NodePort : 실제 물리노드의 포트
- (Client) → NodePort → Port → TargetPort

```bash
kubectl describe svc istio-ingressgateway -n istio-system

..
LoadBalancer Ingress:     127.0.0.1
..
Port:                     status-port  15021/TCP
TargetPort:               15021/TCP
NodePort:                 status-port  30289/TCP
Endpoints:                172.17.0.10:15021
..
Port:                     http2  80/TCP      # <== 서비스 포트
TargetPort:               8080/TCP           # <== ingress-gateway 포트
NodePort:                 http2  31365/TCP   # <== 외부 노출
Endpoints:                172.17.0.10:8080   # <== ingress-gateway IP:포트
..
```

istio-ingressgateway (컨테이너) 포트 확인

- Ingress gw에서 사용하는 포트
- 15021 : health check
- 8080 : HTTP
- 8443 : HTTPS
- 31400
- 15443
- 15090 : prometheus metrics

```bash
kubectl get deploy istio-ingressgateway -n istio-system \
-o jsonpath='{.spec.template.spec.containers[0].ports[*].containerPort}'

15021 8080 8443 31400 15443 15090
```

listener  확인

- Envoy로 부터 파드(아래, istio-ingressgateway)의 리스너 설정을 확인한다
- 외부 → (리스너) → 내부  : 외부에서 내부로 들어오는 포트 정보 확인  

```bash
istioctl proxy-config listener deploy/istio-ingressgateway -n istio-system

ADDRESS PORT  MATCH DESTINATION
0.0.0.0 15021 ALL   Inline Route: /healthz/ready*
0.0.0.0 15090 ALL   Inline Route: /stats/prometheus*
```

route 확인

- Envoy로 부터 파드(아래, istio-ingressgateway)의 라우트 설정을 확인한다
- 내부 → (라우트) → Virtual Servcie : 내부 Virtual Service로 라우팅 조건 확인  

```bash
istioctl proxy-config route deploy/istio-ingressgateway -n istio-system

NAME     DOMAINS     MATCH                  VIRTUAL SERVICE
         *           /healthz/ready*
         *           /stats/prometheus*
```

## Gateway 명세를 추가해 보자

Gateway 설정

```yaml
# vi ch4/coolstore-gw.yaml

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
```

Gateway 적용

```bash
kubectl -n istioinaction apply -f ch4/coolstore-gw.yaml
```

listener 확인 - 포트(8080)가 리스너 항목에 추가됨

```bash
istioctl proxy-config listener deploy/istio-ingressgateway -n istio-system

ADDRESS PORT  MATCH DESTINATION
0.0.0.0 8080  ALL   Route: http.8080
0.0.0.0 15021 ALL   Inline Route: /healthz/ready*
0.0.0.0 15090 ALL   Inline Route: /stats/prometheus*                                                                                                                                                                                                     
```

route  확인 - http.8080 라우트는 모든 요청에 대해 blackhole (404) 로 라우팅

```bash
istioctl proxy-config route deploy/istio-ingressgateway -n istio-system

NAME          DOMAINS     MATCH                  VIRTUAL SERVICE
http.8080     *           /*                     404
              *           /healthz/ready*
              *           /stats/prometheus*
```

```bash
istioctl proxy-config route deploy/istio-ingressgateway \
-o json --name http.8080 -n istio-system

[
    {
        "name": "http.8080",
        "virtualHosts": [
            {
                "name": "blackhole:80",
                "domains": [
                    "*"
                ]
            }
        ],
        "validateClusters": false,
        "ignorePortInHostMatching": true
    }
]
```

## VirtualService 명세를 추가해 보자

VirtualService 명세를 통해서 Gateway 에서 라우팅할 서비스 Endpoint를 등록해 봅니다.

VirtualService 명세 - coolstore-gateway 에 라우팅할 서비스를 추가합니다.

```yaml
# vi ch4/coolstore-vs.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: webapp-vs-from-gw
spec:
  hosts:
  - "webapp.istioinaction.io"
  gateways:
  - coolstore-gateway
  http:
  - route:
    - destination:
        host: webapp
        port:
          number: 80

```

VirtualService 적용

```bash
kubectl apply -f ch4/coolstore-vs.yaml -n istioinaction
```

확인

```yaml
istioctl proxy-config route deploy/istio-ingressgateway -n istio-system

NAME          DOMAINS                     MATCH                  VIRTUAL SERVICE
http.8080     webapp.istioinaction.io     /*                     webapp-vs-from-gw.istioinaction
              *                           /healthz/ready*
              *                           /stats/prometheus*
```

상세조회

```bash
istioctl proxy-config route deploy/istio-ingressgateway \
-n istio-system --name http.8080 -o json

[
    {
        "name": "http.8080",
        "virtualHosts": [
            {
                "name": "webapp.istioinaction.io:80",
                "domains": [
                    "webapp.istioinaction.io"
                ],
                "routes": [
                    {
                        "match": {
                            "prefix": "/"
                        },
                        "route": {
                            "cluster": "outbound|80||webapp.istioinaction.svc.cluster.local",
                            "timeout": "0s",
                            "retryPolicy": {
                                "retryOn": "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes",
                                "numRetries": 2,
                                "retryHostPredicate": [
                                    {
                                        "name": "envoy.retry_host_predicates.previous_hosts",
                                        "typedConfig": {
                                            "@type": "type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate"
                                        }
                                    }
                                ],
                                "hostSelectionRetryMaxAttempts": "5",
                                "retriableStatusCodes": [
                                    503
                                ]
                            },
                            "maxStreamDuration": {
                                "maxStreamDuration": "0s",
                                "grpcTimeoutHeaderMax": "0s"
                            }
                        },
                        "metadata": {
                            "filterMetadata": {
                                "istio": {
                                    "config": "/apis/networking.istio.io/v1alpha3/namespaces/istioinaction/virtual-service/webapp-vs-from-gw"
                                }
                            }
                        },
                        "decorator": {
                            "operation": "webapp.istioinaction.svc.cluster.local:80/*"
                        }
                    }
                ],
                "includeRequestAttemptCount": true
            }
        ],
        "validateClusters": false,
        "ignorePortInHostMatching": true
    }
]
```

테스트 앱 기동

참고: [catalog.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/services/catalog/kubernetes/catalog.yaml), [webapp.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/services/webapp/kubernetes/webapp.yaml)

```bash
kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction
kubectl apply -f services/webapp/kubernetes/webapp.yaml -n istioinaction
```

기동 및 설정 확인

```bash
# kubectl get po -n istioinaction

NAME                       READY   STATUS    RESTARTS   AGE
catalog-5c7f8f8447-xvczs   2/2     Running   0          2m25s
webapp-8dc87795-szkrf      2/2     Running   0          2m22s

# kubectl get gateway -n istioinaction

NAME                AGE
coolstore-gateway   5m33s

# kubectl get virtualservice -n istioinaction

NAME                GATEWAYS                HOSTS                         AGE
webapp-vs-from-gw   ["coolstore-gateway"]   ["webapp.istioinaction.io"]   5m21s
```

호출 테스트

```bash
curl -H "Host: webapp.istioinaction.io" http://127.0.0.1/api/catalog
```

## Istio Ingress Gateway vs Kubernetes Ingress

Kubernetes Ingress’ limitation

- Only support Simple, Underspecified HTTP routes (80/443)
- Lack of specification causes various vendors’ ingress implementation.
- Underspecified things make most vendors have chosen to expose configuration through bespoke annotations.

Istio Ingress Gateway inspired Kubernetes Gateway API in many ways.

## Istio Ingress Gateway vs API Gateway

Istio Ingress Gateway dose not identify clients.