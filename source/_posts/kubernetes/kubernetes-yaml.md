---
title: Kubernetes 服务 Yaml 样例
date: 2022-12-20 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: kubernetes-yaml
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Kubernetes 服务 Yaml 样例

### 简介

本文是在 Kubernetes 中部署一个简单服务的 Yaml 记录。

### 样例

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-deployment
  labels:
    app: tomcat
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat
  template:
    metadata:
      labels:
        app: tomcat
    spec:
      containers:
        - name: tomcat
          image: tomcat:9.0
          ports:
            - containerPort: 8080
---

kind: Service
apiVersion: v1
metadata:
  labels:
    app: tomcat
  name: tomcat-svc
  namespace: demo
spec:
  ports:
    - port: 8080
      targetPort: 8080
---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tomcat-ingress
  namespace: demo
spec:
  ingressClassName: nginx
  rules:
    - host: <host>
      http:
        paths:
          - pathType: Prefix
            path: "/"
            backend:
              service:
                name: tomcat-svc
                port:
                  number: 8080
```

### 参考资料

[官方文档](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
