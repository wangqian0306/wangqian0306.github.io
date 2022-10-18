---
title: KRaft
date: 2022-10-17 22:43:13
tags:
- "Kafka"
id: kraft
no_word_count: true
no_toc: false
categories: 参考资料
---

## KRaft

### 简介

最新的 Kafka 版本已经可以采用 KRaft 替代 ZooKeeper 了，所以再此进行一些知识整理。

### 原因及改善方式

根本原因：随着 Broker 数量和集群中主题(topic)分区(partition)的增加，仍然存在一些在伸缩情况下的读写 ZooKeeper 产生的流量瓶颈。

细节原因：

- 大多数的元数据更改传播都发生在 Controller 与 Broker 之间，并且与主题分区数量呈线性关系。
- Controller 需要向 ZooKeeper 写入更新的元数据信息来进行持久化，所以最终所花的时间也与写入持久化的数据量成线性关系。
- 使用 ZooKeeper 作为元数据存储工具还有一些挑战，例如 Znodes 的数量限制，watcher 的最大数量限制，对 Broker 额外的合规性检查来保证每个 Broker 维护了自己的元数据视图。当更新延迟或重新排序时，这些元数据视图可能会有所不同。
- 保护、升级和调试是一件很痛苦的事情。简化分布式系统可延长其使用寿命和稳定性。

改善方式：

- 使用 Controller 直接维护元数据日志，并将其作为内部主题进行存储。

> 注：这样一来也就意味着操作会被有序的追加记录在元数据中，并与异步日志 I/O 一起批处理，以实现更好的性能。

- 元数据更改传播会被 Broker 通过复制元数据变更日志而不是 RPC 的方式完成。

> 注：这意味着不需要再担心一致性的问题，每个 Broker 的元数据视图最终都会保持一致，因为它们来自与同一日志，并且当前所处的状态与 offset 相关。另一个好处是，这将 Controller 的元数据日志与其他日志分离进行管理。(具有单独的端口，请求处理队列，指标，线程等)。

- 通过将一小部分 Broker 同步元数据日志的方式，我们可以得到另一个 quorum 的 Controller 而不是单个 Controller。

### 实现细节

#### 数据同步方式

原先的 Kafka 采用了主备复制算法(Primary-Backup)：

Leader 接收到数据会将其复制到其他 Follower 副本，在 Follower 副本承认写入之后会写回信。具体流程如下：

[Primary-Backup](https://s6.jpg.cm/2022/10/17/PHmFAT.png)

最新的复制算法是仲裁复制(quorum replication)：

Leader 接收到数据会将其复制到其他 Follower 副本，在 Follower 副本副本承认写入之后会写回信。在大部分 Follower 返回回信之后 Leader 将认为写入已提交，并将返回到写入客户端。

[quorum replication](https://s6.jpg.cm/2022/10/17/PHpTFQ.png)

KRaft 选用仲裁复制算法的原因是：

- 为了可用性，可以负担核心元数据日志的更多副本
- 因为系统对元数据的追加写入延迟很敏感，这样的情况会是集群的热点

#### 选举方式

集群内共有三种角色：Leader，Voter 和 Observer。Leader 和其他 Voter 共同组成 Quorum，并负责保持复制的日志的共识，并在需要时选举新的 Leader。在集群内的其他 Broker 都是 Observer，它们只负责被动的读取复制日志来跟随 Quorum。每条记录在写入日志时都会加上 Leader 的 Epoch。

在集群启动后，所有 Broker 会按照初始配置的 Quorum 成 Voter，并且从本地日志中读取当前 Epoch(Raft 原文中称为 term 即任期)。在下图中，让我们假设我们的 Quorum 为三名 Voter。每个记录在其本地日志中都有六条记录，分别带有绿色和黄色：

[初始环境](https://s6.jpg.cm/2022/10/18/PHfPhE.jpg)

经过一段时间而没有找到 Leader 后，Voter 可能会进入一个新的 Epoch，并过渡到作为 Leader 候选人的临时角色。然后，它将向 Quorum 中的所有其他 Broker 发送请求，要求他们投票支持它作为这个 Epoch 的新 Leader。

[投票请求](https://s6.jpg.cm/2022/10/18/PHfqnQ.jpg)

在投票请求中含有两部分的关键信息：其他 Broker 投票的 Epoch，和候选人本地日志的 offset。在接受投票的过程中，每个 Voter 会检查请求的 Epoch 是否大于其自己的 Epoch；如果已经投票过该 Epoch；或者它本地日志已经超出了给定的 offset。如果上述内容都是否，才会将此投票视为真实的。投票会被本地持久化存储，以便在 Quorum 中的 Broker 不会忘记投票的情况，即便是在刚刚启动时。当候选人收集到过半 Quorum 的选票(包括他自己)，就可以认为投票已经完成了。

需要注意的是如果在之前设置的时间期限内候选者没能获取到足够的投票，它将认为投票程序失败，并将尝试再次提高其 Epoch 并重试。为了避免任何僵局情况，例如多个候选人同时要求投票，从而防止另一个人获得足够的选票以应对颠簸的 Epoch，我们还引入了重试前的随机备份时间。

结合所有这些条件检查和投票超时机制，我们可以保证在 KRaft 上，在给定的 Epoch 最多有一个 Leader 当选，并且这个当选的 Leader 将拥有所有选票的记录。

#### 日志复制



### 参考资料

[Why ZooKeeper Was Replaced with KRaft – The Log of All Logs](https://www.confluent.io/blog/why-replace-zookeeper-with-kafka-raft-the-log-of-all-logs/)

[Getting Started with the KRaft Protocol](https://www.confluent.io/blog/what-is-kraft-and-how-do-you-use-it/)
