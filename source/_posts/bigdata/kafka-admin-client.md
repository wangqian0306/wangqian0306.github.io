---
title: KafkaAdminClient
date: 2021-10-19 22:43:13
tags:
- "Kafka"
- "Java"
id: kafka-admin-client
no_word_count: true
no_toc: false
categories: 大数据
---

## KafkaAdminClient

### 简介

虽然可以使用命令行脚本来管理 Kafka，但是如果想在应用程序，运维框架或是监控平台中集成它们就会很困难。而且在服务器端的脚本通常是使用**Kafka服务器端代码**运行的，不会有权限相关的限制。在这种情况下就可以使用 KafkaAdminClient。

> 注：服务器端也有一个 AdminClient 但是社区已经不再推荐使用它了。

### 功能

1. 主题管理：包括主题的创建、删除和查询。
2. 权限管理：包括具体权限的配置与删除。
3. 配置参数管理：包括 Kafka 各种资源的参数设置、详情查询。所谓的 Kafka 资源，主要有 Broker、主题、用户、Client-id 等。
4. 副本日志管理：包括副本底层日志路径的变更和详情查询。
5. 分区管理：即创建额外的主题分区。
6. 消息删除：即删除指定位移之前的分区消息。
7. Delegation Token 管理：包括 Delegation Token 的创建、更新、过期和详情查询。
8. 消费者组管理：包括消费者组的查询、位移查询和删除。
9. Preferred 领导者选举：推选指定主题分区的 Preferred Broker 为领导者。

### 设计

AdminClient 是一个双线程的设计：分为前端主线程和后端 I/O 线程。

前端线程负责将用户要执行的操作转换成对应的请求，然后再将请求发送到后端 I/O 线程的队列中；而后端 I/O 线程从队列中读取相应的请求，然后发送到对应的 Broker 节点上，之后把执行结果保存起来，以便等待前端线程的获取。

![KafkaAdminClient 设计方式](https://i.loli.net/2021/10/19/7DNXKt5MCqLsmhT.png)

### 链接例程

```text
Properties props = new Properties();
props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka-host:port");
props.put("request.timeout.ms", 600000);

try (AdminClient client = AdminClient.create(props)) {
         // 执行你要做的操作……
}
```

### 参考资料

[Kafka 核心技术与实战](https://time.geekbang.org/column/intro/100029201)