---
title: Istio Securing (5)  
version: v1.0  
description: istio in action 9장  
date: 2023-04-28 19:00:00 +09:00  
categories: network
badges:
- type: info  
  tag: 교육  
  rightpanel: true
---

지금까지 Istio 에서 제공하는 인증과 인가에 대해서 살펴보았습니다 Istio 는 Envoy 의 기본 RBAC 기능들을 사용하여 인가를 구축하고 있는데요. 이번 장에서는 인가 / 권한에 대해 커스텀 메커니즘을 적용하는 방법에 대해서 살펴 보겠습니다. 

<!--more-->

# 9.5 Integrating with custom external authorization services
Istio 의 서비스 프록시가 요청을 허용할지를 결정하기 위해 다른 인가 서비스를 호출하도록 설정할 수 있습니다

아래 그림에서는 요청 인입 시 Envoy 프록시에서 외부의 인가서버 (Authorization server) 를 호출하여 요청을 허용 (Allow) /거부 (reject) 할 지를 확인합니다.  
![external_authz_server.png](/assets/img/Istio-ch9-securing-5-external_authz/external_authz_server.png)

“커스텀 인가”를 적용하려면 AuthorizationPolicy 에서 action 을 `CUSTOM` 으로 설정하면 됩니다

다음 실습을 통해서 외부 인가를 통한 요청 허용을 확인해 봅시다 

## 9.5.1 Hands-on with external authorization

실습 환경 초기화

```bash
kubectl delete ns istioinaction

kubectl delete authorizationpolicy,peerauthentication,requestauthentication --all -n istio-system

kubectl delete deploy/sleep -n default
```

실습 환경 설정

```bash
kubectl create ns istioinaction 

## istio proxy가 sidecar로 injection 되도록 네임스페이스 레이블 설정
kubectl label namespace istioinaction istio-injection=enabled

## catalog와 webapp 배포
kubectl apply -f services/catalog/kubernetes/catalog.yaml -n istioinaction
kubectl apply -f services/webapp/kubernetes/webapp.yaml -n istioinaction

## webapp과 catalog의 gateway, virtualservice 설정
kubectl apply -f services/webapp/istio/webapp-catalog-gw-vs.yaml -n istioinaction

## default 네임스페이스에 sleep 앱 배포
kubectl apply -f ch9/sleep.yaml -n default
```

```bash
## 인가 서버 기동
kubectl apply -f istio-1.17.2/samples/extauthz/ext-authz.yaml -n istioinaction
```

```bash
kubectl get po -n istioinaction

kubectl get svc -n istioinaction
```

## 9.5.2 Configuring Istio for ExtAuthz

인가 서버 엔드포인트 설정 

```bash
kubectl edit -n istio-system cm istio
```

```yaml
extensionProviders:
- name: "sample-ext-authz-http"
  envoyExtAuthzHttp:
    service: "ext-authz.istioinaction.svc.cluster.local"
    port: "8000"
    includeRequestHeadersInCheck: ["x-ext-authz"]
```

- includeHeadersInCheck (DEPRECATED)

(참고) 아래와 같이 IstioOperator CR로 적용할 수 있음. 

```bash
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    extensionProviders:
    - name: "sample-ext-authz-http"
      envoyExtAuthzHttp:
        service: "ext-authz.istioinaction.svc.cluster.local"
        port: "8000"
        includeRequestHeadersInCheck: ["x-ext-authz"]
```

```bash
istioctl install -y -f ext_authz_meshconfig.yaml
```

(주의) 주의할 사항은 extensionProviders 통째로 기존 설정을 덮어 쓰기 때문에, 기존 설정이 있을 경우 포함시켜 주어야 합니다 

```bash
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  meshConfig:
    extensionProviders:
    - name: "sample-ext-authz-http"
      envoyExtAuthzHttp:
        service: "ext-authz.istioinaction.svc.cluster.local"
        port: "8000"
        includeRequestHeadersInCheck: ["x-ext-authz"]
########## 기존 프로바이더 설정 유지 ####################
    - envoyOtelAls:
        port: 4317
        service: opentelemetry-collector.istio-system.svc.cluster.local
      name: otel
    - name: skywalking
      skywalking:
        port: 11800
        service: tracing.istio-system.svc.cluster.local
```

## 9.5.3 Using a custom AuthorizationPolicy resource

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istioinaction
spec:
  selector:
    matchLabels:
      app: webapp
  action: CUSTOM    # ❶ Uses a custom action
  provider:
    name: sample-ext-authz-http  # ❷ MUST match the meshconfig name
  rules:
  - to:
    - operation:
        paths: ["/"]  # ❸ Path on which to apply authz
```

```bash
## 헤더 없이 호출
kubectl -n default exec -it deploy/sleep -- \
  curl webapp.istioinaction/api/catalog

# denied by ext_authz for not found header `x-ext-authz: allow` in the request
```

- “RBAC: access denied” 가 리턴될 경우 MeshConfig (`istio` configmap) 설정 확인

```bash
## 헤더 적용 호출
kubectl -n default exec -it deploy/sleep -- \
  curl -H "x-ext-authz: allow" webapp.istioinaction/api/catalog
```

### FAQ

> istiod-64848b6c78-c8tr2 discovery 2023-04-27T23:42:27.706471Z	error	authorization	Processed authorization policy: failed to process CUSTOM action: available providers are [] but found "sample-ext-authz-http”
> 

Solved)

```bash
## extensionProviders 을 확인합니다 (두 개가 있다거나, 오타 여부 등)
kubectl edit cm istio -n istio-system

..
    extensionProviders
    - name: "sample-ext-authz-http"
      envoyExtAuthzHttp:
        service: "ext-authz.foo.svc.cluster.local"
        port: "8000"
        includeRequestHeadersInCheck: ["x-ext-authz"]
..
    extensionProviders  # <-- 이렇게 기존 설정이 이미 있으면 하위에 추가해야 합니다 
    - envoyOtelAls:
        port: 4317
        service: opentelemetry-collector.istio-system.svc.cluster.local
      name: otel
    - name: skywalking
      skywalking:
        port: 11800
        service: tracing.istio-system.svc.cluster.local

```

# Summary

- PeerAuthentication
    - Peer-to-Peer authentication
    - Strict Authentication ~ Traffic encryption, 감청(eavesdropped) 방지
- PERMISSIVE ~ accept both encrypted traffic and clear-text traffic
- AuthorizationPolicy
    - Service-to-Service authorization
    - End-user authorization
    - extract metadata from
        - workload identity certificate
        - end-user JWT
    - authorize requests based on the set of metadata
- RequestAuthentication
    - End-user authentication
    - JWT
- External Authorization
    - using CUSTOM action of AuthorizationPolicy
    - append external authorizer to extensionProviders in MeshConfig