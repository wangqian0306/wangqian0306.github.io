---
title: Consul
date: 2022-06-23 23:09:32
tags:
- "Consul"
- "Kubernetes"
- "Container"
- "Docker"
- "Helm"
id: consul
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Consul

### 简介

Consul 是一种多网络管理工具，提供功能齐全的服务网格(ServiceMesh)解决方案，可解决运营微服务和云基础设施（多云和混合云）的网络和安全挑战。

### 安装与部署

#### 在本机上安装

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install consul
```

> 注：其他平台请参照 [官方文档](https://developer.hashicorp.com/consul/downloads)

#### 在 Kubernetes 上部署

> 注：在部署 Consul 之前需要安装 Helm 并在 Kubernetes 上配置 StorageClass。

生成配置文件：

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm inspect values hashicorp/consul > values.yaml
```

配置下面的内容：

```yaml
global:
  enabled: true
  logLevel: "info"
  logJSON: false
  name: consul
server:
  enabled: true
  storageClass: nfs-client
ui:
  enbaled: true
  ingress:
    enabled: true
    ingressClassName: "nginx"
    pathType: Prefix
    hosts: [ { host:"<host>" } ]
connectInject:
  enabled: true
  cni:
    enabled: true
    logLevel: info
    cniBinDir: "/opt/cni/bin"
    cniNetDir: "/etc/cni/net.d"
```

然后使用下面的命令部署集群：

```bash
helm install consul hashicorp/consul --create-namespace --namespace consul --values values.yaml
```

### API 

Consul 中的服务是不会随着平台而变化的，如需编辑可调用 API ：

```http request
### 检查服务状态
GET http://<host>:8500/v1/agent/checks

### 查看服务列表
GET http://<host>:8500/v1/agent/services

### 刪除空服务
PUT http://<host>:8500/v1/agent/service/deregister/gateway-consul
```

### 在 Kubernetes 上部署服务

下面是使用 Spring Cloud Consul 的部署样例：

```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: <name>
  namespace: <namespace>
spec:
  selector:
    app: <name>
  ports:
    - name: http
      protocol: TCP
      port: 8080
      targetPort: 8080
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: <name>-config
  namespace: <namespace>
data:
  application-prod.yaml: |
    server:
      port: ${SERVER_PORT:8080}
    spring:
      cloud:
        consul:
          host: ${CONSUL_HOST:consul-server.consul.svc}
          port: ${CONSUL_PORT:8500}
          discovery:
            prefer-ip-address: true
            tags: version=1.0
            instance-id: ${spring.application.name}:${spring.cloud.client.hostname}:${spring.cloud.client.ip-address}:${server.port}
            healthCheckInterval: 15s
            register: false

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <name>-sa
  namespace: <namespace>
automountServiceAccountToken: true
---
apiVersion: consul.hashicorp.com/v1alpha1
kind: ServiceDefaults
metadata:
  name: <name>
  namespace: <namespace>
spec:
  protocol: "http"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <name>-deployment
  namespace: <namespace>
  labels:
    app: <name>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <name>
  template:
    metadata:
      labels:
        app: <name>
      annotations:
        consul.hashicorp.com/connect-inject: "true"
    spec:
      serviceAccountName: <name>-sa
      containers:
        - name: <name>
          image: xxx:xxx
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: prod
          volumeMounts:
            - name: <name>-config
              mountPath: /app/application-prod.yaml
              subPath: application-prod.yaml
      volumes:
        - name: <name>-config
          configMap:
            name: <name>-config
            items:
              - key: application-prod.yaml
                path: application-prod.yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  labels:
    app: <name>
  name: <name>
  namespace: <namespace>
spec:
  ingressClassName: nginx
  rules:
    - host: <host>
      http:
        paths:
          - backend:
              service:
                name: <name>
                port:
                  number: 8080
            path: /api
            pathType: Prefix
```

> 注：挂载地址与环境变量请自行设定。

### 参考资料

[官方文档](https://www.consul.io/docs/k8s/installation/install)
