---
title: Ingress-Nginx
date: 2022-04-25 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: kubernetes-ingress-nginx
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Ingress-Nginx

### 简介

Ingress-Nginx 是 Kubernetes 的 ingress controller，使用nginx 作为反向代理和负载均衡器。

### 部署

使用如下命令部署：

```bash
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml
mv deploy.yaml ingress-nginx-controller.yaml
sed -i 's#registry.k8s.io/ingress-nginx#registry.aliyuncs.com/google_containers#g' ingress-nginx-controller.yaml
sed -i 's#registry.aliyuncs.com/google_containers/controller#registry.aliyuncs.com/google_containers/nginx-ingress-controller#g' ingress-nginx-controller.yaml
kubectl apply -f ingress-nginx-controller.yaml
```

检查 pod 和 svc 状态：

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

> 注：在单节点部署的时候出现了外部 IP 绑定处于 Pending 的状况，使用如下命令进行了配置 `kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer", "externalIPs":["xxx.xxx.xxx.xxx"]}}'`

### 参考资料

[官方文档](https://github.com/kubernetes/ingress-nginx)

[部署说明](https://kubernetes.github.io/ingress-nginx/deploy/)