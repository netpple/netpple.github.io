---
title: Istio Securing (3)  
version: v1.0  
description: istio in action 9장  
date: 2023-04-22 09:50:00 +09:00  
layout: page  
toc: 13  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
histories:
- date: 2023-04-22 09:50:00 +09:00
  description: 최초 등록
---

서비스 간 인가 `authorization` 에 대해서 알아봅시다

<!--more-->

# 9.3 서비스-to-서비스 인가  

`Authorization` (인가)는  `인증된 대상` (authenticated subject) 에게 리소스에 대한 접근 (accessing), 편집 (editing), 삭제 (deleting) 등과 같은 오퍼레이션 수행을 허가할 지 여부를 결정하는 절차입니다

정책은 `인증된 대상` (who) 과 `authorization` (권한, what)을 함께 연결지어 누가(who) 무엇(what)을 할 수 있는지를 정의합니다

Istio 는 메시 전체, 네임스페이스 단위, 워크로드 단위의 접근 정책을 정의할 수 있는 선언적 API인  AuthorizationPolicy 커스텀 리소스를 제공합니다

아래 그림은 특정 ID가 탈취(침해, compromised)된 경우 어떻게 접근정책이 스코프 혹은 피해 반경을 제한하는지 보여줍니다
![권한 - ID탈취 시 영향범위 제한](/docs/assets/img/istio-in-action/authz_reduce_compromised_id_scope.png)

## 실습 환경

첫째, 👉🏻 *먼저, “[실습 초기화](/docs/istio-in-action/Istio-ch9-securing-1-overview#실습-초기화){:target="_black"}” 후 진행해 주세요*  
둘째, 실습 환경 구성하기

```bash
## 실습 코드 경로에서 실행합니다
# cd book-source-code

## install apps
kubectl -n istioinaction apply -f \
 services/catalog/kubernetes/catalog.yaml
 
kubectl -n istioinaction apply -f \
 services/webapp/kubernetes/webapp.yaml

kubectl -n istioinaction apply -f \
 services/webapp/istio/webapp-catalog-gw-vs.yaml

kubectl -n default apply -f \
 ch9/sleep.yaml

## applies PeerAuthentication
kubectl -n istio-system apply -f \
 ch9/meshwide-strict-peer-authn.yaml

kubectl -n istioinaction apply -f \
 ch9/workload-permissive-peer-authn.yaml
```
- *catalog.yaml* : backend 앱
- *istio-injection=enabled* : 실습 네임스페이스에 레이블 추가 (istio-proxy sidecar 자동주입)
- *webapp.yaml* : frontend 앱. 요청을 받아서 catalog 호출
- *webapp-catalog-gw-vs.yaml* : 라우트 정보
    - `coolstore-gateway` : istio-ingressgateway에 인입할 트래픽의 outside route 정의
    - `webapp-virtualservice` : `coolstore-gateway` 로 인입된 트래픽의 inside route (destination) 정의
- *sleep.yaml* : client 앱. webapp 호출
- *meshwide-strict-peer-authn.yaml* : 기본 설정. `STRICT` (mTLS)
- *workload-permissive-peer-authn.yaml* : webapp 설정. `PERMISSIVE` (http도 허용)

셋째, 실습환경 확인  
```bash
## sidecar 확인 (컨테이너 2개)
kubectl -n istioinaction get po

NAME                       READY   STATUS    RESTARTS   AGE
catalog-5c7f8f8447-jf6pv   2/2     Running   0          52s
webapp-8dc87795-qww5r      2/2     Running   0          52s

## gateway, virtualservice
kubectl -n istioinaction get gw,vs -o name

gateway.networking.istio.io/coolstore-gateway
virtualservice.networking.istio.io/webapp-virtualservice

## PeerAuthentication 설정 확인
kubectl get pa -A

NAMESPACE       NAME      MODE         AGE
istio-system    default   STRICT       5m59s
istioinaction   webapp    PERMISSIVE   5m59s

## client pod 확인
kubectl -n default get po -o name

pod/sleep-<omitted>
```

## AuthorizationPolicy 를 적용하지 않은 경우

> 질문) Istio 는 아무 AuthorizationPolicy가 설정돼 있지 않으면 어떻게 동작할까?   
> 답변) 모든 요청에 대해 권한체크를 하지 않음
> 

### 호출테스트0 (OK)

istio-ingressgateway 를 통해서 webapp 호출

