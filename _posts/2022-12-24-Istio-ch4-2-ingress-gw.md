---
title: Istio Ingress Gateway (2)  
version: v1.0  
description: istio in action 4장 실습2  
date: 2022-12-24 22:00:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: false
---
Istio의 Ingress Gateway 실습 두번째 파트입니다.(실습1에서 이어집니다)

<!--more-->

👉🏻 Istio-ch4-1 에서 이어집니다.

## Securing gateway traffic

### HTTPS 통신하기

Serect 생성 - 서버 인증서 저장

```bash
kubectl create -n istio-system secret tls webapp-credential \
--key ch4/certs/3_application/private/webapp.istioinaction.io.key.pem \
--cert ch4/certs/3_application/certs/webapp.istioinaction.io.cert.pem

## Secret 생성 확인
# kubectl get secret webapp-credential -n istio-system

NAME                TYPE                DATA   AGE
webapp-credential   kubernetes.io/tls   2      47s
```

(참고) Secret에 저장된 인증서를 확인해 봐요

- Issuer 는 발급처(CA)를 의미합니다.
- Validity 는 인증서 유효기간 입니다.
- Subject 는 발급받은 서버정보입니다.

```bash
## 인증서 확인
kubectl get secret webapp-credential -n istio-system -o yaml | \
grep tls.crt | awk '{print $2}' | base64 -d | \
openssl x509 -text -noout | grep Issuer -A 4

Issuer: C=US, ST=Denial, O=Dis, CN=webapp.istioinaction.io
Validity
  Not Before: Jul  4 12:49:32 2021 GMT
  Not After : Jun 29 12:49:32 2041 GMT
Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=webapp.istioinaction.io
..
```

서버 인증서(Secret) 적용 (Gateway)

```yaml
# vi ch4/coolstore-gw-tls.yaml

apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
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
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: webapp-credential
    hosts:
    - "webapp.istioinaction.io"
```

```bash
kubectl apply -f ch4/coolstore-gw-tls.yaml -n istioinaction
```

호출테스트 1

```bash
curl -v -H "Host: webapp.istioinaction.io" https://127.0.0.1/api/catalog

*   Trying 127.0.0.1:443...
* Connected to localhost (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: /etc/ssl/cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to 127.0.0.1:443
* Closing connection 0
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to 127.0.0.1:443
```

⇒  (호출 실패) 원인: (기본 인증서 경로에) 인증서 없음. 사설인증서 이므로 “사설CA 인증서(체인)” 필요

호출테스트 2 - “사설 CA인증서” 경로 추가

- 인증서 참고: [ch4/certs/2_intermeidate/certs/ca-chain.cert.pem](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch4/certs/2_intermediate/certs/ca-chain.cert.pem)

```bash
curl -v -H "Host: webapp.istioinaction.io" https://127.0.0.1:443/api/catalog \
--cacert ch4/certs/2_intermediate/certs/ca-chain.cert.pem

*   Trying 127.0.0.1:443...
* Connected to 127.0.0.1 (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: ch4/certs/2_intermediate/certs/ca-chain.cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to 127.0.0.1:443
* Closing connection 0
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to 127.0.0.1:443
```

⇒  (호출 실패) 원인: 인증실패. 서버인증서가 발급된(issued) 도메인 “webapp.istioinaction.io”로 호출하지 않음 (127.0.0.1로 호출함)

호출테스트 3 (성공)

> “webapp.istioinaction.io” 도메인으로 호출 시  resolve를 127.0.0.1로 강제하도록 resolve 옵션 사용
> 

