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

### 参考资料

[Why ZooKeeper Was Replaced with KRaft – The Log of All Logs](https://www.confluent.io/blog/why-replace-zookeeper-with-kafka-raft-the-log-of-all-logs/)

[Getting Started with the KRaft Protocol](https://www.confluent.io/blog/what-is-kraft-and-how-do-you-use-it/)
