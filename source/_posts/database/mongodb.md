---
title: MongoDB
date: 2021-06-07 23:09:32
tags:
- "MongoDB"
id: mongodb
no_word_count: true
no_toc: false
categories: "MongoDB"
---

## MongoDB Community Edition

### 简介

MongoDB 是一个通用的文档数据库，可以使用社区版的 MongoDB 进行本地使用。

### 部署方式

可以使用如下 `docker-compose.yaml` 文件部署服务：

```yaml
services:
  mongo:
    image: mongodb/mongodb-community-server:latest
    user: "1000:1000"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=root
      - MONGO_INITDB_ROOT_PASSWORD=123456
      - MONGO_INITDB_DATABASE=demo
    ports:
      - "27017:27017"
    volumes:
      - type: bind
        source: ./data
        target: /data/db
```

> 注：运行用户不要是 root 会有权限问题。

使用如下命令即可运行服务：

```bash
mkdir -p data
docker-compose up -d
```

使用如下命令进入容器：

```bash
docker-compose exec mongo bash
```

使用如下命令进入交互式管理工具：

```bash
mongosh -u root -p
```

使用如下指令创建用户：

```text
use <db>
db.createUser({user:"<username>",pwd:"<password>",roles:[{role:"readWrite",db:"<db>"}]});
```

### 参考资料

[官方手册](https://www.mongodb.com/docs/manual/)
