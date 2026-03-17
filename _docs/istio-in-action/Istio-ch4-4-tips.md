---
title: Istio Ingress Gateway (4)  
version: v1.0  
description: istio in action 4장 실습4  
date: 2023-01-01 09:00:00 +09:00  
layout: page  
toc: 6  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
histories:
- date: 2023-01-01 09:00:00 +09:00
  description: 최초 등록
---

Split gateways, Gateway injection, Ingress GW 로깅, Gateway configuration 등 운영팁들을 살펴봅니다.

<!--more-->

# Operational tips

## Split gateway responsibilities

- 다같이 쓰는 것들은 아무래도 부담 스럽죠
- 팀별로 전용 gateway를 구성해 봅시다
- istioinaction 네임스페이스에 전용 gateway를 띄워봅니다

IstioOperator 명세 - [*ch4/my-user-gateway.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/my-user-gateway.yaml)

- istioctl 이 명세를 바탕으로 K8s 명세를 generate 함.
- 아래 명세는 실습을 위해 31400 포트만 오픈하도록 명세를 수정함. (-edited.yaml)
- 참고) [istio operater controller](https://tetrate.io/blog/what-is-istio-operator/)를 설치하여 관리하는 방법도 있음
- 참고) [IstioOperator options](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)

```yaml
# vi ch4/my-user-gateway-edited.yaml

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: my-user-gateway-install
  namespace: istioinaction
spec:
  profile: empty
  values:
    gateways:
      istio-ingressgateway:
        autoscaleEnabled: false
  components:
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
    - name: my-user-gateway
      namespace: istioinaction
      enabled: true
      label:
        istio: my-user-gateway
      k8s:
        service:
          ports:
            - name: tcp  # my-user-gateway 에서 사용할 포트 설정
              port: 31400
              targetPort: 31400
```
* 원본 명세를 일부 수정하였습니다. ch4/my-user-gateway-edited.yaml 로 저장해 주세요  

