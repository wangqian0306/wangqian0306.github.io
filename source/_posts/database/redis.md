---
title: Redis 安装及基础使用
date: 2021-08-04 22:12:59
tags: "Redis"
id: redis-install
no_word_count: true
no_toc: false
categories: Redis
---

## Redis 安装及基础使用

### 容器化安装

```yaml
services:
  redis:
    image: redis:latest
    container_name: redis
    ports:
      - "6379:6379"
```

### 客户端

Redis 官方提供了 `RedisInsight` 工具来协助用户管理数据库。

### 参考资料

[RedisInsight](https://redis.com/redis-enterprise/redis-insight/#insight-form)
