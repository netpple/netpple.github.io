---
title: Traffic control - Fine-grained traffic routing
version: v1.0  
description: istio in action 5장  
date: 2023-01-07 21:00:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: true  
---
Istio의 traffic control 기법 routing, shifting, mirroring, Outbound traffic controlling 들에 대해 다룹니다.

<!--more-->

## 개요

- 실습 git: [https://github.com/istioinaction/book-source-code](https://github.com/istioinaction/book-source-code)
- 출처 : Istio in Action 챕터5

### 실습환경

실습환경이 준비 안된 분들은 다음 가이드를 참고해주세요. 👉🏻 [실습환경갖추기](/2023/Istio-Environment/)

## 5.1 Reducing the risk of deploying new code

> *most importantly, when we make changes to a service and introduce new versions, how do we safely expose our clients and customers to these changes with minimal disruption and impact?*
> 

### Decoupling deployment and release

- **Why** decoupling ? Reducing the risk of deployments
    - Releasing means bringing live traffic to new deployment in production
    - But, this is **NOT** an `all-or-nothing` proposition. (돌이킬 수 있는 것이 아님)
- **Pros**
    - more **finely control** how and which users are exposed to the new changes
    - **reduce the risk** of bringing new code to production

## 5.2 Routing requests with Istio

### Request level routing

**dark-launch**

- 일부 사용자에게만 새로운 버전을 노출(release) 한다
- header matching for certain user groups

**환경 초기화**

```bash
kubectl delete deployment,svc,gateway,\
virtualservice,destinationrule --all -n istioinaction
```

**catalog v1 배포**  

```bash
kubectl apply -f services/catalog/kubernetes/catalog.yaml \
-n istioinaction
```

catalog service 호출:  *curl → catalog.istioinaction*

```bash
kubectl run -i -n default --rm --restart=Never dummy \
--image=curlimages/curl --command -- \
sh -c 'curl -s http://catalog.istioinaction/items'

[
  {
    "id": 1,
    "color": "amber",
    "department": "Eyewear",
    "name": "Elinor Glasses",
    "price": "282.00"
  },
..
]
```

istio-ingressgateway 호출 (실패)   *Gateway 명세 (outside route) 등록 필요*

```bash
curl -v http://localhost

*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80 (#0)
> GET / HTTP/1.1
> Host: localhost
> User-Agent: curl/7.84.0
> Accept: */*
>
* Recv failure: Connection reset by peer
* Closing connection 0
curl: (56) Recv failure: Connection reset by peer
```

**istio-ingressgateway 에 access 로그 없음*

![스크린샷 2023-01-05 오후 4.15.27.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-05_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_4.15.27.png)

**Gateway 명세 등록**

“catalog.istioinaction.io” 호출 허용

```yaml
# cat ch5/catalog-gateway.yaml

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: catalog-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "catalog.istioinaction.io"
```

```bash
kubectl apply -f ch5/catalog-gateway.yaml -n istioinaction
```

istio-ingressgateway 호출 (실패) ~ *404. VirtualService 명세 (inside route) 필요*

```bash
curl -v -H "Host: catalog.istioinaction.io" http://localhost

*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80 (#0)
> GET / HTTP/1.1
> Host: catalog.istioinaction.io
> User-Agent: curl/7.84.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 404 Not Found
< date: Thu, 05 Jan 2023 06:53:48 GMT
< server: istio-envoy
< content-length: 0
<
* Connection #0 to host localhost left intact
```

**istio-ingressgateway 에 access 로그*

```bash
istio-ingressgateway-.. istio-proxy [2023-01-05T06:53:49.054Z] "GET / HTTP/1.1" 404 NR route_not_found - "-" 0 0 1 - "172.17.0.1" "curl/7.84.0" "6e6ac8e9-2e92-96fb-ad31-635c787f6fc4" "catalog.istioinaction.io" "-" - - 172.17.0.6:8080 172.17.0.1:60544 - -
```

**VirtualService 명세 등록**

```yaml
# cat ch5/catalog-vs.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - catalog-gateway
  http:
  - route:
    - destination:
        host: catalog
```

```bash
kubectl apply -f ch5/catalog-vs.yaml -n istioinaction
```

```bash
curl -v -H "Host: catalog.istioinaction.io" http://localhost
..
< HTTP/1.1 200 OK
..
    <h4>Congrats!</h4>
      <p>
        You're successfully running JSON Server
        <br> ✧*｡٩(ˊᗜˋ*)و✧*｡
      </p>
..

```

```bash
istio-ingressgateway-.. istio-proxy [2023-01-05T07:07:57.886Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 1135 6 6 "172.17.0.1" "curl/7.84.0" "7431ea00-f59c-9e06-8a10-3f7e23703f3e" "catalog.istioinaction.io" "172.17.0.11:3000" outbound|80||catalog.istioinaction.svc.cluster.local 172.17.0.6:47720 172.17.0.6:8080 172.17.0.1:30989 - -
```

** 172.17.0.6:8080 (istio-ingressgateway),  172.17.0.11:3000 (catalog)*

**catalog v2 배포**

catalog v2를 배포해 보자 (service는 v1과 동일).  v2에서는 imageUrl 필드가 추가되었다. 

```bash
kubectl apply -f services/catalog/kubernetes/catalog-deployment-v2.yaml \
-n istioinaction

kubectl get deploy -n istioinaction

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
catalog      1/1     1            1           148m
catalog-v2   1/1     1            1           17s
```

호출테스트 (OK) : **v1과 v2** (has `*imageUrl*`)  **섞여 나옴**

```bash
for in in {1..10}; do curl http://localhost/items \
-H "Host: catalog.istioinaction.io"; printf "\n\n"; done
..
[
  {
    "id": 0,
    "color": "teal",
    "department": "Clothing",
    "name": "Small Metal Shoes",
    "price": "232.00",
    "imageUrl": "http://lorempixel.com/640/480"
  }
]
[
  {
    "id": 0,
    "color": "teal",
    "department": "Clothing",
    "name": "Small Metal Shoes",
    "price": "232.00"
  }
]
..
```

> *새로운 버전(v2)이 배포 되자마자 사용자들에게 노출되는게 부담스럽다.
기존 버전(v1)으로만 요청이 들어오도록 할 수는 없을까?*
> 

(실험1) **모든 catalog 트래픽을 v1 으로만 routing 해보자**

![스크린샷 2023-01-05 오후 5.40.17.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-05_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_5.40.17.png)

catalog v1, v2 모두 공통으로 `app: catalog` 레이블을 가짐

catalog v1의 버전 레이블은 `version : v1` , catalog v2의 버전 레이블은 `version: v2` 임

catalog service 는 `app: catalog` 레이블을 endpoint 로 하므로 v1, v2 모두 해당됨

VirtualService 에서는 route destination 으로 catalog service 가 지정됨

따라서, v1 으로만 라우팅을 하기 위해서는 

- catalog service의 endpoint 구분을 위하여
- 레이블 정보를 제공할 추가적인 명세 (DestinationRule) 작성이 필요하고
- VirtualService 명세 수정이 필요함

예) 레이블로 Pod를 식별해 보자 (아래 두 명령의 결과를 비교해 보세요)