Ingress gateway 명세 출력 - [참고](https://istio.io/latest/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

```bash
# istioctl manifest generate -n istioinaction -f ch4/my-user-gateway-edited.yaml
```

Ingress gateway  설치

```bash
istioctl install -y -n istioinaction -f ch4/my-user-gateway-edited.yaml

✔ Ingress gateways installed
✔ Installation complete
Thank you for installing Istio 1.16.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/99uiMML96AmsXY5d6
```

```bash
kubectl get istiooperators.install.istio.io -A

NAMESPACE       NAME                                      REVISION   STATUS   AGE
istio-system    installed-state                                               17h
istioinaction   installed-state-my-user-gateway-install                       28m
```

설치 확인

```bash
kubectl get deploy my-user-gateway

NAME              READY   UP-TO-DATE   AVAILABLE   AGE
my-user-gateway   1/1     1            1           19m
```

포트 확인

```bash
kubectl get svc my-user-gateway -n istioinaction

NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)
my-user-gateway        LoadBalancer   10.96.169.79     127.0.0.1     31400:30813/TCP
```

**실습. my-user-gateway를 경유하여 TCP 통신을 해봅시다**    

Gateway 명세
- ch4/gateway-tcp.yaml 명세를 수정합니다 (ch4/gateway-tcp-edited.yaml)
- istio: my-user-gateway 를 selector에 설정합니다 

```yaml 
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: echo-tcp-gateway
spec:
  selector:
    istio: my-user-gateway  # 새로운 gateway를 바라보도록 수정합니다
  servers:
  - port:
      number: 31400
      name: tcp-echo
      protocol: TCP
    hosts:
    - "*"
```

```bash
kubectl apply -f ch4/gateway-tcp-edited.yaml -n istioinaction
```

VirtualService 명세
```bash
kubectl apply -f ch4/echo-vs.yaml -n istioinaction
```

앱 배포
```bash
kubectl apply -f ch4/echo.yaml -n istioinaction
```

맥(로컬) 연결 설정 - “minikube service 포트”를 기억해 두세요 (사용자 환경마다 다름)
```bash
minikube service my-user-gateway -n istioinaction

|---------------|-----------------|-------------|---------------------------|
|   NAMESPACE   |      NAME       | TARGET PORT |            URL            |
|---------------|-----------------|-------------|---------------------------|
| istioinaction | my-user-gateway | tcp/31400   | http://192.168.49.2:30813 |
|---------------|-----------------|-------------|---------------------------|
🏃  my-user-gateway 서비스의 터널을 시작하는 중
|---------------|-----------------|-------------|------------------------|
|   NAMESPACE   |      NAME       | TARGET PORT |          URL           |
|---------------|-----------------|-------------|------------------------|
| istioinaction | my-user-gateway |             | http://127.0.0.1:56002 |
|---------------|-----------------|-------------|------------------------|
```

호출 테스트
```bash 
telnet localhost 56002

Trying ::1...
Connected to localhost.
Escape character is '^]'.
..
Service default.
hello Sam    # <-- type here
hello Sam    # <-- echo here
```

## Gateway Injection

- IstioOperator : istio 관련하여 사용자에게 너무 많은 권한이 노출됨
- gw injection 은 “stubbed-out”, 일부 설정만 노출하고 나머지는 istio가 처리함 (annotations)

명세 [my-user-gw-injection.yaml](https://github.com/istioinaction/book-source-code/blob/master/ch4/my-user-gw-injection.yaml)

```yaml
# vi ch4/my-user-gw-injection.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-user-gateway-injected
  namespace: istioinaction
spec:
  selector:
    matchLabels:
      ingress: my-user-gateway-injected
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
        inject.istio.io/templates: gateway
      labels:
        ingress: my-user-gateway-injected
    spec:
      containers:
      - name: istio-proxy
        image: auto   # <-- stubbed-out image
---
apiVersion: v1
kind: Service
metadata:
  name: my-user-gateway-injected
  namespace: istioinaction
spec:
  type: LoadBalancer
  selector:
    ingress: my-user-gateway-injected
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-user-gateway-injected-sds
  namespace: istioinaction
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-user-gateway-injected-sds
  namespace: istioinaction
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: my-user-gateway-injected-sds
subjects:
- kind: ServiceAccount
  name: default
```

명세 적용

```bash
kubectl apply -f ch4/my-user-gw-injection.yaml
```

확인

```bash
kubectl get deploy my-user-gateway-injected

kubectl get svc my-user-gateway-injected
```

## Ingress gateway access logs

- demo 설치 시 (--profile demo) 액세스 로깅은 표준출력 임
- production 설치 시 (--profile default) 액세스 로깅은 disabled 임
- 로그 부담을 최소화 해야 하고
- 꼭 필요한 로그 선별 필요

로그 조회 (표준출력, demo)

```bash
kubectl logs -f deploy/istio-ingressgateway -n istio-system
```

로그 출력 설정

```bash
istioctl install --set meshConfig.accessLogFile=/dev/stdout
```

Telemetry API - 원하는 로그만 선별하자

```yaml
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: ingress-gateway
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  accessLogging:
  - providers:
    - name: envoy
    disabled: false
```

## Reducing gateway configuration

- stubbed-out ⇒ 일부 명세만 작성하면 나머지는 Istio에서 해줌
- configuration trimming ⇒ 필요한 설정만 남김 (Istio에서 최적화)
- 예) PILOT_FILTER_GATEWAY_CLUSTER_CONFIG

```yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: control-plane
spec:
  profile: minimal
  components:
    pilot:
      k8s:
        env:
        - name: PILOT_FILTER_GATEWAY_CLUSTER_CONFIG
          value: "true"
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_DNS_CAPTURE: "true"
    enablePrometheusMerge: true
```

> *The important part of this configuration is the PILOT_FILTER_GATEWAY_CLUSTER_ CONFIG feature flag. It trims down the clusters in the gateway’s proxy configuration to only those that are actually referenced in a VirtualService that applies to the particular gateway. (Istio IN ACTION, 2022)*
>