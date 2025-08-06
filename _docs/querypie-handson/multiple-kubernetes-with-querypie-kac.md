---
title: [핸즈온, 초중급] 쿠버네티스, 멀티클러스터 어떻게 관리하세요? (1편)
version: v0.1
date: 2025-08-06 18:50:00 +09:00
description: 실전 쿠버네티스 멀티클러스터 환경에서 사용할 수 있는 효과적인 인증과 접근 콘트롤 방법을 알려드립니다. 
label: 쿼리파이 핸즈온
comments: true
image: https://netpple.github.io/docs/assets/img/make-container-without-docker-intro-1.png
histories:
- date: 2025-08-06 18:50:00 +09:00
  description: 최초 등록
rightpanel: false
---

# [핸즈온, 초중급] 쿠버네티스, 멀티클러스터 어떻게 관리하세요? (1편)

## 들어가며

클라우드 네이티브 환경에서 여러 쿠버네티스 클러스터를 운영하는 것은 이제 선택이 아닌 필수가 되었습니다. 저 역시 이전 직장에서 수년간 대규모 서비스를 운영하며 이러한 현실을 몸소 체험했습니다.

수백만에서 수천만 사용자가 이용하는 서비스를 쿠버네티스 기반으로 운영하면서, EKS, AKS, GKE와 같은 퍼블릭 클라우드 서비스부터 온프레미스 환경까지 아우르는 복잡한 멀티클러스터 환경을 안정적으로 관리해야 하는 도전에 직면했습니다.

### **대규모 프로덕션 환경에서 마주한 현실적인 어려움들:**

**높은 가용성이 요구되는 서비스의 운영 복잡성**
- 24시간 무중단 서비스를 지원하는 다수의 클러스터 관리
- 트래픽 급증 상황에서의 신속한 스케일링과 동시에 보안 정책 유지
- 개발팀, SRE팀, 인프라팀 간 역할 분담과 협업 프로세스의 복잡성

**접근 제어의 현실적 한계**
- 다수의 개발자와 운영자가 필요에 따라 여러 클러스터에 접근해야 하는 상황
- Kubeconfig 파일 공유 과정에서 발생하는 보안 위험과 관리 복잡성
- 개발/스테이징/프로덕션 환경 간 컨텍스트 혼동으로 인한 아찔한 순간들
- 서비스 특성상 높은 가용성이 요구되는 환경에서의 권한 관리 딜레마

**멀티클러스터 운영의 기술적 복잡성**
- 워크로드 특성에 따른 동적 스케일링이 필요한 환경에서의 클러스터별 최적화
- 각 클러스터마다 다른 RBAC 정책으로 인한 일관성 부족과 운영 실수 위험
- 지역별, 환경별로 분산된 클러스터들의 인증서 만료 추적과 갱신 작업
- 새로운 기능 배포를 위한 클러스터 추가 시마다 반복되는 권한 설정 작업

**서비스 운영시 보안 감사 요구사항**
- 수많은 사용자의 클러스터 접근 기록을 추적해야 하는 필요성
- 서비스 장애 발생 시 빠른 원인 분석을 위한 상세한 감사 로그 요구
- 기업 보안 정책 및 규제 준수를 위한 일관된 접근 제어 정책 적용의 어려움

이러한 경험을 통해 멀티클러스터 환경에서의 접근 제어와 관리가 단순한 기술적 문제가 아니라, 서비스 안정성과 팀 생산성에 직접적인 영향을 미치는 핵심 운영 이슈임을 깨달았습니다.

