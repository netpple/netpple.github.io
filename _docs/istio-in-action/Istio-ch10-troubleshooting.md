---
title: Istio Troubleshooting  
version: v1.0  
description: istio in action 10장  
date: 2023-05-08 19:00:00 +09:00  
layout: post  
toc: 16  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
  histories:
- date: 2023-05-08 19:00:00 +09:00
  description: 최초 등록
---

10장에서는 Istio data-plane troubleshooting 에 대해 다룹니다

<!--more-->

# 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 챕터10

## 다루는 내용

- Data-plane 의 문제를 진단하고 조치해나가는 과정을 실습해 봅니다
    - Misconfiguration 진단 및 조치
    - Application 진단 및 조치

## 용어

## 실습환경

- minikube (k8s) 및 istio 설치.  참고: [https://netpple.github.io/2023/Istio-Environment/](https://netpple.github.io/2023/Istio-Environment/)
- **실습 네임스페이스** : istioinaction
- **실습 디렉토리** : book-source-code

### 실습초기화

반복 실습 등을 위해 초기화 후 사용하세요

*istioinaction 네임스페이스 초기화*

```bash
kubectl delete ns istioinaction &&
kubectl create ns istioinaction &&
kubectl label ns istioinaction istio-injection=enabled
```

*istio-system 네임스페이스 초기화*

```bash
kubectl delete authorizationpolicy,peerauthentication,requestauthentication -n istio-system
```

MeshConfig 에 external authz 설정을 확인해서 지워줍니다

```bash
# kubectl edit cm istio -n istio-system

apiVersion: v1
data:
  mesh: |-
  ..
    extensionProviders:
  #### 삭제 시작 #####
    - envoyExtAuthzHttp:
        includeRequestHeadersInCheck:
        - x-ext-authz
        port: "8000"
        service: ext-authz.istioinaction.svc.cluster.local
      name: sample-ext-authz-http
  #### 삭제 끝 #####
  ..
```

*default 네임스페이스 초기화*

```bash
kubectl delete deploy/sleep -n default
kubectl delete svc/sleep -n default
```

# 10.1 The most common mistake: A misconfigured data plane

```bash
## catalog v1 배포
kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction

## catalog v2 배포
kubectl apply -f ch10/catalog-deployment-v2.yaml -n istioinaction

## catalog-gateway 배포 - catalog.istioinaction.io:80
kubectl apply -f ch10/catalog-gateway.yaml -n istioinaction

## 
kubectl apply -f ch10/catalog-virtualservice-subsets-v1-v2.yaml -n istioinaction
```

- [catalog.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/services/catalog/kubernetes/catalog.yaml)
- [catalog-deployment-v2.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch10/catalog-deployment-v2.yaml)
- [catalog-gateway.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch10/catalog-gateway.yaml)
- [catalog-virtualservice-subsets-v1-v2.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch10/catalog-virtualservice-subsets-v1-v2.yaml)

```bash
for i in {1..100}; do curl http://localhost/items \
-H "Host: catalog.istioinaction.io" \
-w "\nStatus Code %{http_code}\n"; sleep .5;  done
```

> *출력 결과는 ?*
> 

# 10.2 Identifying data-plane issues

*수사는 어떻게 할 것인가? (다양한 수사도구를 확인해 보아요)*

xDS SYNC 현황 등 proxy 상태 조회

```bash
istioctl proxy-status
```

Kiali 조회 - Istio Config 오류 시 warning 제공 

```bash
istioctl dashboard kiali

## or ##
# kubectl port-forward -n istio-system svc/kiali 20001
```

![스크린샷 2023-03-23 오전 8.37.38.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.37.38.png)

![스크린샷 2023-03-23 오전 8.38.01.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.38.01.png)

![스크린샷 2023-03-23 오전 8.38.32.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.38.32.png)

![스크린샷 2023-03-23 오전 8.40.30.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.40.30.png)

![스크린샷 2023-03-23 오전 8.39.09.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.39.09.png)

namespace validation

```bash
# istioctl analyze -n istioinaction

Error [IST0101] (VirtualService istioinaction/catalog-v1-v2) Referenced host+subset in destinationrule not found: "catalog.istioinaction.svc.cluster.local+version-v1"
Error [IST0101] (VirtualService istioinaction/catalog-v1-v2) Referenced host+subset in destinationrule not found: "catalog.istioinaction.svc.cluster.local+version-v2"
Error: Analyzers found issues when analyzing namespace: istioinaction.
See https://istio.io/v1.16/docs/reference/config/analysis for more information about causes and resolutions
```

pod validation

```bash
# istioctl x describe pod catalog-5c7f8f8447-f54sh

Pod: catalog-5c7f8f8447-f54sh
   Pod Revision: default
   Pod Ports: 3000 (catalog), 15090 (istio-proxy)
--------------------
Service: catalog
   Port: http 80/HTTP targets pod port 3000
--------------------
Effective PeerAuthentication:
   Workload mTLS mode: PERMISSIVE

Exposed on Ingress Gateway http://127.0.0.1
VirtualService: catalog-v1-v2
   WARNING: No destinations match pod subsets (checked 1 HTTP routes)
      Warning: Route to subset version-v1 but NO DESTINATION RULE defining subsets!
      Warning: Route to subset version-v2 but NO DESTINATION RULE defining subsets!
```

> *어떻게 하면 문제를 해결할 수 있을까요?*
> 

# 10.3 Discovering misconfigurations manually from the Envoy config

## 10.3.1 Envoy administration interface

*Envoy 대시보드*

```bash
istioctl dashboard envoy deploy/catalog -n istioinaction
```

config_dump 클릭

![스크린샷 2023-04-30 오전 11.25.03.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-04-30_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.25.03.png)

## 10.3.2 Querying proxy configurations using istioctl

### *THE INTERACTION OF ENVOY APIs TO ROUTE A REQUEST*

![스크린샷 2023-04-30 오전 11.28.07.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-04-30_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.28.07.png)

### [LDS] *QUERYING THE ENVOY LISTENER CONFIGURATION*

```bash
# istioctl pc listeners deploy/istio-ingressgateway -n istio-system

ADDRESS PORT  MATCH DESTINATION
0.0.0.0 8080  ALL   Route: http.8080
0.0.0.0 15021 ALL   Inline Route: /healthz/ready*
0.0.0.0 15090 ALL   Inline Route: /stats/prometheus*
```

### [RDS] *QUERYING THE ENVOY ROUTE CONFIGURATION*

```bash
# istioctl pc routes deploy/istio-ingressgateway -n istio-system --name http.8080

NAME          DOMAINS                         MATCH     VIRTUAL SERVICE
http.8080     catalog.istioinaction.io        /*        catalog-v1-v2.istioinaction
```

```bash
# istioctl pc routes deploy/istio-ingressgateway -n istio-system --name http.8080 -o json

..
"route": {
  "weightedClusters": {
    "clusters": [
      {
        "name": "outbound|80|version-v1|catalog.istioinaction.svc.cluster.local",
        "weight": 20
      },
      {
        "name": "outbound|80|version-v2|catalog.istioinaction.svc.cluster.local",
        "weight": 80
      }
    ],
    "totalWeight": 100
  },
..
```

### [CDS] QUERYING THE ENVOY CLUSTER CONFIGURATION

```bash
# istioctl pc clusters deploy/istio-ingressgateway.istio-system --fqdn catalog.istioinaction.svc.cluster.local --port 80 --subset version-v1

SERVICE FQDN   PORT   SUBSET   DIRECTION   TYPE   DESTINATION RULE
(결과 없음)
```

- 패킷을 보낼 ENVOY 클러스터에 대한 정보가 없음

ENVOY 클러스터 정보 (destinationrule) 를 등록해 주자

- DestinationRule YAML validation
    
    ```bash
    # istioctl analyze ch10/catalog-destinationrule-v1-v2.yaml -n istioinaction
    
    ✔ No validation issues found when analyzing ch10/catalog-destinationrule-v1-v2.yaml.
    ```
    
- DestinationRule 적용
    
    ```bash
    kubectl apply -f ch10/catalog-destinationrule-v1-v2.yaml
    ```
    
- 등록 확인
    
    ```bash
    istioctl pc clusters deploy/istio-ingressgateway.istio-system --fqdn catalog.istioinaction.svc.cluster.local --port 80
    ```
    
    ![스크린샷 2023-03-23 오후 12.20.04.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.20.04.png)
    

### [CDS] HOW CLUSTERS ARE CONFIGURED

```bash
# istioctl pc clusters deploy/istio-ingressgateway.istio-system --fqdn catalog.istioinaction.svc.cluster.local --port 80 --subset version-v1 -o json

..
"edsClusterConfig": {
  "edsConfig": {
    "ads": {},
    "initialFetchTimeout": "0s",
    "resourceApiVersion": "V3"
  },
  "serviceName": "outbound|80|version-v1|catalog.istioinaction.svc.cluster.local"
},
..
```

> *The output shows that `edsClusterConfig` is configured to use the Aggregated Discovery Service (**ADS**) to query the endpoints. The service name `outbound|80|version -v1|catalog.istioinaction.svc.cluster.local` is used as a filter for the endpoints to query from ADS.*
> 

### [EDS] QUERYING ENVOY CLUSTER ENDPOINTS

```bash
# istioctl pc endpoints deploy/istio-ingressgateway.istio-system --cluster "outbound|80|version-v1|catalog.istioinaction.svc.cluster.local"

ENDPOINT            STATUS      OUTLIER CHECK     CLUSTER
172.17.0.6:3000     HEALTHY     OK                outbound|80|version-v1|catalog.istioinaction.svc.cluster.local
```

ENDPOINT(ip:port) 는 각 자 환경마다 다름

```bash
# kubectl get pod -n istioinaction --field-selector status.podIP=172.17.0.6
NAME                       READY   STATUS    RESTARTS      AGE
catalog-5c7f8f8447-f54sh   2/2     Running   2 (16m ago)   3h56m
```

> *문제는 해결 되었나요 ? 호출이 잘되는지 확인해 보세요*
> 

```bash
curl -H "Host: catalog.istioinaction.io" localhost/items
```

> *Kiali 대시보드도 처음과 비교해 보세요*
> 

![스크린샷 2023-04-30 오후 1.29.36.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-04-30_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.29.36.png)

![스크린샷 2023-04-30 오후 1.29.55.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-04-30_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.29.55.png)

> *istioctl analyze/describe 도 처음과 비교해 보세요*
> 

```bash
# istioctl analyze -n istioinaction

✔ No validation issues found when analyzing namespace: istioinaction.

# istioctl x describe pod catalog-5c7f8f8447-m7k2k

Pod: catalog-5c7f8f8447-m7k2k
   Pod Revision: default
   Pod Ports: 3000 (catalog), 15090 (istio-proxy)
--------------------
Service: catalog
   Port: http 80/HTTP targets pod port 3000
DestinationRule: catalog for "catalog.istioinaction.svc.cluster.local"
   Matching subsets: version-v1
      (Non-matching subsets version-v2)
   No Traffic Policy
--------------------
Effective PeerAuthentication:
   Workload mTLS mode: PERMISSIVE

Exposed on Ingress Gateway http://127.0.0.1
VirtualService: catalog-v1-v2
   Weight 20%
```

지금까지 istio data-plane 의 “misconfiguration 이슈” 진단하는 과정을 실습을 통해 살펴보았습니다

다음은 data-plane의 “애플리케이션 이슈”를 진단하고 해결해 나가보도록 하겠습니다 

## 10.3.3 Troubleshooting application issues

“간헐적 타임아웃”을 발생시키는 애플리케이션 이슈를 다뤄봅시다 

### SETTING UP AN INTERMITTENTLY SLOW WORKLOAD THAT TIMES OUT

catalog-v2 앱 중 하나를 “slow response” 하도록 설정합니다

```bash
CATALOG_POD=$(kubectl get pods -l version=v2 -n istioinaction \-o jsonpath={.items..metadata.name} | cut -d ' ' -f1) ;

kubectl -n istioinaction exec -c catalog $CATALOG_POD \
-- curl -s -X POST -H "Content-Type: application/json" \
-d '{"active": true, "type": "latency", "volatile": true}' \
localhost:3000/blowup ;

echo $CATALOG_POD
```

- CATALOG_POD 를 기억해 두세요

VirtualService 타임아웃을 0.5s 로 설정합니다 (slow response 발생 시 타임아웃 동작)

```bash
kubectl patch vs catalog-v1-v2 -n istioinaction --type json \
-p '[{"op": "add", "path": "/spec/http/0/timeout", "value": "0.5s"}]'
```

```json
// kubectl get vs catalog-v1-v2 -o jsonpath='{.spec.http[?(@.timeout=="0.5s")]}'

{
  "route": [
    {
      "destination": {
        "host": "catalog.istioinaction.svc.cluster.local",
        "port": {
          "number": 80
        },
        "subset": "version-v1"
      },
      "weight": 20
    },
    {
      "destination": {
        "host": "catalog.istioinaction.svc.cluster.local",
        "port": {
          "number": 80
        },
        "subset": "version-v2"
      },
      "weight": 80
    }
  ],
  "timeout": "0.5s"
}

```

```bash
for in in {1..9999}; do curl http://localhost/items \
-H "Host: catalog.istioinaction.io" \
-w "\nStatus Code %{http_code}\n"; sleep 1; done

..
Status code 504
..
```

- 간헐적으로 504 응답코드 발생 (slow response)

```bash
# kubectl -n istio-system logs deploy/istio-ingressgateway | grep 504

..
[2023-03-23T03:53:08.335Z] "GET /items HTTP/1.1" 504 UT response_timeout - "-" 0 24 501 - "172.17.0.1" "curl/7.86.0" "d3bfca59-6327-9f24-a755-50d32a8782f2" "catalog.istioinaction.io" "172.17.0.17:3000" outbound|80|version-v2|catalog.istioinaction.svc.cluster.local 172.17.0.14:49258 172.17.0.14:8080 172.17.0.1:5221 - -
..
```

(알아보기 어렵다)

참고) 로그 출력 설정  - 액세스로그가 나오지 않을 경우 아래와 같이 MeshConfig 설정

