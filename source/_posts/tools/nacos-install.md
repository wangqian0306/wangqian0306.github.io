---
title: Nacos 安装
date: 2021-08-03 23:09:32
tags:
- "Nacos"
- "Spring Boot"
- "Spring Cloud Alibaba"
id: nacos-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Nacos 安装

### 简介

Nacos 一个易于构建云原生应用的动态服务发现、配置管理和服务管理平台。

### 简单使用

创建 docker-compose 文件

```bash
vim docker-compose.yaml
```

填入如下内容：

```bash
services:
  nacos:
    image: nacos/nacos-server:latest
    container_name: nacos-standalone
    ports:
      - "8848:8848"
      - "9848:9848"
      - "9555:9555"
    environment:
      MODE: standalone
    restart: always
```

启动服务：

```bash
docker-compose up -d
```

### 注意事项

#### Docker Swarm

在 Docker Swarm 平台上部署 Nacos 相关服务时需要声明使用的网卡和网段，防止注册时使用了 Ingress 网段。

SpringCloud 框架下的配置样例如下：

```text
spring.cloud.inetutils.preferred-networks=<network>
```
