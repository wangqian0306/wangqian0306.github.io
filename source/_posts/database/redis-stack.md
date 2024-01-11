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
  redis-stack:
    image: redis/redis-stack:latest
    container_name: redis
    ports:
      - "6379:6379"
      - "8001:8001"
```

> 注：8001 端口是 RedisInsight 客户端管理工具的端口。

#### 增强功能

Redis Stack 与原版 Redis 相比有如下的增强：

设计方面：

- 支持使用 Hashset 和 JSON 两种基本数据类型，且可以使用索引、全文检索、聚合查询等功能

功能方面：

- 图数据存储和检索
- 时序型数据存储和检索
- 矢量相似性搜索
- 概率数据结构
  - 布隆过滤器(Bloom Filter)
  - 布谷过滤器(Cuckoo Filter)
  - Count-min Sketch 算法
  - Top-K 工具

### 使用样例

#### 检索数组

可以使用如下方式插入样例数据：

```text
JSON.SET demo $ '{"name":"Paul John","email":"paul.john@example.com","age":42,"city":"London","temp":[1.1,2.2,3.3,4.4,5.5,6.6,7.7,8.8,9.9,10,11.11,12.12,13.13,14.14,15.15,16.16,17.17,18.18]}'
```

使用如下命令即可获取数组中取样步长为2的所有元素：

```text
JSON.GET demo $.temp[0:-1:2]
```

### 参考资料

[官方文档](https://redis.io/docs/stack/)