> **sleep** —> `istio-ingressgateway` — *route* —`webapp svc`—> ([istio-proxy]→[**webapp**]) —`catalog svc`—>([istio-proxy]→[**catalog**])
> 

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL -o /dev/null -w "%{http_code}\n" \
  -H "Host: webapp.istioinaction.io" \
  istio-ingressgateway.istio-system/api/catalog

200
```
👉🏻Call Graph 확인 (200 OK)
![ingress-gateway 트래픽 유입](/docs/assets/img/istio-in-action/sleep_to_ingreegw.png)

### 호출 테스트1 (OK)

이번에는 istio-ingressgateway 를 통하지 않고 **바로** **webapp** 호출해 봅니다

> sleep —`webapp svc`—> ([istio-proxy]→[webapp]) —`catalog svc`—>([istio-proxy]→[catalog])
> 

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL -o /dev/null -w "%{http_code}\n" \
  webapp.istioinaction/api/catalog

200
```
👉🏻 Call Graph 확인 (2OO OK)     
![webapp 트래픽 유입](/docs/assets/img/istio-in-action/sleep_to_webapp_200_permissive.png)

### 호출 테스트2 (X, 404)
webapp 에 없는 페이지 (/hello/world) 호출 ⇒ “404 리턴”
> sleep —(X)—> webapp    `/hello/world`  

```bash
kubectl -n default exec deploy/sleep -c sleep -- \
 curl -sSL webapp.istioinaction/hello/world

404
```
👉🏻 Call Graph 확인 (404 NOK)
![webapp 404](/docs/assets/img/istio-in-action/sleep_to_webapp_404.png)

## AuthorizationPolicy 를 적용해보자
> AuthorizationPolicy 를 설정하면 정책을 통과한 트래픽만 허용됩니다  
>

*webapp 에서 `/api/catalog` 경로를 `ALLOW` 해보자*

```bash
kubectl apply -f -<<END
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "allow-catalog-requests-in-web-app"
  namespace: istioinaction
spec:
  selector:
    matchLabels:
      app: webapp
  rules:
  - to:
    - operation:
        paths: ["/api/catalog"]
  action: ALLOW
END
```

### 호출 테스트3 (OK)

> sleep → webapp    `/api/catalog`    

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL -o /dev/null -w "%{http_code}\n" \
  webapp.istioinaction/api/catalog

200
```
![webapp ALLOW 정책](/docs/assets/img/istio-in-action/sleep_to_webapp_ALLOW.png)


### 호출 테스트4 (X, 403)

> sleep —(X)—> webapp    `/hello/world`

webapp 에 없는 페이지 (/hello/world) 호출 ⇒ “403 리턴”

```bash
kubectl -n default exec deploy/sleep -c sleep -- \
 curl -sSL -w "\n%{http_code}" \
  webapp.istioinaction/hello/world
  
RBAC: access denied
403
```

![webapp 403 call graph](/docs/assets/img/istio-in-action/sleep_to_webapp_403.png)
![webapp 403 로그](/docs/assets/img/istio-in-action/sleep_to_webapp_403_log.png)

/hello/world 는 webapp 에 "존재하지 않는 경로" 인데요    
> `질문` /hello/world 처럼 "정책이 없는 경로" 는 어떻게 처리할까요 ?    
> `답변` DENY

/hello/world 는 호출 테스트2 에서 "404를 리턴"하였습니다         
> `질문` 기본 정책이 DENY 라면 호출 테스트2 에서 403이 아닌 404를 리턴한 이유는 ?  
> `답변` AuthorizationPolicy 정책이 하나 이상 설정이 돼야 기본 정책 `DENY`도 적용됩니다   
>

### AuthorizationPolicy 적용 원칙

“*deny-by-default*”

<img src="/docs/assets/img/istio-in-action/deny_by_default.png" width=300 style="margin: 0 0 0 20px" />

1. 요청 허용
   - ALLOW 가 한개 이상 존재
2. 요청 거부 
   - DENY 에 매칭됨  
   - ALLOW 가 없음 (기본 DENY 적용)
 
> `기본 DENY` 정책은 "무엇을 허용할 것인가 (화이트리스트)" 만 고민하면 됩니다 

<br />
🙏🏻 *다음 실습을 위해 AuthorizationPolicy 는 삭제해 주세요*
```bash
kubectl delete authorizationpolicy allow-catalog-requests-in-web-app
```

## 모든 요청을 거부하는 AuthorizationPolicy

모든 요청을 거부하는 “mesh-wide 정책”을 추가해 봅시다

*"deny-all"*

### Why ?

- 복잡한 인가 (authorization) 정책을 Simple 하게 
- 일단 다 막고 필요할 때 ALLOW 
- 일종의 화이트(ALLOW) 리스트 관리
- Best Practice (이렇게 해보니 좋더라)
- 일명, Catch-all deny-all  (싹~잡아 전부 DENY)

### 적용 방법

- `mesh-wide` scope (istio-system)
- `{}` empty-spec

```bash
kubectl apply -f -<<END
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: istio-system  # <-- mesh-wide. target all in the mesh
spec: {}                   # <-- empty spec. deny every request
END
```

### 호출테스트5 (X, 403)

> sleep —(X)—> webapp

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL -w "\n%{http_code}\n" \
  webapp.istioinaction/api/catalog

RBAC: access denied
403
```
👉🏻 webapp (istio-proxy) 에서 요청을 deny 합니다 
![deny-all_rbac_access_denied](/docs/assets/img/istio-in-action/sleep_to_webapp_deny-all.png)

