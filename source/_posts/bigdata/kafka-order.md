---
title: Kafka 消息顺序
date: 2021-05-31 22:43:13
tags:
- "Kafka"
id: kafka-order
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka 消息顺序

### 简介

在需要保证消息顺序的情况下应当采用如下的方式使用 Kafka。

### 概念说明

在 Kafka 中每个 `topic` 会有一个或多个 `partition`，而在含有多个 `partition` 的情况下就无法保证消息有序了。

那我们可以通过限制 `partition` 数量的方式来确保顺序。

> 注： 由于 Kafka 的分区数量可以增加所以此处还需额外针对 `key` 和 `partition` 进行维护。

### 官方说明

```text
Events with the same event key (e.g., a customer or vehicle ID) are written to the same partition,
 and Kafka guarantees that any consumer of a given topic-partition will always read that partition's
  events in exactly the same order as they were written.
```

> 注：节选自 Kafka 官方文档 1.1 节 `Main Concepts and Terminology`

### 实现方式

所以可以得出以下结论：

在同 `key` 在同个 `partition` 中，Kafka 的消息顺序是可以保证的。

所以在实际使用中，我们可以为需要排序的内容指定 `partition` 的方式来确保消息顺序。

### 可能遇到的问题

当 Kafka 在遇到消息发送失败的情况下会进行如下图所示的重试：

![Kafka 消息发送](https://miro.medium.com/max/700/1*TDcFaq7kDN_gnOmL2D7R-Q.png)

而这种情况又会导致 **乱序**。

为了解决此问题有两种解决方案：

- 抛弃重试策略 (不可接受)
- 在重试时不接受其他消息

在《Kafka 权威指南》这本书里的描述是这样的：

> Kafka 可以保证同一个分区里的消息是有序的。也就是说，如果生产者按照
> 一定的顺序发送消息，broker 就会按照这个顺序把它们写入分区，消费者也
> 会按照同样的顺序读取它们。在某些情况下，顺序是非常重要的。例如，往
> 一个账户存入 100 元再取出来，这个与先取钱再存钱是截然不同的！不过，
> 有些场景对顺序不是很敏感。
> 如果把 retries 设为非零整数，同时把 max.in.flight.requests.per.connection
> 设为比 1 大的数，那么，如果第一个批次消息写入失败，而第二个批次写入
> 成功，broker 会重试写入第一个批次。如果此时第一个批次也写入成功，那
> 么两个批次的顺序就反过来了。
> 一般来说，如果某些场景要求消息是有序的，那么消息是否写入成功也是
> 很关键的，所以不建议把 retries 设为 0。可以把 max.in.flight.requests.
> per.connection 设为 1，这样在生产者尝试发送第一批消息时，就不会有其
> 他的消息发送给 broker。不过这样会严重影响生产者的吞吐量，所以只有在
> 对消息的顺序有严格要求的情况下才能这么做。

### 参考资料

[Kafka 官方文档](http://kafka.apache.org/documentation/)

[Kafka : Ordering Guarantees](https://medium.com/@felipedutratine/kafka-ordering-guarantees-99320db8f87f#:~:text=Now%20it's%20better%2C%20Kafka%20preser,read%20them%20in%20that%20order)

[Kafka The Definitive Guide](https://www.confluent.io/wp-content/uploads/confluent-kafka-definitive-guide-complete.pdf)

> 注：《Kafka 权威指南》有中文版