---
redirect_to: /docs/istio-in-action/Istio-ch3-envoy
title: Envoy 실습  
version: v1.0  
description: istio in action 3장 실습  
date: 2022-12-20 18:00:00 +09:00  
hidden: true  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: false  
---

<meta http-equiv="refresh" content="0; url={{ page.redirect_to }}">

Istio의 핵심 컴포넌트, Envoy proxy를 실습을 통해 이해하는 시간을 가져봅니다.

<!--more-->

## 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 챕터3

## 실습

### 실습1. Envoy proxy 실행

envoy 및 앱(이하, httpbin), curl 다운로드

```bash
docker pull envoyproxy/envoy:v1.19.0
docker pull curlimages/curl
docker pull citizenstig/httpbin
```

httpbin 기동

```bash
docker run -d --name httpbin citizenstig/httpbin
```

curl 로 httpbin 확인

```bash
docker run -it --rm --link httpbin curlimages/curl \
curl -X GET http://httpbin:8000/headers
```

Envoy 설정

```yaml
# vi ch3/simple.yaml

admin:
  address:
    socket_address: { address: 0.0.0.0, port_value: 15000 }

static_resources:
  listeners:
  - name: httpbin-demo
    address:
      socket_address: { address: 0.0.0.0, port_value: 15001 }
    filter_chains:
    - filters:
      - name:  envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: httpbin_local_route
            virtual_hosts:
            - name: httpbin_local_service
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route:
                  auto_host_rewrite: true
                  cluster: httpbin_service
  clusters:
    - name: httpbin_service
      connect_timeout: 5s
      type: LOGICAL_DNS
      dns_lookup_family: V4_ONLY
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: httpbin
        endpoints:
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: httpbin
                  port_value: 8000
```

Envoy 기동 

```bash
docker run --name proxy --link httpbin envoyproxy/envoy:v1.19.0 \
--config-yaml "$(cat ch3/simple.yaml)"
```

curl 로 Envoy 호출 확인

```bash
docker run -it --rm --link proxy curlimages/curl \
curl -X GET http://proxy:8000/headers
```

Envoy 중지

```bash
docker rm -f proxy
```

### 실습2. Envoy proxy 타임아웃 설정

simple.yaml 에서 타임아웃만 1초로 변경해 봅니다.

```yaml
# vi ch3/simple_change_timeout.yaml

admin:
  address:
    socket_address: { address: 0.0.0.0, port_value: 15000 }

static_resources:
  listeners:
  - name: httpbin-demo
    address:
      socket_address: { address: 0.0.0.0, port_value: 15001 }
    filter_chains:
    - filters:
      - name:  envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: httpbin_local_route
            virtual_hosts:
            - name: httpbin_local_service
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route:
                  auto_host_rewrite: true
                  cluster: httpbin_service
                  timeout: 1s
  clusters:
    - name: httpbin_service
      connect_timeout: 5s
      type: LOGICAL_DNS
      dns_lookup_family: V4_ONLY
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: httpbin
        endpoints:
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: httpbin
                  port_value: 8000
```

Envoy 기동

```bash
docker run --name proxy --link httpbin envoyproxy/envoy:v1.19.0 \
--config-yaml "$(cat ch3/simple_change_timeout.yaml)"
```

curl로 Envoy 호출 (타임아웃 설정 변경 확인)

```bash
docker run -it --rm --link proxy curlimages/curl \
curl -X GET http://proxy:15001/headers
```

### 실습3 Envoy Admin API

admin API로 Envoy stat 확인

```bash
docker run -it --rm --link proxy curlimages/curl \
curl -X GET http://proxy:15000/stats | grep retry
```

retry 설정 수정

```yaml
# vi ch3/simple_retry.yaml

admin:
  address:
    socket_address: { address: 0.0.0.0, port_value: 15000 }

static_resources:
  listeners:
  - name: httpbin-demo
    address:
      socket_address: { address: 0.0.0.0, port_value: 15001 }
    filter_chains:
    - filters:
      - name:  envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          http_filters:
          - name: envoy.filters.http.router
          route_config:
            name: httpbin_local_route
            virtual_hosts:
            - name: httpbin_local_service
              domains: ["*"]
              routes:
              - match: { prefix: "/" }
                route:
                  auto_host_rewrite: true
                  cluster: httpbin_service
                  retry_policy:
                      retry_on: 5xx
                      num_retries: 3
  clusters:
    - name: httpbin_service
      connect_timeout: 5s
      type: LOGICAL_DNS
      dns_lookup_family: V4_ONLY
      lb_policy: ROUND_ROBIN
      load_assignment:
        cluster_name: httpbin
        endpoints:
        - lb_endpoints:
          - endpoint:
              address:
                socket_address:
                  address: httpbin
                  port_value: 8000
```

Envoy 재기동 (retry 설정적용)

```bash
docker rm -f proxy

docker run --name proxy --link httpbin envoyproxy/envoy:v1.19.0 \
--config-yaml "$(cat ch3/simple_retry.yaml)"
```

설정 적용 확인

```bash
docker run -it --rm --link proxy curlimages/curl \
curl -X GET http://proxy:15000/stats | grep retry
```