결과 해석
- sleep 에서 보낸 요청을 webapp (istio-proxy) 에서 거부함
- mesh 로 오는 모든 요청에 대해 AuthorizationPolicy를 deny-all (`spec: {}`) 로 설정했기 때문

**(참고) istio-ingressgateway로 호출한다면 ?**

결과는 `403 denied`로 동일합니다. 다만, istio-ingressgateway 에서 막힌다는 점이 다릅니다.  
deny-all 로 설정하면서 외부 유입 트래픽에 대해서도 DENY 정책을 기본으로 합니다  

> sleep —(X, 403)—>`istio-ingressgateway`  * 트래픽이 webapp 쪽으로 유입되지 않습니다.
> 

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL -H "Host: webapp.istioinaction.io" \
  istio-ingressgateway.istio-system/api/catalog

RBAC: access denied
```
![](/docs/assets/img/istio-in-action/sleep_to_ingressgw_deny-all.png)

**(참고) webapp 에 대해 AuthorizationPolicy를 ALLOW 한다면 ?**

> sleep —> webapp —(X,403)—> catalog
> 

webapp 으로는 요청이 들어오지만, webapp 에서 catalog 요청은 `RBAC: access denied` 됨

## 특정 네임스페이스에서 오는 요청만 허용해보자

sleep이 속한 “default” 네임스페이스에서 오는 요청을 허용합니다

```bash
kubectl apply -f -<<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "webapp-allow-view-default-ns"
  namespace: istioinaction
spec:
  rules:
  - from:
    - source:
        namespaces: ["default"]
    to:
    - operation:
        methods: ["GET"]
EOF
```

```bash
## istiod 로그 - 정책 적용 확인 
<omit> ads  Push debounce stable[65] 1 for config AuthorizationPolicy/istioinaction/webapp-allow-view-default-ns: 100.584958ms since last change, 100.584667ms since last push, full=true
<omit> ads  XDS: Pushing:2022-12-31T04:09:20Z/44 Services:14 ConnectedEndpoints:4 Version:2022-12-31T04:09:20Z/44
<omit> ads  LDS: PUSH for node:istio-egressgateway-79598956cf-nq9gq.istio-system resources:0 size:0B
<omit> ads  LDS: PUSH for node:istio-ingressgateway-854c9d9c5f-vbj4j.istio-system resources:1 size:3.8kB
<omit> ads  LDS: PUSH for node:webapp-8dc87795-f4htw.istioinaction resources:22 size:104.3kB
<omit> ads  LDS: PUSH for node:catalog-5c7f8f8447-h252p.istioinaction resources:22 size:94.0kB
```
    

### 호출테스트6 (X, 403)

> sleep —(X)—> webapp

```bash
kubectl exec -n default deploy/sleep -c sleep --  \
 curl -sSL webapp.istioinaction/api/catalog