이번 글에서는 **QueryPie**를 활용하여 실제 대규모 서비스 운영에서 겪었던 이와 같은 문제들을 체계적으로 해결하는 방법을 실습을 통해 살펴보겠습니다. [기존에 정리한 멀티클라우드 쿠버네티스 접근 제어 가이드](https://www.querypie.com/ko/resources/discover/blog/4/multi-cloud-kubernetes-access-control)에서 다룬 이론적 배경과 실무 경험을 결합하여, 실제 환경에서 바로 적용할 수 있는 구현 과정과 운영 노하우를 단계별로 공유하겠습니다.

## 실습 환경 구성 가이드

이번 실습에서는 쿠버네티스 멀티클러스터 환경을 로컬에서 구현하여 QueryPie의 핵심 기능들을 직접 체험해보겠습니다. 복잡한 클라우드 환경 없이도 로컬에서 충분히 실습이 가능하도록 구성했습니다.

### **사전 지식 요구사항**

다음 기술들에 대한 기본적인 이해가 있으면 도움이 되지만, 모르더라도 단계별 가이드를 따라 실습을 진행할 수 있습니다:

**권장 배경 지식:**
- 컨테이너 기술 (Docker) - 컨테이너 이미지와 실행 환경에 대한 기본 개념
- 쿠버네티스 기초 - Pod, Service, Namespace 등 기본 리소스 이해, kubectl 사용법

### **필수 준비사항**

실습 환경은 macOS ARM 기반(M시리즈)에서 검증되었으며, 다음 도구들이 필요합니다:

- **Docker Desktop (v2+)**: 쿠버네티스 클러스터를 컨테이너로 실행하기 위한 기반 환경
- **kubectl (v1.28+)**: 쿠버네티스 API 서버와 통신하여 클러스터를 관리하는 명령행 도구
- **Kind (v0.29.0+)**: 여러 개의 쿠버네티스 클러스터를 로컬에서 손쉽게 생성하고 관리할 수 있는 도구
- **QueryPie Community (v11.0.1+)**: DB / 서버 / K8s / Web 접근 제어 및 관리 기능을 제공하는 무료 버전

## QueryPie, 쿼리파이?

실습을 시작하기 전에 이번 핸즈온의 핵심 도구인 QueryPie에 대해 간략히 소개해드리겠습니다.

QueryPie는 "Query"와 "Pie"의 합성어로, 복잡한 IT 리소스 접근을 파이를 나누어 먹듯 쉽고 직관적으로 만들겠다는 철학에서 출발한 통합 접근 제어 플랫폼입니다.

실제로 멀티클러스터 쿠버네티스 환경에서 권한 관리와 접근 제어는 매우 복잡한 작업인데, QueryPie는 이러한 복잡성을 사용자 친화적인 인터페이스로 단순화하여 제공합니다.

### **엔터프라이즈급 보안 솔루션을 무료로**

QueryPie는 원래 대기업과 금융기관에서 사용하는 고가의 엔터프라이즈 보안 솔루션입니다. ISMS-P, CC (국정원 인증), ISO 27001/27017, SOC 2, PCI DSS, GDPR, HIPAA 등 다수의 국내 외 보안 인증을 획득하고, 수많은 기업에서 시스템의 접근 제어를 담당하고 있는 검증된 솔루션이죠.

[최근 출시된 QueryPie Community 버전](https://byline.network/2025/07/22-443/)을 통해 엔터프라이즈급 접근 제어 기능을 무료로 사용할 수 있게 되었습니다.

**무료 제공 범위:**
- 사용자: 5명 이하 팀에서 완전 무료
- 리소스: 데이터베이스, 서버, K8s 클러스터, 웹앱 개수 제한 없음
- 핵심 기능: 유료 엔터프라이즈 버전의 주요 기능들을 그대로 사용 가능

**엔터프라이즈 수준의 기능들:**
- 멀티클러스터 통합 관리 및 모니터링
- 세밀한 RBAC/ABAC 기반 권한 제어
- 실시간 감사 로깅 및 규제 준수 지원
- AI 지원 기능 - MCP 제공, AI 접근통제

## QueryPie Community 설치

1. 쿼리파이 설치스크립트 실행  
※ 맥 환경 지원을 위해 특별히 준비한 쿼리파이 버전이니 반드시 아래 스크립트로 설치해 주세요

```bash
bash <(curl -s https://raw.githubusercontent.com/querypie/tpm/refs/heads/main/aws-ami/scripts/setup.v2.sh) --install 11.0.1-beta
```

2. /etc/hosts 설정※ /etc/hosts에 아래 한줄을 추가해 주세요. 로컬 테스트 환경에서 QueryPie Proxy에 접근하기 위함입니다.

```bash
vi /etc/hosts

# 추가할 내용
127.0.0.1 customer.kac-proxy.domain
```

3. http://localhost:8000  
접속최초 접근 시, 라이센스 입력 화면
4. 라이선스 발급 신청  
 - https://www.querypie.com/ko/querypie/license/community/apply5. 
5. 라이선스 입력 (OR 업로드)    
![라이선스 입력 화면](/docs/assets/img/querypie-handson/image_01.png)

6. 로그인최초 로그인 (qp-admin/querypie) 후에 반드시 비밀번호 변경을 해야 합니다.
※ 변경한 비밀번호는 원활한 실습을 위해 기억해 주세요.  
♬ 쉽죠? 한방 설치 -> 라이센스 등록 -> 로그인 (설치완료!)  
참고) QueryPie 매뉴얼: https://docs.querypie.com/ko/querypie-manual/11.1.0/-16Kind   

## K8s 여러벌 설치
Kind에 대해서는 자세한 설명은 생략하겠습니다.  
※ 아래 AIHub가 설명해 준 내용으로 갈음할게요.  
![AIHub 설명 화면](/docs/assets/img/querypie-handson/image_02.png)  

1. Kind 설치
```bash
brew install kind
```

2. K8s 클러스터 설정

production과 develop 클러스터 설정 두 개를 만들어 보겠습니다.  
참고1) 6443 포트는 QueryPie에서 쓰기 때문에, 6444부터 씁니다.  
참고2) QueryPie 컨테이너와 로컬호스트를 경유해서 통신하기 위해서 "host.docker.internal" 도메인을 SAN에 추가해줍니다.

