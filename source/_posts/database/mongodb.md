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
    image: mongo:4.4.1
    container_name: mongo
    restart: always
    volumes:
      - ./configdb:/data/configdb
      - ./db:/data/db
    ports:
      - 27017:27017
    command: --bind_ip_all --wiredTigerCacheSizeGB 48 --oplogSize 1048576
    environment:
      - MONGO_INITDB_DATABASE=<db>
      - MONGO_INITDB_ROOT_USERNAME=<username>
      - MONGO_INITDB_ROOT_PASSWORD=<password>
      - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      - GOSU_VERSION=1.12
      - JSYAML_VERSION=3.13.1
      - GPG_KEYS=20691EEC35216C63CAF66CE1656408E390CFB1F5
      - MONGO_PACKAGE=mongodb-org
      - MONGO_REPO=repo.mongodb.org
      - MONGO_MAJOR=4.4
      - MONGO_VERSION=4.4.1
      - UID=<uid>
      - GID=<gid>
```

使用如下命令即可运行服务：

```bash
docker-compose up -d
```

使用如下命令进入容器：

```bash
docker-compose exec mongo bash
```

使用如下命令进入交互式管理工具：

```bash
mongo -u root -p
```

使用如下指令创建用户：

```text
use admin
db.createUser({user:"<username>",pwd:"<password>",roles:[{role:"readWrite",db:"<db>"}]}
```

### 参考资料

[官方手册](https://www.mongodb.com/docs/manual/)