```bash
curl -v https://webapp.istioinaction.io/api/catalog \
--cacert ch4/certs/2_intermediate/certs/ca-chain.cert.pem \
--resolve webapp.istioinaction.io:443:127.0.0.1

* Added webapp.istioinaction.io:443:127.0.0.1 to DNS cache
* Hostname webapp.istioinaction.io was found in DNS cache
*   Trying 127.0.0.1:443...
* Connected to webapp.istioinaction.io (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: ch4/certs/2_intermediate/certs/ca-chain.cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=webapp.istioinaction.io
*  start date: Jul  4 12:49:32 2021 GMT
*  expire date: Jun 29 12:49:32 2041 GMT
*  common name: webapp.istioinaction.io (matched)
*  issuer: C=US; ST=Denial; O=Dis; CN=webapp.istioinaction.io
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* h2h3 [:method: GET]
* h2h3 [:path: /api/catalog]
* h2h3 [:scheme: https]
* h2h3 [:authority: webapp.istioinaction.io]
* h2h3 [user-agent: curl/7.84.0]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x14200bc00)
> GET /api/catalog HTTP/2
> Host: webapp.istioinaction.io
> user-agent: curl/7.84.0
> accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< content-length: 357
< content-type: application/json; charset=utf-8
< date: Sat, 24 Dec 2022 02:16:48 GMT
< x-envoy-upstream-service-time: 13
< server: istio-envoy
<
* Connection #0 to host webapp.istioinaction.io left intact
[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

### HTTPS 강제하기

http 요청을 받더라도 https 로 강제 리다이렉트 설정 (우)

![스크린샷 2022-12-24 오전 11.27.42.png](/assets/img/Istio-ch4-2%20dec7b2ab8c7c41409925bb16789bec78/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-24_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.27.42.png)

```bash
kubectl apply -f ch4/coolstore-gw-tls-redirect.yaml -n istioinaction
```

- 참고: [ch4/coolstore-gw-tls-redirect.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch4/coolstore-gw-tls-redirect.yaml)

호출테스트 - http로 호출하더라도 https로 리다이렉트됨

```bash
curl -v -H "Host: webapp.istioinaction.io" http://127.0.0.1/api/catalog

