---
title: AList
date: 2024-05-21 22:26:13
tags:
- "AList"
id: alist
no_word_count: true
no_toc: false
---

## AList

### 简介

AList 是一个支持多种存储的网盘管理工具。

### 安装

编写如下 `docker-compose.yaml` :

```yaml
services:
  alist:
    image: 'xhofe/alist:latest'
    container_name: alist
    volumes:
      - '/etc/alist:/opt/alist/data'
    ports:
      - '5244:5244'
    environment:
      - PUID=0
      - PGID=0
      - UMASK=022
    restart: unless-stopped
```

然后使用如下命令启动服务即可：

```bash
docker-compose up -d
```

### 第三方版本

[小雅](https://hub.docker.com/r/xiaoyaliu/alist)

使用第三方版本可以自带一些内容源。

> 注：如需使用 API 可以使用命令 `alist <user> set <password>` 的方式自行设置密码，并在 nginx 配置中打开相应路由。  

### 参考资料

[官方项目](https://github.com/alist-org/alist)

[官方文档](https://alist.nn.ci/zh/guide/)
