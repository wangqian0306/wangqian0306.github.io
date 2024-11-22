---
title: Watchtower
date: 2024-11-22 21:41:32
tags: "Container"
id: watchtower
no_word_count: true
no_toc: false
categories: Container
---

## Watchtower

### 简介

Watchtower 是一个 Docker，它主要被用来自动更新容器镜像。

> 注：此项目只能在开发环境使用。

### 使用方式

可以使用 docker-compose 部署：

```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - REPO_USER=<user>
      - REPO_PASS=<password>
    command: --interval 14400
    restart: always
```

> 注：interval 表示检查镜像的时间单位为秒，样例是 4 小时拉一次。

### 参考资料

[官方项目](https://github.com/containrrr/watchtower)

[官方文档](https://containrrr.dev/watchtower)
