---
title: dive
date: 2024-9-27 21:41:32
tags:
- "Container"
id: dive
no_word_count: true
no_toc: false
categories:
- "Container"
---

## dive

### 简介

dive 是一个 Docker 工具，可以用来检索每个 Layer 中的内容。

### 安装和使用方式

- RHEL/CentOS

```bash
DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -OL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.rpm
rpm -i dive_${DIVE_VERSION}_linux_amd64.rpm
```

```bash
dive <image>
```

> 注：之前一直对 GraalVM Native Image 的结构没有基础的认知，可以通过此工具查看具体容器的构成和目录情况。

### 参考资料

[官方项目](https://github.com/wagoodman/dive)
