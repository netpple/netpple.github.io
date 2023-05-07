---
title: Istio Securing (4)  
version: v1.0  
description: istio in action 9장  
date: 2023-04-24 09:00:00 +09:00  
layout: post  
toc: 14  
categories: network
label: istio in action
comments: true
rightpanel: true
badges:
- type: info  
  tag: 교육
histories:
- date: 2022-12-24 22:00:00 +09:00
  description: 최초 등록
---

앞에서 서비스(피어) 간 인증/인가에 대해서 알아보았는데요. 이번에는 End-user 의 인증과 인가에 대해서 알아봅니다 .

<!--more-->

# 9.4 End-user 인증과 인가 

Istio 에서는 JWT 를 사용하여 End-user 의 인증과 인가를 제공합니다. 

먼저, JWT 에 대한 개념을 가볍게 짚어 보겠습니다.

## 9.4.1 JWT, JSON Web Token 이란

JWT 는 서버가 클라이언트를 인증하는데 사용되는 완전한 `claim` 정보입니다
- `claim` : JWT 에서 클라이언트 정보를 컴팩트하게 포함한 JSON 개체입니다
- `sub`, *Subject* : 인증 대상이 되는 주체. 즉 서버에 인증에 필요한 정보(`claim`) 를 제공하고 요청을 하는 주체로 JWT 스펙에 포함 됩니다


*JWT 구조*

- Header — 타입 and 해시 알고리즘
- Payload — 유저 `claims`
- Signature — 서명, 서명 검증을 통해 JWT 의 `authenticity` 보장. `authenticity`는 JWT가 위변조 되지 않았음을 보장하는 보안속성 입니다

JWT 구조를 이루는 — Header, Payload, Signature — 세가지 요소는 HTTP 요청에서 사용할 수 있도록 점 (.)으로 구분되고 Base64 URL 인코딩 됩니다

