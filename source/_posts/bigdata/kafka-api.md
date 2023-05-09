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

在发送数据时可以采用以下三种方式:

- 发送并忘记(fire-and-forget)

我们把消息发送给服务器，但井不关心它是否正常到达。大多数情况下，消息会正常到达，因为Kafka 是高可用的，而且生产者会自动尝试重发。不过，使用这种方式有时候也会丢失一些消息。

> 注：在需要严格的数据顺序时不建议采用此种方式。

- 同步发送

我们使用 `send()` 方怯发送消息，它会返回一个 Future 对象，调用 `get()` 方法进行等待，就可以知道悄息是否发送成功。

- 异步发送

我们调用 `send()` 方怯，并指定一个回调函数，服务器在返回响应时调用该函数。

> 注：只有在不改变主题分区数量的情况下，键与分区之间的映射才能保持不变。

简单使用

```python
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers='xxx:xxx,xxx:xxx')
producer.send('<topic>', key=b'<key>', value=b"<value>")
producer.close()
```

> 注：尽量使用域名而不要写 IP 地址！因为此问题在之前的使用过程中遇到了程序正常运行却没有输出的麻瓜问题。

### Consumer API

Producer API 允许应用程序从 Kafka 集群中的主题拉取数据流。

![Kafka 消费数据流程](https://i.loli.net/2021/08/25/lp5OYrdqkW6vBNa.png)

> 注：在同一个群组里，我们无法让一个线程运行多个消费者，也无法让多个线程安全的共享一个消费者。如有需要可以使用 Java 的 Executor Service 启动多个线程，使每个消费者运行在自己的线程上。

在接收数据时也可以采用以下几种种方式提交偏移量(offset):

- 自动提交

在 `enable.auto.commit` 参数设置为 true 时，每过 5 秒(`auto.commit.interval.ms`)，消费者会把 `poll()` 方法接收到的最大偏移量提交上去。

可能会有数据重复，但一般情况下不会有什么问题，不过在处理异常或提前退出轮询时要格外小心。

- 手动提交

在手动提交时需要将 `enable.auto.commit` 参数设置为 false，然后使用 `commitSync()` 方法提交偏移量。

- 异步提交

`commitSync()` 方法在成功提交或碰到无怯恢复的错误之前都会一直重试，但 `commitAsync()` 方法不会。

与此同时带来的问题是可能会造成消息重复。需要尤其注意偏移量的提交顺序。

- 同步和异步组合提交

消费者关闭前一般会组合使用 `commitSync()` 和 `commitAsync()`。

如果一切正常，我们使用 `commitAsync()` 方法提交，若如果直接关闭消费者则会使用 `commitSync()` 方法。

简单使用

```python
from kafka import KafkaConsumer

consumer = KafkaConsumer(bootstrap_servers='xxxx:xxxx,xxxx:xxxx', topic='<topic>', group_id='<group>')
for msg in consumer:
    print (msg)
```

### Streams API

Kafka Streams 是用于构建应用程序和微服务的客户端库，其中输入和输出数据存储在 Kafka 集群中。

### Connect API

Connect API 允许实现从某个源数据系统不断拉入 Kafka 或从 Kafka 推送到某个接收器数据系统的连接器。

在此时我们可以把 Kafka 看成一个数据管道。

### Admin API

Admin API 支持管理和检查主题、broker、acl 和其他 Kafka 对象。