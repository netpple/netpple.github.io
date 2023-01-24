---
title: Istio 실습환경  
version: v1.0 
description: istio in action 실습환경 안내  
date: 2023-01-07 21:00:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: true
---
실습환경은 “깔았다/지웠다” 를 반복할 수 있도록 설명합니다.  
docker 는 설치돼 있다고 가정합니다. 

<!--more-->

## minikube

### 설치

공식: [https://minikube.sigs.k8s.io/docs/start/](https://minikube.sigs.k8s.io/docs/start/) 

mac 환경 기준

```bash
brew install minikube
```

### K8s

최초 설치

```bash
## k8s
minikube start

## addon
minikube addons enable ingress

## tunnel for LoadBalancer
sudo minikube tunnel
```

- *addons 목록 참고*
    
    ```bash
    minikube addons list
    ```
    

중지 / 재기동

```bash
## 중지 
minikube stop

## 기동 
minikube start

## 터널링
minikube tunnel

## 확인 - 인그레스 포트
minikube service list -n istio-system
|---------------|----------------------|-------------------
|   NAMESPACE   |         NAME         |    TARGET PORT    
|---------------|----------------------|-------------------
..
| istio-system  | istio-ingressgateway | status-port/15021 
|               |                      | http2/80          
|               |                      | https/443         
..
```

삭제

```bash
minikube delete
```

## Istio

### Istioctl

istio CLI 도구를 설치합니다. 

```bash
brew install istioctl
```

### Istio

K8s 에 istio를 설치합니다. 

```bash
## 설치가부 확인
# istioctl x precheck

istioctl install --set profile=demo -y

## 설치 확인
kubectl get all -n istio-system
```

### addon

```bash
# istioctl version
client version: 1.16.1
control plane version: 1.16.1
data plane version: 1.16.1 (2 proxies)

## 
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.16.1 sh -

cd istio-1.16.1

kubectl apply -f ./samples/addons
```

## 실습코드

```bash

git clone https://github.com/istioinaction/book-source-code.git
cd book-source-code
```

### 실습 네임스페이스

```bash
kubectl create ns istioinaction

kubectl label namespace istioinaction istio-injection=enabled

kubectl get ns istioinaction --show-labels
```