production-config.yaml
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster1
networking:
  apiServerPort: 6444
  podSubnet: "10.240.0.0/16"
  serviceSubnet: "10.96.0.0/12"
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      certSANs:
      - "host.docker.internal"
      - "localhost"
      - "127.0.0.1"
      - "cluster1-control-plane"
    etcd:
      local:
        serverCertSANs:
        - "host.docker.internal"
        - "localhost"
        - "127.0.0.1"
        peerCertSANs:
        - "host.docker.internal"
        - "localhost"
        - "127.0.0.1"
- role: worker
```

develop-config.yaml

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cluster2
networking:
  apiServerPort: 6445
  podSubnet: "10.241.0.0/16"
  serviceSubnet: "10.97.0.0/12"
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 8081
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      certSANs:
      - "host.docker.internal"
      - "localhost"
      - "127.0.0.1"
      - "cluster2-control-plane"
    etcd:
      local:
        serverCertSANs:
        - "host.docker.internal"
        - "localhost"
        - "127.0.0.1"
        peerCertSANs:
        - "host.docker.internal"
        - "localhost"
        - "127.0.0.1"
- role: worker
```

3. K8s 클러스터 생성  

production 클러스터
```bash
kind create cluster --config production-config.yaml
```

develop 클러스터
```bash
kind create cluster --config development-config.yaml
```

4. 클러스터 상태 확인# 생성된 클러스터 목록 확인

```bash
kind get clusters

# 도커 컨테이너 확인
docker ps

# kubectl 컨텍스트 확인
kubectl config get-contexts
```

## K8s 클러스터 등록

QueryPie에 K8s production, develop 클러스터를 등록해 봅시다.
1. QueryPie Admin Page 접속  
QueryPie 상단 메뉴 우측 "Go to Admin Page"를 클릭합니다.  
![Admin Page 접속](/docs/assets/img/querypie-handson/image_03.png)

