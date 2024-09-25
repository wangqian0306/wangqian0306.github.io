---
title: Kubernetes 生产环境
date: 2023-02-01 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: kubernetes-prod
no_word_count: true
no_toc: false
categories: 
- "Kubernetes"
---

## Kubernetes 生产环境

### 简介

看到 SpringOne 大会上提到的生产级别 K8s 集群具有的内容，此处简单进行下记录。

### 部署方式

从结构上来说应该分成以下几个部分：

1. 使用 Terraform 来部署 K8s ，其中包含 kubernetes 集群，容器仓库，helm 。
2. 使用 Argo CD 完成持续部署，此外还有 Lets'Encrypt 和 Traefik。
3. 使用 Robusta 完成系统监控，其中还包含 Prometheus 和 Grafana。

![bootstrapper-overview](https://raw.githubusercontent.com/hivenetes/k8s-bootstrapper/refs/heads/main/docs/assets/bootstrapper-overview.png)

### 参考资料

[Let's Generate Art With Kubernetes And Spring! (SpringOne 2024)](https://www.youtube.com/watch?v=v5vHP3l_DHM&t=483s)

[Kubernetes Bootstrapper](https://github.com/hivenetes/k8s-bootstrapper)
