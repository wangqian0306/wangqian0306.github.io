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

> 注：本示例采用支持 RFC2136 标准的 BIND 服务，前期准备参见 BIND 文档。

首先需要在外部 DNS 服务器上运行如下命令，生成密钥：

```bash
tsig-keygen -a hmac-sha256 externaldns
```

应该得到这样的输出，将其放置在 `/etc/named.conf` 文件中：

```text
key "externaldns" {
        algorithm hmac-sha256;
        secret "<secret>";
};
```

在 `/etc/named.conf` 文件中，修改 `zone` 配置：

```text
zone "k8s.example.org" {
    type master;
    file "/etc/bind/pri/k8s/k8s.zone";
    allow-transfer {
        key "externaldns-key";
    };
    update-policy {
        grant externaldns-key zonesub ANY;
    };
};
```

然后编写 `/etc/bind/pri/k8s/k8s.zone` 文件

```text
$TTL 60 ; 1 minute
k8s.example.org         IN SOA  k8s.example.org. root.k8s.example.org. (
                                16         ; serial
                                60         ; refresh (1 minute)
                                60         ; retry (1 minute)
                                60         ; expire (1 minute)
                                60         ; minimum (1 minute)
                                )
                        NS      ns.k8s.example.org.
ns                      A       123.456.789.012
```

然后在任意可以链接到 Kubernetes 的设备上编写 `external-dns.yaml` 文件并部署即可：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
  labels:
    name: external-dns
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
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.13.1
        args:
        - --registry=txt
        - --txt-prefix=external-dns-
        - --txt-owner-id=k8s
        - --provider=rfc2136
        - --rfc2136-host=<host>
        - --rfc2136-port=53
        - --rfc2136-zone=<zone:k8s.example.org>
        - --rfc2136-tsig-secret=<secret>
        - --rfc2136-tsig-secret-alg=hmac-sha256
        - --rfc2136-tsig-keyname=externaldns-key
        - --rfc2136-tsig-axfr
        - --source=ingress
        - --domain-filter=<zone:k8s.example.org>
```

使用如下命令部署即可：

```bash
kubectl apply -f external-dns.yaml
```

之后正常创建 Ingress 后 ping 相应域名即可完成检查。

### 参考资料

[官方项目](https://github.com/kubernetes-sigs/external-dns)

[RFC2136 配置方式](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/rfc2136.md)
