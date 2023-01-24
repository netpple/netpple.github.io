---
title: Istio Observability (1)  
version: v0.5  
description: istio in action 7장  
date: 2023-01-24 10:00:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: false
---
클라우드와 MSA (Micro Service Architecture) 환경은 무수히 많은 서비스들이 복잡하게 얽혀 있는데요. 이런 복잡한 환경에서 Istio가 Observability에 어떻게 기여할 수 있는지 알아봅니다.

<!--more-->

## 개요

- 클라우드, MSA 는 near-exponential (지수함수)에 가까운 복잡도(Complexity) 증가를 보입니다.
- Observability ~ Understanding “What’s really happening”
- 장애가 발생했을 때 빠르게 복구하기 위하여 꼭 필요합니다 (MTTR, 복구시간 단축)
- Istio는 Observability 를 위해 어플리케이션 네트워크 레벨의 metric 수집을 제공합니다.
- Istio가 제공하는 network metrics를 통해서 시각적으로 network call graphs 를 이해할 수 있습니다.

### 다루는 내용

- Observability 필요성
- Monitoring 이란
- Istio의 metric 수집
- Istio’s “Key metrics”
- Metrics-collection systems
- configure the proxies to report “more”
- control-plane metrics
- Customize metrics

### 실습환경

- minikube (k8s) 및 istio 설치.  참고: [https://netpple.github.io/2023/Istio-Environment/](https://netpple.github.io/2023/Istio-Environment/)
- **실습 네임스페이스** : istioinaction
- **실습 디렉토리** : book-source-code

## 7.1 What is observability?

**Observability가 뭐에요?**

- Observability 는 단지 보는 것만으로 (just by looking) 시스템의 “**internal state**”를 이해할 수 있는 수준의 “특징 (characteristic)” 임
- Observability 는 시스템의 “**Runtime Control**” 구현에 중요함
- “On the General Theory of Control System” (1960, Rudolf E. Kalman) 에서 최초로 언급됨
- Discern “**When things are going wrong**”
    - wrong을 알려면 “well”을 정의하고 관찰(**observe**) 할 수 있어야 함
    ”When things are going well”
- **Implement** the right levels of automated and manual **controls** to maintain this dynamic
    - observe를 통해 문제(wrong)가 식별 (discern)되면 자동이든 수동이든 “제어”되도록 구현가능
- Istio는 **application network level** 의  observability를 제공함
- Istio만이 Observability를 제공하는 유일할 것은 아니며
- Observability는 application instrumentation, network instrumentation, signal collection infrastructure, databases  등 시스템의 다양한 레벨에서의 계측을 포함하고
- 예상치 못한 문제가 발생했을 때 방대한 데이터들에서 필요한 데이터를 선별하여 문제에 대한 전체적인 퍼즐을 짜맞추게 됩니다

### 7.1.1 observability vs. monitoring

**모니터링 하고 어떻게 다른가요?** 

- monitoring is … “collecting” “aggregating” “matching”
*metrics, logs, traces, …*
- monitoring is subset of obsavability
- **monitoring 은** metrics을 토대로 *(known, 알려진)* **undesirable states를 watch** 하고 알람을 전송함
- **observability 는** 시스템이 훨씬 더 **unpredictable** 하고 나아가 시스템에서 가능한 실패 전부를 **알 수 없다고 가정함** (보다 현실적)
- 따라서 monitoring 보다 **훨씬 더 많은 데이터를 필요로 함**
- 예) monitoring 관점(system load, resources, traffics …)에서는 문제가 없지만 고객(Jone Doe)이 시스템 응답(10초)이 느리다고 느끼는 문제
- observability 관점에서는 (monitoring 보다) 더 많은 레이어들에서 데이터를 추출하고 고객 요청 (Jone Done)이 시스템으로 전달된 exact path 를 결정함

### 7.1.2 How Istio helps with observability

**그래서 Istio는 observability 확보에 어떤 도움을 주나요?**

- **data plane proxy ~** app. side’s **Service proxy** (Envoy)
- sits in the **request path** between services,
- **capture metrics** related to request handling and service interaction (tps, latency, failures …)
- add new metrics
- tracing requests
    - 요청의 흐름에 어떤 서비스, 컴포넌트가 관여돼 있는지
    - 각 노드에서 요청을 처리하는데 얼마나 소요 되는지
- monitoring-tools 활용 : Prometheus, Grafana, Kiali , …

이번 장에서는 앞의 2장에서 사용했던 *(데모용도의)* 모니터링 add-ons 를 제거하고 좀 더 실서비스에 가까운 셋업을 해보겠습니다.

**초기화**

add-on 을 제거합니다.

```bash

cd istio-1.16.1

kubectl delete -f samples/addons/
```

istioinaction 네임스페이스 초기화

```bash
kubectl delete -n istioinaction \
deploy,svc,gw,vs,dr --all
```

* deploy - deployment, svc - service, gw - gateway, vs -virtualservice, dr - destinationrule

## 7.2 Exploring Istio metrics

- data plane ~ handle requests
- control plane ~ configure data plane
- **give insight** (“what’s going on” at runtime) for application network

> *Let’s dig ! “What metrics are available for data/control plane”*
> 

### 7.2.1 Metrics in the data plane

> *Envoy can keep a large set of connection, request, and run-time metrics that we can use to form a picture of a service’s network and communication health.*
> 

지금 부터 실습을 통해서 Istio가  어떻게 application network 상의 metrics를 수집하여 explore, visualize 할 수 있는 영역으로 보내는지 살펴 봅니다.

*실습 기준이 되는 디렉토리 (`book-source-code`)와 네임스페이스(`istioinaction`) 를 기억해 주세요*

예제 앱 설치 및 네트워크 환경 설정

