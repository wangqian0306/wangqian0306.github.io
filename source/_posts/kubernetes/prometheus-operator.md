---
title: Prometheus Operator
date: 2023-01-16 20:52:13
tags:
- "Container"
- "Docker"
- "Kubernetes"
- "Prometheus"
id: prometheus-operator
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Prometheus Operator

### 简介

Prometheus Operator 提供 Kubernetes 原生部署和管理 Prometheus 和相关监控组件。该项目的目的是简化和自动化基于 Prometheus 的 Kubernetes 集群监控堆栈的配置。

### 安装

拉取项目：

```bash
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
```

初始化基本环境：

```bash
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
```

> 注：若输出为 `No resources found` 则代表可执行下一步。

拉取镜像并修改容器地址：

- `prometheusAdapter-deployment.yaml`
- `kubeStateMetrics-deployment.yaml`

```text
registry.k8s.io/prometheus-adapter/prometheus-adapter:{version}
registry.k8s.io/kube-state-metrics/kube-state-metrics:{version}
```

部署服务：

```bash
kubectl create -f manifests/
```

编写 `prometheus.yaml` 并部署 Ingress ：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  name: grafana-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: grafana.<host>
      http:
        paths:
          - backend:
              service:
                name: grafana
                port:
                  number: 3000
            path: /
            pathType: Prefix
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  name: alertmanager-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: alert.<host>
      http:
        paths:
          - backend:
              service:
                name: alertmanager-main
                port:
                  number: 9093
            path: /
            pathType: Prefix
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  name: prometheus-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: prometheus.<host>
      http:
        paths:
          - backend:
              service:
                name: prometheus-k8s
                port:
                  number: 9090
            path: /
            pathType: Prefix
```

```bash
kubectl apply -f prometheus.yaml
```

### 参考资料

[官方文档](https://prometheus-operator.dev/docs/prologue/introduction/)
