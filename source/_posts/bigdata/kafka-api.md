---
title: Kafka API
date: 2021-08-24 22:43:13
tags:
- "Kafka"
id: kafka-api
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka API

### 简介

Kafka 存在以下五种 API：

- Producer API
- Consumer API
- Streams API
- Connect API
- Admin API

### Producer API

Producer API 允许应用程序向 Kafka 集群中的主题发送数据流。

Produce API 使用了异步发送消息的方式，在发送过程中涉及的线程是 main 线程和 Sender 线程，以及一个线程共享变量——RecordAccumulator。

![Kafka 发送数据流程](https://i.loli.net/2021/08/24/YgBIm7HbrFNcvPp.png)

### Consumer API

Producer API 允许应用程序从 Kafka 集群中的主题拉取数据流。

![Kafka 消费数据流程](https://i.loli.net/2021/08/25/lp5OYrdqkW6vBNa.png)

### Streams API

Kafka Streams 是用于构建应用程序和微服务的客户端库，其中输入和输出数据存储在 Kafka 集群中。

### Connect API

Connect API 允许实现从某个源数据系统不断拉入 Kafka 或从 Kafka 推送到某个接收器数据系统的连接器。

### Admin API

Admin API 支持管理和检查主题、broker、acl 和其他 Kafka 对象。