```bash
## catalog 앱 기동
kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction

## webapp 앱 기동
kubectl apply -f services/webapp/kubernetes/webapp.yaml -n istioinaction

## gateway, virtualservice 설정
kubectl apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml -n istioinaction
```

```bash
## 확인
kubectl get deploy,svc,gw,vs -n istioinaction -o name

deployment../catalog
deployment../webapp
service/catalog
service/webapp
gateway../coolstore-gateway
virtualservice../webapp-virtualservice
```

```bash
## 호출테스트
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

가장 첫번째로 확인해야 할 것은 **sidecar proxy metrics** 입니다.

배포한 앱의 Pod를 조회해 보세요. webapp, catalog 모두 sidecar proxy를 가지고 있습니다 *(READY 항목, 컨테이너가 2개입니다)*

```bash
## Pod 조회
kubectl get po -n istioinaction

NAME         READY   STATUS   ..
catalog-..   2/2     Running  ..
webapp-..    2/2     Running  ..
```

sidecar proxy 가 제공하는 메트릭을 확인해 보세요

```bash
## sidecar proxy (istio-proxy) 확인
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats
```

```
## 출력 예시 ##
..
wasmcustom.reporter=.=destination;.;source_workload=.=istio-ingressgateway;.;source_workload_namespace=.=istio-system;.;source_principal=.=spiffe://cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account;.;source_app=.=istio-ingressgateway;.;source_version=.=unknown;.;source_canonical_service=.=istio-ingressgateway;.;source_canonical_revision=.=latest;.;source_cluster=.=Kubernetes;.;destination_workload=.=webapp;.;destination_workload_namespace=.=istioinaction;.;destination_principal=.=spiffe://cluster.local/ns/istioinaction/sa/webapp;.;destination_app=.=webapp;.;destination_version=.=unknown;.;destination_service=.=webapp.istioinaction.svc.cluster.local;.;destination_service_name=.=webapp;.;destination_service_namespace=.=istioinaction;.;destination_canonical_service=.=webapp;.;destination_canonical_revision=.=latest;.;destination_cluster=.=Kubernetes;.;request_protocol=.=http;.;response_flags=.=-;.;connection_security_policy=.=mutual_tls;.;response_code=.=200;.;grpc_response_status=.=;.;istio_requests_total: 5
.. 
```

(참고) pilot-agent 를 이용해 조회할 수 도 있습니다

```bash
kubectl exec -it deploy/webapp -c istio-proxy \
-- pilot-agent request GET stats
```

```bash
kubectl exec -it deploy/webapp -c istio-proxy \
-- pilot-agent request GET help
```

보시다시피 별도 설정없이도 풍부한 메트릭을 제공합니다. 

- istio_requests_total
- istio_request_bytes
- istio_response_bytes
- istio_request_duration
- istio_request_duration_milliseconds

(참고) [Standard Istio Metrics](https://istio.io/latest/docs/reference/config/metrics/) 을 참고해주세요

- Metrics
    - for HTTP,HTTP2,GRPC traffic
        - Request Count
        - Request Duration
        - Request Size
        - Respons Size
        - gRPC Request Message Count
        - gRPC Response Message Count
    - for Tcp traffic
        - Tcp Bytes Sent
        - Tcp Bytes Received
        - Tcp Connections Opened
        - Tcp Connections Closed
- Labels

**Configuring proxies to report more Envoy Statistics**

트러블슈팅을 위해 더 많은 envoy 상태정보를 리포트하도록 설정해 봅니다

webapp에서 upstream (catalog) 호출 시 여러 가지 설정(load balancing, security, circuit-breaking, ..)을 할 수 있는데요

webapp → catalog 호출에 대한 상세정보를 제공하도록 설정합니다.

방법1) default 설정 (IstioOperator 명세)

방법2) per-workload 설정 (workload 명세)  “추천” 
*(ch6 circuit-break 에서 다룬 방법입니다)*

```yaml
# cat ch7/webapp-deployment-stats-inclusion.yaml
...
metadata:
  annotations:
    proxy.istio.io/config: |-
      proxyStatsMatcher:
        inclusionPrefixes:
        - "cluster.outbound|80||catalog.istioinaction"
...
```

```bash
## 명세 적용
kubectl apply -n istioinaction -f \
ch7/webapp-deployment-stats-inclusion.yaml
```

```bash
## 호출테스트
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog

