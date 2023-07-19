---
title: PostgreSQL
date: 2023-07-19 23:09:32
tags:
- "PostgreSQL"
id: postgresql
no_word_count: true
no_toc: false
categories: "PostgreSQL"
---

## PostgreSQL

### 简介

PostgreSQL 是一个对象关系数据库管理系统（ORDBMS）

### 部署方式

#### Docker

- 编写如下 Docker Compose 文件

```yaml
version: '3.1'

services:
  db:
    image: postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: example
```

- 使用如下命令启动运行

```bash
docker-compose up -d
```

### 参考资料

[官方文档](https://www.postgresql.org/docs/current/index.html)
