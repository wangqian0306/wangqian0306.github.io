---
title: Cloud Native Buildpacks
date: 2023-1-11 21:41:32
tags:
- "CNB"
- "Container"
id: cnb
no_word_count: true
no_toc: false
categories: Container
---

## Cloud Native Buildpacks

### 简介

Cloud Native Buildpacks 是一种标准接口，目标是将任何应用程序转化为在任何云平台上都能运行的镜像。

### 核心概念

#### 使用人员

- 程序开发人员
- 构建包作者
- 运维人员

#### 组件及其负责内容

- **BuildPack**：Buildpack 负责检查应用程序源代码(框架级别)，识别和收集依赖关系，并输出符合 OCI 规范的应用程序和依赖容器层
- **Builder**：Builder 是一系列有序 `buildpack` 的集合，以及 `build image` ，运行生命周期，运行 `run image` 。它会获取代码并构建成品的 `app image` 。
- **Build Image**：构建环境的镜像
- **Run Image**：为应用程序映像提供基础映像。
- **Lifecycle(生命周期)**：Analyze，Detect，Restore，Build，Export，Create，Launch，Rebase

### 安装方式

Pack 是 Cloud Native Buildpacks 项目的基础构建工具，提供了默认的 Cli 和 Go 库。

可以使用如下命令安装 Cli :

```bash
(curl -sSL "https://github.com/buildpacks/pack/releases/download/{version}/pack-{verison}-linux.tgz" | sudo tar -C /usr/local/bin/ --no-same-owner -xzv pack)
```

> 注：也可以使用容器的方式跳过此处环境安装。

### 初步试用

```bash
git clone https://github.com/buildpacks/samples
cd samples/apps/java-maven
pack build myapp --builder cnbs/sample-builder:jammy
docker run --rm -p 8080:8080 myapp
```

### 在生产环境中使用

在实际的使用流程中可以选择 `Paketo Buildpacks` 项目提供的各种 Builder，具体支持以下语言：

- Java
- Node.js
- .Net Core
- Go
- Python
- PHP
- Ruby

> 注：使用过程请参照 [Paketo Buildpacks](https://paketo.io/docs/) 文档和 [样例代码](https://github.com/paketo-buildpacks/samples)。

### 参考资料

[官方文档](https://buildpacks.io/docs/)

[Paketo Buildpacks](https://paketo.io/docs/)
