---
title: Elasticsearch 入门
date: 2020-07-04 23:09:32
tags:
- "Elasticsearch"
- "Elastic Stack"
id: elasticsearch
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## Elasticsearch 入门

### 简介

Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎。

### 本地安装

在 CentOS 中可以使用如下命令配置软件源

```bash
vim /etc/yum.repos.d/elastic.repo
```

写入如下配置项即可

```text
[elastic]
name=elastic
baseurl=https://mirrors.tuna.tsinghua.edu.cn/elasticstack/yum/elastic-7.x/
enable=1
gpgcheck=0
```

在写入完成后可以使用如下命令安装软件

```bash
yum install elasticsearch -y
```

- 配置

软件配置在 `/etc/elasticsearch` 目录中。

默认日志在 `/var/log/elasticsearch` 目录中。

- JDK 配置建议

Xms 和 Xms 设置成一样。

XMx 不要超过机器内存的 50 %，不要超过 30 GB。

### 容器化安装

#### 单机运行

- 编写如下 Docker Compose 文件

```yaml
version: '3'
services:
  es:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.1
    environment:
      - discovery.type=single-node
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - 9200:9200
      - 9300:9300
```

- 使用如下命令启动运行

```bash
docker-compose up -d
``` 

#### 集群运行

- 编写如下 Docker Compose 文件

```yaml
version: '3'
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.1
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data01:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - elastic
  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.1
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data02:/usr/share/elasticsearch/data
    networks:
      - elastic
  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.15.1
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data03:/usr/share/elasticsearch/data
    networks:
      - elastic

volumes:
  data01:
    driver: local
  data02:
    driver: local
  data03:
    driver: local

networks:
  elastic:
    driver: bridge
```

- 使用如下命令启动运行

```bash
docker-compose up -d
```

> 注：如需在生产环境中使用 Docker 方式运行 Elasticsearch 请参照官方文档步骤进行细节调整。

### 常见问题

#### 索引不可写入

使用如下方式修改配置即可

`POST`: `http://<host>:<port>/_settings`

```json
{
  "index": {
    "blocks": {
      "read_only_allow_delete": "false"
    }
  }
}
```

> 注：若修改之后不生效请检查磁盘剩余空间。

### 参考资料

[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-keystore-bind-mount)