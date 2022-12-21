---
title: Helm
date: 2022-12-21 21:41:32
tags:
- "Container"
- "Docker"
- "Kubernetes"
- "Helm"
id: helm
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Helm 

### 简介

Helm 是一款管理 Kubernetes 应用程序的便捷工具。

### 安装

使用如下命令安装 Helm：

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

安装完成后可以使用如下命令检查服务安装情况：

```bash
helm version
```

### 配置国内源(可选)

```text
helm repo add kaiyuanshe http://mirror.kaiyuanshe.cn/kubernetes/charts
helm repo add azure http://mirror.azure.cn/kubernetes/charts
helm repo add bitnami https://charts.bitnami.com/bitnami
```

> 注: 默认使用官方源速度我看着还行，此处仅留作备用。

### 常用命令

检索软件包：

```bash
helm search <package>
```

安装软件包：

```bash
helm install <package> -n <namespace>
```

查看已经安装的软件包：

```bash
helm list -n <namespace>
```

卸载软件包：

```bash
helm uninstall <package> -n <namespace>
```

### 参考资料

[官方文档](https://helm.sh/docs/)