*[jwt-cli 유틸](https://github.com/mike-engel/jwt-cli)을 사용하여 다음 JWT 토큰을 디코딩 해봅시다*
```bash
## jwt-cli 설치
brew install mike-engel/jwt-cli/jwt-cli

## 확인
jwt help
```

 [*jwt 샘플*, ch9/enduser/user.jwt](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/enduser/user.jwt)

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IkNVLUFESkpFYkg5YlhsMHRwc1FXWXVvNEV3bGt4RlVIYmVKNGNra2FrQ00iLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ3NDUxNDUwMzgsImdyb3VwIjoidXNlciIsImlhdCI6MTU5MTU0NTAzOCwiaXNzIjoiYXV0aEBpc3Rpb2luYWN0aW9uLmlvIiwic3ViIjoiOWI3OTJiNTYtN2RmYS00ZTRiLWE4M2YtZTIwNjc5MTE1ZDc5In0.jNDoRx7SNm8b1xMmPaOEMVgwdnTmXJwD5jjCH9wcGsLisbZGcR6chkirWy1BVzYEQDTf8pDJpY2C3H-aXN3IlAcQ1UqVe5lShIjCMIFTthat3OuNgu-a91csGz6qtQITxsOpMcBinlTYRsUOICcD7UZcLugxK4bpOECohHoEhuASHzlH-FYESDB-JYrxmwXj4xoZ_jIsdpuqz_VYhWp8e0phDNJbB6AHOI3m7OHCsGNcw9Z0cks1cJrgB8JNjRApr9XTNBoEC564PX2ZdzciI9BHoOFAKx4mWWEqW08LDMSZIN5Ui9ppwReSV2ncQOazdStS65T43bZJwgJiIocSCg
```

*jwt 샘플 디코딩*
```bash
cat ch9/enduser/user.jwt | jwt decode -

Token header
------------
{
  "typ": "JWT",
  "alg": "RS256",
  "kid": "CU-ADJJEbH9bXl0tpsQWYuo4EwlkxFUHbeJ4ckkakCM"
}

Token claims
------------
{
  "exp": 4745145038,  #❶ expiration time
  "group": "user", #❷ "group" claim
  "iat": 1591545038, #❸ issue time
  "iss": "auth@istioinaction.io", #❹ token issuer
  "sub": "9b792b56-7dfa-4e4b-a83f-e20679115d79" #❺ subject of the token
}
```
앞서 설명드린대로 `claim`에는 `subject` 정보들이 포함돼 있습니다  
`claim` 정보를 통해 서비스가 클라이언트를 식별하고 인가를 할 것인지 결정할 수 있게 됩니다 

예를 들면, 위의 토큰에서 `sub` 는  "user" `group`에 속해 있습니다.
서비스에서는 이 정보를 토대로 해서 `sub`의 접근 레벨을 결정할 수 있는데요.

이러한 `claim` 정보를 신뢰하기 위해서는 토큰 검증이 필요합니다. 

### JWT 의 발급과 검증

*인증서버, Authentication Server*
- 인증서버는 “토큰 서명”을 위한 `private key` 와 “토큰 검증”을 위한 `public key`를 가지고 있음
- 인증서버에서 `private key` 로 서명한 JWT (JSON Web Token) 을 발급
- 인증서버의 `public key`는 JWKS (JSON Web Key Set) 형태의 HTTP 엔드포인트로 제공
- 서비스는 인증서버에서 발급된 JWT 를 검증하기 위해 필요한 `public key`를 JWKS 에서 찾습니다
- `public key`로 JWT 서명을 복호화 하여 얻은 해시값과 JWT 토큰 데이터의 해시값을 비교하여
- 해시값이 동일할 경우 토큰 `claim`에 변조가 없었음을 보장하므로 신뢰할 수 있습니다  
  ![스크린샷 2023-02-12 오후 2.52.27.png](/docs/assets/img/istio-in-action/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2023-02-12_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%2592%25E1%2585%25AE_2.52.27.png)

*인증서버 구축 방식*
1. 애플리케이션 백엔드 프레임웍 개발
2. 인증 서비스 구축 예) OpenIAM, Keycloak.
3. IaaS, Identity-as-a-Service 솔루션 연동 예) Auth0, Okta, …

## 9.4.2 End-user 인증/인가 처리 - Ingress Gateway 

- Istio 워크로드는 JWT 인증/인가를 설정 할 수 있음
- End-user 는 인증 프로바이더로 부터 인증되어 토큰을 발급받은 유저를 의미합니다
- End-user 의 인가는 워크로드의 어느 레벨에서나 수행할 수 있지만 
- 일반적으로는 Ingress Gateway 단에서 수행 되는데요. 
  - 이는 잘못된 요청을 미리 거부함으로써
  - 후속 서비스에서 사고로 정보가 유출되거나 
  - 악의적인 사용자가 "Replay 공격"을 할 수 없도록 
  - 앞 단에서 미리 JWT의 민감정보를 처리하기 위함입니다

### 실습 환경

첫째, 👉🏻 *먼저, “[실습 초기화](/docs/istio-in-action/Istio-ch9-securing-1-overview#실습-초기화){:target="_black"}” 후 진행해 주세요*  
둘째, 실습 환경 구성하기

```bash
## 실습 코드 경로에서 실행합니다
# cd book-source-code

## webapp
kubectl apply -f services/catalog/kubernetes/catalog.yaml \
-n istioinaction

## catalog
kubectl apply -f services/webapp/kubernetes/webapp.yaml \
-n istioinaction
```

Gateway, VirtualService 설정 적용 : [ch9/enduser/ingress-gw-for-webapp.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/enduser/ingress-gw-for-webapp.yaml)

```bash
kubectl apply -f -<<END
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: webapp-gateway
  namespace: istioinaction
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: webapp-virtualservice
  namespace: istioinaction
spec:
  hosts:
  - "webapp.istioinaction.io"
  gateways:
  - webapp-gateway
  http:
  - route:
    - destination:
        host: webapp
        port:
          number: 80
END
```

## 9.4.3 RequestAuthentication - JWT 검증 

*RequestAuthentication*
- JWT 토큰을 검증합니다
- 유효한 토큰으로 부터 `claim` 을 추출합니다 
- 인가 정책에서 사용하기 위해 `claim` 을 `filter metadata`로 저장합니다

*filter metadata*
- 서비스 프록시에서 요청 필터링 시 사용가능한 key/value 집합 
- Istio 사용자에게 이것은 대부분 구현 세부 사항입니다 

예를 들어, "group: admin" `claim`을 포함한 요청이 검증되면  
`filter metadata` 로 저장이 되고 인가 정책에 사용됩니다

End-user 요청에 따라 아래 3가지 경우가 발생할 수 있습니다
- "유효한 토큰" ~ 요청이 허용되고 해당 요청의 `claim`은 `filter metadata` 형태로 정책에 제공됩니다 
- "유효하지 않은 토큰" ~ 요청은 거부됩니다
- "토큰 없음" ~ 요청은 허용하지만 ID를 식별할 수 없고 `filter metadata`로 저장할 정보, 즉 `claim`이 없습니다

정리해 보면, 요청에 JWT 토큰이 있고 없고의 차이는 
- 토큰 있음 : `RequestAuthentication` 필터로 요청이 검증되고 `claims` 을 커넥션의 `filter metadata` 에 저장합니다
- 토큰 없음 : 커넥션의 `filter metadata`에 저장할 `claim`이 없습니다

여기서 중요한 암묵적인 세부사항은 `RequestAuthentication`은 "인가를 강제하지 않는다"는 것입니다  
토큰 검증과 `claim` 추출을 통해 인증의 유효성을 검증하고 인가에서 활용할 정보를 저장하는 역할을 하는 것이죠      
즉, 여전히 `AuthorizationPolicy` 가 필요합니다

지금부터 RequestAuthentication 을 만들고 앞에서 언급한 케이스들에 대한 실습을 진행해 보겠습니다.

### RequestAuthentication 만들기

다음은 `istio-ingressgateway`에 적용할 `RequestAuthentication` 입니다  
`istio-ingressgateway`에서 "auth@istioinaction.io"가 발급한 토큰을 검증하도록 설정합니다

```bash
kubectl apply -f -<<END
apiVersion: "security.istio.io/v1beta1"
kind: "RequestAuthentication"
metadata:
  name: "jwt-token-request-authn"
  namespace: istio-system           # ❶ 적용할 네임스페이스
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  jwtRules:
  - issuer: "auth@istioinaction.io" # ❷ 발급자
    jwks: |                         # ❸ 검증용 pubkey
      { "keys":[ {"e":"AQAB","kid":"CU-ADJJEbH9bXl0tpsQWYuo4EwlkxFUHbeJ4ckkakCM","kty":"RSA","n":"zl9VRDbmVvyXNdyoGJ5uhuTSRA2653KHEi3XqITfJISvedYHVNGoZZxUCoiSEumxqrPY_Du7IMKzmT4bAuPnEalbY8rafuJNXnxVmqjTrQovPIerkGW5h59iUXIz6vCznO7F61RvJsUEyw5X291-3Z3r-9RcQD9sYy7-8fTNmcXcdG_nNgYCnduZUJ3vFVhmQCwHFG1idwni8PJo9NH6aTZ3mN730S6Y1g_lJfObju7lwYWT8j2Sjrwt6EES55oGimkZHzktKjDYjRx1rN4dJ5PR5zhlQ4kORWg1PtllWy1s5TSpOUv84OPjEohEoOWH0-g238zIOYA83gozgbJfmQ"}]}
END
```
- `auth@istioinaction.io` 에서 발급된 토큰을 허용합니다
- `jwks` 항목에 "auth@istioinaction.io" `issuer` 가 발급한 토큰을 복호화할 수 있는 public key 를 포함합니다 

### 유효한 토큰으로 요청 보내기

정상적인 JWT 토큰으로 `istio-ingressgateway`에 요청을 보내 봅시다  
아래와 같이 [유저토큰](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/enduser/user.jwt){:target="_blank"}
을 헤더에 설정하여 보냅니다. (응답으로 200 OK 가 나오면 됩니다)

```bash
USER_TOKEN=$(< ch9/enduser/user.jwt); \
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $USER_TOKEN" \
     -sSl -o /dev/null -w "%{http_code}" localhost/api/catalog

200
```

* 200 응답을 리턴합니다. ("요청"이 성공합니다)

아무 `AuthorizationPolicy`이 설정되지 않은 경우 정책의 기본값은 `ALLOW` 이므로 요청이 "인가" 됩니다  

### 유효하지 않은 토큰으로 요청 보내기

이번에는 잘못된 발급처(`issuer`)로 설정된 JWT 토큰으로 요청을 보내 보겠습니다  
앞서`RequestAuthentication`의 발급처는 `auth@istioinaction.io` 입니다  
아래, 토큰은 발급처가 "old-auth@istioinaction.io" 임을 확인합니다
```bash
cat ch9/enduser/not-configured-issuer.jwt | jwt decode -

Token header
------------
{
  "typ": "JWT",
  "alg": "RS256",
  "kid": "CU-ADJJEbH9bXl0tpsQWYuo4EwlkxFUHbeJ4ckkakCM"
}

Token claims
------------
{
  "exp": 4745151548,
  "group": "user",
  "iat": 1591551548,
  "iss": "old-auth@istioinaction.io",
  "sub": "79d7506c-b617-46d1-bc1f-f511b5d30ab0"
}
```

예상대로, 요청을 보내면 실패합니다

```bash
WRONG_ISSUER=$(< ch9/enduser/not-configured-issuer.jwt); \
curl -H "Host: webapp.istioinaction.io" \
     -H "Authorization: Bearer $WRONG_ISSUER" \
     -sSL localhost/api/catalog

Jwt issuer is not configured
```

토큰의 issuer가 `old-auth@istioinaction.io` 로 `RequestAuthentication` 에 설정한 
jwtRules 의 issuer, jwks 와 매칭되지 않기 때문에 인증에 실패합니다 

### 토큰 없이 보낸 요청이 성공함 

이번에는 토큰 없이 호출해 보겠습니다.

```bash
curl -H "Host: webapp.istioinaction.io" \
-sSl -o /dev/null -w "%{http_code}\n" localhost/api/catalog

200
```

아무 토큰을 설정하지 않았음에도 200 OK 응답이 나옵니다. 

*Why ?*
- 다양한 서비스 상황에서 토큰 없는 요청이 발생할 수 있기 때문에
- Istio 의 기본설정은 토큰 없는 요청을 허용합니다

다음 실습에서 토큰 없는(미인증, unauthenticated) 요청을 DENY 해보겠습니다 

### 토큰 없는 요청 거부하기 

*AuthorizationPolicy*

```bash
kubectl apply -f -<<END
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: app-gw-requires-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]         # ❶
    to:
    - operation:
        hosts: ["webapp.istioinaction.io"]  # ❷
