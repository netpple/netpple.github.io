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

> Span은 "이름", "시작시간", "기간"을 가지고 있는 작업의 논리적인 단위를 나타냅니다.   
> Span은 인과적인 관계를 모델링하기 위해 "중첩"과 "정렬"을 사용합니다.  
> 
> ![스크린샷 2023-01-29 오후 1.00.46.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.00.46.png)
> 

*참고로 … span 은 건축에서는 교량을 **지지하는 단위 구간**을 의미합니다*

<img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.59.11.png" width=301 />
<br/><br/>

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
>     <img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.52.10.png" width="180" />
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

![스크린샷 2023-01-25 오전 8.05.46.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.05.46.png)

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
<omit> Working on configmap prometheus/istio-dashboards
<omit> File in configmap istio-extension-dashboard.json ADDED
<omit> File in configmap istio-mesh-dashboard.json ADDED
<omit> File in configmap istio-performance-dashboard.json ADDED
<omit> File in configmap istio-service-dashboard.json ADDED
<omit> File in configmap istio-workload-dashboard.json ADDED
<omit> File in configmap pilot-dashboard.json ADDED
```

<img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.26.05.png" width=70 /> 클릭

![스크린샷 2023-01-25 오전 8.25.43.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_8.25.43.png)

### 8.1.2 컨트롤 플레인 메트릭

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

### 8.1.3 데이터플레인 메트릭  

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



## 8.2 Distributed tracing

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
> <img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.16.31.png" width=200 />
> 

### 8.2.1 분산트레이싱의 동작 방식

*Span 과 Trace context ⇒ Trace*
- 해당 서비스에서 Span 생성
- 트레이싱엔진으로 Span 전송
- 다른 서비스로 Trace context 전파
- Trace 기록 ~ 서비스 간의 인과성 추적
- Span ID, Trace ID ~ 서비스 간 연계 및 추적 

![스크린샷 2023-01-25 오후 12.43.37.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.43.37.png)

*Istio 는 분산 트레이싱 엔진으로의 "Span 전송"을 핸들링 합니다* 

Zipkin 트레이싱 헤더
- x-request-id
- x-b3-traceid
- x-b3-spanid
- x-b3-parentspanid
- x-b3-sampled
- x-b3-flags
- x-ot-span-context

![스크린샷 2023-01-25 오후 1.09.05.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.09.05.png)

### 8.2.2 분산 트레이싱 시스템 설치

*Jaeger 설치가 다소 복잡해서 그냥 Istio 샘플 addon을 쓰겠습니다*

```bash
cd istio-1.16.1

kubectl apply -f samples/addons/jaeger.yaml
```
```bash
## 설치 확인
kubectl get po,svc -n istio-system -o name
```

### 8.2.3 Istio 분산 트레이싱 설정

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

### 8.2.4 분산 트레이싱 대시보드 - JAEGER UI

*JAEGER UI 접속*

```bash
istioctl dashboard jaeger --browser=false
```
[http://localhost:16686](http://localhost:16686)

<img src="" />

*요청 유입 및 모니터링*

```bash
for in in {1..10}; do \
  curl -H "Host: webapp.istioinaction.io" localhost/api/catalog;
done
```


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

![스크린샷 2023-01-25 오후 7.12.23.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.12.23.png)

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

![스크린샷 2023-01-25 오후 7.18.57.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.18.57.png)

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

![webapp span  안나옴 ( 존재하지 않는 collectorEndpoint 로 수정했기 때문 )](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.40.46.png)

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

![webapp span 확인됨 ](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-25_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_7.47.40.png)

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

![Applications 로 조회 - prometheus 는 “2”](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.54.07.png)

Applications 로 조회 - prometheus 는 “2”

![Workload 로 조회 - prometheus 는 “3”](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.58.09.png)

Workload 로 조회 - prometheus 는 “3”

**Application vs Workload**

- default, ingress ~ apps는 N/A, workloads는 1
- prometheus  apps는 2, workloads는 3
- Q) 왜 prom-grafana 는 app 이 없다고 할까?

  <img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_10.33.14.png" width=240 />
    
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

    ![스크린샷 2023-01-26 오후 1.26.18.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.26.18.png)

<br />
호출 테스트  
```bash
for in in {1..20}; do curl http://localhost/api/catalog -H \
"Host: webapp.istioinaction.io"; sleep .5s; done
```

*호출 후 Call graph 를 확인해 보세요*
![스크린샷 2023-01-26 오후 1.27.09.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.27.09.png)
<img src="/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.28.11.png" width=110 />

*From the graph …*

- Traversal and flow of traffic
- Number of bytes, requests, ..
- Multiple traffic flows for multiple versions
- RPS (Requests Per Second); % of total traffic for multiple versions
- Application health based on network traffic
- HTTP/TCP traffic
- Networking failures, which can be quickly identified
    
    ![스크린샷 2023-01-26 오후 1.57.17.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-26_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_1.57.17.png)
    

**CORRELATION OF TRACES, METRICS, AND LOGS**

Kiali is gradually evolving into the one dashboard that answers all service mesh observability questions.

*Kiali는 모든 서비스 메시의 observability 질문에 응답하는 “하나의 대시보드”로 계속해서 진화중임.*

One of the Kiali features — **correlating traces, metrics, and logs** — is just a promise of the possibilities to come.

To view the correlation between telemetry data, drill into one of the workloads by clicking the **Workloads menu item** at left in the overview dashboard in figure 8.13, and then **select a workload** from the list. The menu items in the Workload view reveal the following (see, for example, figure 8.16):

![스크린샷 2023-01-29 오전 9.12.47.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_9.12.47.png)

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
  *how ? “annotate requests”*       
  *간트 차트와 비슷하다*  
  ![스크린샷 2023-01-29 오후 2.05.43.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.05.43.png)
  ![스크린샷 2023-01-29 오후 2.06.42.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.06.42.png)

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
        
        ![스크린샷 2023-01-29 오후 2.24.08.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.08.png)
        
    - metric correlation
        
        ![스크린샷 2023-01-29 오후 2.24.36.png](/assets/img/Istio-ch8-observability-2-visibility/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-29_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.24.36.png)