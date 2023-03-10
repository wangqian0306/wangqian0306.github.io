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
  transparentProxy:
    defaultEnabled: true
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

> 注: 在配置

### API 

Consul 服务若出现异常可以通过此种方式进行删除：

```http request
### 检查服务状态
GET http://<host>:8500/v1/agent/checks

### 查看服务列表
GET http://<host>:8500/v1/agent/services

### 刪除空服务
PUT http://<host>:8500/v1/agent/service/deregister/<service-name>
```

### 在 Kubernetes 上开发与部署服务

流程及插件文档详见 [整合文档](https://developer.hashicorp.com/consul/docs/integrate/partnerships)

部署样例参见：

[Nginx Ingress Consul 服务部署](https://github.com/dhiaayachi/eks-consul-ingressnginx)

### 参考资料

[官方文档](https://www.consul.io/docs/k8s/installation/install)
