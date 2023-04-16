---
title: Istio Observability (2)  
version: v1.1  
description: istio in action 8장  
date: 2023-04-16 21:25:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: true
---
ch7 에서 다룬 observability 의 visualize 에 대해 알아봅니다. visualize 를 위한 도구로 Grafana (Metrics), Jaeger/Zipkin (Distributed Tracing), Kiali (Call Graph) 등을 살펴봅니다.

<!--more-->

## 개요

- Prometheus 가 수집한 Istio의 data/control plane 메트릭 그래프에 대해 살펴 봅니다
- Grafana 의 Istio 대시보드를 통해 data/control plane 을 모니터링 할 수 있습니다
- Distributed Tracing 은 여러 홉을 거치는 서비스의 call graph로 부터 지연 (latencies) 을 파악하는데 매우 유용합니다
- Distributed Tracing 은 서로 관련 있는 requests 에 메타데이터를 어노테이션 하고, Istio가 자동으로 해당 메타데이터를 detect 하여 “**span”** 에 실어 **tracing 엔진**에  보냅니다.

### TERM

[**Span** ?](https://www.jaegertracing.io/docs/1.41/architecture/)

> A span represents **a logical unit of work** that has an operation name, the start time of the operation, and the duration. 
Spans may be nested and ordered to model **causal relationships**.
> 
> 
> ![스크린샷 2023-01-29 오후 1.00.46.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.00.46.png)
> 

*참고로 … span 은 건축에서 교량을 **지지하는 단위 구간**을 의미하기도 한다*

<img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.59.11.png" width=301 />
<br/><br/>

**Trace**

> A trace represents the data or execution path through the system. It can be thought of as a **directed acyclic graph** (DAG) of spans.

[* DAG 방향성 비순환 그래프](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
> 
> - model **relationships** between different entities
> - useful in **representing** systems that have **multiple** **dependencies** and constraints, such as in scheduling and data compression
> - used to represent **hierarchical** **structures**, where a **parent** node **has** one or more **child nodes**, but **child** node **cannot have multiple parents**
> - used to represent **relationships** between different tasks, where certain tasks can only start after certain other tasks have been completed (인과성, **causality**)
> - 특징
>     - edge를 통해 node (or vertex) 간에 연결될 수 있음
>     - edge 에서 “순환” (cycle) 은 없음 (acyclic, **비순환**)
>     - Topological Ordering (**순서**) 있음
>
>     <img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.52.10.png" width="180" />
>     

### 다루는 내용

- Visualizing “metrics” using Grafana
- Visualizing “Distributed Tracing” using Jaeger/Zipkin
- Visualizing “network call graph” using Kiali

### 실습환경

- minikube (k8s) 및 istio 설치.  참고: [https://netpple.github.io/2023/Istio-Environment/](https://netpple.github.io/2023/Istio-Environment/)
- **실습 네임스페이스** : istioinaction
- **실습 디렉토리** : book-source-code

## 8.1 Grafana - Istio 서비스와 control-plane Visualize

ch7 에서 설치한 프로메테우스를 사용합니다. 

```bash
kubectl get po -n prometheus -o name

pod/prom-grafana-6d5b6696b5-b6xdq
pod/prom-kube-prometheus-stack-operator-749bbf567c-4flbc
pod/prometheus-prom-kube-prometheus-stack-prometheus-0
```

Grafana 에 접속해 봅시다.  로컬 포트(3000)으로 포트포워딩 합니다.

```bash
kubectl -n prometheus port-forward svc/prom-grafana 3000:80
```

브라우저 ⇒ [http://localhost:3000/login](http://localhost:3000/login)   (admin/prom-operator)

![스크린샷 2023-01-25 오전 8.05.46.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.05.46.png)

### 8.1.1 Istio Grafana 대시보드 구성하기

대시보드 : *{book-source-code}*/ch8/dashboards/*

- Istio Grafaba dashboards : [https://grafana.com/orgs/istio/dashboards](https://grafana.com/orgs/istio/dashboards)

먼저, 대시보드 파일(json)을 configmap 으로 생성합니다. 

```bash
# 기준 경로 *{book-source-code}/ch8*
cd ch8

kubectl -n prometheus create cm istio-dashboards \
--from-file=pilot-dashboard.json=dashboards/\
pilot-dashboard.json \
--from-file=istio-workload-dashboard.json=dashboards/\
istio-workload-dashboard.json \
--from-file=istio-service-dashboard.json=dashboards/\
istio-service-dashboard.json \
--from-file=istio-performance-dashboard.json=dashboards/\
istio-performance-dashboard.json \
--from-file=istio-mesh-dashboard.json=dashboards/\
istio-mesh-dashboard.json \
--from-file=istio-extension-dashboard.json=dashboards/\
istio-extension-dashboard.json
```

Grafana (오퍼레이터)가 configmap(istio-dashboards)을 마운트 하도록 “레이블”에 표시를 해줍니다.

```bash
kubectl label -n prometheus cm istio-dashboards grafana_dashboard=1
```

```bash
## grafana Pod 로그 
# stern prom-grafana-*

..
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] Working on configmap prometheus/istio-dashboards
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap istio-extension-dashboard.json ADDED
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap istio-mesh-dashboard.json ADDED
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap istio-performance-dashboard.json ADDED
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap istio-service-dashboard.json ADDED
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap istio-workload-dashboard.json ADDED
prom-grafana-6d5b6696b5-b6xdq grafana-sc-dashboard [2023-01-24 23:22:40] File in configmap pilot-dashboard.json ADDED
```

<img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.26.05.png" width=70 /> 클릭

![스크린샷 2023-01-25 오전 8.25.43.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.25.43.png)

### 8.1.2 Viewing control-plane metrics

`Istio Control Plane Dashboard`

**Pilot Push Time** ~ visualizing `pilot_proxy_convergence_time`  (the time taken to distribute changes to the proxies)

### 8.1.3 Viewing data-plane metrics

`Istio Service Dashboard` 

## 8.2 Distributed tracing

분산 환경은 monolith 환경과 다름. 따라서 분산 환경 디버깅을 위한 방법과 툴들이 필요함.

Distributed Tracing (분산 Tracing)이 바로 그것임.

구글 Dapper (2010)에서 기원하였으며, requests에 correlation ID, trace ID를 포함하여 관련 서비스간의 호출을 식별하고 특정 요청 처리에 포함된 전체적인 호출 그래프 (call graph)를 확인할 수 있음.

Istio data-plane 에서는 request 마다 이러한 메타데이터 (correlation ID, trace ID 등)를 추가할 수 도 있고, 메타데이터가 포함돼 있지 않거나 (unrecognized) 인식불가한 메타데이터인 경우, 혹은 외부로 부터 들어온 requests 인 경우에는 삭제할 수도 있습니다.

Distributed Tracing 오픈소스 툴로 Open Telemetry가 있습니다. 
Open Telemetry는 Distributed Tracing과 관련된 컨셉과 API 스펙을 캡쳐한 Open Tracing 을 포함하고 있습니다.
Distributed Tracing  서비스 간의 요청 호출, 요청에 대한 어노테이션 처리 등 개발자가 해주어야 할 부분이 있는 반면에, Tracing 엔진은 이러한 요청들을 모으고 전체적인 흐름에서 오동작을 식별 해낼 수 있습니다.

Istio를 사용하면 서비스 메시에 Distributed Tracing을 쉽게 적용할 수 있습니다.

> Services often take multiple hops to service a request.
> 
> 
> <img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.16.31.png" width=200 />
> 

<br />
*(배경)*

**In a monolith**, if things start to misbehave, we can jump in and start debugging with familiar tools at our disposal.  We have debuggers, runtime profilers, and memory analysis tools to find areas where parts of the code introduce latency or trigger faults that cause an application feature to misbehave. 

**With an application made up of distributed parts**, **we need a new set of tools** to accomplish the same things.

*(Distributed tracing의 기원과 개요)*

**Distributed tracing** give us insights into the components of a distributed system involved in serving a request. It was **introduced by the Google Dapper paper** (”Dapper, a Large-Scale Distributed Systems Tracing Infrastructure”, 2010, [https://research.google/pubs/pub36356](https://research.google/pubs/pub36356) )
and **involves annotating requests with** `correlation IDs` that represent service-to-service calls **and** `trace IDs` that represent a specific request through a graph of service-to-service calls.
Istio’s data plane can **add these kinds of metadata** to the requests as they pass through the data plane (and, **importantly, remove them** when they are **unrecognized** **or come from external** entities.)

<br />
*(OpenTelemetry - Opentracing 을 포함 )*

*Telemetry : 원격측정

**OpenTelemetry** is a community-driven framework that includes **OpenTracing**, which is a **specification that captures concepts and APIs related to distributed tracing**.

Distributed tracing, in part, relise on **developers** **instrumenting** their code **and** **annotating** **requests** as they are processed by the application and make new requests to other system.
(개발자가 해줘야 하는 부분이 있다 ~ 코드나 requests 에)

**A tracing engine helps put together** the **full picture of a request flow**, which can be used to **identify misbehaving ares** of our architecture.
(Tracing engine 의 역할 ~ put together, full picture ⇒ identify misbehaving areas)

<br />
*(Istio 를 쓰세요)*

**With Istio**, we can **provide the bulk of the heavy lifting** developers would otherwide have to implement themselves and provide distributed tracing as part of the service mesh.

(Istio 를 사용하면 Distributed Tracing의 많은 부분을 대신해줍니다.

### 8.2.1 How does distributed tracing work?

Span 과 trace context ⇒ Trace

- Create a Span
- Send the span to the OpenTracing engine
- Propagate the trace context to other services
- Construct a Trace ~ “**causal** relationship” between services *(direction, timing, … )*
- Span ID, Trace ID ⇒ for **correlation**, propagated between services

![스크린샷 2023-01-25 오후 12.43.37.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.43.37.png)

“Istio can handle sending the Spans to the distributed tracing engine.”

Zipkin tracing headers

- x-request-id
- x-b3-traceid
- x-b3-spanid
- x-b3-parentspanid
- x-b3-sampled
- x-b3-flags
- x-ot-span-context

![스크린샷 2023-01-25 오후 1.09.05.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.09.05.png)

### 8.2.2 Installing a distributed tracing system

Jaeger 설치가 다소 복잡해서 그냥 Istio 샘플 addon을 쓰겠음

```bash
cd istio-1.16.1

kubectl apply -f samples/addons/jaeger.yaml
```

확인

```bash
kubectl get po,svc -n istio-system -o name
```

### 8.2.3 Configuring Istio to perform distributed tracing

Istio 는 다양한 레벨 (global / namespace / workload) 에 Distributed Tracing 적용 가능

참고: Istio’s [Telemetry API](https://istio.io/latest/docs/tasks/observability/telemetry/) 

방법1. **Configuring tracing at installation**

Istio supports distributed tracing backends including Zipkin, Datadog, Jaeger (Zipkin compatible), and others. 

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      tracing:
        lightstep: {}
        zipkin: {}
        datadog: {}
        stackdriver: {}
```

예시) Jaeger (Zipkin compatible) 사용 시 

```yaml
# cat ch8/install-istio-tracing-zipkin.yaml
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      tracing:
        sampling: 100
        zipkin:
          address: zipkin.istio-system:9411
```

```bash
## 적용
istioctl install -y -f ch8/install-istio-tracing-zipkin.yaml
```

방법2. **Configuring tracing using meshconfig**

```yaml
# kubectl get cm istio -n istio-system -o yaml

# ...
apiVersion: v1
data:
  mesh: |- 
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
    enablePrometheusMerge: true
    rootNamespace: istio-system
    trustDomain: cluster.local
meshNetworks: 'networks: {}'
# ...

```

방법3. **Configuring tracing per workload**

“어노테이션” `proxy.istio.io/config` 으로 설정

```yaml
apiVersion: apps/v1
kind: Deployment
...
spec:
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          tracing:
            zipkin:
              address: zipkin.istio-system:9411
```

**Examining the default tracing headers**

지금까지 뭐했냐면요 … distributed tracing 엔진 (Jaeger) 과 Istio 를 설정하였습니다. 

Istio가 OpenTracing 헤더와 correlation ID 를 자동으로 주입해 주는지 실습해 보겠습니다. **[http://httpbin.org](http://httpbin.org) 은 simple HTTP 테스트 서비스 입니다.* 

```yaml
# cat ch8/tracing/thin-httpbin-virtualservice.yaml
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
    - "httpbin.istioinaction.io"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: thin-httpbin-virtualservice
spec:
  hosts:
  - "httpbin.istioinaction.io"
  gateways:
  - coolstore-gateway
  http:
  - route:
    - destination:
        host: httpbin.org
---
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-httpbin-org
spec:
  hosts:
  - httpbin.org
ports:
- number: 80
  name: http
  protocol: HTTP
location: MESH_EXTERNAL
resolution: DNS
```

```bash
kubectl apply -n istioinaction \
-f ch8/tracing/thin-httpbin-virtualservice.yaml
```

호출 테스트     client (curl) —> istio-ingress-gateway —> httpbin.org

```bash
curl -H "Host: httpbin.istioinaction.io" http://localhost/headers

{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.istioinaction.io",
    "User-Agent": "curl/7.85.0",
    "X-Amzn-Trace-Id": "Root=1-63d0c0d3-16a602144b1411b43a596a18",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "e9fa90a180e41b73",
    "X-B3-Traceid": "484333fa50c1e0a8e9fa90a180e41b73",
    "X-Envoy-Attempt-Count": "1",
    "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
    "X-Envoy-Internal": "true",
    "X-Envoy-Peer-Metadata": "*<omitted>*",
    "X-Envoy-Peer-Metadata-Id": "router~172.17.0.11~istio-ingressgateway-6785fcd48-tplc2.istio-system~istio-system.svc.cluster.local"
```

*X-B3-* Zipkin 헤더가 자동으로 request 헤더에 추가되었습니다. 추가된 Zipkin 헤더는 “Span” 을 생성하는데 사용되고 Jaeger로 보내집니다.* 

### 8.2.4 Viewing distributed tracing data

```bash
istioctl dashboard jaeger --browser=false
```

[http://localhost:16686](http://localhost:16686) 

### 8.2.5 Trace sampling, force traces, and custom tags

tracing sampling 은 성능이슈가 있음

**Tuning the trace sampling for the mesh**

“Sampling Rate” 높을 수록 ~ 성능부담 커짐

istio configmap 에서 sampling rate 을 조절해 봅니다. (100 → 10) *globally 적용됨*

```bash
# kubectl edit -n istio-system cm istio

..
mesh: |-
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        sampling: 10  # <-- from 100
        zipkin:
          address: zipkin.istio-system:9411
..
```

- Q) **Sampling 적용**은 istio-ingressgateway 를 restart 해야만 적용됨
    - istiod 로그 상에 istio cm(configmap) 변경 로그는 찍힘
    - workload 단위 (ex: webapp deploy) 명세 변경은 적용안됨
    - istiod, webapp restart 로 적용안됨

**Workload 단위**의 적용은 ~ 앞서 살펴보았듯이 해당 워크로드의 annotation

```yaml
# cat ch8/webapp-deployment-zipkin.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: webapp
  name: webapp
spec:
# ...
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          tracing:
            sampling: 10
            zipkin:
              address: zipkin.istio-system:9411
# ...
```

```bash
kubectl apply -f ch8/webapp-deployment-zipkin.yaml \
-n istioinaction
```

**FORCE-TRACING FROM THE CLIENT**

평소 운영 시에는 sampling rate 을 최소로 유지하고 이슈발생 시 특정 workload 에 대해서 tracing을 강제할 수 있습니다. request 에 tracing을 강제하려면 `x-envoy-force-trace`  헤더를 설정합니다. 

```bash
curl -H "x-envoy-force-trace: true" \
-H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

**CUSTOMIZING THE TAGS IN A TRACE**

Tags ~ 트레이싱에 추가 메타데이터를 부여

Tag는 커스텀 key-value 쌍으로 span 에 붙여져서 트레이싱 엔진에 전달됨.

Custom Tags 설정 유형

- Explicitly specifying a value
- Pulling a value from environment variables
- Pulling a value from request headers

```yaml
apiVersion: apps/v1
kind: Deployment
...
spec: 
  template:
    metadata:
      annotations:
        proxy.istio.io/config: |
          tracing:
            sampling: 100
            customTags:
              custom_tag:
                literal:
                  value: "Test Tag"
            zipkin:
              address: zipkin.istio-system:9411
```

```bash
kubectl apply -n istioinaction \
-f ch8/webapp-deployment-zipkin-tag.yaml
```

![스크린샷 2023-01-25 오후 7.12.23.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.12.23.png)

Custom Tags 용도 : reporting, filtering, exploring the tracing data

*공식: [https://istio.io/latest/docs/tasks/observability/distributed-tracing/](https://istio.io/latest/docs/tasks/observability/distributed-tracing/) 

**CUSTOMIZING THE BACKEND DISTRIBUTED TRACING ENGINE**

**How to configure** the backend settings for **connecting with the distributed tracing engine**.

**Telemetry API**

default tracing configuration 조회

```bash
istioctl pc bootstrap -n istioinaction deploy/webapp \
-o json | jq .bootstrap.tracing
```

![스크린샷 2023-01-25 오후 7.18.57.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.18.57.png)

- *istioctl pc (proxy-config)*
- tracing enging 은  ZipkinConfig
- span 은 /api/v2/spans  로 전달

Custom Zipkin Configuration 수정 (configmap)

```yaml
# cat ch8/istio-custom-bootstrap.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio-custom-zipkin
data:
  custom_bootstrap.json: |
    {
      "tracing": {
        "http": {
          "name": "envoy.tracers.zipkin",
          "typedConfig": {
            "@type": "type.googleapis.com/envoy.config.trace.v3.ZipkinConfig",
            "collectorCluster": "zipkin",
            "collectorEndpoint": "/zipkin/api/v1/spans",
            "traceId128bit": "true",
            "collectorEndpointVersion": "HTTP_JSON"
          }
        }
      }
    }
```

```bash
kubectl apply -n istioinaction \
-f ch8/istio-custom-bootstrap.yaml
```

Custom Zipkin Configuration 적용 > webapp

```yaml
# cat ch8/webapp-deployment-custom-boot.yaml
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
        sidecar.istio.io/bootstrapOverride: "istio-custom-zipkin"
        proxy.istio.io/config: |
          tracing:
            sampling: 10
            zipkin:
              address: zipkin.istio-system:9411
      labels:
        app: webapp
    spec:
      containers:
      - env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: CATALOG_SERVICE_HOST
          value: catalog.istioinaction
        - name: CATALOG_SERVICE_PORT
          value: "80"
        - name: FORUM_SERVICE_HOST
          value: forum.istioinaction
        - name: FORUM_SERVICE_PORT
          value: "80"
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

```bash
kubectl apply -n istioinaction \
-f ch8/webapp-deployment-custom-boot.yaml
```

적용여부 확인

```bash
istioctl pc bootstrap -n istioinaction deploy/webapp \
-o json | jq .bootstrap.tracing
```

적용 후 호출테스트

```bash
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

![webapp span  안나옴 ( 존재하지 않는 collectorEndpoint 로 수정했기 때문 )](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.40.46.png)

webapp span  안나옴 ( 존재하지 않는 collectorEndpoint 로 수정했기 때문 )

webapp 초기화 후 확인해 보자

```bash
kubectl apply -n istioinaction \
-f services/webapp/kubernetes/webapp.yaml 
```

적용 후 호출테스트

```bash
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

![webapp span 확인됨 ](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.47.40.png)

webapp span 확인됨 

## 8.3 Visualization with Kiali

Grafana 와 달라요

- give a visual overview of what services are communicating with others
- present an interactive drawing or map of the services in the cluster

Kiali visualizes the Istio metrics stored in Prometheus *(hard dependency)*

### 8.3.1 Installing Kiali

Kiali Operator 설치 권장 : https://github.com/kiali/kiali-operator

Kiali 공식 가이드 : [https://v1-41.kiali.io/docs/installation/installation-guide/](https://v1-41.kiali.io/docs/installation/installation-guide/) 

Step1. Kiali Operator 설치

```bash
kubectl create ns kiali-operator
helm install \
--set cr.create=true \
--set cr.namespace=istio-system \
--namespace kiali-operator \
--repo https://kiali.org/helm-charts \
--version 1.40.1 \
kiali-operator \
kiali-operator
```

Step2. Kiali Dashboard 설치 (Kiali Custom Resource, CR)

```yaml
apiVersion: kiali.io/v1alpha1
kind: Kiali
metadata:
  namespace: istio-system
  name: kiali
spec:
  istio_namespace: "istio-system"
  istio_component_namespaces:
    prometheus: prometheus
  auth:
    strategy: anonymous
  deployment:
    accessible_namespaces:
    - '**'
  external_services:
    prometheus:
      cache_duration: 10
      cache_enabled: true
      cache_expiration: 300
      url: "http://prom-kube-prometheus-stack-prometheus.prometheus:9090"
    tracing:
      enabled: true
      in_cluster_url: "http://tracing.istio-system:16685/jaeger"
      use_grpc: true  
```

- Kiali CR example : [https://github.com/kiali/kiali-operator/blob/master/crd-docs/cr/kiali.io_v1alpha1_kiali.yaml](https://github.com/kiali/kiali-operator/blob/master/crd-docs/cr/kiali.io_v1alpha1_kiali.yaml)
- Kiali CRD : [https://github.com/kiali/kiali-operator/blob/master/crd-docs/crd/kiali.io_kialis.yaml](https://github.com/kiali/kiali-operator/blob/master/crd-docs/crd/kiali.io_kialis.yaml)

Kiali dashboard 접속을 위해 포트포워딩

```bash
kubectl -n istio-system port-forward deploy/kiali 20001
```

[http://localhost:20001](http://localhost:20001)

![Applications 로 조회 - prometheus 는 “2”](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.54.07.png)

Applications 로 조회 - prometheus 는 “2”

![Workload 로 조회 - prometheus 는 “3”](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.58.09.png)

Workload 로 조회 - prometheus 는 “3”

**Application vs Workload**

- default, ingress ~ apps는 N/A, workloads는 1
- prometheus  apps는 2, workloads는 3
- Q) 왜 prom-grafana 는 app 이 없다고 할까?

  <img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_10.33.14.png" width=240 />
    
  A) Application 에 포함이 돼려면 “**Label App**” 으로 지정이 돼야 함 (아래 참고 deployment (prom-grafana) 에서 pod label 에 `app: prom-grafana`  추가  
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata: 
      name: prom-grafana
    # ...
    spec:
      template:
        metadata:
          labels:
            app: prom-grafana    # <-- Pod label 추가 
    # ...
    ```
    
    ** 주) 기동 중인 pod label 만 변경해서는 반영되지 않음*
    

*(참고) Kiali 공식 : [https://kiali.io/docs/architecture/terminology/concepts/](https://kiali.io/docs/architecture/terminology/concepts/)*

- Workload
    
    > A workload is a running binary that can be deployed as a set of identical running replicas. For example, in Kubernetes, **this would be the Pods** part of a deployment. A `service A` deployment with three replicas would be a workload.
    > 
- **Application**
    
    > Is a **logical grouping of Workloads** **defined by the application labels** that users apply to an object. In Istio it is defined by the **Label App**.
    > 
- **Label App**
    
    > This is the ‘`app`’ label on an object. see [**Istio** **Label Requirements**](https://istio.io/latest/docs/ops/deployment/requirements/).
    
    *Pods with `app` and `version` labels : We recommend adding an explicit `app` label and `version` label to the specification of the pods deployed using a Kubernetes Deployment. The `app` and `version` labels add contextual information to the metrics and telemetry that Istio collects.*
    > 
    > - *The `app` label : **Each deployment should have** a distinct `app` label with a meaningful value. The `app` label is used to add contextual information in distributed tracing.*
    > - *The `version` label : This label indicates the version of the application corresponding to the particular deployment.*

    ![스크린샷 2023-01-26 오후 1.26.18.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.26.18.png)

<br />
호출 테스트  
```bash
for in in {1..20}; do curl http://localhost/api/catalog -H \
"Host: webapp.istioinaction.io"; sleep .5s; done
```

*호출 후 Call graph 를 확인해 보세요*
![스크린샷 2023-01-26 오후 1.27.09.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.27.09.png)
<img src="/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.28.11.png" width=110 />

*From the graph …*

- Traversal and flow of traffic
- Number of bytes, requests, ..
- Multiple traffic flows for multiple versions
- RPS (Requests Per Second); % of total traffic for multiple versions
- Application health based on network traffic
- HTTP/TCP traffic
- Networking failures, which can be quickly identified
    
    ![스크린샷 2023-01-26 오후 1.57.17.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.57.17.png)
    

**CORRELATION OF TRACES, METRICS, AND LOGS**

Kiali is gradually evolving into the one dashboard that answers all service mesh observability questions.

*Kiali는 모든 서비스 메시의 observability 질문에 응답하는 “하나의 대시보드”로 계속해서 진화중임.*

One of the Kiali features — **correlating traces, metrics, and logs** — is just a promise of the possibilities to come.

To view the correlation between telemetry data, drill into one of the workloads by clicking the **Workloads menu item** at left in the overview dashboard in figure 8.13, and then **select a workload** from the list. The menu items in the Workload view reveal the following (see, for example, figure 8.16):

![스크린샷 2023-01-29 오전 9.12.47.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_9.12.47.png)

- Overview — 서비스 파드들, Istio 설정, Call graph
- Traffic — Success rate of inbound and outbound traffic
- Logs — Application logs, Envoy access logs, and spans correlated together
- Inbound Metrics and Outbound Metrics — Correlated with spans
- Traces — The traces reported by Jaeger
- Envoy — Envoy 설정 (clusters, listeners, routes ..)

Correlation 해주니깐 (연관된 지표들을 한 곳에 모아놔 주니깐) 디버깅이 매우 간단해 집니다. 여러 윈도우를 스위치 해가며 볼 필요도 없고 시점 기준으로 여러 그래프를 비교할 필요도 없습니다. 

예를 들어 대시보드 상에서 request spike 가 나타나면 그것과 관련하여 새로운 버전 혹은 degraded 서비스로 부터 요청이 처리되었다는 “traces” 가 바로 있습니다. 

[Kiali 는 또한 Istio 리소스에 대한 validation 도 제공합니다.](https://kiali.io/docs/features/validations/)

- VirtualService pointing to non-existent Gateway
- Routing to destination that do not exist
- More than one VirtualService for the same host
- Service subsets not found
- (참고) Kiali’s [AuthorizationPolicy](https://kiali.io/docs/features/validations/#authorizationpolicies)
    - [KIA0101 - Namespace not found for this rule](https://kiali.io/docs/features/validations/#kia0101---namespace-not-found-for-this-rule)
    - [KIA0102 - Only HTTP methods and fully-qualified gRPC names are allowed](https://kiali.io/docs/features/validations/#kia0102---only-http-methods-and-fully-qualified-grpc-names-are-allowed)
    - [KIA0104 - This host has no matching entry in the service registry](https://kiali.io/docs/features/validations/#kia0104---this-host-has-no-matching-entry-in-the-service-registry)
    - [KIA0105 - This field requires mTLS to be enabled](https://kiali.io/docs/features/validations/#kia0105---this-field-requires-mtls-to-be-enabled)
    - [KIA0106 - Service Account not found for this principal](https://kiali.io/docs/features/validations/#kia0106---service-account-not-found-for-this-principal)
    - [Destination rules](https://kiali.io/docs/features/validations/#destinationrules)
        - [KIA0201 - More than one DestinationRules for the same host subset combination](https://kiali.io/docs/features/validations/#kia0201---more-than-one-destinationrules-for-the-same-host-subset-combination)
        - [KIA0202 - This host has no matching entry in the service registry (service, workload or service entries)](https://kiali.io/docs/features/validations/#kia0202---this-host-has-no-matching-entry-in-the-service-registry-service-workload-or-service-entries)
        - [KIA0203 - This subset’s labels are not found in any matching host](https://kiali.io/docs/features/validations/#kia0203---this-subsets-labels-are-not-found-in-any-matching-host)
        - [KIA0204 - mTLS settings of a non-local Destination Rule are overridden](https://kiali.io/docs/features/validations/#kia0204---mtls-settings-of-a-non-local-destination-rule-are-overridden)
        - [KIA0205 - PeerAuthentication enabling mTLS at mesh level is missing](https://kiali.io/docs/features/validations/#kia0205---peerauthentication-enabling-mtls-at-mesh-level-is-missing)
        - [KIA0206 - PeerAuthentication enabling namespace-wide mTLS is missing](https://kiali.io/docs/features/validations/#kia0206---peerauthentication-enabling-namespace-wide-mtls-is-missing)
        - [KIA0207 - PeerAuthentication with TLS strict mode found, it should be permissive](https://kiali.io/docs/features/validations/#kia0207---peerauthentication-with-tls-strict-mode-found-it-should-be-permissive)
        - [KIA0208 - PeerAuthentication enabling mTLS found, permissive mode needed](https://kiali.io/docs/features/validations/#kia0208---peerauthentication-enabling-mtls-found-permissive-mode-needed)
        - [KIA0209 - DestinationRule Subset has not labels](https://kiali.io/docs/features/validations/#kia0209---destinationrule-subset-has-not-labels)
    - [Gateways](https://kiali.io/docs/features/validations/#gateways)
        - [KIA0301 - More than one Gateway for the same host port combination](https://kiali.io/docs/features/validations/#kia0301---more-than-one-gateway-for-the-same-host-port-combination)
        - [KIA0302 - No matching workload found for gateway selector in this namespace](https://kiali.io/docs/features/validations/#kia0302---no-matching-workload-found-for-gateway-selector-in-this-namespace)
    - [Mesh Policies](https://kiali.io/docs/features/validations/#meshpolicies)
        - [KIA0401 - Mesh-wide Destination Rule enabling mTLS is missing](https://kiali.io/docs/features/validations/#kia0401---mesh-wide-destination-rule-enabling-mtls-is-missing)
    - [PeerAuthentication](https://kiali.io/docs/features/validations/#peerauthentication)
        - [KIA0501 - Destination Rule enabling namespace-wide mTLS is missing](https://kiali.io/docs/features/validations/#kia0501---destination-rule-enabling-namespace-wide-mtls-is-missing)
        - [KIA0505 - Destination Rule disabling namespace-wide mTLS is missing](https://kiali.io/docs/features/validations/#kia0505---destination-rule-disabling-namespace-wide-mtls-is-missing)
        - [KIA0506 - Destination Rule disabling mesh-wide mTLS is missing](https://kiali.io/docs/features/validations/#kia0506---destination-rule-disabling-mesh-wide-mtls-is-missing)
    - [Ports](https://kiali.io/docs/features/validations/#ports)
        - [KIA0601 - Port name must follow [-suffix] form](https://kiali.io/docs/features/validations/#kia0601---port-name-must-follow-protocol-suffix-form)
        - [KIA0602 - Port appProtocol must follow form](https://kiali.io/docs/features/validations/#kia0602---port-appprotocol-must-follow-protocol-form)
    - [Services](https://kiali.io/docs/features/validations/#services)
        - [KIA0701 - Deployment exposing same port as Service not found](https://kiali.io/docs/features/validations/#kia0701---deployment-exposing-same-port-as-service-not-found)
    - [Sidecars](https://kiali.io/docs/features/validations/#sidecars)
        - [KIA1004 - This host has no matching entry in the service registry](https://kiali.io/docs/features/validations/#kia1004---this-host-has-no-matching-entry-in-the-service-registry)
        - [KIA1006 - Global default sidecar should not have workloadSelector](https://kiali.io/docs/features/validations/#kia1006---global-default-sidecar-should-not-have-workloadselector)
    - [VirtualServices](https://kiali.io/docs/features/validations/#virtualservices)
        - [KIA1101 - DestinationWeight on route doesn’t have a valid service (host not found)](https://kiali.io/docs/features/validations/#kia1101---destinationweight-on-route-doesnt-have-a-valid-service-host-not-found)
        - [KIA1102 - VirtualService is pointing to a non-existent gateway](https://kiali.io/docs/features/validations/#kia1102---virtualservice-is-pointing-to-a-non-existent-gateway)
        - [KIA1104 - The weight is assumed to be 100 because there is only one route destination](https://kiali.io/docs/features/validations/#kia1104---the-weight-is-assumed-to-be-100-because-there-is-only-one-route-destination)
        - [KIA1105 - This host subset combination is already referenced in another route destination](https://kiali.io/docs/features/validations/#kia1105---this-host-subset-combination-is-already-referenced-in-another-route-destination)
        - [KIA1106 - More than one Virtual Service for same host](https://kiali.io/docs/features/validations/#kia1106---more-than-one-virtual-service-for-same-host)
        - [KIA1107 - Subset not found](https://kiali.io/docs/features/validations/#kia1107---subset-not-found)
        - [KIA1108 - Preferred nomenclature: /](https://kiali.io/docs/features/validations/#kia1108---preferred-nomenclature-gateway-namespacegateway-name)
    - [WorkloadEntries](https://kiali.io/docs/features/validations/#workloadentries)
        - [KIA1201 - Missing one or more addresses from matching WorkloadEntries](https://kiali.io/docs/features/validations/#kia1201---missing-one-or-more-addresses-from-matching-workloadentries)
    - [Workloads](https://kiali.io/docs/features/validations/#workloads)
        - [KIA1301 - This workload is not covered by any authorization policy](https://kiali.io/docs/features/validations/#kia1301---this-workload-is-not-covered-by-any-authorization-policy)
    - [Generic](https://kiali.io/docs/features/validations/#generic)
        - [KIA0002 - More than one selector-less object in the same namespace](https://kiali.io/docs/features/validations/#kia0002---more-than-one-selector-less-object-in-the-same-namespace)
        - [KIA0003 - More than one object applied to the same workload](https://kiali.io/docs/features/validations/#kia0003---more-than-one-object-applied-to-the-same-workload)
        - [KIA0004 - No matching workload found for the selector in this namespace](https://kiali.io/docs/features/validations/#kia0004---no-matching-workload-found-for-the-selector-in-this-namespace)
        - [KIA0005 - No matching namespace found or namespace is not accessible](https://kiali.io/docs/features/validations/#kia0005---no-matching-namespace-found-or-namespace-is-not-accessible)

### 8.3.2 Conclusion

- Grafana — Scarping Prometheus metrics and Visualizing metrics for Istio
- Jeager — Distributed Tracing for understanding latencies in a multi-hop call graph
    - annotate correlate requests with metatdata
    - detect metadata and send spans to tracing engine
- Kiali — Representing the traffic flow in a call graph and Digging into the configuration that enables this traffic flow.

## Summary

- Grafana — Istio control/data plane 메트릭 대시보드 제공
- Distributed tracing (Jaeger) — service requests 에 대한 Insight 제공 
** how ? “annotate requests”   
** 간트 차트와 비슷하다*
  ![스크린샷 2023-01-29 오후 2.05.43.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.05.43.png)
  ![스크린샷 2023-01-29 오후 2.06.42.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.06.42.png)

- Applications — “Trace header” 전파.  request 의 전체 view  확보
- Trace — a collection of spans.  분산 환경에서 요청을 처리하는 단계별 홉과 레이턴시 디버깅 제공
- Trace header 설정
    - global 설정 — `defaultConfig`  (from Istio installation)
    - workload 단위 설정 — `proxy.istio.io/config`  (from annotation)
- Kiali Operator 설정
    - metrics — Prometheus 연동 설정
    - traces — Jaeger 연동 설정
- Kiali — supports ***Istio-specific*** dashboards
    - networking graph
        
        ![스크린샷 2023-01-29 오후 2.24.08.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.08.png)
        
    - metric correlation
        
        ![스크린샷 2023-01-29 오후 2.24.36.png](/assets/img/Istio-ch8-observability-2-visibility%20b06a0bd1502d4e55a54a41be98fa423c/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.36.png)