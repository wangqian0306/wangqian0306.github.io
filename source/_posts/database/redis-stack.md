---
title: Redis Stack
date: 2022-09-29 22:12:59
tags: "Redis"
id: redis-stack
no_word_count: true
no_toc: false
categories: Redis
---

## Redis Stack

### 简介

Redis Stack 是 Redis 关于数据模型和处理引擎的扩展。包括了一些扩展模块和 RedisInsight 。

### 使用 Docker 安装

#### 服务器版

```yaml
version: "3"
services:
  redis-stack-server:
    image: redis/redis-stack-server:latest
    container_name: redis-stack-server
    ports:
      - "6379:6379"
```

#### 本地测试

```yaml
version: "3"
services:
  redis-stack-server:
    image: redis/redis-stack-server:latest
    container_name: redis
    ports:
      - "6379:6379"
      - "8001:8001" 
```

> 注：8001 端口是 RedisInsight 客户端管理工具的端口。~~~~

### 参考资料

[官方文档](https://redis.io/docs/stack/)
