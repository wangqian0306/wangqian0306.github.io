---
title: Docker Swarm 初步使用
date: 2021-09-09 20:26:13
tags:
- "Container"
- "Docker Compose"
- "Docker Swarm"
id: docker-swarm 初步使用
no_word_count: true
no_toc: false
categories: Container
---

## Docker Swarm 初步使用

### 简介

Docker Swarm 是 Docker 的集群管理工具。它将 Docker 主机池转变为单个虚拟 Docker 主机。

### 安装

具体方案请参照 [官方文档](https://docs.docker.com/engine/swarm/swarm-mode/)

### 使用

在 Docker Swarm 集群中部署服务采用的是 Docker Compose 文件的格式。

但是某些特定的参数项将不再生效，例如：

- container_name
- expose
- restart
- depends_on

### 常用命令

- 部署或更新服务

```bash
docker stack deploy -c docker-compose.yaml <name> --with-registry-auth
```

- 删除服务

```bash
docker stack rm <name>
```

### 注意事项

Docker Swarm 默认使用了两个网络

- Docker 原始的内部网络用于服务间通信
- Ingress 网络用于对外提供服务