```bash
kubectl edit cm istio -n istio-system

apiVersion: v1
data:
  mesh: |-
    accessLogFile: /dev/stdout
..
```

### CHANGING THE ENVOY ACCESS LOG FORMAT

ENVOY 액세스 로그 포맷을 JSON으로 읽기 쉽게 바꿉니다 (MeshConfig 설정)

```bash
# kubectl edit cm istio -n istio-system

apiVersion: v1
data:
  mesh: |-
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
..
```

참고) istioctl install 로 설정할 수 도 있으나 기존 MeshConfig 을 덮어쓰기 때문에 주의요함

```bash
istioctl install --set meshConfig.accessLogFile="/dev/stdout" --set meshConfig.accessLogEncoding="JSON"
```

`504` 로그 확인

```bash
kubectl -n istio-system logs deploy/istio-ingressgateway | grep 504 | tail -n 1 | jq

{
  "authority": "catalog.istioinaction.io",
  "request_id": "4a1fe131-7363-9a90-a18f-f5412f9ede67",
  "response_flags": "UT",
  "requested_server_name": null,
  "upstream_cluster": "outbound|80|version-v2|catalog.istioinaction.svc.cluster.local",
  "response_code": 504,
  "upstream_transport_failure_reason": null,
  "bytes_sent": 24,
  "duration": 500,
  "downstream_remote_address": "172.17.0.1:50956",
  "bytes_received": 0,
  "protocol": "HTTP/1.1",
  "response_code_details": "response_timeout",
  "downstream_local_address": "172.17.0.14:8080",
  "upstream_host": "172.17.0.17:3000",
  "path": "/items",
  "upstream_service_time": null,
  "user_agent": "curl/7.86.0",
  "upstream_local_address": "172.17.0.14:56280",
  "x_forwarded_for": "172.17.0.1",
  "method": "GET",
  "start_time": "2023-03-23T03:55:51.239Z",
  "route_name": null,
  "connection_termination_details": null
}
```