2. Kubernetes > Clusters 메뉴  
Admin Page에서 Kubernetes > Clusters를 클릭합니다.  
![Kubernetes Clusters 메뉴](/docs/assets/img/querypie-handson/image_04.png)
3. Create ClusterCreate Cluster를 클릭합니다.  
![Create Cluster 버튼](/docs/assets/img/querypie-handson/image_05.png)
4. K8s 클러스터 정보를 등록합니다.  
![클러스터 정보 등록 화면](/docs/assets/img/querypie-handson/image_06.png)  
입력 항목 설명
1) Name  
예) production-cluster, develop-cluster

2) Version  
아래와 같이 터미널에서 "Server Version" (v1.33.1)을 입력해 주세요
```bash
$ kubectl version
Client Version: v1.28.1
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.33.1
```

3) API URL  
아래와 같이 host.docker.internal로 입력합니다.  
(컨테이너가 로컬호스트를 경유해서 통신하기 위함)
production-cluster 입력https://host.docker.internal:6444
develop-cluster 입력https://host.docker.internal:6445

4) Credential 정보 입력
4-1) 스크립트 다운로드 (generate_kubepie_sa.sh)
"download and run this script"를 클릭하여 K8s 크리덴셜 정보 (TOKEN, CA) 정보 추출을 도와주는 스크립트를 다운로드 합니다.  
![스크립트 다운로드 화면](/docs/assets/img/querypie-handson/image_07.png)  
4-2) 크리덴셜 정보를 가져올 클러스터 선택 (production, develop 각각 실행해 주세요)
```bash
# K8s 클러스터 변경
$ kubectl config use-context production-cluster

# 크리덴셜 정보 출력
$ generate_kubepie_sa.sh
...
Finished successfully.
...
>>> Service Account token
eyJhbGciOiJSUzI1NiIsImtpZCI6IjlXR1p... (중략)
...
--------------
>>> CA Cert
-----BEGIN CERTIFICATE-----
MIIDBTCCAe2gAwIBAgIIQ5qE5Ai5VcwwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yNTA3MzExMTI4NTBaFw0zNTA3MjkxMTMzNTBaMBUx
... (중략)
-----END CERTIFICATE-----
```
4-3) generate_kubepie_sa.sh 실행 시 출력된 "Service Access Token" 값과 "CA Cert" (Certificate Authority) 값을 복사하여 폼에 입력합니다.  
![크리덴셜 정보 입력 화면](/docs/assets/img/querypie-handson/image_08.png)  

