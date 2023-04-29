---
title: Istio 실습환경  
version: v1.1 
description: istio in action 실습환경 안내  
date: 2023-04-25 19:45:00 +09:00  
layout: post  
toc: 1 
categories: network  
comment: true
label: istio in action
rightpanel: true
histories:
- date: 2023-04-25 19:45:00 +09:00
  description: istio 1.17.2 적용  
- date: 2023-01-07 21:00:00 +09:00
  description: 최초 등록
badges:
- type: info  
  tag: 교육
---
실습환경은 “깔았다/지웠다” 를 반복할 수 있도록 설명합니다.  
docker 는 설치돼 있다고 가정합니다. 

<!--more-->
최근 업데이트 : 23/04/25 - istio-1.17.2 적용

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
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.17.2 sh -

cd istio-1.17.2

## .bash_profile 에 설정해 주세요
export PATH=$PWD/bin:$PATH
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
cd istio-1.17.2

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