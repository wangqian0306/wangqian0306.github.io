---
title: Nexus 服务安装及配置流程
date: 2020-12-01 21:57:04
tags: "Linux"
id: nexus
no_word_count: true
no_toc: false
categories: Linux
---

## Nexus 服务安装及配置流程

### 简介

Neuxs 可以作为 Proxy 缓存外网上的软件包。

### 安装

> 注：此处采用 Docker 的方式运行 Nexus 软件源，需要 Docker 和 Docker-Compose 软件。

- 选定安装位置创建 `nexus` 文件夹

> 注：此处建议安装在 /opt 目录下

```bash
mkdir /opt/nexus
```

- 在 `nexus` 文件夹中新增 `docker-compose.yaml` 文件

```bash
vim /opt/nexus/docker-compose.yaml
```

```yaml
version: "2"

services:
  nexus:
    image: sonatype/nexus3
    volumes:
      - ./nexus-data:/nexus-data
    ports:
      - 8081:8081
```

- 开启服务

```bash
cd /opt/nexus
docker-compose up -d
```

- 查看默认密码

```bash
docker-compose exec nexus cat /nexus-data/admin.password
```

- 登录界面

访问 `http://<ip>:8081` 并使用 `admin` 账户进行登录。

### 软件源配置

在 Nexus 中软件源分为以下三种：

- hosted (本地直接存储)
- proxy (远程文件代理)
- group (资源组)

其中 hosted 需要本地上传，proxy 需要指定远程目录地址，而 group 可以将这两种资源整合起来对外提供服务。