> [Envoy’s Response Flag](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#command-operators)
> 
> - UT - Upstream request timeout
> - UH - No healthy upstream hosts
> - NR - No [route configured](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_routing#arch-overview-http-routing)
> - UC - Upstream connection termination
> - DC - Downstream connection termination

SLOW_POD 확인

```bash
SLOW_POD_IP=$(kubectl -n istio-system logs deploy/istio-ingressgateway | grep 504 | tail -n 1 | jq -r .upstream_host | cut -d ":" -f1) ;
SLOW_POD=$(kubectl get pods -n istioinaction --field-selector status.podIP=$SLOW_POD_IP -o jsonpath={.items..metadata.name})

echo $SLOW_POD
```

- slow reponse 설정했던 CATALOG_POD 와 비교해보세요

### INCREASING THE LOGGING LEVEL FOR THE INGRESS GATEWAY

istio-ingressgateway 의 로그레벨을 변경합니다 

로그 레벨 조회

```bash
# istioctl pc log deploy/istio-ingressgateway -n istio-system
..
connection: warning
..
http: warning
..
pool: warning
..
router: warning
..
```

로그 레벨 변경

```bash
istioctl pc log deploy/istio-ingressgateway.istio-system --level http:debug,router:debug,connection:debug,pool:debug
```

로그 저장

```bash
kubectl logs -n istio-system deploy/istio-ingressgateway > /tmp/ingress-logs.txt
```

로그 확인

```bash
# vi /tmp/ingress-logs.txt
## find '504'
..
2023-03-23T04:09:47.825217Z     debug   envoy http      [C9446][S10916694052055293453] encoding headers via codec (end_stream=false):
':status', '504'
'content-length', '24'
'content-type', 'text/plain'
'date', 'Thu, 23 Mar 2023 04:09:47 GMT'
'server', 'istio-envoy'
..

## ------------- ##

## find 'C9446' (Connection ID)
[C9446] new stream   # <-- Start
## Stream ID 'S10916694052055293453' # <-- 
2023-03-23T04:09:47.323754Z     debug   envoy http      [C9446][S10916694052055293453] request headers complete (end_stream=true):
':authority', 'catalog.istioinaction.io'
':path', '/items'
':method', 'GET'
'user-agent', 'curl/7.86.0'
'accept', '*/*'

2023-03-23T04:09:47.323758Z     debug   envoy http      [C9446][S10916694052055293453] request end stream
2023-03-23T04:09:47.323766Z     debug   envoy connection        [C9446] current connecting state: false
## /items 요청이 cluster로 매칭됨
2023-03-23T04:09:47.323814Z     debug   envoy router    [C9446][S10916694052055293453] cluster 'outbound|80|version-v2|catalog.istioinaction.svc.cluster.local' match for URL '/items'
2023-03-23T04:09:47.323847Z     debug   envoy router    [C9446][S10916694052055293453] router decoding headers:
':authority', 'catalog.istioinaction.io'
':path', '/items'
':method', 'GET'
':scheme', 'http'
..
'x-envoy-expected-rq-timeout-ms', '500'
..
## C9386 커넥션 - 매칭된 cluster 
2023-03-23T04:09:47.323855Z     debug   envoy pool      [C9386] using existing fully connected connection
2023-03-23T04:09:47.323857Z     debug   envoy pool      [C9386] creating stream
2023-03-23T04:09:47.323861Z     debug   envoy router    [C9446][S10916694052055293453] pool ready
{"response_code_details":"via_upstream","user_agent":"curl/7.86.0","request_id":"722ef34b-553e-9b82-8a73-a716de0b14fc","response_flags":"-","upstream_cluster":"outbound|80|version-v2|catalog.istioinaction.svc.cluster.local","downstream_remote_address":"172.17.0.1:48499","connection_termination_details":null,"upstream_transport_failure_reason":null,"bytes_received":0,"duration":420,"authority":"catalog.istioinaction.io","route_name":null,"response_code":200,"x_forwarded_for":"172.17.0.1","bytes_sent":502,"start_time":"2023-03-23T04:09:46.421Z","path":"/items","upstream_service_time":"420","downstream_local_address":"172.17.0.14:8080","method":"GET","requested_server_name":null,"upstream_host":"172.17.0.17:3000","protocol":"HTTP/1.1","upstream_local_address":"172.17.0.14:52046"}
..
## upstream timeout 으로 client 에서 끊음 (disconnect)
2023-03-23T04:09:47.**824655Z**     debug   envoy router    [C9446][S10916694052055293453] upstream timeout
2023-03-23T04:09:47.824784Z     debug   envoy router    [C9446][S10916694052055293453] resetting pool request
2023-03-23T04:09:47.824807Z     debug   envoy connection        [C9386] closing data_to_write=0 type=1
2023-03-23T04:09:47.824813Z     debug   envoy connection        [C9386] closing socket: 1
2023-03-23T04:09:47.824938Z     debug   envoy connection        [C9386] SSL shutdown: rc=0
## client disconnected
2023-03-23T04:09:47.**825031Z**     debug   envoy pool      [C9386] client disconnected, failure reason:
2023-03-23T04:09:47.825110Z     debug   envoy http      [C9446][S10916694052055293453] Sending local reply with details response_timeout
2023-03-23T04:09:47.825217Z     debug   envoy http      [C9446][S10916694052055293453] encoding headers via codec (end_stream=false):
':status', '504'
'content-length', '24'
'content-type', 'text/plain'
'date', 'Thu, 23 Mar 2023 04:09:47 GMT'
'server', 'istio-envoy'
2023-03-23T04:09:47.825686Z     debug   envoy pool      [C9386] destroying stream: 0 remaining
2023-03-23T04:09:47.831200Z     debug   envoy connection        [C9446] remote close
2023-03-23T04:09:47.831231Z     debug   envoy connection        [C9446] closing socket: 0
```

- SLOW_POD 의 지연으로  UT (Upstream Timeout) 으로 client 에서 disconnect 하여 504 가 발생함

지금까지 istio-ingressgateway 로그 분석을 통해 에러 원인을 확인해 보았습니다 

## 10.3.4 Inspect network traffic with ksniff

ksniff 를 이용한 Kubernetes Pod 패킷 덤프 및 확인 

### INSTALLING KREW, KSNIFF, AND WIRESHARK

설치 (맥 M1)

- krew 설치 - [https://krew.sigs.k8s.io/docs/user-guide/setup/install](https://krew.sigs.k8s.io/docs/user-guide/setup/install)
- ksniff 설치
    
    ```bash
    kubectl krew install sniff
    ```
    
- wireshark 설치 - [https://www.wireshark.org/download.html](https://www.wireshark.org/download.html)

**설치확인**

ksniff → Mac → VM → minikube (container) → pod container

```bash
kubectl sniff <pod> -p -o -
```

*주1) M1 minikube 환경에서 ksniff 로 pod tcpdump 출력 안됨* 

- *본 실습을 수행 하려면 minikube 환경이 아닌 쿠버네티스 클러스터 사용할 것*

주2) M1 vagrant-parallels 환경에서도 출력안됨

[vagrant-parallels 기반 실습 환경](https://www.notion.so/vagrant-parallels-232b55ae5c1e42058145f10d33daa8f2)

### INSPECTING NETWORK TRAFFIC ON THE LOCALHOST INTERFACE

참고 SLOW_POD

```bash
for in in {1..9999}; do curl http://192.168.100.2:31028/items \
-H "Host: catalog.istioinaction.io" \
-w "\nStatus Code %{http_code}\n"; sleep 1; done
```

SLOW_POD에 tcpdump를 겁니다 

```bash
KUBECONFIG=~/.kube/config-sfarm1; kubectl sniff $SLOW_POD -n istioinaction -p -i lo
```

- *kubeconfig가 여러개인 경우, 환경변수(KUBECONFIG)에 명시해야 함*
- *-p, --privileged  : 대상 pod의 netns를 공유하는 ksniff pod (privileged) 를 띄움*
- FAQ - *vagrant-parallels ⇒ ksniff 실행 시 KUBECONFIG 환경변수를 지정할 것*
    
    ```bash
    Error: invalid configuration: [context was not found for specified context: vagrant-admin@vagrant, cluster has no server defined]
    ```
    

트래픽 발생

```bash
for in in {1..9999}; do curl http://search-farm-dev16.dakao.io:30281/items \
-H "Host: catalog.istioinaction.io" \
-w "\nStatus Code %{http_code}\n"; sleep 1; done
```

Wireshark 확인

1. http contains “GET /items”
    
    ![스크린샷 2023-05-02 오전 8.52.39.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-05-02_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.52.39.png)
    
2. 첫번째 아이템 > (right click menu) > “Follow” > “TCP Stream” 
    
    ![스크린샷 2023-05-02 오전 8.53.22.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-05-02_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.53.22.png)
    
    (아래) 창이 뜨면 `close` 
    
    ![스크린샷 2023-05-02 오전 8.53.51.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-05-02_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.53.51.png)
    
3. 패킷 확인 (504 에러)

![스크린샷 2023-03-23 오후 11.01.20.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-03-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_11.01.20.png)

- 4185 패킷 - 요청 GET /items
- 4186 패킷 - 서버 측 ACK
- 4192 패킷 - **클라이언트에서** FIN, ACK (연결종료) 패킷 보냄 
⇒ Why? 4186과 4192의 Time Gap 이 약 500ms  * *0.501683 = 91.020323 - 90.518640*

(참고) 200 OK 경우

![스크린샷 2023-05-02 오전 9.06.15.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-05-02_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_9.06.15.png)

# 10.4 Understanding your application using Envoy Telemetry

## Envoy Telemetry 를 사용하여 애플리케이션 이해하기

*Istio Service Dashboard 를 살펴봅시다*

Reporter > Source 로 설정합니다  ~ 송신(client) 측 envoy 에서 보고(report) 한 메트릭을 봅니다

![grafana_UT_DC_이해하기.png](/docs/assets/img/istio-in-action/grafana_UT_DC_%25E1%2584%258B%25E1%2585%25B5%25E1%2584%2592%25E1%2585%25A2%25E1%2584%2592%25E1%2585%25A1%25E1%2584%2580%25E1%2585%25B5.png)

![스크린샷 2023-05-02 오전 9.48.58.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-05-02_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_9.48.58.png)

Client/Server Success Rate (non-5xx) 이 다름

- Client  : 76.9%
- Server  : 100%

어떤 의미일까요?

- Client 응답에는 5xx 가 있음 (23.1%)
- Server 응답에는 5xx 없음 (0%)

왜 그럴까요?

- Server 에서 수신한 데이터는 모두 성공임 ⇒ 서버 문제는 아님 (서버 문제였다면 서버의 Success Rate도 100%가 아니겠죠)
- 다만, Client 에서서버가 제한시간(500ms)을 넘기는 경우 UT, Upstream Terminate

서버 측 얘기도 들어봅시다

*메트릭을 살펴 봅시다*

prometheus 대시보드에서 다음과 같이 promQL을 조회합니다

```bash
sort_desc(sum(irate(istio_requests_total{reporter="destination", destination_service=~"catalog.istioinaction.svc.cluster.local",response_flags="DC"}[5m]))by(response_code, pod, version))
```

(참고)

```
sort_desc(
  sum(
    irate(
      istio_requests_total {
        reporter="destination",   # 서버 측에서 리포트
        destination_service=~"catalog.istioinaction.svc.cluster.local",   # 서버 측이 목적지
        response_flags="DC"       # DC - 클라이언트에서 커넥션을 끊음
      }[5m]
    )
  )by(response_code, pod, version)
)
```

서버 쪽에 5분간 발생한 DC가 있는지 쿼리한 결과입니다 

이는 Server 입장에서 보면 Client가 일방적으로 (전화를 확~) 끊은 것이죠 ⇒  DC (Downstream Connection Terminate)
*“나는 대답해 줄라 카는데 갸가 확 끊어불써 ~”*

서버오류로 발생한 5xx가 아닌 클라이언트의 UT, 즉 서버 입장에서 보면 DC에 의한 5xx 입니다