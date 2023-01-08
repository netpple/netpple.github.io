---
title: Istio Ingress Gateway (4)  
version: v1.0  
description: istio in action 4장 실습4  
date: 2023-01-01 09:00:00 +09:00  
categories: network  
badges:
- type: info  
  tag: 교육  
  rightpanel: false
---

Split gateways, Gateway injection, Ingress GW 로깅, Gateway configuration 등 운영팁들을 살펴봅니다.

<!--more-->

## Operational tips

### Split gateway responsibilities

- 다같이 쓰는 것들은 아무래도 부담 스럽죠
- 팀별로 전용 gateway를 구성해 봅시다
- istioinaction 네임스페이스에 전용 gateway를 띄워봅니다

IstioOperator 명세 - [*ch4/my-user-gateway.yaml*](https://github.com/istioinaction/book-source-code/blob/master/ch4/my-user-gateway.yaml)

- istioctl 이 명세를 바탕으로 K8s 명세를 generate 함.
- 참고) [istio operater controller](https://tetrate.io/blog/what-is-istio-operator/)를 설치하여 관리하는 방법도 있음
- 참고) [IstioOperator options](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)

```yaml
# vi ch4/my-user-gateway.yaml

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
```

Ingress gateway 명세 출력 - [참고](https://istio.io/latest/docs/setup/install/istioctl/#generate-a-manifest-before-installation)

```yaml
# istioctl manifest generate -n istioinaction -f ch4/my-user-gateway.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-user-gateway-service-account
  namespace: istioinaction
  labels:
    app: istio-ingressgateway
    istio: my-user-gateway
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-user-gateway
  namespace: istioinaction
  labels:
    app: istio-ingressgateway
    istio: my-user-gateway
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
      istio: my-user-gateway
  strategy:
    rollingUpdate:
      maxSurge: 100%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app: istio-ingressgateway
        istio: my-user-gateway
        service.istio.io/canonical-name: my-user-gateway
        service.istio.io/canonical-revision: latest
        istio.io/rev: default
        install.operator.istio.io/owning-resource: unknown
        operator.istio.io/component: "IngressGateways"
        sidecar.istio.io/inject: "false"
      annotations:
        prometheus.io/port: "15020"
        prometheus.io/scrape: "true"
        prometheus.io/path: "/stats/prometheus"
        sidecar.istio.io/inject: "false"
    spec:
      securityContext:
        runAsUser: 1337
        runAsGroup: 1337
        runAsNonRoot: true
        fsGroup: 1337
      serviceAccountName: my-user-gateway-service-account
      containers:
        - name: istio-proxy
          image: "docker.io/istio/proxyv2:1.16.1"
          ports:
            - containerPort: 15021
              protocol: TCP
            - containerPort: 8080
              protocol: TCP
            - containerPort: 8443
              protocol: TCP
            - containerPort: 15090
              protocol: TCP
              name: http-envoy-prom
          args:
          - proxy
          - router
          - --domain
          - $(POD_NAMESPACE).svc.cluster.local
          - --proxyLogLevel=warning
          - --proxyComponentLogLevel=misc:error
          - --log_output_level=default:info
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            privileged: false
            readOnlyRootFilesystem: true
          readinessProbe:
            failureThreshold: 30
            httpGet:
              path: /healthz/ready
              port: 15021
              scheme: HTTP
            initialDelaySeconds: 1
            periodSeconds: 2
            successThreshold: 1
            timeoutSeconds: 1
          resources:
            limits:
              cpu: 2000m
              memory: 1024Mi
            requests:
              cpu: 100m
              memory: 128Mi
          env:
          - name: JWT_POLICY
            value: third-party-jwt
          - name: PILOT_CERT_PROVIDER
            value: istiod
          - name: CA_ADDR
            value: istiod.istio-system.svc:15012
          - name: NODE_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: spec.nodeName
          - name: POD_NAME
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: metadata.namespace
          - name: INSTANCE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: HOST_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: SERVICE_ACCOUNT
            valueFrom:
              fieldRef:
                fieldPath: spec.serviceAccountName
          - name: ISTIO_META_WORKLOAD_NAME
            value: my-user-gateway
          - name: ISTIO_META_OWNER
            value: kubernetes://apis/apps/v1/namespaces/istioinaction/deployments/my-user-gateway
          - name: ISTIO_META_MESH_ID
            value: "cluster.local"
          - name: TRUST_DOMAIN
            value: "cluster.local"
          - name: ISTIO_META_UNPRIVILEGED_POD
            value: "true"
          - name: ISTIO_META_CLUSTER_ID
            value: "Kubernetes"
          volumeMounts:
          - name: workload-socket
            mountPath: /var/run/secrets/workload-spiffe-uds
          - name: credential-socket
            mountPath: /var/run/secrets/credential-uds
          - name: workload-certs
            mountPath: /var/run/secrets/workload-spiffe-credentials
          - name: istio-envoy
            mountPath: /etc/istio/proxy
          - name: config-volume
            mountPath: /etc/istio/config
          - mountPath: /var/run/secrets/istio
            name: istiod-ca-cert
          - name: istio-token
            mountPath: /var/run/secrets/tokens
            readOnly: true
          - mountPath: /var/lib/istio/data
            name: istio-data
          - name: podinfo
            mountPath: /etc/istio/pod
          - name: ingressgateway-certs
            mountPath: "/etc/istio/ingressgateway-certs"
            readOnly: true
          - name: ingressgateway-ca-certs
            mountPath: "/etc/istio/ingressgateway-ca-certs"
            readOnly: true
      volumes:
      - emptyDir: {}
        name: workload-socket
      - emptyDir: {}
        name: credential-socket
      - emptyDir: {}
        name: workload-certs
      - name: istiod-ca-cert
        configMap:
          name: istio-ca-root-cert
      - name: podinfo
        downwardAPI:
          items:
            - path: "labels"
              fieldRef:
                fieldPath: metadata.labels
            - path: "annotations"
              fieldRef:
                fieldPath: metadata.annotations
      - name: istio-envoy
        emptyDir: {}
      - name: istio-data
        emptyDir: {}
      - name: istio-token
        projected:
          sources:
          - serviceAccountToken:
              path: istio-token
              expirationSeconds: 43200
              audience: istio-ca
      - name: config-volume
        configMap:
          name: istio
          optional: true
      - name: ingressgateway-certs
        secret:
          secretName: "istio-ingressgateway-certs"
          optional: true
      - name: ingressgateway-ca-certs
        secret:
          secretName: "istio-ingressgateway-ca-certs"
          optional: true
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          preferredDuringSchedulingIgnoredDuringExecution:
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: my-user-gateway
  namespace: istioinaction
  labels:
    app: istio-ingressgateway
    istio: my-user-gateway
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: istio-ingressgateway
      istio: my-user-gateway
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-user-gateway-sds
  namespace: istioinaction
  labels:
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-user-gateway-sds
  namespace: istioinaction
  labels:
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: my-user-gateway-sds
subjects:
- kind: ServiceAccount
  name: my-user-gateway-service-account
---
apiVersion: v1
kind: Service
metadata:
  name: my-user-gateway
  namespace: istioinaction
  annotations:
  labels:
    app: istio-ingressgateway
    istio: my-user-gateway
    release: istio
    istio.io/rev: default
    install.operator.istio.io/owning-resource: unknown
    operator.istio.io/component: "IngressGateways"
spec:
  type: LoadBalancer
  selector:
    app: istio-ingressgateway
    istio: my-user-gateway
  ports:
    -
      name: status-port
      port: 15021
      protocol: TCP
      targetPort: 15021
    -
      name: http2
      port: 80
      protocol: TCP
      targetPort: 8080
    -
      name: https
      port: 443
      protocol: TCP
      targetPort: 8443
---
```

Ingress gateway  설치

```bash
istioctl install -y -n istioinaction -f ch4/my-user-gateway.yaml

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
my-user-gateway        LoadBalancer   10.96.169.79     127.0.0.1     15021:31846/TCP,80:32385/TCP,443:30475/TCP
```

### Gateway Injection

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

### Ingress gateway access logs

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

### Reducing gateway configuration

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