5) Save 저장  
Logging Options 및 Tags는 실습에서는 따로 설정하지 않았습니다.  
자세한 내용은 공식 매뉴얼을 참고해 주세요.K8s 접근 제어 (Access Control) 설정  
QueryPie의 Kubernetes 좌측 메뉴 그룹을 보면 K8s Access Control이 있습니다.  
등록한 K8s 클러스터들에 대해서 사용자들의 접근 (Access)에 대해서 정책을 설정할 수 있습니다.  
![Access Control 메뉴](/docs/assets/img/querypie-handson/image_09.png)  
Access Control은 QueryPie에 등록된 유저들에 대하여 Role을 할당할 수 있습니다.  
![Access Control 목록 화면](/docs/assets/img/querypie-handson/image_10.png)  
Admin 계정을 클릭하여 등록된 Roles과 Clusters 목록을 확인할 수 있어요.  
![Admin Access Control 상세 화면](/docs/assets/img/querypie-handson/image_11.png)  
아직 등록된 Role이 없습니다. Role을 만들어 봅시다.  
![Create Role 버튼](/docs/assets/img/querypie-handson/image_12.png)  
"Create Role" 버튼을 클릭합니다.  
![Create Role 팝업](/docs/assets/img/querypie-handson/image_13.png)  
간단하게 Name과 Description만 입력하면 Role을 만들 수 있습니다.  
![Role 등록 팝업 화면](/docs/assets/img/querypie-handson/image_14.png)  
목록에 admin-role이 추가되고 상세정보를 확인해 보세요.  
![admin-role 상세 화면](/docs/assets/img/querypie-handson/image_15.png)  
하단 Policies 목록이 비어있습니다.  
Policy를 만들어 봅시다.Policies 메뉴로 이동합니다.  
![Policies 메뉴](/docs/assets/img/querypie-handson/image_16.png)  
"Create Policy" 버튼을 클릭합니다.  
![Policies 목록 화면](/docs/assets/img/querypie-handson/image_17.png)  
간단하게 Name, Description을 입력하면 생성됩니다.  
![신규 Policy 등록 팝업](/docs/assets/img/querypie-handson/image_18.png)  
![Policies 목록에 product-policy 추가됨](/docs/assets/img/querypie-handson/image_19.png)  
생성된 Policy (product-policy)를 클릭하면, 정책에 대한 세부 화면이 뜹니다.  
![product-policy 상세 화면](/docs/assets/img/querypie-handson/image_20.png)  
"</> Go to Editor Mode"를 클릭하면 정책을 편집할 수 있습니다.  
![product-policy 편집 모드](/docs/assets/img/querypie-handson/image_21.png)  
"Save Changes"를 클릭해서 바로 저장해 봅시다.  
![정책 저장](/docs/assets/img/querypie-handson/image_22.png)  
생성된 product-policy를 Role에 추가해 보겠습니다.Roles > admin-role을 클릭합니다.  
하단 목록 Policies > "Assign Policies"를 클릭합니다.  
product-policy를 체크 후 "Assign" 버튼을 클릭합니다.  
admin-role의 Policies 목록에 product-policy가 추가된 것을 확인할 수 있습니다.  
Access Control로 돌아가 Admin 계정에 admin-role을 추가해 보겠습니다.  
목록에서 Admin 클릭하여 상세화면으로 진입합니다.  
"Grant Roles" 버튼 클릭 > Role 등록 팝업  
앞서 추가한 "admin-role"이 Grant Roles 화면 목록에 표시됩니다.  
추가할 Role (admin-role)을 선택하고 Grant를 클릭합니다.
※Role에 대한 만료일 (Expiration Date)을 지정할 수 있습니다. (기본값 - 1년)  
admin-role이 Admin (user)에 할당되었습니다.  
지금부터 Admin (user)은 admin-role에 할당된 클러스터에 접근할 수 있습니다.  
하단 Clusters 탭에서 Admin이 접근 가능한 클러스터 목록을 확인할 수 있습니다.  
User (Admin) 정보 확인  
Admin 정보는 General > User Management > Users에서 확인할 수 있습니다.  
Admin은 QueryPie 생성 시 기본 관리자 계정으로 로그인 아이디는 "qp-admin"입니다.  
여기까지, "K8s 클러스터 생성 > QueryPie 등록 > 접근정책 설정"까지 모두 마쳤습니다.  

이제부터는 등록한 K8s 클러스터를 사용하기 위한 사용자 환경 구성에 대해 설명하겠습니다.  
QueryPie Agent 설치QueryPie에 클러스터를 등록하면, 사용자는 QueryPie 인증 한번으로 다수의 클러스터를 손쉽게 왔다갔다 할 수 있습니다.  
QueryPie Agent는 사용자 랩탑에 설치되어 여러개의 클러스터들을 한번의 인증으로 접근할 수 있게 해주고, 각 클러스터들에 대한 QueryPie의 정책 변경 사항들을 실시간으로 동기화해줍니다.  

