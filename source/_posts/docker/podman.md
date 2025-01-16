---
title: Podman 安装和基础命令
date: 2020-12-25 21:41:32
tags: "Container"
id: podman
no_word_count: true
no_toc: false
categories: Container
---

## Podman 

### 安装

使用如下命令进行安装：

```bash
yum install docker epel-release -y
yum install podman-compose -y
```

关闭 SELinux

- 修改服务状态

```bash
setenforce 0
```

- 全局配置

```bash
vim /etc/selinux/config
```

修改如下内容

```text
SELINUX=disabled
```

### 代理配置

Podman 不需要修改代理相关文件，直接使用系统代理，可以使用如下方法进行拉取：

```bash
export HTTP_PROXY="http://127.0.0.1:8888/"
export HTTPS_PROXY="http://127.0.0.1:8888/"
podman pull <image>
unset HTTP_PROXY
unset HTTPS_PROXY
```

### 基本操作

Podman 的基本操作与 Docker 基本相同只不过在拉取镜像的时候有个参数差异。

拉取镜像
```
podman pull <image> 
```

> 注：如果需要拉取 http registry 当中的镜像则需要加入 `--tls-verify=false` 参数。

### 新功能

podman 引入了部分 Kubernetes 的相关功能。目前可以在软件安装完成后使用 pod 部分的相关功能。

部署容器
```bash
podman play kube demo.yml
```

管理容器
```bash
podman pod <command>
```
