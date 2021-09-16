---
title: Kafka Connect
date: 2020-06-09 22:43:13
tags:
- "Kafka"
id: kafka-connect
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka Connect

### 简介

Kafka Connect 是一款接收数据库记录到 Kafka (source)和从 Kafka 将数据写入数据库(sink)的工具。

整体架构如下：

![Kafka Connect](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/7219853951/p68623.png)

### 使用

Kafka Connect 随着 Kafka 本体一起发布无须单独安装，但是如果你打算在生产环境使用它来移动大量的数据，或者打算运行多个连接器，那么最好把 Connect 部署在独立于 broker 的服务器上。

#### 修改配置文件

|配置项|说明|
|:---:|:---:|
|`bootstrap.servers`|Kafka Broker 地址|
|`group.id`|消费组 ID|
|`key.converter`|键转换器|
|`value.converter`|值转换器|

#### 启动 worker

- 分布式启动

```bash
bin/connect-distributed.sh config/connect-distributed.properties
```

- 单机启动

```text
bin/connect-standalone.sh config/connect-distributed.properties
```

#### 检测服务状态

访问服务地址

```text
http://localhost:8083/
```

#### 使用文件插件读取数据至 Kafka

```bash
echo '{"name":"load-kafka-config", "config":{"connector.class":"FileStream-Source","file":"config/server.properties","topic":"kafka-config-topic"}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"
```

读取话题查看链接情况

```bash
bin/kafka-console-consumer.sh --new --bootstrap-server=localhost:9092 --topic kafka-config-topic --from-beginning
```

#### 从 Kafka 写入文件

```bash
echo '{"name":"dump-kafka-config", "config":{"connector.class":"FileStreamSink","file":"copy-of-serverproperties","topics":"kafka-config-topic"}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"
```

查看文件

```bash
cat copy-of-server-properties
```

#### 删除链接器

```bash
curl -X DELETE http://localhost:8083/connectors/load-kafka-config
curl -X DELETE http://localhost:8083/connectors/dump-kafka-config
```


### 概念和原理

Kafka Connect 由如下内容组成：

#### 连接器和任务(Connectors and tasks)

连接器负责以下三个内容：

- 决定需要多少任务
- 按照任务来拆分数据并进行复制
- 从 worker 进程获取任务配置并将其进行传递

任务负责如下内容：

- 将数据移入或移出 Kafka

#### worker 进程

worker 进程是连接器和任务的 “容器”。它们负责：

- REST API 
- 配置管理
- 可靠性、高可用性、伸缩性和负载均衡

