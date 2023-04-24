---
title: Kubernetes-Dashboard
date: 2023-02-01 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: kubernetes-dashboard
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Kubernetes-Dashboard

### 简介

Kubernetes Dashboard 是一个用于 Kubernete 集群的通用 Web UI。它允许用户在网页上管理集群。由于其本身需要外部 URL 所以本文的前置依赖条件是已经配置好了 Ingress-Nginx 或同等内容，最好配置了 External-DNS。

### 部署

使用如下命令部署仪表版：

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

编写 `dashboard-ingress.yaml` 文件开放外网访问：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  name: dashboard-ingress
  namespace: kubernetes-dashboard
spec:
  ingressClassName: nginx
  rules:
    - host: <host>
      http:
        paths:
          - backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
            path: /
            pathType: Prefix
status:
  loadBalancer: {}
```

> 注：host (样例 `k8s-dashboard.xxx.xxx`) 需要写入 dns 服务器或者 hosts 文件中。

部署完成后可以使用如下命令检查 Ingress 状态，若能获得 ADDRESS 则可以正常访问 `https://<host>`：

```bash
kubectl get ingress -n kubernetes-dashboard
```

之后可以新建 `dashboard-sa.yaml` 并填入如下内容和命令来创建 service account 并赋予权限生成 token:

```text
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

```bash
kubectl apply -f dashboard-sa.yaml
kubectl -n kubernetes-dashboard create token admin-user
```

将生成的 Token 填入 dashboard 即可。

### 参考资料

[官方文档](https://github.com/kubernetes/dashboard)
