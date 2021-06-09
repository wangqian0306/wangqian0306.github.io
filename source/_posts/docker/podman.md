---
title: Podman 安装和基础命令
date: 2020-12-25 21:41:32
tags: "Container"
id: podman
no_word_count: true
no_toc: false
categories: Container
---

## Podman 安装

使用如下命令进行安装

CentOS 7:
```bash
yum install podman -y
```

## 关闭 SELinux

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

## 基本操作

Podman 的基本操作与 Docker 基本相同只不过在拉取镜像的时候有个参数差异。

拉取镜像
```
podman pull <image> 
```

> 注：如果需要拉取 http registry 当中的镜像则需要加入 `--tls-verify=false` 参数。

## 新功能

podman 引入了部分 Kubernetes 的相关功能。目前可以在软件安装完成后使用 pod 部分的相关功能。

部署容器
```bash
podman play kube demo.yml
```

管理容器
```bash
podman pod <command>
```

## podman-compose

在 podman 中也有像 docker-compose 的相关命令，即 `podman-compose`。

可以使用如下命令进行安装：

```bash
pip3 install podman-compose
```

但是在使用中需要注意 `podman-compose` 目前的命令非常不完善有且仅有以下几项：

- pull
- push
- build
- up
- down
- run
- start
- stop
- restart 

而且整个软件需要使用镜像 `k8s.gcr.io/pause:3.1` 才能正常运行。故不推荐使用此工具。