QueryPie Agent를 설치해 봅시다.  
1. 상단메뉴 가장 우측 Admin > Multi-Agent를 클릭합니다  
![Admin Multi-Agent 메뉴](/docs/assets/img/querypie-handson/image_23.png)  
2. 팝업 화면에서 Mac > Apple Silicon을 클릭하여 다운로드 받습니다.  
![Agent 다운로드 화면](/docs/assets/img/querypie-handson/image_24.png)  
3. 다운로드 완료 후 설치를 진행합니다.  
![Agent 설치 화면](/docs/assets/img/querypie-handson/image_25.png)  
4. QueryPie Agent 실행등록된 QueryPie 서버가 없는 경우 화면입니다.  
![Agent 첫 실행 화면](/docs/assets/img/querypie-handson/image_26.png)  
5. QueryPie Host 입력QueryPie URL을 입력  
![QueryPie URL 입력 화면](/docs/assets/img/querypie-handson/image_27.png)  
6. 로그인qp-admin과 "비밀번호"를 입력하여 로그인 합니다.  
![Agent 로그인 화면](/docs/assets/img/querypie-handson/image_28.png)  
7. Kubernetes > Role을 선택합니다.  
![Kubernetes Role 선택 화면](/docs/assets/img/querypie-handson/image_29.png)  
앞서, QueryPie에서 생성한 admin-role을 선택하면, 접근할 수 있는 K8s 클러스터 목록이 보입니다.  
8. 에이전트 우측 상단의 "설정 (톱니)" 버튼을 클릭합니다.  
※ Setting > Kubernetes 탭을 확인합니다.  
QueryPie Agent에서 관리하는 Kubeconfig 정보를 확인할 수 있습니다.  
Kind에서 K8s 생성시 만든 kubeconfig를 사용하지 않도록 아래와 같이 QueryPie 전용 KUBECONFIG 환경 변수를 설정해서 클러스터를 확인해 보세요.  

```bash
export KUBECONFIG="~/.kube/querypie/localhost_8000"  
kubectl config get-contexts

CURRENT   NAME                              CLUSTER                    AUTHINFO                               NAMESPACE
          qp:localhost:8000:develop-cluster qp:localhost:8000:default  qp:localhost:8000:develop-cluster:Admin default
*         qp:localhost:8000:product-cluster qp:localhost:8000:default  qp:localhost:8000:product-cluster:Admin default

```

admin-role에 등록된 클러스터 두 개가 잘 보인다면 "성공"입니다 :-)

## 맺음말  
이번 글에서는 실제 대규모 서비스 운영 경험을 바탕으로 멀티클러스터 쿠버네티스 환경의 현실적인 문제들을 살펴보고, QueryPie Community 버전을 활용한 해결 방안을 실습을 통해 직접 구현해봤습니다.

**1편에서 함께 완성한 것들 👏👏👏:**  

✅ 문제 인식 - 쿠버네티스 클러스터 관리의 실제 어려움들  
✅ QueryPie 설치 - Community 버전 설치부터 라이센스 등록까지  
✅ K8s 멀티클러스터 구축 - Kind를 활용한 production/develop 클러스터 생성  
✅ 클러스터 통합 관리 - QueryPie에 클러스터 등록 및 연동  
✅ 기본 접근 제어 설정 - Role과 Policy 생성 및 사용자 권한 할당 (Access Control)  
✅ QueryPie Agent 설치 - 통합 인증을 통한 멀티클러스터 접근 구성  

이제 기본적인 환경 구성과 접근 제어 설정이 완료되었으니, 더욱 흥미진진한 실전 활용 단계로 넘어갈 차례입니다.

**2편에서는 실제 운영 시나리오를 중심으로:**  

🚀 세밀한 권한 제어 실습 - 클러스터별, 네임스페이스별, 리소스별 상세 정책 설정  
🚀 실시간 모니터링 체험 - 사용자 접근 활동 추적 및 감사 로그 확인  
🚀 고급 보안 기능 활용 - 컨테이너 접근 세션 레코딩  

실제 프로덕션 환경에서 "이런 기능이 있었으면 좋았을 텐데..."라고 아쉬워했던 부분들을 하나씩 체험하며, 
멀티클러스터 환경의 복잡성이 어떻게 체계적이고 안전한 관리 경험으로 바뀌는지 함께 확인해보겠습니다.  

준비된 환경을 그대로 유지해주세요. 2편에서 바로 이어서 진행합니다!

🎯 2편에서 뵙겠습니다!