```bash
kubectl get pod -l app=catalog -n istioinaction --show-labels

kubectl get pod -l app=catalog,version=v2 -n istioinaction --show-labels
```

**DestinationRule 등록 (subsets 정의)**  
Pod를 식별할 정보를 추가해 봅니다.

```yaml
# cat ch5/catalog-dest-rule.yaml

apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog.istioinaction.svc.cluster.local
  subsets:
  - name: version-v1
    labels:
      version: v1
  - name: version-v2
    labels:
      version: v2
```

> *VirtualService 와 DestinationRule 의 (service) host ~  “short names” or “FQDN” ?*  
> 둘 다 사용가능 (FQDN 권장)
> 
> Note for Kubernetes users: When short names are used (e.g. “reviews” instead of “reviews.default.svc.cluster.local”), Istio will interpret the short name based on the namespace of the rule, not the service. A rule in the “default” namespace containing a host “reviews” will be interpreted as “reviews.default.svc.cluster.local”, irrespective of the actual namespace associated with the reviews service. To avoid potential misconfigurations, it is recommended to always use fully qualified domain name
[https://istio.io/latest/docs/reference/config/networking/virtual-service/](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
>

```bash
kubectl apply -f ch5/catalog-dest-rule.yaml -n istioinaction

# kubectl get destinationrule -n istioinaction
catalog   catalog.istioinaction.svc.cluster.local   33s
```

**VirtualService 수정 (subset 추가)**

```yaml
# cat ch5/catalog-vs-v1.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - catalog-gateway
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

```yaml
kubectl apply -f ch5/catalog-vs-v1.yaml -n istioinaction
```

호출 테스트 (OK) ~ **Only V1** 만 출력

```bash
for in in {1..10}; do curl http://localhost/items \
-H "Host: catalog.istioinaction.io"; printf "\n\n"; done

..
[
  {
    "id": 0,
    "color": "teal",
    "department": "Clothing",
    "name": "Small Metal Shoes",
    "price": "232.00"
  }
]
..
```

```bash
..
istio-ingressgateway-.. istio-proxy [2023-01-05T07:43:46.238Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 1 0 "172.17.0.1" "curl/7.84.0" "2203842e-e4f8-99b8-a22f-af671f9b3f0b" "catalog.istioinaction.io" "172.17.0.11:3000" outbound|80|version-v1|catalog.istioinaction.svc.cluster.local 172.17.0.6:51458 172.17.0.6:8080 172.17.0.1:17488 - -
..
```

> *드디어, 기존 버전 (v1) 으로만 사용자 요청이 들어온다. 이제는 새로운 버전(v2)을 배포하더라도 사용자에게 노출될 일이 없다. 
그렇다면, 새로 배포된 버전(v2)에 문제가 없는지 요청을 선별하여 확인하려면 어떻게 해야 할까?*
> 

**(실험2) V2 로도 트래픽을 보내고 싶다**

request 헤더에 `x-istio-cohort: internal` 가 있으면 v2로 라우팅 하도록 해봅니다. 

![스크린샷 2023-01-05 오후 4.44.47.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-05_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_4.44.47.png)

VirtualService 명세 수정이 필요합니다

```yaml
# cat ch5/catalog-vs-v2-request.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - catalog-gateway
  http:
  - match:      # <-- matched route
    - headers:
        x-istio-cohort:
          exact: "internal"
    route:
    - destination:
        host: catalog
        subset: version-v2
  - route:      # <-- default route
    - destination:
        host: catalog
        subset: version-v1
```

```yaml
kubectl apply -f ch5/catalog-vs-v2-request.yaml -n istioinaction
```

호출 테스트 (OK) ~ **V2** 출력 *(has imageUrl)*

```bash
curl http://localhost/items \
 -H "Host: catalog.istioinaction.io" -H "x-istio-cohort: internal"

..
[
  {
    "id": 0,
    "color": "teal",
    "department": "Clothing",
    "name": "Small Metal Shoes",
    "price": "232.00",
    "imageUrl": "http://lorempixel.com/640/480"
  }
]
..
```

```bash
istio-ingressgateway-.. istio-proxy [2023-01-05T09:07:53.297Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 698 22 20 "172.17.0.1" "curl/7.84.0" "294d8b6d-3a07-924a-ab6a-3c09fb6ce4f7" "catalog.istioinaction.io" "172.17.0.12:3000" outbound|80|version-v2|catalog.istioinaction.svc.cluster.local 172.17.0.6:36334 172.17.0.6:8080 172.17.0.1:35964 - -
```

> *지금까지 앞단 (edge)의 ingressgateway 설정을 통해서 요청 트래픽을 라우팅 해보았습니다.
이번에는 ingressgateway 안쪽의 “call graph” 경로상에서 트래픽룰을 적용해 보겠습니다.*
> 
> 
> ![스크린샷 2023-01-05 오후 8.27.07.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-05_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_8.27.07.png)
> 

### Routing deep within a call graph

webapp을 통해서 catalog 로 요청을 하도록 변경합니다.

catalog 앞단에 webapp을 배치하고 앞에서 테스트 하였던

- v1 only 라우팅
- 헤더설정을 통한 v2 라우팅

을 테스트해 보겠습니다

**환경 초기화**

```bash
kubectl delete gateway,virtualservice,destinationrule --all \
-n istioinaction
```

**webapp 기동**

```bash
kubectl apply -n istioinaction -f \
services/webapp/kubernetes/webapp.yaml

kubectl get deploy
..
catalog      1/1     1            1           4h30m
catalog-v2   1/1     1            1           122m
webapp       1/1     1            1           4m42s

kubectl get svc
..
catalog   ClusterIP   10.110.245.150   ..  80/TCP 
webapp    ClusterIP   10.108.53.203    ..  80/TCP 
```

**route 적용 (Gateway, VirtualService)**

```bash
kubectl apply -n istioinaction -f \
services/webapp/istio/webapp-catalog-gw-vs.yaml

kubectl get gateway coolstore-gateway -o yaml
..
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - webapp.istioinaction.io
    port:
      name: http
      number: 80
      protocol: HTTP

kubectl get virtualservice webapp-virtualservice -o yaml
..
spec:
    gateways:
    - coolstore-gateway
    hosts:
    - webapp.istioinaction.io
    http:
    - route:
      - destination:
          host: webapp
          port:
            number: 80
```

호출테스트 (OK)   curl → ingressgw → webapp → catalog

```bash
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00","imageUrl":"http://lorempixel.com/640/480"},{"id":2,"colo ..
```

curl → ingressgateway → webapp

```bash
istio-ingressgateway-.. istio-proxy [2023-01-05T09:33:21.129Z] "GET /api/catalog HTTP/1.1" 200 - via_upstream - "-" 0 357 87 85 "172.17.0.1" "curl/7.84.0" "01312fa3-7f06-98d6-b9d1-bec2ec29bb7e" "webapp.istioinaction.io" "172.17.0.13:8080" outbound|80||webapp.istioinaction.svc.cluster.local 172.17.0.6:34980 172.17.0.6:8080 172.17.0.1:56844 - -
```

ingressgateway → webapp → catalog 

```bash
webapp-.. istio-proxy [2023-01-05T09:33:21.157Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 37 36 "172.17.0.1" "beegoServer" "01312fa3-7f06-98d6-b9d1-bec2ec29bb7e" "catalog.istioinaction:80" "172.17.0.11:3000" outbound|80||catalog.istioinaction.svc.cluster.local 172.17.0.13:41858 10.107.27.61:80 172.17.0.1:0 - default
webapp-8dc87795-sstvv webapp 2023/01/05 09:33:21.205 [M] [router.go:1014]  172.17.0.1 - - [05/Jan/2023 09:33:21] "GET /api/catalog HTTP/1.1 200 0" 0.053679  curl/7.84.0

..

webapp-.. istio-proxy [2023-01-05T09:33:21.146Z] "GET /api/catalog HTTP/1.1" 200 - via_upstream - "-" 0 357 59 57 "172.17.0.1" "curl/7.84.0" "01312fa3-7f06-98d6-b9d1-bec2ec29bb7e" "webapp.istioinaction.io" "172.17.0.13:8080" inbound|8080|| 127.0.0.6:37193 172.17.0.13:8080 172.17.0.1:0 outbound_.80_._.webapp.istioinaction.svc.cluster.local default
```

**catalog v1 으로만 route 되도록 설정해 봅시다**

```bash
kubectl apply -f ch5/catalog-dest-rule.yaml -n istioinaction

kubectl apply -f ch5/catalog-vs-v1-mesh.yaml -n istioinaction

kubectl get destinationrule catalog -o yaml -n istioinaction
..
spec:
  host: catalog.istioinaction.svc.cluster.local
  subsets:
  - name: version-v1
    labels:
      version: v1
  - name: version-v2
    labels:
      version: v2

kubectl get virtualservice catalog -o yaml -n istioinaction
..
spec:
  hosts:
  - catalog
  gateways:
    - mesh
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

>"mesh"? To apply the rules to both gateways and sidecars, specify "mesh" as one of the gateway names.  
참고: https://istio.io/latest/docs/reference/config/networking/virtual-service/?_ga=2.107883266.1226744782.1679299300-734770911.1670141435
>

호출테스트 (OK) curl → ingressgateway → webapp → catalog v1

```bash
curl -H "Host: webapp.istioinaction.io" http://localhost/api/catalog

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas ..
```

ingressgateway 로그
```bash
istio-ingressgateway.. istio-proxy [2023-01-05T09:48:21.757Z] "GET /api/catalog HTTP/1.1" 200 - via_upstream - "-" 0 357 12 11 "172.17.0.1" "curl/7.84.0" "a6cf39f6-a0ce-9808-b2b9-601a81688f5a" "webapp.istioinaction.io" "172.17.0.13:8080" outbound|80||webapp.istioinaction.svc.cluster.local 172.17.0.6:46790 172.17.0.6:8080 172.17.0.1:48439 - -
```

webapp 로그
```bash
webapp-.. istio-proxy [2023-01-05T09:48:21.762Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 5 4 "172.17.0.1" "beegoServer" "a6cf39f6-a0ce-9808-b2b9-601a81688f5a" "catalog.istioinaction:80" "172.17.0.11:3000" outbound|80|version-v1|catalog.istioinaction.svc.cluster.local 172.17.0.13:50098 10.107.27.61:80 172.17.0.1:0 - -
..
```

catalog 로그
```bash
catalog-.. istio-proxy [2023-01-05T09:48:21.762Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 2 2 "172.17.0.1" "beegoServer" "a6cf39f6-a0ce-9808-b2b9-601a81688f5a" "catalog.istioinaction:80" "172.17.0.11:3000" inbound|3000|| 127.0.0.6:34315 172.17.0.11:3000 172.17.0.1:0 outbound_.80_.version-v1_.catalog.istioinaction.svc.cluster.local default
```

**헤더 설정으로 catalog v2 로 route 되도록 설정해 봅시다**

바로 이전 VirtualService 설정에  아래처럼 match 룰이 추가됩니다.

```bash
diff ch5/catalog-vs-v1-mesh.yaml ch5/catalog-vs-v2-request-mesh.yaml
..
>   - match:
>     - headers:
>         x-istio-cohort:
>           exact: "internal"
>     route:
>     - destination:
>         host: catalog
>         subset: version-v2
```

```bash
kubectl apply -f ch5/catalog-vs-v2-request-mesh.yaml -n istioinaction
```

호출테스트 (OK)  `x-istio-cohort: internal` *헤더를 포함하여 호출하면 v2 (has imageUrl) 가 응답*

```bash
curl http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io" \
-H "x-istio-cohort: internal"

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00","imageUrl":"http://lorempixel.com/640/480"}, .. ]
```

ingressgateway 로그
```bash
istio-ingressgateway-.. istio-proxy [2023-01-05T09:48:21.757Z] "GET /api/catalog HTTP/1.1" 200 - via_upstream - "-" 0 357 12 11 "172.17.0.1" "curl/7.84.0" .. "webapp.istioinaction.io" "172.17.0.13:8080" outbound|80||webapp.istioinaction.svc.cluster.local 172.17.0.6:46790 172.17.0.6:8080 172.17.0.1:48439 - -
```

webapp 로그
```bash
..
webapp-.. istio-proxy [2023-01-05T11:06:39.212Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 698 38 37 "172.17.0.1" .. "catalog.istioinaction:80" "172.17.0.12:3000" outbound|80|version-v2|catalog.istioinaction.svc.cluster.local 172.17.0.13:50270 10.107.27.61:80 172.17.0.1:0 - -
..
```

catalog 로그
```bash
..
catalog-v2-.. istio-proxy [2023-01-05T11:06:39.218Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 698 18 17 "172.17.0.1" .. "catalog.istioinaction:80" "172.17.0.12:3000" inbound|3000|| 127.0.0.6:59251 172.17.0.12:3000 172.17.0.1:0 outbound_.80_.version-v2_.catalog.istioinaction.svc.cluster.local default
```

## 5.3 Traffic shifting

- “canary” or incrementally release
- all live traffic to a set of versions based on weights
- dark-launch (어둠의 론칭) ~ internal 사용자에게만 신규버전(v2)을 미리 노출해 문제점을 확인한다
- routing weights ~ 전체 traffic의 90%는 v1, 10%만 v2로 인입시켜 보자  (문제생기면 rollback)

### Manual Canary Release

```bash
kubectl get po

catalog-5c7f8f8447-6kqcg      2/2     Running   2 (21m ago)   23h
catalog-v2-65cb96c66d-z86hn   2/2     Running   2 (21m ago)   23h
webapp-8dc87795-sstvv         2/2     Running   2 (18h ago)   23h
```

*5.2 마지막 실습에서 header matching으로 v2 인입 테스트를 하였는데요. 
모든 트래픽을 v1으로 보내도록 리셋하겠습니다*

**100% → v1 라우팅**

```bash
kubectl apply -f ch5/catalog-vs-v1-mesh.yaml -n istioinaction

kubectl get virtualservice catalog -o yaml -n istioinaction

..
spec:
  gateways:
  - mesh
  hosts:
  - catalog
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

호출테스트 (OK) ~ 100% v1

```bash
for i in {1..10}; do curl http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io"; done
```

**10% → v2 , 90% → v1 라우팅 적용해 봅시다**

```bash
kubectl apply -f ch5/catalog-vs-v2-10-90-mesh.yaml

kubectl get virtualservice catalog -o yaml -n istioinaction

..
spec:
  gateways:
  - mesh
  hosts:
  - catalog
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 90
    - destination:
        host: catalog
        subset: version-v2
      weight: 10
```

호출테스트 (OK) ~ 100회 호출 중 10%(10개) 에 근사한 v2 count 를 보여줌

```bash
for i in {1..100}; do curl -s http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io" | grep -i imageUrl; done | wc -l

10
```

**50% → v2 , 50% → v1 라우팅 적용해 봅시다**

```bash
kubectl apply -f ch5/catalog-vs-v2-50-50-mesh.yaml

kubectl get virtualservice catalog -o yaml -n istioinaction

..
spec:
  gateways:
  - mesh
  hosts:
  - catalog
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 50
    - destination:
        host: catalog
        subset: version-v2
      weight: 50
```

호출 테스트 (OK) ~ v1 50% 

```bash
for i in {1..100}; do curl -s http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io" | grep -i imageUrl; done | wc -l

50
```

Traffic shifting 을 manually 조정해 보았는데요. 

- weight을 조정하여 incrementally release (v2: 1 ~ 100%) 하거나 rollback (v2: 0%) 할 수 있습니다.
- weight의 합계는 100(%) 이어야 합니다. * 합계가 안맞으면 오동작
- subset은 DestinationRule에 정의된 것을 사용합니다.

CI/CD 도구를 이용하여 Traffic shifting을 **자동화**할 수 있습니다. 

### Automating Canary Release /w Flagger

**Pre-requisite**

초기화 - *주의) catalog(deployment)는 삭제하지 않습니다*

```bash
kubectl delete virtualservice catalog -n istioinaction ;
kubectl delete deploy catalog-v2 -n istioinaction ;
kubectl delete service catalog -n istioinaction ;
kubectl delete destinationrule catalog -n istioinaction ;
```

[Flagger 설치](https://docs.flagger.app/install/flagger-install-on-kubernetes)

```bash
helm repo add flagger https://flagger.app

kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml

helm install flagger flagger/flagger \
  --namespace=istio-system \
  --set crd.create=false \
  --set meshProvider=istio \
  --set metricServer=http://prometheus:9090
```

**Flagger Canary 적용**

Flagger’s Canary 명세 (for catalog)

```yaml
# cat ch5/flagger/catalog-release.yaml

apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: catalog-release
  namespace: istioinaction
spec:
  targetRef:   # <-- 배포 대상(target): catalog
    apiVersion: apps/v1
    kind: Deployment
    name: catalog
  progressDeadlineSeconds: 60
  service:    # <-- Service/VirtualService 설정값
    name: catalog
    port: 80
    targetPort: 3000
    gateways:
    - mesh
    hosts:
    - catalog
  analysis:   # <-- canary progression 파라메터
    interval: 45s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    match:
    - sourceLabels:
        app: webapp
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s
```

```bash
kubectl apply -f ch5/flagger/catalog-release.yaml -n istioinaction
```

catalog 에 대한 Canary 명세를 배포 하면 flagger (operator) 가 catalog를 위한 canary 배포환경을 구성합니다.
flagger 로그를 확인해 보세요. Service, Deployment, VirtualService 등을 설치하는 것을 확인할 수 있습니다.

```
# kubectl logs -f deploy/flagger -n istio-system

flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.276Z","caller":"controller/controller.go:307","msg":"Synced istioinaction/catalog-release"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.960Z","caller":"router/kubernetes_default.go:175","msg":"Service catalog-canary.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.982Z","caller":"router/kubernetes_default.go:175","msg":"Service catalog-primary.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.984Z","caller":"controller/events.go:33","msg":"all the metrics providers are available!","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.992Z","caller":"canary/deployment_controller.go:337","msg":"Deployment catalog-primary.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:32:57.994Z","caller":"controller/events.go:45","msg":"catalog-primary.istioinaction not ready: waiting for rollout to finish: observed deployment generation less than desired generation","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.946Z","caller":"controller/events.go:33","msg":"all the metrics providers are available!","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.952Z","caller":"canary/deployment_controller.go:63","msg":"Scaling down Deployment catalog.istioinaction","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.966Z","caller":"router/kubernetes_default.go:175","msg":"Service catalog.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.977Z","caller":"router/istio.go:104","msg":"DestinationRule catalog-canary.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.981Z","caller":"router/istio.go:104","msg":"DestinationRule catalog-primary.istioinaction created","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.986Z","caller":"router/istio.go:317","msg":"VirtualService catalog.istioinaction updated","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-06T13:33:42.994Z","caller":"controller/events.go:33","msg":"Initialization done! catalog-release.istioinaction","canary":"catalog-release.istioinaction"}
```


flagger 가 구성한 환경을 확인해 보세요  

```bash
# kubectl get virtualservice
NAME                    GATEWAYS                HOSTS                         AGE
catalog                 ["mesh"]                ["catalog"]                   24m
..


# kubectl get service 
NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
catalog           ClusterIP   10.108.251.64    <none>        80/TCP    25m
catalog-canary    ClusterIP   10.108.159.216   <none>        80/TCP    25m
catalog-primary   ClusterIP   10.105.154.125   <none>        80/TCP    25m


# kubectl get destinationrule
NAME              HOST              AGE
catalog-canary    catalog-canary    24m
catalog-primary   catalog-primary   24m


# kubectl get deployment
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
catalog           0/0     0            0           34m
catalog-primary   1/1     1            1           34m
..


# kubectl get po
NAME                               READY   STATUS    RESTARTS      AGE
catalog-primary-76d46cb86b-84zv9   2/2     Running   0             33m
```

![스크린샷 2023-01-07 오후 12.49.34(2).png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-07_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_12.49.34(2).png)

> *Flagger watches for changes to the original deployment target (in this case, the catalog deployment), creates the canary deployment (catalog-canary) and service (catalog-canary), and adjusts the VirtualService weights.*
>

Flagger 로 기존 catalog(deployment) 를 canary 배포할 수 있는 환경을 구성하였습니다

트래픽을 유입시키겠습니다 *주) 1초 간격으로 호출을 계속 발생하도록 유지합니다  

```bash
while true; do curl http://localhost/api/catalog \
-H "Host: webapp.istioinaction.io"; sleep 1; done
```

Flagger가 작성한 VirtualService를 확인해 보세요. 

```yaml
# kubectl get virtualservice catalog -o yaml -n istioinaction
# ...
spec:
  gateways:
  - mesh
  hosts:
  - catalog
  http:
  - match:
    - sourceLabels:
        app: webapp
    route:
    - destination:
        host: catalog-primary
      weight: 100
    - destination:
        host: catalog-canary
      weight: 0
  - route:
    - destination:
        host: catalog-primary
      weight: 100
```

> *Let’s introduce v2 of catalog and see how Flagger automates it through a release and makes decisions based on metrics. Let’s also generate load to the service through Istio, so Flagger has a baseline of what the metrics look like when healthy. In a new terminal window, run the following to loop through calling the services*
> 

**Automates releasing catalog v2 using Flagger**

imageUrl 출력 (v2)을 포함하는 catalog deployment 명세입니다

```yaml
# cat ch5/flagger/catalog-deployment-v2.yaml

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

명세를 적용합니다

```bash
kubectl apply -f ch5/flagger/catalog-deployment-v2.yaml \
-n istioinaction
```

Flagger의 Release 과정은 다음과 같이 모니터링 합니다. 

```bash
# kubectl get canary catalog-release -w

NAME              STATUS        WEIGHT   LASTTRANSITIONTIME
..
catalog-release   Progressing   0        2023-01-07T05:36:31Z
catalog-release   Progressing   10       2023-01-07T05:37:16Z
catalog-release   Progressing   20       2023-01-07T05:38:01Z
catalog-release   Progressing   20       2023-01-07T05:38:46Z
catalog-release   Progressing   30       2023-01-07T05:39:31Z
catalog-release   Progressing   40       2023-01-07T05:40:16Z
catalog-release   Progressing   50       2023-01-07T05:41:01Z
catalog-release   Promoting     0        2023-01-07T05:41:46Z
catalog-release   Finalising    0        2023-01-07T05:42:31Z
catalog-release   Succeeded     0        2023-01-07T05:43:16Z
..
```

Flagger (operator) 로그를 통해서도 release 상세로그를 확인할 수 있습니다. 

```bash
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:36:31.611Z","caller":"controller/events.go:33","msg":"New revision detected! Scaling up catalog.istioinaction","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:37:16.622Z","caller":"controller/events.go:33","msg":"Starting canary analysis for catalog.istioinaction","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:37:16.637Z","caller":"controller/events.go:33","msg":"Advance catalog-release.istioinaction canary weight 10","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:38:01.641Z","caller":"controller/events.go:33","msg":"Advance catalog-release.istioinaction canary weight 20","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:38:46.615Z","caller":"controller/events.go:45","msg":"Halt advancement no values found for istio metric request-duration probably catalog.istioinaction is not receiving traffic","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:39:31.630Z","caller":"controller/events.go:33","msg":"Advance catalog-release.istioinaction canary weight 30","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:40:16.640Z","caller":"controller/events.go:33","msg":"Advance catalog-release.istioinaction canary weight 40","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:41:01.642Z","caller":"controller/events.go:33","msg":"Advance catalog-release.istioinaction canary weight 50","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:41:46.623Z","caller":"controller/events.go:33","msg":"Copying catalog.istioinaction template spec to catalog-primary.istioinaction","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:42:31.621Z","caller":"controller/events.go:33","msg":"Routing all traffic to primary","canary":"catalog-release.istioinaction"}
flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T05:43:16.614Z","caller":"controller/events.go:33","msg":"Promotion completed! Scaling down catalog.istioinaction","canary":"catalog-release.istioinaction"}
```

webapp 로그 출력 확인 (OK) ~ `imageUrl` 포함 (v2 전환 완료)

```bash
# while true; do curl http://localhost/api/catalog -H "Host: webapp.istioinaction.io"; sleep 3; done

.. ,{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00","imageUrl":"http://lorempixel.com/640/480"}, ..
```

> *We used Flagger to automatically control the canary release using Istio’s APIs and removed the need to manually configure resources or introduce any manual behavior that could cause configuration errors. Flagger can also do dark-launch testing, traffic mirroring, and more; see [https://flagger.app](https://flagger.app)*
> 

Canary 삭제

```bash
kubectl delete canary catalog-release
```

- Flagger 로그
    
    ```bash
    flagger-94d44f76c-xw89q flagger {"level":"info","ts":"2023-01-07T06:50:06.415Z","caller":"controller/controller.go:172","msg":"Deleting catalog-release.istioinaction from cache"}
    ```
    
    - *Flagger가 만든 service (catalog, catalog-canary, catalog-primary), destinationrule (catalog-canary, catalog-primary), deployment (catalog-primary) 를 제거함*

catalog 삭제

```bash
kubectl delete deploy catalog -n istioinaction
kubectl delete virtualservice catalog -n istioinaction
```

Flagger 삭제

```bash
helm uninstall flagger -n istio-system
```

## 5.4 Reducing risk even further: Traffic mirroring

초기 환경 셋업

```bash
kubectl apply -f services/catalog/kubernetes/catalog-svc.yaml \
 -n istioinaction;

kubectl apply -f services/catalog/kubernetes/catalog-deployment.yaml \
 -n istioinaction;

kubectl apply -f services/catalog/kubernetes/catalog-deployment-v2.yaml \
 -n istioinaction;

kubectl apply -f ch5/catalog-dest-rule.yaml \
 -n istioinaction;

kubectl apply -f ch5/catalog-vs-v1-mesh.yaml \
 -n istioinaction;
```

호출테스트 (OK) - catalog v1 으로만 트래픽 유입

```bash
curl http://localhost/api/catalog -H "Host: webapp.istioinaction.io"

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

catalog v1 로그

```bash
catalog-6c89984555-rmmmm istio-proxy [2023-01-07T08:09:50.278Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 7 5 "172.17.0.1" "beegoServer" "f3892be4-9af3-962d-8acd-94d280dec0a9" "catalog.istioinaction:80" "172.17.0.14:3000" inbound|3000|| 127.0.0.6:45377 172.17.0.14:3000 172.17.0.1:0 outbound_.80_.version-v1_.catalog.istioinaction.svc.cluster.local default
```

catalog v2 로그 (유입없음)

### Traffic Mirroring

![스크린샷 2023-01-07 오후 4.44.40.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-07_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_4.44.40.png)

VirtualService 명세 - mirror 설정

```yaml
# cat ch5/catalog-vs-v2-mirror.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  gateways:
    - mesh
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 100
    mirror:
      host: catalog
      subset: version-v2
```

```bash
kubectl apply -f ch5/catalog-vs-v2-mirror.yaml \
 -n istioinaction
```

호출테스트 (OK) - mirror 트래픽 유입 확인

```bash
curl http://localhost/api/catalog -H "Host: webapp.istioinaction.io"

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

catalog v1 로그

```bash
catalog-.. catalog request path: /items
catalog-.. catalog blowups: {}
catalog-.. catalog number of blowups: 0
catalog-.. catalog GET catalog.istioinaction:80 /items 200 502 - 0.958 ms
catalog-.. catalog GET /items 200 0.958 ms - 502
catalog-.. istio-proxy [2023-01-07T08:13:56.332Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 502 5 4 "172.17.0.1" "beegoServer" "65b8876f-156a-96f6-86c9-9bb858de6b8b" "catalog.istioinaction:80" "172.17.0.14:3000" inbound|3000|| 127.0.0.6:58015 172.17.0.14:3000 172.17.0.1:0 outbound_.80_.version-v1_.catalog.istioinaction.svc.cluster.local default
```

catalog v2 로그 (mirror traffic) ~  “-shadow” postfix 호출 (mirrored request)

```bash
catalog-v2-.. catalog request path: /items
catalog-v2-.. catalog blowups: {}
catalog-v2-.. catalog number of blowups: 0
catalog-v2-.. catalog GET catalog.istioinaction-shadow:80 /items 200 698 - 1.408 ms
catalog-v2-.. catalog GET /items 200 1.408 ms - 698
catalog-v2-.. istio-proxy [2023-01-07T08:13:56.333Z] "GET /items HTTP/1.1" 200 - via_upstream - "-" 0 698 4 3 "172.17.0.1,172.17.0.13" "beegoServer" "65b8876f-156a-96f6-86c9-9bb858de6b8b" "catalog.istioinaction-shadow:80" "172.17.0.8:3000" inbound|3000|| 127.0.0.6:40107 172.17.0.8:3000 172.17.0.13:0 outbound_.80_.version-v2_.catalog.istioinaction.svc.cluster.local default
```

> *Mirroring traffic is one part of the story to lower the risk of doing releases. Just as with request routing and traffic shifting, our applications should be aware of this context and be able to run in both live and mirrored modes, run as multiple versions, or both. See our blog posts at [http://bit.ly/2NSE2gf](http://bit.ly/2NSE2gf) and [http://bit.ly/2oJ86jc](http://bit.ly/2oJ86jc) to learn more.*
> 

## 5.5 Routing to services outside your cluster by using Istio’s service discovery

이번 챕터에서 실습에 사용할 forum app 을 배포합니다. 

```bash
kubectl apply -f services/forum/kubernetes/forum-all.yaml \
 -n istioinaction

## 확인
kubectl get deploy forum \
 -n istioinaction
..
forum        1/1     1            1           5m9s

kubectl get svc forum \
 -n istioinaction
..
forum     ClusterIP   10.99.60.27      <none>        80/TCP    4m42s
```

호출테스트 (OK) ~ webapp → forum → 외부IP(104.21.55.162:80)  *allow_any 

```bash
curl http://localhost/api/users -H "Host: webapp.istioinaction.io"

[{"id":1,"name":"Leanne Graham","username":"Bret","email":"Sincere@april.biz","address":{"street":"Kulas Light","suite":"Apt. 556","city":"Gwenborough","zipcode":"92998-3874"},.. ]
```

webapp → forum

```bash
webapp-.. webapp 2023/01/07 10:59:03.501 [M] [router.go:1014]  172.17.0.1 - - [07/Jan/2023 10:59:03] "GET /api/users HTTP/1.1 200 0" 0.074393  curl/7.84.0
webapp-. istio-proxy .[2023-01-07T10:59:03.430Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 5645 70 70 "172.17.0.1" "beegoServer" "e631fa32-fb6a-921a-8f58-e96f3dcac3d3" "forum.istioinaction:80" "172.17.0.7:8080" outbound|80||forum.istioinaction.svc.cluster.local 172.17.0.13:55894 10.99.60.27:80 172.17.0.1:0 - default
webapp-.. istio-proxy [2023-01-07T10:59:03.427Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 3679 76 75 "172.17.0.1" "curl/7.84.0" "e631fa32-fb6a-921a-8f58-e96f3dcac3d3" "webapp.istioinaction.io" "172.17.0.13:8080" inbound|8080|| 127.0.0.6:53421 172.17.0.13:8080 172.17.0.1:0 outbound_.80_._.webapp.istioinaction.svc.cluster.local default
```

forum → 외부IP(104.21.55.162:80)

```bash
forum-.. istio-proxy [2023-01-07T10:59:03.432Z] "GET /users HTTP/1.1" 200 - via_upstream - "-" 0 1847 65 64 "172.17.0.1" "Go-http-client/1.1" "e631fa32-fb6a-921a-8f58-e96f3dcac3d3" "jsonplaceholder.typicode.com" "104.21.55.162:80" PassthroughCluster 172.17.0.7:50460 104.21.55.162:80 172.17.0.1:0 - allow_any
forum-.. istio-proxy [2023-01-07T10:59:03.430Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 5645 69 68 "172.17.0.1" "beegoServer" "e631fa32-fb6a-921a-8f58-e96f3dcac3d3" "forum.istioinaction:80" "172.17.0.7:8080" inbound|8080|| 127.0.0.6:58511 172.17.0.7:8080 172.17.0.1:0 outbound_.80_._.forum.istioinaction.svc.cluster.local default
```

### Blocking external traffic

![스크린샷 2023-01-07 오후 6.56.18.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-07_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_6.56.18.png)

```bash
istioctl install --set profile=demo \
 --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY

This will install the Istio 1.16.1 demo profile with ["Istio core" "Istiod" "Ingress gateways" "Egress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete                                                                     Making this installation the default for injection and validation.

Thank you for installing Istio 1.16.  Please take a few minutes to tell us about your install/upgrade experience!  https://forms.gle/99uiMML96AmsXY5d6
```

istio configmap 에서 outboundTrafficPolicy 변경을 확인할 수 있습니다.

```bash
# kubectl get cm istio -o yaml -n istio-system
..
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
..
```

호출테스트 (X) ~ 예상대로 호출이 실패합니다. 

```bash
curl http://localhost/api/users -H "Host: webapp.istioinaction.io"

error calling Forum service
```

webapp → forum

```bash
webapp-8dc87795-sstvv istio-proxy [2023-01-07T11:12:51.469Z] "GET /api/users HTTP/1.1" 500 - via_upstream - "-" 0 28 16 15 "172.17.0.1" "beegoServer" "5e171596-6a07-9735-acec-fcd798d7bbb8" "forum.istioinaction:80" "172.17.0.7:8080" outbound|80||forum.istioinaction.svc.cluster.local 172.17.0.13:55894 10.99.60.27:80 172.17.0.1:0 - default
webapp-8dc87795-sstvv istio-proxy [2023-01-07T11:12:51.462Z] "GET /api/users HTTP/1.1" 500 - via_upstream - "-" 0 27 31 30 "172.17.0.1" "curl/7.84.0" "5e171596-6a07-9735-acec-fcd798d7bbb8" "webapp.istioinaction.io" "172.17.0.13:8080" inbound|8080|| 127.0.0.6:51601 172.17.0.13:8080 172.17.0.1:0 outbound_.80_._.webapp.istioinaction.svc.cluster.local default
```

forum —(X)—> 외부IP (104.21.55.162:80) 외부호출이 실패합니다. 

```bash
forum-7985546ffb-clxhz istio-proxy [2023-01-07T11:12:51.472Z] "GET /users HTTP/1.1" 502 - direct_response - "-" 0 0 0 - "172.17.0.1" "Go-http-client/1.1" "5e171596-6a07-9735-acec-fcd798d7bbb8" "jsonplaceholder.typicode.com" "-" - - 104.21.55.162:80 172.17.0.1:0 - block_all
forum-7985546ffb-clxhz istio-proxy [2023-01-07T11:12:51.470Z] "GET /api/users HTTP/1.1" 500 - via_upstream - "-" 0 28 3 2 "172.17.0.1" "beegoServer" "5e171596-6a07-9735-acec-fcd798d7bbb8" "forum.istioinaction:80" "172.17.0.7:8080" inbound|8080|| 127.0.0.6:58511 172.17.0.7:8080 172.17.0.1:0 outbound_.80_._.forum.istioinaction.svc.cluster.local default
```

outboundTrafficPolicy 정책을 REGISTRY_ONLY 로 바꾸었더니 외부호출이 되지 않습니다. 

forum이 호출하는 외부IP (104.21.55.162:80)를 ServiceEntry 로 허용하도록 해보겠습니다. 

### ServiceEntry

![스크린샷 2023-01-07 오후 8.31.28.png](/assets/img/Istio-ch5%20e5d352db30ea41189ae55571b086561b/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-01-07_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_8.31.28.png)

```yaml
# cat ch5/forum-serviceentry.yaml

apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: jsonplaceholder
spec:
  hosts:
  - jsonplaceholder.typicode.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
```

```bash
kubectl apply -f ch5/forum-serviceentry.yaml -n istioinaction
```

호출테스트 (OK)

```yaml
curl http://localhost/api/users -H "Host: webapp.istioinaction.io"


```

webapp 로그 (webapp → forum)
```bash
webapp-.. webapp 2023/01/07 11:27:42.706 [M] [router.go:1014]  172.17.0.1 - - [07/Jan/2023 11:27:42] "GET /api/users HTTP/1.1 200 0" 0.120906  curl/7.84.0
webapp-.. istio-proxy [2023-01-07T11:27:42.588Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 5645 116 116 "172.17.0.1" "beegoServer" "8a5b592f-3ea5-98d8-881d-09ace845b08d" "forum.istioinaction:80" "172.17.0.7:8080" outbound|80||forum.istioinaction.svc.cluster.local 172.17.0.13:42558 10.99.60.27:80 172.17.0.1:0 - default
webapp-.. istio-proxy [2023-01-07T11:27:42.585Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 3679 122 121 "172.17.0.1" "curl/7.84.0" "8a5b592f-3ea5-98d8-881d-09ace845b08d" "webapp.istioinaction.io" "172.17.0.13:8080" inbound|8080|| 127.0.0.6:51601 172.17.0.13:8080 172.17.0.1:0 outbound_.80_._.webapp.istioinaction.svc.cluster.local default

```

forum 로그 (forum → 외부IP)
```bash
forum-.. istio-proxy [2023-01-07T11:27:42.589Z] "GET /users HTTP/1.1" 200 - via_upstream - "-" 0 1847 112 111 "172.17.0.1" "Go-http-client/1.1" "8a5b592f-3ea5-98d8-881d-09ace845b08d" "jsonplaceholder.typicode.com" "104.21.55.162:80" outbound|80||jsonplaceholder.typicode.com 172.17.0.7:58764 104.21.55.162:80 172.17.0.1:0 - default
forum-.. istio-proxy [2023-01-07T11:27:42.588Z] "GET /api/users HTTP/1.1" 200 - via_upstream - "-" 0 5645 115 114 "172.17.0.1" "beegoServer" "8a5b592f-3ea5-98d8-881d-09ace845b08d" "forum.istioinaction:80" "172.17.0.7:8080" inbound|8080|| 127.0.0.6:56407 172.17.0.7:8080 172.17.0.1:0 outbound_.80_._.forum.istioinaction.svc.cluster.local default

```

## Summary

- **DestinationRule** : define Workloads’ **subsets**  ex) version ~ v1, v2
- **VirtualService** : use Workloads’ subsets to route traffic
- VirtualService : configure routing decisions based on app layer info such as HTTP headers  ex) “**dark-launch** technique”
- VirtualService : configure **weighted routing** for gradually increasing traffic to new deployments (blue-green), canary deployments (aka traffic shifting)
- **Traffic shifting** using Flagger
- **outboundTrafficPolicy** : set `REGISTRY_ONLY`  blocking all that leaves the cluster (white-list)
- **ServiceEntry** : permit traffic to external services for `REGISTRY_ONLY`