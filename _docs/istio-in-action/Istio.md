---
title: Istio Sidecar Proxy
version: v1.0
description: 실습으로 istio sidecar proxy 이해하기
date: 2022-12-16 10:00:00 +09:00
toc: 2
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info
  tag: 교육
histories:
- date: 2022-12-16 10:00:00 +09:00 
  description: 최초 등록
---
istio sidecar proxy를 구성하여 resiliency, traffic routing 등을 실습으로 확인해 봅시다 

<!--more-->
## 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 챕터2

## Istio Sidecar Proxy 적용하기

### Prerequisite

catalog YAML (웹API)

```yaml
# vi services/catalog/kubernetes/catalog.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: catalog
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: catalog
  name: catalog
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app: catalog
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: catalog
    version: v1
  name: catalog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog
      version: v1
  template:
    metadata:
      labels:
        app: catalog
        version: v1
    spec:
      serviceAccountName: catalog
      containers:
      - env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        image: istioinaction/catalog:latest
        imagePullPolicy: IfNotPresent
        name: catalog
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        securityContext:
          privileged: false
```

webapp YAML (catalog api를 호출하는 앱)

```yaml
# vi services/webapp/kubernetes/webapp.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: webapp
  name: webapp
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: webapp
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
      labels:
        app: webapp
    spec:
      serviceAccountName: webapp
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

### 네임스페이스 생성

```yaml
kubectl create ns istioinaction
```

### 사이드카 프록시 인젝션

- (방법1) istioctl kube-inject
    
    istioctl 커맨드로 준비된 yaml에 sidecar 설정을 주입하는 방법
    
    ```bash
    istioctl kube-inject -f services/catalog/kubernetes/catalog.yaml
    ```
    
- (방법2) namespace labeling (recommend)
    
    namespace에 레이블을 추가하면 **istiod (오퍼레이터)**가 해당 namepsace의  pod spec에 자동으로 sidecar 설정을 주입
    
    ```bash
    kubectl label namespace istioinaction istio-injection=enabled
    ```
    

### YAML 적용

```bash
kubectl apply -f services/catalog/kubernetes/catalog.yaml
kubectl apply -f services/webapp/kubernetes/webapp.yaml
```

### 호출 테스트

```bash
## catalog 확인
kubectl run -i -n default --rm --restart=Never dummy \ 
--image=curlimages/curl --command -- \
sh -c 'curl -s http://catalog.istioinaction/items/1'

## webapp 확인
kubectl run -i -n default --rm --restart=Never dummy \
--image=curlimages/curl --command -- \
sh -c 'curl -s http://webapp.istioinaction/api/catalog/items/1'
```

### (기타) minikube proxy

* minikube 사용 시 로컬에서 K8s 서비스 접근을 위한 프록시를 띄워서 쉽게 활용할 수 있습니다.

```bash
# minikube service -n istio-system --all
|--------------|----------------------|-------------|------------------------|
|  NAMESPACE   |         NAME         | TARGET PORT |          URL           |
|--------------|----------------------|-------------|------------------------|
| istio-system | grafana              |             | http://127.0.0.1:50717 |
| istio-system | istio-egressgateway  |             | http://127.0.0.1:50719 |
|              |                      |             | http://127.0.0.1:50720 |
| istio-system | istio-ingressgateway |             | http://127.0.0.1:50722 |
|              |                      |             | http://127.0.0.1:50723 |
|              |                      |             | http://127.0.0.1:50724 |
|              |                      |             | http://127.0.0.1:50725 |
|              |                      |             | http://127.0.0.1:50726 |
| istio-system | istiod               |             | http://127.0.0.1:50728 |
|              |                      |             | http://127.0.0.1:50729 |
|              |                      |             | http://127.0.0.1:50730 |
|              |                      |             | http://127.0.0.1:50731 |
| istio-system | jaeger-collector     |             | http://127.0.0.1:50733 |
|              |                      |             | http://127.0.0.1:50734 |
|              |                      |             | http://127.0.0.1:50735 |
| istio-system | kiali                |             | http://127.0.0.1:50737 |
|              |                      |             | http://127.0.0.1:50738 |
| istio-system | prometheus           |             | http://127.0.0.1:50740 |
| istio-system | tracing              |             | http://127.0.0.1:50742 |
|              |                      |             | http://127.0.0.1:50743 |
| istio-system | zipkin               |             | http://127.0.0.1:50745 |
|--------------|----------------------|-------------|------------------------|

# minikube service -n istioinaction --all
|---------------|---------|-------------|------------------------|
|   NAMESPACE   |  NAME   | TARGET PORT |          URL           |
|---------------|---------|-------------|------------------------|
| istioinaction | catalog |             | http://127.0.0.1:50868 |
| istioinaction | webapp  |             | http://127.0.0.1:50870 |
|---------------|---------|-------------|------------------------|
```

### 아래 실습 시 사용할 호출 스크립트

```bash
## webapp 호출
while true; do curl http://localhost:50870/api/catalog; sleep .5; done
```

* localhost:50870  각 자 로컬환경 마다 포트번호는 다릅니다.

## Resiliency

> 탄력성/회복력.  network 등 다양한 문제 상황에 대해 탄력적인 대응책을 제공
예) retries, timeouts, circuit breakers, …
(실습1) 에러 발생 시 retry 하도록 해본다
> 

❊ 아래 실습에서 catalog에 의도적으로 500에러를 재현하고 이를 retry로 극복

### Prerequisite

p.47 - catalog 의 “500”에러 비율 제어  스크립트
용법) [chaos.sh](http://chaos.sh) {에러코드} {빈도} - chaos.sh 500 50 (500에러를 50% 빈도로 재현)

```bash
# vi bin/chaos.sh

