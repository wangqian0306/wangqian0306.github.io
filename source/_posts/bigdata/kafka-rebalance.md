---
title: Kafka Rebalance
date: 2024-03-11 22:43:13
tags:
- "Kafka"
id: kafka-rebalance
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka Rebalance

### 简介

Kafka Rebalance 是 Apache Kafka 中的一个重要概念，用于在消费者组中重新分配分区的过程。

当消费者组中的消费者实例数量发生变化时，例如有新的消费者加入或者已有的消费者退出，Kafka 会触发重新平衡（Rebalance）操作。重新平衡的目的是重新分配主题的分区给各个消费者实例，以确保每个消费者实例负责处理的分区数尽可能均衡。

之前版本的 Rebalance 有如下缺点：

- 将太多的功能都交给了 Client 导致其过于臃肿。
- 依赖于组范围的同步屏障。这意味着一个行为不端的消费者可以摧毁或扰乱整个群体，因为每当消费者加入、离开或失败时，都需要重新平衡整个群体。
- 复杂，经历过 [KIP-429](https://cwiki.apache.org/confluence/display/KAFKA/KIP-429%3A+Kafka+Consumer+Incremental+Rebalance+Protocol) 和 [KIP-345](https://cwiki.apache.org/confluence/display/KAFKA/KIP-345%3A+Introduce+static+membership+protocol+to+reduce+consumer+rebalances) 增强。
- 引入了传播机制，在 Client 端和 Broker 端都不是很清晰。 

所以在 Kafka 3.7 中引入了 [KIP-848](https://cwiki.apache.org/confluence/display/KAFKA/KIP-848%3A+The+Next+Generation+of+the+Consumer+Rebalance+Protocol)

最终的实现目标是：

- 实现真正的增量和协作重平衡，不再依赖全局同步屏障
- 复杂性应该从消费者转移到组协调者
- 该协议仍应允许高级用户（如 Kafka Streams）在客户端上运行分配逻辑。
- 该协议应提供与当前协议相同的保证，即在最坏的情况下至少完成一次，而在正常情况下恰好完成一次
- 该协议应支持在不停机的情况下升级 Consumer

### 实现方式

总的实现思路是采用两种分配方式：

- Coordinator 使用服务端分配器进行计算(默认)
- 指定一个消费组成员，使用客户端分配器进行计算(自定义)

在默认方式中，新的分配方式会增强原有的心跳信息，并以此方式让 Coordinator 向组成员分配/撤销分区，同时允许组成员将其当前状态传播到 Coordinator。

在自定义方式中 Coordinator 会通过心跳通知组内的特定成员，该成员收到通知后会向 Coordinator 获取组的当前状态与它被分配到的分区。

### 时间和事件流程



### 参考资料

[KIP-848 The Next Generation of the Consumer Rebalance Protocol](https://cwiki.apache.org/confluence/display/KAFKA/KIP-848%3A+The+Next+Generation+of+the+Consumer+Rebalance+Protocol)