```

```bash
## 메트릭 확인
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats | grep catalog
```

메트릭을 확인해 볼까요 (아까와 다르게 추가된 것이 있습니다)

** 바로~ catalog.istioinaction 에 대한 metrics 입니다*

아래 metrics는 upstream 에 대한 커넥션 혹은 요청 시 circuit breaking 작동했는지를 나타냅니다. 

![circuit_break 정보](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.31.58.png)

circuit_break 정보

Envoy는 traffic을 식별할 때 `internal origin` 과 `external original` 을 구분합니다.

- `internal origin` : mesh 내부 트래픽  *{cluster_name}.internal.**
    
    ![스크린샷 2023-01-21 오전 12.45.00.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.45.00.png)
    
- `external origin` : 밖에서 들어온 트래픽 (즉, ingress gateway를 통과)

upstream_cx, upstream_rq : upstream 연결과 요청에 대한 지표

![upstream_cx (connection) 정보](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.49.41.png)

upstream_cx (connection) 정보

- …upstream_cx_overflow  (ch6)   `maxConnections` 초과
- …upstream_cx_pool_overflow (ch6)

![upstream_rq (request) 정보](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.34.36.png)

upstream_rq (request) 정보

- ..upstream_rq_pending_overflow (ch6)  `http1MaxPendingRequests` 초과
- ..upstream_rq_retry_overflow (ch6)

TLS traffic : *{cluster_name}.ssl.**

![스크린샷 2023-01-21 오전 12.47.47.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.47.47.png)

Load balancer 에 대한 지표

![load balancing 정보](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.35.47.png)

load balancing 정보

이번에는 cluster 별 정보를 조회해 봅니다.

```bash
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/clusters
```

출력

*catalog endpoint 에 대한 상세한 정보 제공

- IP, region, zone, sub_zone
- cx, rq 정보

![catalog 서비스(클러스터) 정보](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_12.55.31.png)

catalog 서비스(클러스터) 정보

### 7.2.2 Metrics in the control plane

istiod 가 풍부한 정보를 제공 ~ data-plane proxy별 설정 sync 횟수 , sync 소요시간, bad config 정보, 인증서 발급/교체 등

컨트롤플레인 메트릭을 살펴볼까요

```bash
kubectl exec -it -n istio-system deploy/istiod \
-- curl localhost:15014/metrics
```

**388 라인 출력*

인증서관련 정보

```bash
citadel_server_csr_count 4
citadel_server_root_cert_expiry_timestamp 1.988253473e+09
citadel_server_success_cert_issuance_count 4
```

- CSR, Certificate Signing Request 인증서 발급 요청

> *Citadel in Istio is a security component that provides strong service-to-service and end-user authentication with built-in identity and access management functionality. It allows for the configuration of mutual Transport Layer Security (TLS) and service-to-service authentication using JSON Web Tokens (JWT) and X.509 certificates. Citadel also provides support for authenticating end-users using OpenID Connect (OIDC) and OAuth 2.0. It can be used to secure communication within the mesh, as well as between the mesh and external services.*
> 

istio 버전정보

```bash
istio_build{component="pilot",tag="1.16.1"} 1
```

config. sync time histogram ~ 설정이 모든 proxy로 적용되는데 걸리는 시간정보

```bash
pilot_proxy_convergence_time_bucket{le="0.1"} 16 ❶
pilot_proxy_convergence_time_bucket{le="0.5"} 16 ❷
pilot_proxy_convergence_time_bucket{le="1"} 16
pilot_proxy_convergence_time_bucket{le="3"} 16
pilot_proxy_convergence_time_bucket{le="5"} 16
pilot_proxy_convergence_time_bucket{le="10"} 16
pilot_proxy_convergence_time_bucket{le="20"} 16
pilot_proxy_convergence_time_bucket{le="30"} 16
pilot_proxy_convergence_time_bucket{le="+Inf"} 16
pilot_proxy_convergence_time_sum 0.010070247
pilot_proxy_convergence_time_count 16
```

❶ 16 updates were distributed to proxies in less than 0.1 milliseconds.

❷ 0 (None) request took longer and fell in the range from 0.1 to 0.5

how many Services,  how many VirtualServices, how many Proxies   `*gauge*`

```bash
pilot_services 10
pilot_virt_services 1
pilot_vservice_dup_domain 0
pilot_xds{version="1.16.1"} 4
```

> *In Prometheus, a gauge and a counter are both types of metrics, but they have different use cases and behave differently when being queried.*
> 
> 
> *A `gauge` is a metric that represents a value that can go up and down, like the current temperature or the number of active connections. It is used to track the current state of something. A gauge metric can be used to track the current value of a metric, and that value can be increased or decreased over time.*
> 
> *A `counter`, on the other hand, is a metric that only increases over time, like the number of requests received or the number of errors. It is used to track the rate of change of a metric. A counter metric can be used to track the rate at which a metric is changing over time, and it can only be incremented.*
> 
> *When a query is performed on a gauge, it returns the current value of the metric. When a query is performed on a counter, it returns the rate of change of the metric over a certain period of time.*
> 
> *In summary, A gauge measures an instantaneous value, while counter measures the rate of change of a value over a period of time.*
> 

xDS - the number of updates  `*counter*`

```bash
pilot_xds_pushes{type="cds"} 8
pilot_xds_pushes{type="eds"} 20
pilot_xds_pushes{type="lds"} 8
pilot_xds_pushes{type="rds"} 6
```

- cds - cluster discovery
- eds - endpoints discovery
- lds - listener discovery
- rds - router discovery
- sds - secret discovery

“*We cover more control-plane metrics when we explore performance tuning of the Istio control plane in chapter 11.”*

data-plain 과 control-plain 에서 observability 를 위한 metric을 살펴보았습니다

service-mesh 컴포넌트들이 제공하는 metrics을 조회하고 오퍼레이터 등을 통해 활용하기 위해서는 메트릭을 수집하고 time-series DB 등에 저장하여야 합니다. 

이어서 살펴보시죠~

## 7.3 Scraping Istio metrics with prometheus

Prometheus 로 Istio 메트릭을 수집해 봅니다. 

```bash
kubectl exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15090/stats/prometheus
```

** 출력 732 라인 (앞서 보았던 메트릭들을 prometheus 형식으로 출력합니다)*

```bash
..
envoy_cluster_upstream_cx_overflow{cluster_name="outbound|80||catalog.."} 0
..
envoy_cluster_upstream_rq_pending_overflow{cluster_name="outbound|80||catalog.."} 0
..
envoy_cluster_upstream_rq_retry_overflow{cluster_name="outbound|80||catalog.."} 0
..
```

지금부터 Prometheus 가 수집하도록 구성해 보겠습니다

### 7.3.1 Setting up Prometheus and Grafana

kube-prometheus-stack 설치

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update
```

```bash
kubectl create ns prometheus

helm install prom prometheus-community/kube-prometheus-stack \
--version 13.13.1 -n prometheus -f ch7/prom-values.yaml
```