if [ $1 == "500" ]; then

    POD=$(kubectl get pod | grep catalog | awk '{ print $1 }')
    echo $POD

    for p in $POD; do
        if [ ${2:-"false"} == "delete" ]; then
            echo "Deleting 500 rule from $p"
            kubectl exec -c catalog -it $p -- curl  -X POST -H "Content-Type: application/json" -d '{"active":
        false,  "type": "500"}' localhost:3000/blowup
        else
            PERCENTAGE=${2:-100}
            kubectl exec -c catalog -it $p -- curl  -X POST -H "Content-Type: application/json" -d '{"active":
            true,  "type": "500",  "percentage": '"${PERCENTAGE}"'}' localhost:3000/blowup
            echo ""
        fi
    done

fi
```

### 500에러 비율 적용

```bash
## 500에러(50% 빈도)
# bin/chaos.sh 500 50
```

지정한 비율(50%)만큼 에러 발생함

![Kiali 대시보드 - red (Error) / blue (total req.)](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-16_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.08.42.png)

Kiali 대시보드 - red (Error) / blue (total req.)

### (실습1) 에러 발생 시 reslience 하게 retry 하도록 해보자

Resiliency 하게 해보자 ⇒ proxy(envoy)에 endpoint(catalog) 5xx 에러 시 retry 적용

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  http:
  - route:
    - destination:
        host: catalog
    retries:
      attempts: 3
      retryOn: 5xx
      perTryTimeout: 2s
```

retries 를 설정 한 후 결과 (대부분 **정상응답으로 리턴**됨)

![스크린샷 2022-12-16 오전 11.22.47.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-16_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.22.47.png)

![**webapp** proxy(envoy) - 의도한 에러 비율(50%)보다 낮음. (이유는 아래 catalog proxy에서 retry)](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-16_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.24.59.png)

**webapp** proxy(envoy) - 의도한 에러 비율(50%)보다 낮음. (이유는 아래 catalog proxy에서 retry)

![**catalog** proxy(envoy) -  5xx에러 발생 시 retry](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-16_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.23.57.png)

**catalog** proxy(envoy) -  5xx에러 발생 시 retry

### 총평

- 애플리케이션 수정없이 retry 로직을 적용하여 에러 상황을 resilience 하게 대응할 수 있음

## Traffic Routing

> 다양한 이유로 트래픽 라우팅이 필요한 경우가 있음.
트래픽 라우팅을 위한 다양한 방법을 제공함.
**(실습1)** catalog v2 버전 배포 시 기존 트래픽(v1)에 영향을 주지 않도록 해본다
**(실습2)** catalog 요청 헤더에 따라서 v2 버전으로 라우팅하는 실습을 해본다
> 

### Prerequisite

```yaml
# vi services/catalog/kubernetes/catalog-deployment-v2.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: catalog
    version: v2
  name: catalog-v2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog
      version: v2
  template:
    metadata:
      labels:
        app: catalog
        version: v2
    spec:
      containers:
      - env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: SHOW_IMAGE
          value: "true"
        image: istioinaction/catalog:latest
        imagePullPolicy: IfNotPresent
        name: catalog
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        securityContext:
          privileged: false
```

### 버전 (V2) 배포

```bash
kubectl apply -f services/catalog/kubernetes/catalog-deployment-v2.yaml
```

- 트래픽이 v1, v2 로 나뉘어 들어옴
- Service 레이블 (app=catalog)이 일치하므로 Endpoint 로 랜덤 프록시됨

### (실습1) V1 만 받고 싶다

> 신규 버전(V2) 으로 트래픽을 차단하고 싶다
> 

**DestinationRule** - destination을  v1과 v2 subset으로 구분

```yaml
#vi ch2/catalog-destinationrule.yaml

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog
  subsets:
  - name: version-v1
    labels:
      version: v1
  - name: version-v2
    labels:
      version: v2
```

**VirtualService** - 트래픽을 v1 (subset)으로만 유입

```yaml
# vi ch2/catalog-virtualservice-all-v1.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

### (실습2) 특정 조건 매칭 시 V2로 받고 싶다

> 요청 헤더에 특정 값이 매칭되는 경우에 v2 로 트래픽을 보내도록 할 수 있습니다.
> 

**VirtualService** - 매칭 룰 추가 

```yaml
# vi ch2/catalog-virtualservice-dark-v2.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  http:
  - match:
    - headers:
        x-dark-launch:
          exact: "v2"
    route:
    - destination:
        host: catalog
        subset: version-v2
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

**호출 테스트** - 헤더 추가

```bash
## webapp 호출
curl http://localhost:50870/api/catalog -H "x-dark-launch: v2"
```

* localhost:50870  각 자 로컬환경 마다 포트번호는 다릅니다.

### 총평

- 트래픽의 route 를 다양하게 제어할 수 있음  ~  신규 배포 시 안심