END
```
- ❶  요청 주체에 대한 값이 하나도 없음
- ❷  대상 호스트 "webapp.istioinaction.io" 

이번에도 토큰 없이 호출해 보세요.

```bash
curl -H "Host: webapp.istioinaction.io" \
-sSl -o /dev/null -w "%{http_code}\n" localhost/api/catalog

403
```

- 이전과 달리 403 에러가 납니다.
- `AuthorizationPolicy` 로 토큰이 없는 요청을 금지 `DENY` 하였기 때문입니다
- 따라서, 이제는 유효한 토큰으로 요청하여 인증된 End-user 만 webapp 에 접근할 수 있습니다.

이번에는 유저별로 다른 액세스 레벨을 설정해 보겠습니다. 

### JWT Claim 에 따른 접근 레벨 적용  

이번 실습에서는
- 일반 사용자에게는 읽기만 허용하고 쓰기나 수정은 막고
- 관리자에게는 모든 접근을 허용해 봅시다

*실습준비*
- [일반 사용자 토큰](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/enduser/user.jwt)  ~ `group: user` 클레임을 가집니다
    
    ```bash
    cat ch9/enduser/user.jwt | jwt decode -
    
    Token header
    ------------
    {
      "typ": "JWT",
      "alg": "RS256",
      "kid": "CU-ADJJEbH9bXl0tpsQWYuo4EwlkxFUHbeJ4ckkakCM"
    }
    
    Token claims
    ------------
    {
      "exp": 4745145038,
      "group": "user",
      "iat": 1591545038,
      "iss": "auth@istioinaction.io",
      "sub": "9b792b56-7dfa-4e4b-a83f-e20679115d79"
    }
    ```
    
- [관리자 토큰](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch9/enduser/admin.jwt)  ~ `group: admin` 클레임을 가집니다
    
    ```bash
    cat ch9/enduser/admin.jwt | jwt decode -
    
    Token header
    ------------
    {
      "typ": "JWT",
      "alg": "RS256",
      "kid": "CU-ADJJEbH9bXl0tpsQWYuo4EwlkxFUHbeJ4ckkakCM"
    }
    
    Token claims
    ------------
    {
      "exp": 4745145071,
      "group": "admin",
      "iat": 1591545071,
      "iss": "auth@istioinaction.io",
      "sub": "218d3fb9-4628-4d20-943c-124281c80e7b"
    }
    ```

*AuthorizationPolicy 차등 적용*
- 일반 사용자용 AuthorizationPolicy 를 설정합니다.
    
    ```bash
    kubectl apply -f -<<END
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: allow-all-with-jwt-to-webapp
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
      - from:
        - source:
            requestPrincipals: ["auth@istioinaction.io/*"] # ❶
        to:
        - operation:
            hosts: ["webapp.istioinaction.io"]
            methods: ["GET"]
    END
    ```
    - ❶ 요청 주체 `requestPrincipals` 를 식별하기 위한 필터 조건 
- 관리자용 AuthorizationPolicy 를 설정합니다.
    ```bash
    kubectl apply -f -<<END
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "allow-mesh-all-ops-admin"
      namespace: istio-system
    spec:
      selector:
        matchLabels:
          app: istio-ingressgateway
      action: ALLOW
      rules:
        - from:
          - source:
              requestPrincipals: ["auth@istioinaction.io/*"]
          when:
          - key: request.auth.claims[group]
            values: ["admin"]  # ❶
    END
    ```
    - ❶ Allows only requests containing this claim

*테스트*

- 일반유저 : [GET]과 [POST] 호출 결과를 확인합니다
    
    ```bash
    ## [GET] 호출
    USER_TOKEN=$(< ch9/enduser/user.jwt);
    curl -H "Host: webapp.istioinaction.io" \
         -H "Authorization: Bearer $USER_TOKEN" \
         -sSl -o /dev/null -w "%{http_code}\n" localhost/api/catalog
    
    200
    ```
    
    ```bash
    ## [POST] 호출
    USER_TOKEN=$(< ch9/enduser/user.jwt);
    curl -H "Host: webapp.istioinaction.io" \
         -H "Authorization: Bearer $USER_TOKEN" \
         -XPOST localhost/api/catalog \
         --data '{"id": 2, "name": "Shoes", "price": "84.00"}'
    
    RBAC: access denied
    ```
    
- 관리자
    
    ```bash
    ADMIN_TOKEN=$(< ch9/enduser/admin.jwt);
       curl -H "Host: webapp.istioinaction.io" \
         -H "Authorization: Bearer $ADMIN_TOKEN" \
         -XPOST -sSl -w "%{http_code}\n" localhost/api/catalog/items \
         --data '{"id": 2, "name": "Shoes", "price": "84.00"}'
    
    200
    ```

<br />

👉🏻 *[다음편 보기](/docs/istio-in-action/Istio-ch9-securing-5-external_authz)*