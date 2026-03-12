---
title: Istio Observability (2)  
version: v1.2  
description: istio in action 8장  
date: 2023-04-20 19:15:00 +09:00  
layout: page  
toc: 10  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
histories:
- date: 2023-04-20 19:15:00 +09:00
  description: 최초 등록
---
ch7 에서 다룬 observability 의 visualize 에 대해 알아봅니다. visualize 를 위한 도구로 Grafana (Metrics), Jaeger/Zipkin (Distributed Tracing), Kiali (Call Graph) 등을 살펴봅니다.

<!--more-->

# 개요

- Prometheus 가 수집한 Istio의 data/control plane 메트릭 그래프에 대해 살펴 봅니다
- Grafana 의 Istio 대시보드를 통해 data/control plane 을 모니터링 할 수 있습니다
- Distributed Tracing 은 여러 홉을 거치는 서비스의 call graph로 부터 지연 (latencies) 을 파악하는데 매우 유용합니다
- Distributed Tracing 은 서로 관련 있는 requests 에 메타데이터를 어노테이션 하고, Istio가 자동으로 해당 메타데이터를 detect 하여 “**span”** 에 실어 **tracing 엔진**에  보냅니다.

## TERM

[**Span** ?](https://www.jaegertracing.io/docs/1.41/architecture/)

> Span은 "이름", "시작시간", "기간"을 가지고 있는 작업의 논리적인 단위를 나타냅니다.   
> Span은 인과적인 관계를 모델링하기 위해 "중첩"과 "정렬"을 사용합니다.  
> 
> ![스크린샷 2023-01-29 오후 1.00.46.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.00.46.png)
> 

*참고로 … span 은 건축에서는 교량을 **지지하는 단위 구간**을 의미합니다*

<img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.59.11.png" width=301 />

**Trace**  
트레이스는 Span의 인과적인 관계를 표현한 것입니다  
> 트레이스는 시스템을 통과하는 데이터 혹은 실행의 "경로(path)"를 나타냅니다.  
> 트레이스는 일종의 "Span Graph" (DAG,방향성 비순환 그래프) 입니다.  
>
[(참고) DAG 방향성 비순환 그래프](https://en.wikipedia.org/wiki/Directed_acyclic_graph)
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
>     <img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.52.10.png" width="180" />
>     

## 다루는 내용

- Visualizing “metrics” using Grafana
- Visualizing “Distributed Tracing” using Jaeger/Zipkin
- Visualizing “network call graph” using Kiali

## 실습환경

- minikube (k8s) 및 istio 설치.  참고: [https://netpple.github.io/docs/istio-in-action/Istio-Environment](https://netpple.github.io/docs/istio-in-action/Istio-Environment)
- **실습 네임스페이스** : istioinaction
- **실습 디렉토리** : book-source-code

# 8.1 Grafana - Istio 서비스와 control-plane Visualize

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

![스크린샷 2023-01-25 오전 8.05.46.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.05.46.png)

## 8.1.1 Istio Grafana 대시보드 구성하기

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
<omit> Working on configmap prometheus/istio-dashboards
<omit> File in configmap istio-extension-dashboard.json ADDED
<omit> File in configmap istio-mesh-dashboard.json ADDED
<omit> File in configmap istio-performance-dashboard.json ADDED
<omit> File in configmap istio-service-dashboard.json ADDED
<omit> File in configmap istio-workload-dashboard.json ADDED
<omit> File in configmap pilot-dashboard.json ADDED
```

<img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.26.05.png" width=70 /> 클릭

![스크린샷 2023-01-25 오전 8.25.43.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.25.43.png)

## 8.1.2 컨트롤 플레인 메트릭

`Istio Control Plane Dashboard`  

이전 챕터에서 ServiceMonitor 를 설정하여 Control plane 의 지표들을 프로메테우스로 수집하였는데요. 수집된 메트릭을 통해 구성된 Grafana 대시보드를 살펴 보시죠

**Deployed Versions**
```
# Pilot Versions
sum(istio_build{component="pilot"}) by (tag)
```

**Resource Usage**
```
# Memory
process_virtual_memory_bytes{app="istiod"}
process_resident_memory_bytes{app="istiod"}
go_memstats_heap_sys_bytes{app="istiod"}
go_memstats_heap_alloc_bytes{app="istiod"}
go_memstats_alloc_bytes{app="istiod"}
go_memstats_heap_inuse_bytes{app="istiod"}
go_memstats_stack_inuse_bytes{app="istiod"}
container_memory_working_set_bytes{container=~"discovery", pod=~"istiod-.*|istio-pilot-.*"}
container_memory_working_set_bytes{container=~"istio-proxy", pod=~"istiod-.*|istio-pilot-.*"}

# CPU
sum(irate(container_cpu_usage_seconds_total{container="discovery", pod=~"istiod-.*|istio-pilot-.*"}[1m]))
irate(process_cpu_seconds_total{app="istiod"}[1m])
sum(irate(container_cpu_usage_seconds_total{container="istio-proxy", pod=~"istiod-.*|istio-pilot-.*"}[1m]))

# Disk
container_fs_usage_bytes{container="discovery", pod=~"istiod-.*|istio-pilot-.*"}
container_fs_usage_bytes{container="istio-proxy", pod=~"istiod-.*|istio-pilot-.*"}

# Goroutines
go_goroutines{app="istiod"}
```

**Pilot Push Information**
```
# Pilot Pushes
sum(irate(pilot_xds_pushes{type="cds"}[1m]))
sum(irate(pilot_xds_pushes{type="eds"}[1m]))
sum(irate(pilot_xds_pushes{type="lds"}[1m]))
sum(irate(pilot_xds_pushes{type="rds"}[1m]))
sum(irate(pilot_xds_pushes{type="sds"}[1m]))
sum(irate(pilot_xds_pushes{type="nds"}[1m]))

# Pilot Errors
sum(pilot_xds_cds_reject{app="istiod"}) or (absent(pilot_xds_cds_reject{app="istiod"}) - 1)
sum(pilot_xds_eds_reject{app="istiod"}) or (absent(pilot_xds_eds_reject{app="istiod"}) - 1)
sum(pilot_xds_rds_reject{app="istiod"}) or (absent(pilot_xds_rds_reject{app="istiod"}) - 1)
sum(pilot_xds_lds_reject{app="istiod"}) or (absent(pilot_xds_lds_reject{app="istiod"}) - 1)
sum(rate(pilot_xds_write_timeout{app="istiod"}[1m]))
sum(rate(pilot_total_xds_internal_errors{app="istiod"}[1m]))
sum(rate(pilot_total_xds_rejects{app="istiod"}[1m]))
sum(rate(pilot_xds_push_context_errors{app="istiod"}[1m]))
sum(rate(pilot_xds_write_timeout{app="istiod"}[1m]))


# Proxy Push Time - convergence latency 모니터링
sum(irate(pilot_xds_pushes{type="cds"}[1m]))
sum(irate(pilot_xds_pushes{type="eds"}[1m]))
sum(irate(pilot_xds_pushes{type="lds"}[1m]))
sum(irate(pilot_xds_pushes{type="rds"}[1m]))
sum(irate(pilot_xds_pushes{type="sds"}[1m]))
sum(irate(pilot_xds_pushes{type="nds"}[1m]))

# Conflicts
pilot_conflict_inbound_listener{app="istiod"}
pilot_conflict_outbound_listener_http_over_current_tcp{app="istiod"}
pilot_conflict_outbound_listener_tcp_over_current_tcp{app="istiod"}
pilot_conflict_outbound_listener_tcp_over_current_http{app="istiod"}

# ADS Monitoring
pilot_virt_services{app="istiod"}
pilot_services{app="istiod"}
pilot_xds{app="istiod"}
```
*Pilot Push Time*
- visualizing `pilot_proxy_convergence_time`  (the time taken to distribute changes to the proxies)

*Pilot Convergence*
- "mesh 구성요소 간의 일관성을 유지하는 프로세스"
- 메시 구성요소 ~ Envoy 프록시, Mixer, Pilot, Citadel
- 각 구성요소는 서로 다른 설정소스(Istio CRD, configmap, vault 인증서 등)에서 구성정보를 가져올 수 있음
- Convergence는 이러한 구성요소에 변경사항이 발생할 때마다, 구성요소 간의 설정정보의 일관성을 유지하기 위한 프로세스임
- Convergence는 Istio의 구성정보를 수신하여 변경된 사항들을 모든 구성요소에 전파하고, 변경된 구성요소 간에 일관성을 보장하기 위한 추가작업을 수행함.

*Pilot Conflicts*
- endpoint conflict  
  예) 같은 서비스 or 포트에 동일한 엔드포인트가 다수존재 => (해결) 최신버전 Endpoint로 업데이트
- port conflict   
  예) 동일 서비스에 대해 다른 포트 사용 => (해결) 먼저 설정된 포트사용
- route conflict   
  예) 다수의 VirtualService, DestinationRule 설정이 충돌 => (해결) 더 구체적인 설정이 우선

*ADS (Aggregated Discovery Service)*
- 여러개의 Discovery Service들을 모아서(aggregate), Envoy 사이드카(istio-proxy)와 Pilot(istiod) 사이의 통신을 관리하는 Istio의 핵심 컴포넌트
- Service Discovery(xDS) 통합 관리
  - LDS (Listener DS) : Envoy의 리스너 정보를 관리합니다
  - RDS (Rourte DS) : Envoy의 라우팅 규칙을 관리합니다
  - CDS (Cluster DS) : Envoy의 클러스터 정보를 관리합니다
  - EDS (Endpoint DS) : Envoy의 엔드포인트 정보를 관리합니다
  - SDS (Secret DS) : Envoy의 보안 구성을 관리합니다
  - NDS (Network) : Envoy의 서비스네임,IP주소 정보를 관리합니다

**Envoy Information**
``` 
# Envoy Details
sum(irate(envoy_cluster_upstream_cx_total{cluster_name="xds-grpc"}[1m]))
sum(irate(envoy_cluster_upstream_cx_connect_fail{cluster_name="xds-grpc"}[1m]))
sum(increase(envoy_server_hot_restart_epoch[1m]))

# XDS Active Connections
sum(envoy_cluster_upstream_cx_active{cluster_name="xds-grpc"})

# XDS Requests Size
max(rate(envoy_cluster_upstream_cx_rx_bytes_total{cluster_name="xds-grpc"}[1m]))
quantile(0.5, rate(envoy_cluster_upstream_cx_rx_bytes_total{cluster_name="xds-grpc"}[1m]))
max(rate(envoy_cluster_upstream_cx_tx_bytes_total{cluster_name="xds-grpc"}[1m]))
quantile(.5, rate(envoy_cluster_upstream_cx_tx_bytes_total{cluster_name="xds-grpc"}[1m]))
```

**Webhooks**
``` 
# Configuration Validation
sum(rate(galley_validation_passed[1m]))
sum(rate(galley_validation_failed[1m]))

# Sidecar Injection
sum(rate(sidecar_injection_success_total[1m]))
sum(rate(sidecar_injection_failure_total[1m]))
```
*Galley*  
*Istio 구성요소 간 통신을 관리하고, 구성요소의 설정을 유지 및 관리하고, 정책/규칙의 검증 작업을 수행하는 역할을 담당하는 컴포넌트*
- Istio Config 포맷 변환
- Config 검증
- 작업노드에 대한 필요한 설정 정보 배포
- Envoy proxy 추가 시 마다 설정정보 업데이트
- Sidecar auto-injection 수행
- 1.18 에서 제거 예정 => istiod의 ComponentConfig 로 대체

```bash
## (실습) catalog 와 webapp을 각각 재배포 후 대시보드 관찰
kubectl rollout restart deploy/webapp -n istioinaction
kubectl rollout restart deploy/catalog -n istioinaction
```

## 8.1.3 데이터플레인 메트릭  

`Istio Service Dashboard`  

**General - “SERVICE: webapp.istioinaction.svc.cluster.local”**
``` 
# Client Request Volume (webapp)
round(sum(irate(istio_requests_total{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[5m])), 0.001)

# Client Success Rate (non-5xx responses)
sum(irate(istio_requests_total{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local",response_code!~"5.*"}[5m])) / sum(irate(istio_requests_total{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[5m]))

# Client Request Duration
(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))
(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))
(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{reporter="source",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))


# Server Request Volume (catalog)
round(sum(irate(istio_requests_total{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[5m])), 0.001)

# Server Success Rate
sum(irate(istio_requests_total{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local",response_code!~"5.*"}[5m])) / sum(irate(istio_requests_total{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[5m]))

# Server request Duration
(histogram_quantile(0.50, sum(irate(istio_request_duration_milliseconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.50, sum(irate(istio_request_duration_seconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))
(histogram_quantile(0.90, sum(irate(istio_request_duration_milliseconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.90, sum(irate(istio_request_duration_seconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))
(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{reporter="destination",destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m])) by (le))

# TCP Received Bytes
sum(irate(istio_tcp_received_bytes_total{reporter="destination", destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m]))

# TCP Sent Bytes
sum(irate(istio_tcp_sent_bytes_total{reporter="destination", destination_service=~"webapp.istioinaction.svc.cluster.local"}[1m]))
```

**Client Workloads**
``` 
# Incoming Requests By Source And Response Code
round(sum(irate(istio_requests_total{connection_security_policy="mutual_tls",destination_service=~"webapp.istioinaction.svc.cluster.local",reporter="source",source_workload=~"istio-ingressgateway",source_workload_namespace=~"istio-system"}[5m])) by (source_workload, source_workload_namespace, response_code), 0.001)

# Incoming Success Rate (non-5xx responses) By Source
sum(irate(istio_requests_total{reporter="source", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local",response_code!~"5.*", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[5m])) by (source_workload, source_workload_namespace) / sum(irate(istio_requests_total{reporter="source", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[5m])) by (source_workload, source_workload_namespace)

# Incoming Request Duration By Source
..
(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{reporter="source", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{reporter="source", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace, le))

# Incoming Request Size By Source
..
histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{reporter="source", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace, le))

# Response Size By Source
..
histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{reporter="source", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace, le))

# Bytes Received from Incoming TCP Connection
round(sum(irate(istio_tcp_received_bytes_total{reporter="source", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace), 0.001)

# Bytes Sent to Incoming TCP Connection
round(sum(irate(istio_tcp_sent_bytes_total{connection_security_policy="mutual_tls", reporter="destination", destination_service=~"catalog.istioinaction.svc.cluster.local", source_workload=~"webapp", source_workload_namespace=~"istioinaction"}[1m])) by (source_workload, source_workload_namespace), 0.001)
```

**Service Workloads**
``` 
# Incoming Requests By Destination Workload And Response Code
round(sum(irate(istio_requests_total{connection_security_policy="mutual_tls",destination_service=~"catalog.istioinaction.svc.cluster.local",reporter="destination",destination_workload=~"catalog",destination_workload_namespace=~"istioinaction"}[5m])) by (destination_workload, destination_workload_namespace, response_code), 0.001)

# Incoming Success Rate (non-5xx responses) By Destination Workload
sum(irate(istio_requests_total{reporter="destination", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local",response_code!~"5.*", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[5m])) by (destination_workload, destination_workload_namespace) / sum(irate(istio_requests_total{reporter="destination", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[5m])) by (destination_workload, destination_workload_namespace)

# Incoming Request Duration By Service Workload
..
(histogram_quantile(0.99, sum(irate(istio_request_duration_milliseconds_bucket{reporter="destination", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace, le)) / 1000) or histogram_quantile(0.99, sum(irate(istio_request_duration_seconds_bucket{reporter="destination", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace, le))

# Incoming Request Size By Service Workload
..
histogram_quantile(0.99, sum(irate(istio_request_bytes_bucket{reporter="destination", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace, le))

# Response Size By Service Workload
..
histogram_quantile(0.99, sum(irate(istio_response_bytes_bucket{reporter="destination", connection_security_policy!="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace, le))

# Bytes Received from Incoming TCP Connection
round(sum(irate(istio_tcp_received_bytes_total{reporter="destination", connection_security_policy="mutual_tls", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)

# Bytes Sent to Incoming TCP Connection
round(sum(irate(istio_tcp_sent_bytes_total{connection_security_policy!="mutual_tls", reporter="destination", destination_service=~"catalog.istioinaction.svc.cluster.local", destination_workload=~"catalog", destination_workload_namespace=~"istioinaction"}[1m])) by (destination_workload, destination_workload_namespace), 0.001)
```

```bash
## webapp 으로 트래픽 유입 후 데이터플레인 대시보드를 관찰해 보세요 
fortio load -H "Host: webapp.istioinaction.io" -quiet -jitter -t 30s -c 1 -qps 1 http://localhost/api/catalog
```

**테스트**  

*앞의 챕터들에서 다루었던 실습을 복습하면서 대시보드를 확인해 보세요*
- tcp traffic
  ```bash
  ## tcp-echo 설치 
  kubectl apply -f ch4/echo.yaml -n istioinaction
  kubectl apply -f ch4/gateway-tcp.yaml -n istioinaction
  kubectl apply -f ch4/echo-vs.yaml -n istioinaction 
  ```
  ```bash
  ## 터미널2
  telnet localhost 31400
  
  ## 아래와 같이 긴 문자열 입력
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ... 
  ```
- LB algorithm
- Locality-aware
- Latency
- Retries
- timeout
- Circuit-break



# 8.2 Distributed tracing

*(배경)*
- 모놀리딕 환경에서는 시스템이 이상동작을 보이더라도 사용가능한 익숙한 도구를 이용하여 디버깅을 합니다.  
- 디버거, 런타임 프로파일러, 메모리 분석툴 등 코드의 어떤 부분에서 레이턴시가 발생하고 에러를 유발하고
- 어플리케이션 기능을 오동작 하도록 만드는지 발견할 수 있는 도구들이 많습니다  
- 어플리케이션이 분산 컴포넌트로 구성이 될 경우에도 마찬가지로 똑같이 디버깅 할 수 있도록 새로운 툴셋이 필요합니다

*(분산 트레이싱 기원과 개요)*
- 분산 트레이싱은 요청을 처리하는데 포함된 분산 컴포넌트들에 대한 인사이트를 줍니다  
- 분산 트레이싱은 구글 논문 (Dapper, 2010)에서 쳐음 소개됐고 
- 서비스-to-서비스 호출을 나타내는 correlation ID 와 
- 서비스-to-서비스 호출 그래프를 통과하는 특정 요청을 식별하기 위한 trace Id를 어노테이션으로 추가합니다.
  예) istio 의 경우 (Jaeger/Zipkin) ~ `x-request-id`  
- Istio는 correlation ID, trace ID를 요청(request) 에 추가할 수 있습니다.
- 그리고, trace ID가 인식이 되지 않거나 외부에서 온 것일 때에는 삭제할 수 있습니다.

*(OpenTelemetry)*
- OpenTelemetry는 Opentracing을 포함하는 커뮤니티 주도의 프레임웍으로 
- 분산 트레이싱의 개념과 API를 포함하는 스펙입니다.  
- 분산 트레이싱은 일정 부분 개발자에게 의존합니다. 
  - 모니터링을 위한 코드(instrumenting code) 삽입 
  - 요청에 어노테이션 (correlation id, trace Id 등) 추가
- 트레이싱 엔진은 요청 플로우의 전체 그림을 하나로 완성하여 아키텍처 상에서 오동작할 수 있는 영역을 인식하기 쉽도록 돕습니다.

*(Istio 를 쓰세요)*
- Istio는 개발자 여러분들이 추가로 직접 구현해야 할 많은 부분들을 대신해주고 서비스 메시에서의 분산 트레이싱을 제공합니다.

> 서비스에서 하나의 요청을 처리하기 위해 여러 홉을 거치기도 합니다
> 
> <img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.16.31.png" width=200 />
> 

## 8.2.1 분산트레이싱의 동작 방식

*Span 과 Trace context ⇒ Trace*
- 해당 서비스에서 Span 생성
- 트레이싱엔진으로 Span 전송
- 다른 서비스로 Trace context 전파
- Trace 기록 ~ 서비스 간의 인과성 추적
- Span ID, Trace ID ~ 서비스 간 연계 및 추적 

![스크린샷 2023-01-25 오후 12.43.37.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.43.37.png)

*Istio 는 분산 트레이싱 엔진으로의 "Span 전송"을 핸들링 합니다* 

Zipkin 트레이싱 헤더
- x-request-id
- x-b3-traceid
- x-b3-spanid
- x-b3-parentspanid
- x-b3-sampled
- x-b3-flags
- x-ot-span-context

![스크린샷 2023-01-25 오후 1.09.05.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.09.05.png)

## 8.2.2 분산 트레이싱 시스템 설치

*Jaeger 설치가 다소 복잡해서 그냥 Istio 샘플 addon을 쓰겠습니다*

```bash
cd istio-1.17.2

kubectl apply -f samples/addons/jaeger.yaml
```
```bash
## 설치 확인
kubectl get po,svc -n istio-system -o name
```

## 8.2.3 Istio 분산 트레이싱 설정

Istio 는 다양한 레벨 (global / namespace / workload) 에서 분산 트레이싱을 적용 할 수 있습니다  
[참고) Istio Telemetry API](https://istio.io/latest/docs/tasks/observability/telemetry/) 

*방법1. IstioOperator 설정*

Istio 는 다양한 분산 트레이싱 백엔드를 지원합니다  
~ Zipkin, Datadog, Jaeger (Zipkin 호환) ,... 

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

실습에서는 아래 설정을 사용하겠습니다 ~ Jaeger (Zipkin compatible) 설정

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

아래 방법2, 방법3 으로도 분산 트레이싱 설정을 할 수 있습니다  


*방법2. istio configmap 설정 ~ meshconfig*

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

*방법3. 워크로드 어노테이션 설정*

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

**지금부터 트레이싱 헤더를 확인해 봅시다**
- 앞에서 분산 트레이싱 엔진(Jaeger)을 설치하고 Istio 에 트레이싱 엔진을 설정하였습니다.  
- Istio가 OpenTracing 헤더와 correlation ID 를 자동으로 주입해 주는지 실습해 보겠습니다. 
- 아래 실습에서는 "httpbin.istioinaction.io" 요청 시 외부 서비스 "http://httpbin.org"를 호출합니다.
- [http://httpbin.org](http://httpbin.org) 은 simple HTTP 테스트 서비스로 응답 시 헤더 정보를 출력해 줍니다. 
- httpin.org 응답에 포함된 Zipkin 헤더 정보를 확인해 보겠습니다. 

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
## 적용
kubectl apply -n istioinaction \
-f ch8/tracing/thin-httpbin-virtualservice.yaml
```

호출 테스트  
> client (curl) —> istio-ingress-gateway —> httpbin.org (외부)
> 

```bash
# curl -H "Host: httpbin.istioinaction.io" http://localhost/headers

{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.istioinaction.io",
    "User-Agent": "curl/7.85.0",
    "X-Amzn-Trace-Id": "Root=1-63d0c0d3-16a602144b1411b43a596a18",
    "X-B3-Sampled": "1",       # Span 생성과 전송을 위해 자동으로 추가됨
    "X-B3-Spanid": "e9fa90a180e41b73",                  # (상동)
    "X-B3-Traceid": "484333fa50c1e0a8e9fa90a180e41b73", # (상동)
    "X-Envoy-Attempt-Count": "1",
    "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
    "X-Envoy-Internal": "true",
    "X-Envoy-Peer-Metadata": "*<omitted>*",
    "X-Envoy-Peer-Metadata-Id": "*<omitted>*"
    ...
  }
...
}
```

- *X-B3-* Zipkin 헤더가 자동으로 request 헤더에 추가되었습니다. 
- Zipkin 헤더는 “Span” 을 생성하는데 사용되고 Jaeger로 보내집니다.

## 8.2.4 분산 트레이싱 대시보드 - JAEGER UI

*JAEGER UI 접속*

```bash
istioctl dashboard jaeger --browser=false
```
대시보드: [http://localhost:16686](http://localhost:16686){:target="_blank"}

👉🏻Service 콤보에서 "istio-ingresgateway 를 선택" 후 "Find Traces" 버튼을 클릭하세요
<img src="/docs/assets/img/istio-in-action/jaeger_dashboard.png" />

*요청 유입 및 모니터링*

```bash
for in in {1..10}; do \
  curl -H "Host: webapp.istioinaction.io" localhost/api/catalog;
done
```
👉🏻요청이 유입되면 Trace가 대시보드에 출력이 됩니다 
<img src="/docs/assets/img/istio-in-action/jaeger_traces.png" />

👉🏻Trace 목록 중 하나를 클릭하면 상세 Span 정보를 출력합니다 
<img src="/docs/assets/img/istio-in-action/jaeger_spans.png" />


## 8.2.5 Trace sampling, force traces, and custom tags

**TRACE SAMPLING**  
- Trace Sampling => Span 생성과 전송
- “Sampling Rate” 높을 수록 ~ 성능 부담 커짐
- istio configmap 에서 sampling rate 을 조절해 봅니다. (100 → 10) *globally 적용됨*

*트레이스 샘플링 튜닝*

아래와 같이 meshConfig를 수정합니다
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
덧) 샘플링 적용은 istio-ingressgateway 재배포가 필요합니다
- istiod 로그 상에 istio cm(configmap) 변경 로그는 찍힘

덧) 워크로드(ex:deploy/webapp) 단위 샘플링 적용 안됨
- 책에서는 워크로드의 annotaion 으로 샘플링 설정이 가능하다고 하는데
- meshConfig 설정의 sampling 비율로 동작하고 
- workload에 설정한 sampling 비율대로 작동하지 않았습니다

**FORCE-TRACING**
- 평소 운영 시에는 sampling rate 을 최소로 유지하고 
- 이슈가 있을 때만 특정 workload 에 대해서 tracing을 강제할 수 있습니다. 
- 트레이스를 강제하려면 간단하게 `x-envoy-force-trace` 요청 헤더를 추가합니다 
- Istio의 sampling rate과 무관하게 무조건 샘플링 됩니다  

```bash
curl -H "x-envoy-force-trace: true" \
-H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

**CUSTOM TAG**

트레이싱에 추가 메타데이터를 부여  
- Tag 는 커스텀 키/값 쌍으로 Span 정보에 포함되어 트레이싱 엔진에 전달

Custom Tag 의 "Value" 설정 유형  
- "직접 입력" Value
- "환경 변수" Value
- "요청 헤더" Value

```yaml
apiVersion: apps/v1
kind: Deployment
# ...
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
-  커스텀 태그의 키 : custom_tag
-  커스텀 태그의 값 : "Test Tag"

```bash
##  deploy/webapp 에 커스텀 태그 적용
kubectl apply -n istioinaction \
-f ch8/webapp-deployment-zipkin-tag.yaml
```

```bash
## 커스텀 태그 적용 확인을 위해 호출을 해볼까요
curl -H "Host: webapp.istioinaction.io" localhost/api/catalog
```

👉🏻`webapp Span`의 Tags 정보에 "custom_tag" 가 추가되었습니다 
![스크린샷 2023-01-25 오후 7.12.23.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.12.23.png)

Custom Tag 의 용도
- 탐색 ~ 트레이스 데이터
- 리포팅 
- 필터링    
<br /> 

**트레이싱 엔진 설정 커스텀**  

트레이싱 엔진 설정 방법을 알아보겠습니다  
```bash
## deploy/webapp 트레이싱 설정 조회
istioctl pc bootstrap -n istioinaction deploy/webapp \
-o json | jq .bootstrap.tracing
```

![webapp tracing configuration](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.18.57.png)

webapp의 default trace 설정은 다음과 같습니다
- tracing enging 은 Zipkin-based
- Span 은 /api/v2/spans 로 전달
- JSON 엔드포인트로 처리  
<br />


*Zipkin 커스텀 설정을 만들어 봅시다*
- 아래 configmap 은 collectorEndpoint 를 변경한 설정 스니펫 입니다

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
## 네임스페이스(istioinaction)를 주목해 주세요
kubectl apply -n istioinaction \
-f ch8/istio-custom-bootstrap.yaml
```

커스텀 설정을 istioninaction 네임스페이스 상에서 사용할 수 있습니다

👉🏻webapp 에서 커스텀 설정을 사용하도록 해봅시다 

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
- `sidecar.istio.io/bootstrapOverride: "istio-custom-zipkin"`    
  istio-custom-zipkin을 사용하도록 template annotation 에 추가합니다

```bash
## 변경된 설정으로 webapp을 재배포 합니다
kubectl apply -n istioinaction \
-f ch8/webapp-deployment-custom-boot.yaml
```

```bash
## webapp 의 트레이싱 설정을 다시 확인해 보세요
istioctl pc bootstrap -n istioinaction deploy/webapp \
-o json | jq .bootstrap.tracing
```

```bash
## 확인을 위해 webapp 을 호출해 봅시다
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

👉🏻JAEGER 대시보드 확인 - `webapp Span`이 출력되지 않습니다
![webapp span  안나옴 ( 존재하지 않는 collectorEndpoint 로 수정했기 때문 )](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.40.46.png)

💡 놀라지 마세요  :-)    
>  "존재하지 않는 (잘못된)" collectorEndpoint 로 수정했기 때문에 webapp Span이 출력되지 않는게 당연합니다

<br />

webapp 을 원래대로 초기화 후 다시 확인해 볼께요

```bash
## istio-custom-zipkin 어노테이션이 없는 webapp으로 재배포
kubectl apply -n istioinaction \
-f services/webapp/kubernetes/webapp.yaml 
```

```bash
## 호출 테스트
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog
```

👉🏻`webapp Span`이 원래대로 확인됨
![webapp span 확인됨 ](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.47.40.png)


# 8.3 Visualization with Kiali

Grafana 와 달라요
- 어떤 서비스들 간에 통신이 이루어 지고 있는지 시각적인 오버뷰를 제공합니다
- 클러스터 내 서비스들의 인터렉티브한 구성도를 제공합니다

Kiali는 프로메테우스에 저장된 Istio 메트릭을 시각화 합니다

## 8.3.1 Kiali 설치

*Pre-requisite*
- 책하고 다르게 최신 Istio 1.16, 1.17 기준으로 작성하였습니다
- 앞에서 설치한 kube-prometheus-stack 과 Jaeger 를 연동합니다 

*Step1. Kiali Operator 설치*

```bash
## helm repo
helm repo add kiali https://kiali.org/helm-charts
helm repo update 

## kiali-operator install
helm install \
--namespace kiali-operator \
--create-namespace \
--version 1.63.2 \
kiali-operator \
kiali/kiali-operator
```

*Step2. Kiali Dashboard 설치*

```yaml
# cat ch8/kiali.yaml

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

```bash
## 대시보드 설치 
kubectl apply -f ch8/kiali.yaml
```

(참고)
- [Kiali 버전 호환표](https://kiali.io/docs/installation/installation-guide/prerequisites/#version-compatibility){:target="_blank"}  
- [공식 설치 가이드](https://kiali.io/docs/installation/installation-guide/){:target="_blank"}
- Kiali 삭제
  ```bash
  ## 1 - Kiali 대시보드 삭제 (커스텀 리소스 삭제 시 kiali-operator가 제거함) 
  kubectl delete kiali kiali
  
  ## 2 - kiali-operator 삭제
  helm uninstall kiali -n kiali-operator 
  
  ## 3 - 네임스페이스 삭제
  kubectl delete ns kiali-operator 
  ```

*Kiali 대시보드 살펴보기*

```bash
## 포트포워딩 
kubectl -n istio-system port-forward deploy/kiali 20001
```

Kiali 대시보드 [http://localhost:20001](http://localhost:20001)

👉🏻Apps 조회 (default) - prometheus 패널 `2 Applications`
<img src="/docs/assets/img/istio-in-action/kiali_dashboard_apps.png" />

👉🏻Workload 조회 - prometheus 패널 `3 Workloads`
<img src="/docs/assets/img/istio-in-action/kiali_dashboard_workload.png" />

*Application vs Workload 어떻게 다른가요?*

`Healths for` 콤보에서 Apps or Workloads 선택에 따라 출력이 다릅니다
- 예) prometheus 패널에서 Apps는 2, Workloads는 3   

prometheus Apps의 경우, 그라파나(prom-grafana)가 포함되지 않습니다. 왜 그럴까요? 

<img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_10.33.14.png" width=240 />
    
정답) Apps 로 포함되려면 *`Label App`* 으로 지정 돼야 합니다 (재배포 필요)
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
        app: prom-grafana  # <-- Pod label 추가 
# ...
```

*(참고) Kiali 공식 : [https://kiali.io/docs/architecture/terminology/concepts/](https://kiali.io/docs/architecture/terminology/concepts/)*

- Workload  
  - 복제 리플리카들에 해당 하는 "실행 바이너리 Set" 입니다  
  - 쿠버네티스를 예로 들자면 Deployment 에 포함된 파드들 입니다  
  - 3개의 리플리카를 가진 `서비스 A` Deployment 가 워크로드 입니다  
  - istioinaction 네임스페이스에는 워크로드가 catalog 와 webapp 두 개가 있습니다   

- Application  
  - 유저가 "label 로 표시한 워크로드"의 논리적 그룹입니다  
  - 즉, 동일한 label로 표시된 워크로드들의 집합입니다  
  - Istio 에서는 *`Label App`* 으로 정의합니다  

- *`Label App`*  
  - ‘`app`’ 레이블로 정의합니다 [*참고) Istio Label Requirements*](https://istio.io/latest/docs/ops/deployment/requirements/).
  - 파드 레이블 추가 (권장): `app`, `version`  
    - `app` (필수) : 분산 트레이싱에서 애플리케이션을 식별할 수 있도록 추가합니다  
    - `version` (옵션) : 애플리케이션 버전을 식별할 수 있도록 추가합니다  

    ![스크린샷 2023-01-26 오후 1.26.18.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.26.18.png)

*Call graph*
```bash
## webapp 으로 요청을 발생시켜 봅시다
for in in {1..20}; do curl http://localhost/api/catalog -H \
"Host: webapp.istioinaction.io"; sleep .5; done

## fortio로 유입시켜도 좋습니다  
# fortio load -H "Host: webapp.istioinaction.io" -quiet -jitter -t 60s -c 1 -qps 1 http://localhost/api/catalog 
```

👉🏻 대시보드에서 `Graph` 메뉴를 클릭해 보세요  
![스크린샷 2023-01-26 오후 1.27.09.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.27.09.png)
<img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.28.11.png" width=110 />

Call graph 를 통해 확인할 수 있는 정보들    
- 트래픽 플로우 
- 요청수, 바이트수 ...
- 버전별 트래픽 플로우 
- 쓰루풋 (RPS), 버전별 트래픽 비중
- 트래픽 기반으로 앱 상태 확인
- HTTP/TCP 트래픽 상태 (응답코드, 응답속도, ...)
- 네트웍 실패 감지    
<br />

👉🏻 에러 발생 시에는 문제가 있는 부분을 표시해 줍니다 (네트웍 실패감지)
![스크린샷 2023-01-26 오후 1.57.17.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.57.17.png)


**트레이스, 메트릭, 로깅 연관성 (Correlation)**

Kiali는 Observability 관점에서 대응할 수 있는 “통합 대시보드”로 진화하고 있습니다  
트레이스, 메트릭, 로깅을 연관지어 제공하는 기능 역시 그런 맥락입니다

👉🏻 Telemetry 데이터 간의 연관성을 보고싶다면 `Workloads` 메뉴에서 조회하고자 하는 워크로드를 선택합니다  
![스크린샷 2023-01-29 오전 9.12.47.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_9.12.47.png)

워크로드의 서브탭 별로 다음과 같은 정보를 제공합니다
- Overview — 서비스 파드들, Istio 설정, Call graph
- Traffic — 인바운드/아웃바운드 트래픽 성공률
- Logs — 앱로그, Envoy 액세스 로그, Span 정보를 함께 제공 
- Inbound Metrics and Outbound Metrics — Span 과 연관시켜 제공
- Traces — 트레이스 리포트 (by Jaeger)
- Envoy — Envoy 설정 (Clusters, Listeners, Routes ..)

Correlation 제공으로 (연관된 지표들을 한 곳에 모아줌으로써) 디버깅이 매우 간단해 집니다.  
여러 윈도우를 스위치 해가며 볼 필요도 없고 시점 기준으로 여러 그래프를 비교할 필요도 없습니다. 

> *예를 들어 대시보드 상에서 request spike 가 발생하면 관련하여 새로운 버전 혹은 degraded 서비스로 부터 요청이 처리되었다는 “traces”를 바로 확인할 수 있습니다.* 

<br />

*Kiali는 Istio 리소스에 대한 Validation 을 제공합니다*

- 존재하지 않는 Gateway 를 가리키는 VirtualService
- 존재하지 않는 목적지에 대한 라우팅 정보
- 동일한 호스트에 대한 하나 이상의 VirtualService
- DestinationRule 에서 Service subsets 을 찾을 수 없음
- [더 많은 정보를 원하시면 클릭](https://kiali.io/docs/features/validations/){:target="_blank"}

## 8.3.2 결론

- Grafana — 프로메테우스 메트릭을 기반으로 시각화를 제공합니다
- Jeager — Call Graph 의 레이턴시를 이해하는 분산 트레이싱을 제공합니다
    - 관련 요청의 메타데이터에 어노테이션 합니다
    - 메타데이터를 감지하여 Span 정보를 트레이싱 엔진에 전송합니다
- Kiali — 트래픽 흐름을 Call Graph 로 표현하고 상세한 구성 정보를 제공합니다

## 요약 

- Grafana — Istio control/data plane 메트릭 대시보드 제공
- 분산 트레이싱 (Jaeger) — 서비스 요청에 대한 인사이트 제공 (요청 어노테이션)  
  *간트 차트와 비슷하다 (위 - Gantt chart / 아래 - Traces)*  
  <img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.05.43.png" width=350 />  
  <img src="/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.06.42.png" width=350 />

- 어플리케이션 — “트레이스 헤더” 전파. 요청 흐름의 전체 view 확보
- 트레이스 — Span 집합. 분산 환경에서 요청을 처리하는 단계별 홉과 레이턴시 디버깅 제공
- 트레이스 헤더 설정
    - global 설정 — `defaultConfig`  (from Istio installation)
    - 워크로드 단위 설정 — `proxy.istio.io/config`  (from annotation)
- Kiali Operator 설정
    - 메트릭 — Prometheus 연동 설정
    - 트레이스 — Jaeger 연동 설정
- Kiali — *Istio-Specific* 대시보드 지원
    - Call Graph  
        ![스크린샷 2023-01-29 오후 2.24.08.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.08.png)
        
    - Metric Correlation  
        ![스크린샷 2023-01-29 오후 2.24.36.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.36.png)