(참고) [13.13.1](https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack/13.13.1)  *(k8s 1.25.1) 
prom-kube-prometheus-stack-admission-patch-*  Job 실행에러 발생 ⇒ disable*

```yaml
# vi ch7/prom-values.yaml
..
admissionWebhooks:
  ..
  enabled: false
```

* admissionWebhook 은 promQL 등 crd 명세 제출시 validation 을 수행함

(참고) 삭제

```bash
helm uninstall prom

kubectl get all -n prometheus

kubectl delete job --all -n prometheus

kubectl delete ns prometheus
```

### 7.3.2 Configuring the Prometheus Operator to scrape the Istio control plane and workloads

Prometheus 에서 Istio 메트릭을 수집하려면 ServiceMonitor / PodMonitor (CRD) 명세 작성이 필요합니다.

```yaml
# cat ch7/service-monitor-cp.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-component-monitor
  namespace: prometheus
  labels:
    monitoring: istio-components
    release: prom
spec:
  jobLabel: istio
  targetLabels: [app]
  selector:
    matchExpressions:
    - {key: istio, operator: In, values: [pilot]}
  namespaceSelector:
    any: true
  endpoints:
  - port: http-monitoring
    interval: 15s
```

- [ServiceMonitorSpec](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.ServiceMonitorSpec)
- `jobLabel` selects the label from the associated Kubernetes Service which will be used as the `job` label for all metrics.
If the value of this field is empty or if the label doesn’t exist for the given Service, the `job` label of the metrics defaults to the name of the Kubernetes Service.
    
    > (예시) If in `ServiceMonitor.spec.jobLabel: foo` and in `Service.metadata.labels.foo: bar`, then the `job="bar"`  label is added to all metrics.
    > 

(참고) istiod의 Service Spec
ServiceMonitor 에서 `jobLabel=istio` 이고, Service 에서 `istio=pilot` 이므로, 메트릭에는 `job=”pilot”` 이 추가됨

```bash
# kubectl describe svc istiod -n istio-system

..
Labels:            app=istiod
..
                   istio=pilot
..
Port:              http-monitoring  15014/TCP
TargetPort:        15014/TCP
Endpoints:         172.17.0.8:15014
..
```

ServiceMonitor 적용

```bash
## 적용
kubectl apply -f ch7/service-monitor-cp.yaml -n prometheus
```

```bash
## 확인
kubectl get servicemonitor -n prometheus

NAME                       AGE
istio-component-monitor    67s
..
```

로컬에서 prometheus 대시보드에 접근 가능하도록 port-forward

```bash
kubectl -n prometheus port-forward \
statefulset/prometheus-prom-kube-prometheus-stack-prometheus 9090
```

