---
title: Skaffold
date: 2024-05-23 20:52:13
tags:
- "Container"
- "Docker"
- "Kubernetes"
id: skaffold
no_word_count: true
no_toc: false
categories: Kubernetes
---

## Skaffold

### 简介

Skaffold 是一个命令行工具，可促进基于容器的应用程序和 Kubernetes 应用程序的持续开发。 Skaffold 处理构建、推送和部署应用程序的工作流程，并提供用于创建 CI/CD 管道的构建块。

### 安装

使用如下命令安装脚本：

```bash
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
sudo install skaffold /usr/local/bin/
```

### 试用

官方提供了演示项目：

```bash
git clone https://github.com/GoogleContainerTools/skaffold
cd skaffold/examples/getting-started
skaffold dev
```

此命令会构建服务，并将其部署在 k8s 上，在代码发生变动时会自动重新打包部署。

### 参考资料

[官方文档]()

[演示项目]()
