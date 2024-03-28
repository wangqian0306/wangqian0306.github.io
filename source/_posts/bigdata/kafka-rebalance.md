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

### 处理流程

整个 Rebalance 分为三个阶段：Group Epoch, Assignment Epoch, Member Epoch。

#### Group Epoch - 触发 Rebalance

在组中的元数据变更时会触发 Rebalance，具体来说有以下情况：

- 成员加入或离开组
- 成员更新订阅信息
- 成员更新 assignors
- 成员更新 assignors 的原因或元数据
- Coordinator 发现某个成员需要被移除或被他隔离
- 分区元数据变更，例如新增了分区或新匹配的主题被创建

在匹配以上情况的时候会生成新的版本号，而版本号会被存储到组的元数据中同时也意味着会触发一次 assignment。

#### Assignment Epoch - 计算组的分配

当 Group 的版本号大于 Assignment 的版本号时 Coordinator 会按照当前的 Group 元数据计算重新分配的方法并将其持久化。

Coordinator 返回的分配计划只有两种情况，一种是根据默认的服务端分配器计算，另一种是向组内的一个成员请求新的分配计划。

#### Member Epoch - 组内协调

在新 Assignment 写入完成时，组员会独立协调当前与新的目标的分配。最终明确自己的目标分区和任务。协调过程有以下三个阶段：

- Coordinator 撤销不再属于成员目标分配的分区(取交集)
- 当 Coordinator 收到撤销确认时，它会将成员当前分配更新为其目标分配并持久保留它
- Coordinator 将新分区分配给成员，它通过向成员提供目标分区来实现此目的，同时确保尚未被其他成员撤消但已从此集中删除的分区

重新平衡超时由成员在加入组时提供。它基本上是在客户端配置的最大轮询间隔。当组协调器处理检测信号请求时，计时器开始工作。

### 分配流程

组的新目标基本上就是一个入参为当前组的元数据和当前目标的函数。需要注意的是分配是声明性的而不是像当前版本一样是递增的。换言之，assignors 定义组的所需状态，并让 Coordinator 收敛到该状态。

#### Assignor 选择

Coordinator 必须确认究竟使用哪种分配策略。在分配时组内的成员可能有不同的 Assignor ，而 Coordinator 会按照如下方式选择 Assignor：

- 如果可能，使用客户端 Assignor。这意味着服务端 Assignor 必须得到所有成员的支持。如果有多个，则在成员公布其支持的客户端 Assignor 时，它将尊重成员定义的优先级。

- 否则使用服务器端 Assignor。如果在组中指定了多个服务器端 Assignor，则 Coordinator 将使用最常见的分配器。如果成员未提供Assignor，则组协调器将默认为 group.consumer.assignors 中的第一个 Assignor 。

#### 服务端模式

服务端模式是可以进行配置的，客户端可以在心跳信号中声明要使用的 Assignor。若找不到则会爆出 UNSUPPORTED_ASSIGNOR 错误。支持的 Assignor 会在 Broker 配置中列出。官方提供了两种 Assignor ：

- [range](https://github.com/apache/kafka/blob/trunk/group-coordinator/src/main/java/org/apache/kafka/coordinator/group/assignor/RangeAssignor.java)
- [uniform](https://github.com/apache/kafka/blob/trunk/group-coordinator/src/main/java/org/apache/kafka/coordinator/group/assignor/UniformAssignor.java)

> 注：请注意，在这两种情况下，Assignor 都是粘性的。目标是尽量减少分区移动。

#### 客户端模式

客户端分配由消费者执行。整个过程分为以下几个阶段：

- Coordinator 选择一个成员来运行分配逻辑
- Coordinator 通过在成员的下一个检测信号响应中设置 ShouldComputeAssignment 字段来通知成员计算新分配
- 当成员收到此错误时，应调用 ConsumerGroupPrepareAssignment API 来获取当前组元数据和当前目标分配
- 成员使用相关 Assignor 计算分配
- 成员调用 ConsumerGroupInstallAssignment API 来安装新分配。Coordinator 对其进行验证并保留它

> 注：就算是有新的阶段，也会保留分配，以确保组始终可以继续运行，避免单点故障。Coordinator 一次只运行一次分配任务。

所选成员应在重新平衡超时内完成分配过程。当成员收到通知时 Coordinator 端开始计时。如果该过程未在重新平衡超时内完成，则组协调员将选取另一个成员来运行分配。请注意，此处未对先前选择的成员进行隔离，因为隔离仅基于会话。

### 简单理解

假设某个主题有 6 个分区，然后有两个消费者 A B 以 Epoch 5 为当前阶段：

```text
Consumer        Group Coordinator Current        Group Coordinator Target
A(5) [1,2,3]        A(5) [1,2,3]                     A(5) [1,2,3]
B(5) [4,5,6]        B(5) [4,5,6]                     B(5) [4,5,6]
```

在心跳信息返回正常的情况下会持续进行消费，如果此时来了个 C 客户端，向 Group Coordinator 发送注册请求的时候，Group Coordinator 会回复给他，当前在 Epoch 5，然后向 A B 发出撤销 `[3]`, `[6]` 命令撤销完成后更新 Epoch，Group Coordinator 再分配给 C：

```text
Consumer        Group Coordinator Current        Group Coordinator Target
A(5) [1,2,3]        A(5) [1,2,3]                     A(6) [1,2]
B(5) [4,5,6]        B(5) [4,5,6]                     B(6) [4,5]
C(0) []                                              C(6) [3,6]
```

假设此时 A 挂了，但是 B 正常运行：

```text
Consumer        Group Coordinator Current        Group Coordinator Target
B(6) [4,5]        B(6) [4,5]                         B(7) [4,5,1]
C(6) [6]          C(6) [6]                           C(7) [6,2,3]
```

之后和上一步的流程一样，最后就会变成  `B(7) [4,5,1]` `C(7) [6,2,3]`。

### 参考资料

[KIP-848 The Next Generation of the Consumer Rebalance Protocol](https://cwiki.apache.org/confluence/display/KAFKA/KIP-848%3A+The+Next+Generation+of+the+Consumer+Rebalance+Protocol)

[Apache Kafka's Next-Gen Rebalance Protocol: Towards More Stable and Scalable Consumer Groups](https://www.confluent.io/events/current/2023/apache-kafkas-next-gen-rebalance-protocol-towards-more-stable-and-scalable/)