![http://localhost:9090/targets](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.45.20.png)

http://localhost:9090/targets

이번에는 data-plane 메트릭 수집을 위해 PodMonitor를 적용해 봅니다.

istio-proxy 컨테이너가 있는 Pod로부터 메트릭을 수집하는 PodMonitor 명세입니다

[prometheus-operator/api.md at main · prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#monitoring.coreos.com/v1.PodMetricsEndpoint)

```yaml
# cat ch7/pod-monitor-dp.yaml
---
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: envoy-stats-monitor
  namespace: prometheus
  labels:
    monitoring: istio-proxies
    release: prom
spec:
  selector:
    matchExpressions:
    - {key: istio-prometheus-ignore, operator: DoesNotExist}
  namespaceSelector:
    any: true
  jobLabel: envoy-stats
  podMetricsEndpoints:
  - path: /stats/prometheus
    interval: 15s
    relabelings:
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_container_name]
      regex: "istio-proxy"
    - action: keep
      sourceLabels: [__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape]
    - sourceLabels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
      action: replace
      regex: ([^:]+)(?::\d+)?;(\d+)
      replacement: $1:$2
      targetLabel: __address__
    - action: labeldrop
      regex: "__meta_kubernetes_pod_label_(.+)"
    - sourceLabels: [__meta_kubernetes_namespace]
      action: replace
      targetLabel: namespace
    - sourceLabels: [__meta_kubernetes_pod_name]
      action: replace
      targetLabel: pod_name
```

```bash
kubectl apply -f ch7/pod-monitor-dp.yaml -n prometheus
```

![스크린샷 2023-01-21 오후 4.51.11.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_4.51.11.png)

```bash
for i in {1..100}; do curl http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io"; sleep .5s; done
```

![스크린샷 2023-01-21 오후 5.36.53.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.36.53.png)

## 7.4 Customizing Istio’s standard metrics

Istio Standard metrics

![스크린샷 2023-01-21 오후 5.40.28.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.40.28.png)

> (출처) [Istio Standard Metrics](https://istio.io/latest/docs/reference/config/metrics/)
*A `COUNTER` is a strictly increasing integer
A `DISTRIBUTION` maps ranges of values to frequency*
> 

**Envoy Plugin**

- control how metrics are displayed, customized, and created

Main Concept

- **Metric** : counter, gauge, histogram/distribution (between service calls)
- **Dimension** :
    
    ![스크린샷 2023-01-21 오후 5.53.26.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.53.26.png)
    
    > We see two different entries for istio_requests_total if the dimensions differ.
    > 
    > 
    > ![스크린샷 2023-01-21 오후 5.55.07.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.55.07.png)
    > 
    
    *Where do the values for a particular **dimension come from** ?*
    
    - *****************From attributes*****************
- **[Attribute](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes#attributes)** :
    
    ![Envoy’s request attributes](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.52.44.png)
    
    Envoy’s request attributes
    
    Envoy Attributes 종류
    
    - Request
    - Response
    - Connection
    - Upstream
    - Metadata/filter state
    - Wasm

Istio Attributes  (from Istio’s **peer-metadata** filter built into Istio-proxy)

![스크린샷 2023-01-21 오후 6.03.01.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-21_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_6.03.01.png)

- prefix them with **upstream_peer** or **downstream_peer**
- 예) downstream_peer.istio_version, upstream_peer.cluster_id

*살펴본 바와 같이 **Attribute** 는 **Dimension** value 를 정의하는데 사용됩니다.*

***Attribute** 를 사용해서 기존 metric의 **Dimension** 을 커스터마이징 해봅시다.*

### 7.4.1 Configuring existing metrics

Istio 의 기본 메트릭 설정은 **`EnvoyFilter`** 의 **stats** proxy plugin 에 설정됩니다.

Istio 가 설치될 때 함께 설치되는 EnvoyFilter 는 다음과 같습니다. (istio 1.16.1)

```bash
# kubectl get envoyfilter -n istio-system

NAME                    AGE
stats-filter-1.13       17d
stats-filter-1.14       17d
stats-filter-1.15       17d
stats-filter-1.16       17d
tcp-stats-filter-1.13   17d
tcp-stats-filter-1.14   17d
tcp-stats-filter-1.15   17d
tcp-stats-filter-1.16   17d
```

```yaml
# kubectl get envoyfilter stats-filter-1.16 -n istio-system
...
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: envoy.filters.http.router
      proxy:
        proxyVersion: ^1\.16.*
    patch:
      operation: INSERT_BEFORE
      value:
        name: istio.stats     # ❶
        typed_config:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:           # ❷
              configuration:
                '@type': type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "debug": "false",
                    "stat_prefix": "istio"
                  }
              root_id: stats_outbound
              vm_config:
                code:
                  local:
                    inline_string: envoy.wasm.stats
                runtime: envoy.wasm.runtime.null
                vm_id: stats_outbound
...
```

❶ istio.stats : Wasm (WebAssembly) plugin that implements the statistics functionality. This Wasm filter is actually compiled directly into the Envoy codebase and runs against a NULL VM, so it’s not run in a Wasm VM.

> istio.stats 는 Wasm filter 임. 이 filter는 Envoy 코드에 컴파일돼 있고, NULL VM 에서 동작함 (Not in a Wasm VM)
> 

To run it in a Wasm VM, you must pass the --setvalues.telemetry.v2.prometheus.wasmEnabled=true flag to installation with istioctl or the respective IstioOperator configuration. 

**ADDING DIMENSIONS TO EXISTING METRICS**

*“Let’s add upstream_proxy_version and source_mesh_id dimensions”*

기존 

```yaml
# kubectl get istiooperator installed-state -n istio-system -o yaml
---
...
    telemetry:
      enabled: true
      v2:
...
        prometheus:
          enabled: true
          wasmEnabled: false
...
```

dimension 을 “추가❶”하거나 “삭제❷”할 수 있습니다

```yaml
# cat ch7/metrics/istio-operator-new-dimensions.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              metrics:
              - name: requests_total
                dimensions:     # ❶
                  upstream_proxy_version: upstream_peer.istio_version
                  source_mesh_id: node.metadata['MESH_ID']  
                tags_to_remove: # ❷
                - request_protocol
            outboundSidecar:
              metrics:
              - name: requests_total
                dimensions:
                  upstream_proxy_version: upstream_peer.istio_version
                  source_mesh_id: node.metadata['MESH_ID']
                tags_to_remove:
                - request_protocol
            gateway:
              metrics:
              - name: requests_total
                dimensions:
                  upstream_proxy_version: upstream_peer.istio_version
                  source_mesh_id: node.metadata['MESH_ID']
                tags_to_remove:
                - request_protocal
```

metric: requests_total  **주) metrix prefix `istio_`  는 자동으로 붙기 때문에생략해야 됨*

- dimensions:
    - upstream_proxy_version
        - a value from an attribute “upstream_peer.istio_version”
    - source_mesh_id
        - a value from an attribute “node.metadata[’MESH_ID’]

```bash
istioctl install -f ch7/metrics/istio-operator-new-dimensions.yaml -y

✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete
```

- *참고:*
    - *`--dry-run` 옵션을 추가하면 미리 적용결과를 진단해 볼 수 있습니다*
    - `verify-install` *커맨드를 사용하면 리소스별로 적용결과를 출력합니다*
        
        ```bash
        istioctl verify-install  -f ch7/metrics/istio-operator-new-dimensions.yaml
        
        *✔ ClusterRole: istiod-istio-system.istio-system checked successfully
        ✔ ClusterRole: istio-reader-istio-system.istio-system checked successfully
        ✔ ClusterRoleBinding: istio-reader-istio-system.istio-system checked successfully
        ✔ ClusterRoleBinding: istiod-istio-system.istio-system checked successfully
        ✔ ServiceAccount: istio-reader-service-account.istio-system checked successfully
        ...*
        ```
        
    - `~~uninstall`  *설치를 되돌립니다~~  ⇒  **envoyfilter를 비롯해서  control-plane 주요설정들을 모두 삭제**하므로  **절대로**하면 안됨. 말 그대로 istio 를 삭제함*
        
        > ***Uninstall Istio from a cluster***
        > 
        > 
        > ![스크린샷 2023-01-23 오후 1.48.11.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.48.11.png)
        > 
        
        ```bash
        ~~istioctl uninstall -f ch7/metrics/istio-operator-new-dimensions.yaml~~
        
        *Removed ClusterRole::istiod-clusterrole-istio-system.
        Removed ClusterRole::istiod-gateway-controller-istio-system.
        Removed ClusterRoleBinding::istiod-clusterrole-istio-system.
        Removed ClusterRoleBinding::istiod-gateway-controller-istio-system.
        Removed ConfigMap:istio-system:istio.
        Removed Deployment:istio-system:istiod.
        Removed ConfigMap:istio-system:istio-sidecar-injector.
        Removed MutatingWebhookConfiguration::istio-sidecar-injector.
        Removed PodDisruptionBudget:istio-system:istiod.
        Removed ClusterRole::istio-reader-clusterrole-istio-system.
        Removed ClusterRoleBinding::istio-reader-clusterrole-istio-system.
        Removed Role:istio-system:istiod.
        Removed RoleBinding:istio-system:istiod.
        Removed Service:istio-system:istiod.
        Removed ServiceAccount:istio-system:istiod.
        Removed EnvoyFilter:istio-system:stats-filter-1.13.
        Removed EnvoyFilter:istio-system:tcp-stats-filter-1.13.
        Removed EnvoyFilter:istio-system:stats-filter-1.14.
        Removed EnvoyFilter:istio-system:tcp-stats-filter-1.14.
        Removed EnvoyFilter:istio-system:stats-filter-1.15.
        Removed EnvoyFilter:istio-system:tcp-stats-filter-1.15.
        Removed EnvoyFilter:istio-system:stats-filter-1.16.
        Removed EnvoyFilter:istio-system:tcp-stats-filter-1.16.
        Removed ValidatingWebhookConfiguration::istio-validator-istio-system.
        ✔ Uninstall complete*
        ```
        

```bash
## istiooperator 명세가 업데이트 되고
kubectl get istiooperator installed-state \
 -n istio-system -o yaml

..
*metrics:
- dimensions:
    source_mesh_id: node.metadata['MESH_ID']
    upstream_proxy_version: upstream_peer.istio_version
  name: requests_total
  tags_to_remove:
  - request_protocol*
..

## envoyfilter "stats-filter-{stat-postfix}"도 업데이트 되었습니다
kubectl get envoyfilter stats-filter-1.16 \
 -n istio-system -o yaml

..
*value: |
  {"metrics":[{"dimensions":{"source_mesh_id":"node.metadata['MESH_ID']","upstream_proxy_version":"upstream_peer.istio_version"},"name":"requests_total","tags_to_remove":["request_protocol"]}]}
..*
```

“*Let’s Istio’s proxy know about it (New dimension)”*

⇒ annotate “Pod spec”  `sidecar.istio.io/extraStatTags`

```yaml
# cat ch7/metrics/webapp-deployment-extrastats.yaml
...
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          extraStatTags:
          - "upstream_proxy_version"
          - "source_mesh_id"
      labels:
        app: webapp
...
```

```bash
# 적용
kubectl apply -n istioinaction -f\
 ch7/metrics/webapp-deployment-extrastats.yaml
```

```bash
# 호출
curl -H "Host: webapp.istioinaction.io" \
http://localhost/api/catalog

*[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]*
```

```bash
# 메트릭 체크
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_requests_total
```

![istio_requests_total (metric) 에 dimension (upstream_proxy_version, source_mesh_id) 추가됨](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.50.53.png)

istio_requests_total (metric) 에 dimension (upstream_proxy_version, source_mesh_id) 추가됨

![tags_to_remove : [request_protocol] 삭제됨](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.53.51.png)

tags_to_remove : [request_protocol] 삭제됨

*지금까지 실습한 dimension 추가와 삭제는 **Telemetry** API를 이용해서도 가능합니다.*

**Using the new Telemetry API** (Istio 1.12+)

앞서 IstioOperator 를 이용한 new metric 설정은 “전역 설정 (globally config.)” 입니다.

Telemetry API를 이용하면 namespace, workload 단위로 설정할 수 있어욧!

먼저 전역설정한 dimension (upstream_proxy_version, source_mesh_id)을 삭제합니다

```bash
istioctl install -y -f -<<END
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              metrics:
              - name: requests_total
                tags_to_remove:
                - upstream_proxy_version
                - source_mesh_id
            outboundSidecar:
              metrics:
              - name: requests_total
                tags_to_remove:
                - upstream_proxy_version
                - source_mesh_id
            gateway:
              metrics:
              - name: requests_total
                tags_to_remove:
                - upstream_proxy_version
                - source_mesh_id
END
```

Telemetry 로 istioinaction 네임스페이스에 dimension을 추가/삭제하면 다음과 같습니다.

```yaml
# cat ch7/metrics/v2/add-dimensions-telemetry.yaml
---
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: add-dimension-tags
  namespace: istioinaction
spec:
  metrics:
  - providers:
      - name: prometheus
    overrides:
      - match:
          metric: REQUEST_COUNT
          mode: CLIENT_AND_SERVER
        disabled: false
        tagOverrides:
          upstream_proxy_version:
            operation: UPSERT
            value: upstream_peer.istio_version
          source_mesh_id:
            operation: UPSERT
            value: node.metadata['MESH_ID']
          request_protocol:
            operation: REMOVE
```

```bash
## 적용
kubectl apply -n istioinaction -f \
ch7/metrics/v2/add-dimensions-telemetry.yaml
```

Telemetry 

- Istio 공식 [Telemetry](https://istio.io/latest/docs/reference/config/telemetry/#Telemetry) 문서
    
    ![스크린샷 2023-01-23 오후 1.27.54.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.27.54.png)
    
- 이미 ch4 에서 access logging 에서 살짝 살펴보았고
    
    ![스크린샷 2023-01-23 오후 1.24.58.png](/assets/img/Istio-ch7-observability%20e786c38007504d889cf4e5e92dcd6e32/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-23_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.24.58.png)
    
- ch8 에서는 tracing 을 살펴 볼 것 입니다

*지금까지 existing standard metric (istio_requests_total)의 dimension 을 커스텀 해보았습니다.*

### 7.4.2 Creating new metrics

*Let’s create our own metric !*

```yaml
# cat ch7/metrics/istio-operator-new-metric.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            inboundSidecar:
              definitions:
              - name: get_calls
                type: COUNTER
                value: "(request.method.startsWith('GET') ? 1 : 0)"
            outboundSidecar:
              definitions:
              - name: get_calls
                type: COUNTER
                value: "(request.method.startsWith('GET') ? 1 : 0)"
            gateway:
              definitions:
              - name: get_calls
                type: COUNTER
                value: "(request.method.startsWith('GET') ? 1 : 0)"
```

- get_calls ⇒ istio_get_calls (prefix “istio_” is added automatically.)
- CEL, Common Expression Language [https://opensource.google/projects/cel](https://opensource.google/projects/cel)
    - must return an integer for type COUNTER

```bash
## 적용
istioctl install -y -f ch7/metrics/istio-operator-new-metric.yaml
```

```bash
## 확인
kubectl get istiooperator -n istio-system installed-state -o yaml

..
*definitions:
- name: get_calls
  type: COUNTER
  value: '(request.method.startsWith('GET') ? 1 : 0)'
..*

kubectl get envoyfilter -n istio-system stats-filter-1.16 -o yaml

..
*value: |
 {"definitions":[{"name":"get_calls","type":"COUNTER","value":"(request.method.startsWith('GET') ? 1 : 0)"}]}*
..

```

Pod annotation (`proxy.istio.io/config`)에 메트릭 `istio_get_calls`  을 추가해 줍니다

- *proxyStatsMatcher.inclusionPrefixes[] ~ metrics 추가*
- **extraStatTags[] ~ dimensions 추가*

```yaml
# cat ch7/metrics/webapp-deployment-new-metric.yaml
...
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp

  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          proxyStatsMatcher:
            inclusionPrefixes:
            - "istio_get_calls"
      labels:
        app: webapp
...
```

```bash
## 적용
kubectl -n istioinaction apply -f\
 ch7/metrics/webapp-deployment-new-metric.yaml
```

```bash
## 호출
curl -H "Host: webapp.istioinaction.io" localhost/api/catalog
```

```bash
## 메트릭 확인
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_get_calls

*istio_get_calls{} 2*
```

- 추가한 metric “istio_get_calls{}” 이 출력됨
- istio_get_calls (metric)에 대한 dimension 은 하나도 없음

*GET 요청을 카운트 하는 메트릭을 만들어 보았는데요. 
catalog 서비스의 /items 에 대한 요청을 카운트 하려면 어떻게 해야 할까요?  
이어서 Dimension과 attribute 를 생성해 보겠습니다.*

### 7.4.3 Grouping calls with new attributes

기존 attributes 를 가지고 새로운 attributes 를 만들 수 있습니다. 

EnvoyFilter의  attribute-gen 필터를 이용하여 새로운 attribute를 정의해 봅니다.

1. attribute-gen : Attribute (`istio_operationId`) 생성

```yaml
# cat ch7/metrics/attribute-gen.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: attribute-gen-example
  namespace: istioinaction
spec:
  configPatches:
  ## Sidecar Outbound
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: istio.stats
      proxy:
        proxyVersion: ^1\.16.*
    patch:
      operation: INSERT_BEFORE
      value:
        name: istio.attributegen
        typed_config:
          '@type': type.googleapis.com/udpa.type.v1.TypedStruct
          type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
          value:
            config:
              configuration:
                '@type': type.googleapis.com/google.protobuf.StringValue
                value: |
                  {
                    "attributes": [
                      {
                        "output_attribute": "istio_operationId",
                        "match": [
                         {
                           "value": "getitems",
                           "condition": "request.url_path == '/items' && request.method == 'GET'"
                         },
                         {
                           "value": "createitem",
                           "condition": "request.url_path == '/items' && request.method == 'POST'"
                         },
                         {
                           "value": "deleteitem",
                           "condition": "request.url_path == '/items' && request.method == 'DELETE'"
                         }
                       ]
                      }
                    ]
                  }
              vm_config:
                code:
                  local:
                    inline_string: envoy.wasm.attributegen
                runtime: envoy.wasm.runtime.null
```

```bash
kubectl apply -f ch7/metrics/attribute-gen.yaml -n istioinaction
```

2. Create a new dimension (`upstream_operation`) : 1에서 생성한 attribute (`istio_operationId`)를 사용하는 dimension 생성. catalog API의 /items 호출하는 metric에 추가

```yaml
# cat ch7/metrics/istio-operator-new-attribute.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: demo
  values:
    telemetry:
      v2:
        prometheus:
          configOverride:
            outboundSidecar:
              metrics:
              - name: requests_total
                dimensions:
                  upstream_operation: istio_operationId

```

```bash
istioctl install -y -f ch7/metrics/istio-operator-new-attribute.yaml
```

```yaml

## 확인 outboundSidecar 에만 적용됨
# kubectl get istiooperator -n istio-system installed-state -o yaml

...
    telemetry:
      enabled: true
      v2:
        enabled: true
        metadataExchange:
          wasmEnabled: false
        prometheus:
          configOverride:
...
            outboundSidecar:
              definitions:
              - name: get_calls
                type: COUNTER
                value: '(request.method.startsWith(''GET'') ? 1 : 0)'
              metrics:
              - dimensions:
                  upstream_operation: istio_operationId
                name: requests_total
...
```

3. Pod Annotation(`proxy.istio.io/config`) 에 dimension (`upstream_operation`) 추가 

- *extraStatTags[] ~ dimensions 추가*
- **proxyStatsMatcher.inclusionPrefixes[] ~ metrics 추가*

```yaml
# cat ch7/metrics/webapp-deployment-extrastats-new-attr.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webapp
  name: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |-
          extraStatTags:
          - "upstream_operation"
      labels:
        app: webapp
    spec:
      containers:
      - env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: istioinaction/webapp:latest
        imagePullPolicy: IfNotPresent
        name: webapp
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        securityContext:
          privileged: false

```

```yaml
kubectl -n istioinaction apply -f\
 ch7/metrics/webapp-deployment-extrastats-new-attr.yaml 
```

호출테스트

```bash
curl -H "Host: webapp.istioinaction.io" \
http://localhost/api/catalog
```

catalog pod 로그

```bash
catalog-f475cb899-dlv9w istio-proxy [2023-01-24T05:25:36.714Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 21 21 "172.17.0.1" "beegoServer" "539a9d16-fd10-9d3a-b858-2876b1d125c6" "10.100.82.10:80" "172.17.0.9:3000" inbound|3000|| 127.0.0.6:38723 172.17.0.9:3000 172.17.0.1:0 outbound_.80_._.catalog.istioinaction.svc.cluster.local default
```

메트릭 확인 : new dimension (`upstream_operation`) 추가 확인!

```bash
kubectl -n istioinaction exec -it deploy/webapp -c istio-proxy \
-- curl localhost:15000/stats/prometheus | grep istio_requests_total

..
istio_requests_total{response_code="200",reporter="source",source_workload="webapp",source_workload_namespace="istioinaction",source_principal="spiffe://cluster.local/ns/istioinaction/sa/webapp",source_app="webapp",source_version="unknown",source_cluster="Kubernetes",destination_workload="catalog",destination_workload_namespace="istioinaction",destination_principal="spiffe://cluster.local/ns/istioinaction/sa/catalog",destination_app="catalog",destination_version="v1",destination_service="catalog.istioinaction.svc.cluster.local",destination_service_name="catalog",destination_service_namespace="istioinaction",destination_cluster="Kubernetes",request_protocol="http",response_flags="-",grpc_response_status="",connection_security_policy="unknown",source_canonical_service="webapp",destination_canonical_service="catalog",source_canonical_revision="latest",destination_canonical_revision="v1",upstream_operation="getitems"} 1
```

> *You should know that **the more** our applications **communicate** **over** **the** **network**, **the more** things **can** **go** **wrong** !*
> 

Having a consistent view into what’s happening between services is almost prerequisite to running a MSA.

Istio makes **metrics collection** between services **easier** by observing things like success rate, failure rate, number of retries, latency …

Istio can simplify collecting [*golden-signal*](https://sre.google/sre-book/monitoring-distributed-systems/) networking metrics.

이번 챕터에서는 Istio service proxy (Envoy) 와 control plane 의 **metric 수집 (scrape)**에 대해서 알아 ****보았고, **메트릭 확장 (extend)**, 프로메테우스와 같은 time series DB로 **메트릭을 모으는(aggregate) 방법**을 살펴 보았습니다 ~ ***Scraping, Extending, Aggregating Metrics***

다음 챕터에서는 “**Visualizing Metrics** ” (Grafana, Kiali) 에 대해 살펴보겠습니다. 

## Summary

- Monitoring is the process of collecting and aggregating metrics to **watch** **for known undesirable states** so that **corrective measures** can be taken.
*모니터링은 “**알려진 이상상태**를 감지”하여 시정조치가 이루어질 수 있도록 메트릭을 수집하고 어그리게이션하는 프로세스입니다.*
- Istio collects the metrics used for monitoring when intercepting requests in the sidecar proxy. Because the proxy acts at layer7 (the application-networking layer), it has access to a great deal of information such as status codes, HTTP methods, and headers that can be used in metrics.
*Istio 는 sidecar proxy (Envoy) 에서 요청을 처리할 때 모니터링을 위한 메트릭을 수집합니다.*
- One of the key metrics is `istio_requests_total` , which counts requests and answers questions such as how many requests ended with status code 200.
`*istio_requests_total` 은 요청 상태별 집계 등 다양한 요청 집계를 제공하는 핵심 메트릭 입니다.*
- The metrics exposed by the proxies set the foundation to build an observable system.
*프록시에서 제공하는 메트릭들은 관측가능한 시스템을 만드는 기반을 제공합니다.*
- By default, Istio configures the proxies to expose only a limited set of statistics. You can configure the proxies to report more mesh-wide using the `meshConfig.defaultConfig` or on a per-workload basis using the annotation `proxy.istio.io/config` .
*Istio 기본설정은 proxy metric 을 제한적으로 노출합니다. 메트릭을 더 노출하고 싶다면 mesh-wide (globally) 설정은* `meshConfig.defaultConfig` *를 통해서 하고, workload 단위로 설정하려면* `proxy.istio.io/config` *어노테이션에 설정합니다.*
- The control plane also exposes metrics for its performance. The most important is the histogram `pilot_proxy_convergence_time`, which measures the time taken to distribute changes to the proxies.
*control plane 은 Istio 성능 관련 메트릭을 제공합니다. 가장 중요한 메트릭은*`pilot_proxy_convergence_time` *히스토그램인데요 프록시들로 설정이 적용되는데 걸리는 시간을 측정합니다.*
- We can **customize the metrics** available in Istio using the `IstioOperator` and use them in services by setting the `extraStats`  value in the annotation `proxy.istio.io/config`  that defines the proxy configuration. This level of control gives the operator (end user) flexibility over what telemetry gets scraped and how to present it in dashboards.
*메트릭 커스터마이징은 IstioOperator “명세”를 통해서 하고 앱에서 (커스텀) 메트릭을 사용하려면* `proxy.istio.io/config` *어노테이션의 value로* `extraStats` *를 설정합니다.*