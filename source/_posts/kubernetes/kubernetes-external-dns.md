---
title: Kubernetes 外部 DNS
date: 2023-02-01 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
- "DNS"
id: kubernetes-external-dns
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Kubernetes 外部 DNS

### 简介

ExternalDNS 项目可以把 Kubernetes 集群内的 Service 和 Ingress 实例同步到外部的 DNS 服务提供方。

> 注：不同的服务提供方有不同的对接方式，具体支持的平台请参阅官方项目。

### 安装方式

> 注：本示例采用支持 RFC2136 标准的 BIND 服务，前期准备参见 BIND 文档的 **动态配置** 章节。

然后在任意可以链接到 Kubernetes 的设备上编写 `external-dns.yaml` 文件并部署即可：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
  labels:
    name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
  namespace: external-dns
rules:
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  - pods
  - nodes
  verbs:
  - get
  - watch
  - list
- apiGroups:
  - extensions
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
  namespace: external-dns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: external-dns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: external-dns
spec:
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.13.4
        args:
        - --registry=txt
        - --txt-prefix=external-dns-
        - --txt-owner-id=k8s
        - --provider=rfc2136
        - --rfc2136-host=<dns_server_host>
        - --rfc2136-port=53
        - --rfc2136-zone=<zone>
        - --rfc2136-tsig-secret=<key.secret>
        - --rfc2136-tsig-secret-alg=hmac-sha256
        - --rfc2136-tsig-keyname=externaldns-key
        - --rfc2136-tsig-axfr
        - --source=ingress
        - --domain-filter=<zone>
```

使用如下命令部署即可：

```bash
kubectl apply -f external-dns.yaml
```

之后正常创建 Ingress ，并使用如下命令可以检查服务日志：

```bash
kubectl logs -f deploy/external-dns -n external-dns
```

若出现如下内容即可访问对应 URL：

```text
"Adding RR: xxxx 0 A xxx.xxx.xxx.xxx"
```

### 参考资料

[官方项目](https://github.com/kubernetes-sigs/external-dns)

[RFC2136 配置方式](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/rfc2136.md)