RBAC: access denied
```

webapp  `403 - rbac_access_denied_matched_policy[none]` 
```
istio-proxy [2022-12-30T13:03:35.611Z] "GET /api/catalog HTTP/1.1" 403 - rbac_access_denied_matched_policy[none] - "-" 0 19 0 - "-" "curl/7.83.1" "d6a17339-59dd-941d-90f6-373dd2d9193a" "webapp.istioinaction" "-" inbound|8080|| - 172.17.0.3:8080 172.17.0.1:30299 - -
```

*🤔 `default 네임스페이스` 를 허용 했음에도 요청이 거부 (403, denied) 되는 이유는 ?*
- pod (sleep)에 `istio-proxy` 없음
- 인증 처리 못함 => ID 식별 안됨 => 권한 적용 못함

*이 문제를 풀려면 ?*

`방법1)` sidecar (istio-proxy) 를 주입한다 ⇒ *기존 legacy (sleep pod) 재배포 필요*
    
 ```bash
 ## labeling
 kubectl label ns default istio-injection=enabled
 
 ## pod redeploy
 kubectl delete po -l app=sleep -n default
 # .. OR ..
 # kubectl rollout restart deploy/sleep -n default
 
 ## test1 - 실패
 kubectl exec -n default deploy/sleep -c sleep --  \
  curl -sSL webapp.istioinaction/api/catalog
 
 error calling Catalog service
 
 ## test2 - 성공
 kubectl exec -n default deploy/sleep -c sleep --  \
  curl -sSL catalog.istioinaction/items
 
 200
 ```
    
Q) test1 (sleep→webapp) 은 실패, test2 는 성공 하였습니다. 이유는 ?    
A) `default 네임스페이스` 요청 허용
> test1 (성공) : sleep —(X, 500)—> webapp —(X, 403)—>catalog  

- `sleep → webapp` : (허용) `default 네임스페이스`의 요청을 허용함
- `webapp → catalog` : (거부) deny-all 적용

> test2 (실패) : sleep —(O)—> catalog  

- `sleep → catalog` : (허용) `default 네임스페이스`의 요청을 허용함  

*🙏🏻다음 실습을 위해 default 네임스페이스를 원래대로 되돌립니다*

```bash
## istio-injection 레이블 제거
kubectl label ns default istio-injection-

## pod redeploy
kubectl rollout restart deploy/sleep -n default
```
    
`방법2)` webapp 에서 *non-authenticated* 요청을 허용합니다 🤏*보안 상 별로지만, 설정만으로 처리가능*
    
    아래 실습에서 이어서 해봅니다. 
    

## non-authenticated 요청을 허용해 보자

webapp 에 미인증 요청을 허용해 보겠습니다  
webapp (selector) 으로 향하는 GET 요청을 ALLOW 합니다  

```bash
kubectl apply -f -<<END
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "webapp-allow-unauthenticated-view-default-ns"
  namespace: istioinaction
spec:
  selector:
    matchLabels:
      app: webapp
  rules:
    - to:
      - operation:
          methods: ["GET"]
END
```

### 호출테스트7 (X, 500)

“호출테스트6” 의 결과와 비교

- webapp 의 에러코드가 달라짐 (500)
- catalog 에 호출 로그 찍힘 (403)

> sleep —(X, 500)—> webapp —(X, 403)—> catalog

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL  -w "\n%{http_code}\n" \
  webapp.istioinaction/api/catalog

error calling Catalog service
500
```

왜 여전히 실패할까? 

- sleep —> webapp : *sleep 요청은 webapp에서 허용됐지만*
- webapp —(X,403) —> catalog : 실패  `403 - rbac_access_denied_matched_policy[none]`

기본 정책이 mesh-wide deny all 이므로 webapp —*(AuthorizationPolicy 추가)*—> catalog 구간도 정책을 추가해 줘야 합니다  

## ServiceAccount ALLOW 하기 

webapp 서비스 어카운트 (sa/webapp) 에 catalog "GET"을 허용해 봅니다 

```bash
kubectl apply -f -<<END
apiVersion: "security.istio.io/v1beta1"
kind: "AuthorizationPolicy"
metadata:
  name: "catalog-viewer"
  namespace: istioinaction
spec:
  selector:
    matchLabels:
      app: catalog
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/istioinaction/sa/webapp"]
    to:
    - operation:
        methods: ["GET"]
END
```

### 호출테스트8 (OK)

> sleep —(**non-authenticated 허용**)—>  webapp —(**sa 허용**) —> catalog
>

```bash
kubectl exec -n default deploy/sleep -c sleep -- \
 curl -sSL webapp.istioinaction/api/catalog

[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

<br />

👉🏻 *[다음편 보기](/docs/istio-in-action/Istio-ch9-securing-4-end-user-auth)*