*   Trying 127.0.0.1:80...
* Connected to localhost (127.0.0.1) port 80 (#0)
> GET /api/catalog HTTP/1.1
> Host: webapp.istioinaction.io
> User-Agent: curl/7.84.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 301 Moved Permanently
< location: https://webapp.istioinaction.io/api/catalog
< date: Sat, 24 Dec 2022 02:31:40 GMT
< server: istio-envoy
< content-length: 0
<
* Connection #0 to host localhost left intact
```

### Mutual TLS

상호(mutual) 인증. 서버만 인증하는 것이 아니라 클라이언트도 인증을 받는다

![Basic model of how mTLS is established between a client and sever (Istio IN ACTION, p.95)](/assets/img/Istio-ch4-2%20dec7b2ab8c7c41409925bb16789bec78/mutual-tls.png)

Basic model of how mTLS is established between a client and sever (Istio IN ACTION, p.95)

Secret (클라이언트 인증서) 생성 (*전체 복붙*)

```bash
kubectl create -n istio-system secret \
generic webapp-credential-mtls --from-file=tls.key=\
ch4/certs/3_application/private/webapp.istioinaction.io.key.pem \
--from-file=tls.crt=\
ch4/certs/3_application/certs/webapp.istioinaction.io.cert.pem \
--from-file=ca.crt=\
ch4/certs/2_intermediate/certs/ca-chain.cert.pem
```

Gateway - Secret (클라이언트 인증서) 적용 (우)

![스크린샷 2022-12-24 오전 11.44.17.png](/assets/img/Istio-ch4-2%20dec7b2ab8c7c41409925bb16789bec78/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-24_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.44.17.png)

```bash
kubectl apply -f ch4/coolstore-gw-mtls.yaml -n istioinaction
```

참고: [ch4/coolstore-gw-mtls.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch4/coolstore-gw-mtls.yaml)

호출테스트1

```bash
curl -v https://webapp.istioinaction.io/api/catalog \
--cacert ch4/certs/2_intermediate/certs/ca-chain.cert.pem \
--resolve webapp.istioinaction.io:443:127.0.0.1

* Added webapp.istioinaction.io:443:127.0.0.1 to DNS cache
* Hostname webapp.istioinaction.io was found in DNS cache
*   Trying 127.0.0.1:443...
* Connected to webapp.istioinaction.io (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: ch4/certs/2_intermediate/certs/ca-chain.cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Request CERT (13):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Certificate (11):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=webapp.istioinaction.io
*  start date: Jul  4 12:49:32 2021 GMT
*  expire date: Jun 29 12:49:32 2041 GMT
*  common name: webapp.istioinaction.io (matched)
*  issuer: C=US; ST=Denial; O=Dis; CN=webapp.istioinaction.io
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* h2h3 [:method: GET]
* h2h3 [:path: /api/catalog]
* h2h3 [:scheme: https]
* h2h3 [:authority: webapp.istioinaction.io:443]
* h2h3 [user-agent: curl/7.84.0]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x12980ec00)
> GET /api/catalog HTTP/2
> Host: webapp.istioinaction.io
> user-agent: curl/7.84.0
> accept: */*
>
* LibreSSL SSL_read: error:1404C45C:SSL routines:ST_OK:reason(1116), errno 0
* Failed receiving HTTP2 data
* LibreSSL SSL_write: SSL_ERROR_SYSCALL, errno 0
* Failed sending HTTP2 data
* Connection #0 to host webapp.istioinaction.io left intact
curl: (56) LibreSSL SSL_read: error:1404C45C:SSL routines:ST_OK:reason(1116), errno 0
```

⇒ (호출실패) 클라이언트 인증서 없음

호출테스트2 (성공) - 클라이언트 인증서/키 옵션추가 

```bash
curl -v https://webapp.istioinaction.io/api/catalog \
--cacert ch4/certs/2_intermediate/certs/ca-chain.cert.pem \
--resolve webapp.istioinaction.io:443:127.0.0.1 \
--cert ch4/certs/4_client/certs/webapp.istioinaction.io.cert.pem \
--key ch4/certs/4_client/private/webapp.istioinaction.io.key.pem

* Added webapp.istioinaction.io:443:127.0.0.1 to DNS cache
* Hostname webapp.istioinaction.io was found in DNS cache
*   Trying 127.0.0.1:443...
* Connected to webapp.istioinaction.io (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: ch4/certs/2_intermediate/certs/ca-chain.cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Request CERT (13):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Certificate (11):
* (304) (OUT), TLS handshake, CERT verify (15):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=webapp.istioinaction.io
*  start date: Jul  4 12:49:32 2021 GMT
*  expire date: Jun 29 12:49:32 2041 GMT
*  common name: webapp.istioinaction.io (matched)
*  issuer: C=US; ST=Denial; O=Dis; CN=webapp.istioinaction.io
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* h2h3 [:method: GET]
* h2h3 [:path: /api/catalog]
* h2h3 [:scheme: https]
* h2h3 [:authority: webapp.istioinaction.io]
* h2h3 [user-agent: curl/7.84.0]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x15400bc00)
> GET /api/catalog HTTP/2
> Host: webapp.istioinaction.io
> user-agent: curl/7.84.0
> accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< content-length: 357
< content-type: application/json; charset=utf-8
< date: Sat, 24 Dec 2022 02:51:48 GMT
< x-envoy-upstream-service-time: 6
< server: istio-envoy
<
* Connection #0 to host webapp.istioinaction.io left intact
[{"id":1,"color":"amber","department":"Eyewear","name":"Elinor Glasses","price":"282.00"},{"id":2,"color":"cyan","department":"Clothing","name":"Atlas Shirt","price":"127.00"},{"id":3,"color":"teal","department":"Clothing","name":"Small Metal Shoes","price":"232.00"},{"id":4,"color":"red","department":"Watches","name":"Red Dragon Watch","price":"232.00"}]
```

### multi TLS

여러 Virtual host의 TLS 인증를 처리해 보자. 

Secret 추가 - 서버인증서, catalog-credential

```bash
kubectl create -n istio-system secret tls catalog-credential \
--key ch4/certs2/3_application/private/catalog.istioinaction.io.key.pem \
--cert ch4/certs2/3_application/certs/catalog.istioinaction.io.cert.pem
```

(참고) 인증서(catalog-credential) 확인

```bash
kubectl get secret -n istio-system catalog-credential -o yaml | \
grep tls.crt | awk '{print $2}' | base64 -d | \
openssl x509 -text -noout | grep Issuer -A 4

Issuer: C=US, ST=Denial, O=Dis, CN=catalog.istioinaction.io
Validity
    Not Before: Jul  4 13:30:38 2021 GMT
    Not After : Jun 29 13:30:38 2041 GMT
Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=catalog.istioinaction.io
```

Gateway 수정 - Virtual host (catalog.istioinaction.io) 와 TLS (Secret, catalog-credential) 추가하기

![스크린샷 2022-12-24 오전 11.58.07.png](/assets/img/Istio-ch4-2%20dec7b2ab8c7c41409925bb16789bec78/%25E1%2584%2589%25E1%2585%25B3%25E1%2584%258F%25E1%2585%25B3%25E1%2584%2585%25E1%2585%25B5%25E1%2586%25AB%25E1%2584%2589%25E1%2585%25A3%25E1%2586%25BA_2022-12-24_%25E1%2584%258B%25E1%2585%25A9%25E1%2584%258C%25E1%2585%25A5%25E1%2586%25AB_11.58.07.png)

```bash
kubectl apply -f ch4/coolstore-gw-multi-tls.yaml -n istioinaction
```

참고: [ch4/coolstore-gw-multi-tls.yaml](https://raw.githubusercontent.com/istioinaction/book-source-code/master/ch4/coolstore-gw-multi-tls.yaml)

VirtualService 추가 - catalog.istioinaction.io

```yaml
# vi ch4/catalog-vs.yaml

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - coolstore-gateway
  http:
  - route:
    - destination:
        host: catalog
        port:
          number: 80
```

```bash
kubectl apply -f ch4/catalog-vs.yaml -n istioinaction
```

```bash
# kubectl get vs -n istioinaction

NAME                 GATEWAYS                HOSTS                          AGE
catalog-vs-from-gw   ["coolstore-gateway"]   ["catalog.istioinaction.io"]   44s
webapp-vs-from-gw    ["coolstore-gateway"]   ["webapp.istioinaction.io"]    2d15h
```

호출테스트 1 - webapp.istioinaction.io

```bash
curl -v https://webapp.istioinaction.io/api/catalog \
--cacert ch4/certs/2_intermediate/certs/ca-chain.cert.pem \
--resolve webapp.istioinaction.io:443:127.0.0.1
```

호출테스트 2 - catalog.istioinaction.io (cacert 경로가 ch4/certs2/* 임에 유의)

```bash
curl -v https://catalog.istioinaction.io/items \
--cacert ch4/certs2/2_intermediate/certs/ca-chain.cert.pem \
--resolve catalog.istioinaction.io:443:127.0.0.1

* Added catalog.istioinaction.io:443:127.0.0.1 to DNS cache
* Hostname catalog.istioinaction.io was found in DNS cache
*   Trying 127.0.0.1:443...
* Connected to catalog.istioinaction.io (127.0.0.1) port 443 (#0)
* ALPN: offers h2
* ALPN: offers http/1.1
*  CAfile: ch4/certs2/2_intermediate/certs/ca-chain.cert.pem
*  CApath: none
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-CHACHA20-POLY1305-SHA256
* ALPN: server accepted h2
* Server certificate:
*  subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=catalog.istioinaction.io
*  start date: Jul  4 13:30:38 2021 GMT
*  expire date: Jun 29 13:30:38 2041 GMT
*  common name: catalog.istioinaction.io (matched)
*  issuer: C=US; ST=Denial; O=Dis; CN=catalog.istioinaction.io
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* h2h3 [:method: GET]
* h2h3 [:path: /items]
* h2h3 [:scheme: https]
* h2h3 [:authority: catalog.istioinaction.io]
* h2h3 [user-agent: curl/7.84.0]
* h2h3 [accept: */*]
* Using Stream ID: 1 (easy handle 0x15a00bc00)
> GET /items HTTP/2
> Host: catalog.istioinaction.io
> user-agent: curl/7.84.0
> accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< x-powered-by: Express
< vary: Origin, Accept-Encoding
< access-control-allow-credentials: true
< cache-control: no-cache
< pragma: no-cache
< expires: -1
< content-type: application/json; charset=utf-8
< content-length: 502
< etag: W/"1f6-ih2h+hDQ0yLLcKIlBvwkWbyQGK4"
< date: Sat, 24 Dec 2022 03:27:23 GMT
< x-envoy-upstream-service-time: 27
< server: istio-envoy
<
[
  {
    "id": 1,
    "color": "amber",
    "department": "Eyewear",
    "name": "Elinor Glasses",
    "price": "282.00"
  },
  {
    "id": 2,
    "color": "cyan",
    "department": "Clothing",
    "name": "Atlas Shirt",
    "price": "127.00"
  },
  {
    "id": 3,
    "color": "teal",
    "department": "Clothing",
    "name": "Small Metal Shoes",
    "price": "232.00"
  },
  {
    "id": 4,
    "color": "red",
    "department": "Watches",
    "name": "Red Dragon Watch",
    "price": "232.00"
  }
* Connection #0 to host catalog.istioinaction.io left intact
]
```