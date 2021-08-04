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
version: "3"
services:
  redis:
    image: redis:latest
    container_name: redis
    ports:
      - "6379:6379"
```