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

![改善结果](https://cwiki.apache.org/confluence/download/attachments/123898922/a.png?version=1&modificationDate=1564694752000&api=v2)

### 实现细节

#### 数据同步方式

原先的 Kafka 采用了主备复制算法(Primary-Backup)：

Leader 接收到数据会将其复制到其他 Follower 副本，在 Follower 副本承认写入之后会写回信。具体流程如下：

![Primary-Backup](https://s6.jpg.cm/2022/10/17/PHmFAT.png)

最新的复制算法是仲裁复制(quorum replication)：

Leader 接收到数据会将其复制到其他 Follower 副本，在 Follower 副本副本承认写入之后会写回信。在大部分 Follower 返回回信之后 Leader 将认为写入已提交，并将返回到写入客户端。

![quorum replication](https://s6.jpg.cm/2022/10/17/PHpTFQ.png)

KRaft 选用仲裁复制算法的原因是：

- 为了可用性，可以负担核心元数据日志的更多副本
- 因为系统对元数据的追加写入延迟很敏感，这样的情况会是集群的热点

#### 选举方式

集群内共有三种角色：Leader，Voter 和 Observer。Leader 和其他 Voter 共同组成 Quorum，并负责保持复制的日志的共识，并在需要时选举新的 Leader。在集群内的其他 Broker 都是 Observer，它们只负责被动的读取复制日志来跟随 Quorum。每条记录在写入日志时都会加上 Leader 的 Epoch。

在集群启动后，所有 Broker 会按照初始配置的 Quorum 成 Voter，并且从本地日志中读取当前 Epoch(Raft 原文中称为 term 即任期)。在下图中，让我们假设我们的 Quorum 为三名 Voter。每个记录在其本地日志中都有六条记录，分别带有绿色和黄色：

![初始环境](https://s6.jpg.cm/2022/10/18/PHfPhE.jpg)

经过一段时间而没有找到 Leader 后，Voter 可能会进入一个新的 Epoch，并过渡到作为 Leader 候选人的临时角色。然后，它将向 Quorum 中的所有其他 Broker 发送请求，要求他们投票支持它作为这个 Epoch 的新 Leader。

![投票请求](https://s6.jpg.cm/2022/10/18/PHfqnQ.jpg)

在投票请求中含有两部分的关键信息：其他 Broker 投票的 Epoch，和候选人本地日志的 offset。在接受投票的过程中，每个 Voter 会检查请求的 Epoch 是否大于其自己的 Epoch；如果已经投票过该 Epoch；或者它本地日志已经超出了给定的 offset。如果上述内容都是否，才会将此投票视为真实的。投票会被本地持久化存储，以便在 Quorum 中的 Broker 不会忘记投票的情况，即便是在刚刚启动时。当候选人收集到过半 Quorum 的选票(包括他自己)，就可以认为投票已经完成了。

需要注意的是如果在之前设置的时间期限内候选者没能获取到足够的投票，它将认为投票程序失败，并将尝试再次提高其 Epoch 并重试。为了避免任何僵局情况，例如多个候选人同时要求投票，从而防止另一个人获得足够的选票以应对颠簸的 Epoch，我们还引入了重试前的随机备份时间。

结合所有这些条件检查和投票超时机制，我们可以保证在 KRaft 上，在给定的 Epoch 最多有一个 Leader 当选，并且这个当选的 Leader 将拥有所有选票的记录。

#### 日志复制

与 Kafka 一样，KRaft 才有用拉取的机制来保持复制内容一致，而不是原始的 Raft 论文引入的基于推送的模型。在下图中，假设 Leader-1 在 Epoch 3 中有两条记录(红色的)，而 Voter-2 正在拉取此数据。

![数据拉取-1](https://s6.jpg.cm/2022/10/18/PHzAfi.jpg)

与 Kafka 中现有的复制副本获取逻辑一样，Voter-2 将在其提取请求中编码两条信息：要从中获取的 Epoch 及其日志和偏移量。收到请求后，Leader-1 将首先检查 Epoch，如果它有效，将返回从给定 offset 开始的数据。读取的 Voter-2 会将返回的数据追加到其本地日志中，然后使用新的偏移量再次开始读取。这里没有什么新东西，只是普通的复制副本获取协议。

但是，假设另一个 Voter 已经偏离了日志记录。在样例中，Voter-3 是 Epoch 2 上的旧领导者，其本地日志上有一些附加的记录，这些记录尚未复制到 Quorum。当意识到 Epoch 以 Leader-1 作为前导起始集时，它将向 Leader-1 发送一个包含 Epoch 2 以及日志和 offset 的提取请求。Leader-1 将验证并发现此 Epoch 和 offset 不匹配，因此将在响应中返回错误代码，告诉 Voter-3 Epoch 2 仅提交了 offset 为 6 的记录。然后，Voter-3 将截断其本地日志以达到 offset 6。

![数据拉取-2](https://s6.jpg.cm/2022/10/18/PHzXZk.jpg)

然后，Voter-3 将再次重新发送拉取请求，这次是 Epoch 2 和偏移量 6。然后，Leader-1 可以将 Epoch 中的数据返回到 Voter-3，后者将在附加到其本地日志时从返回的数据中了解此新 Epoch。

请注意，如果 Voter-2 和 Voter-3 无法在预定义的时间内成功从 Leader-1 中获取响应，则它可能会增加其 Epoch 并尝试选举为 Epoch 4 的新 Leader。因此，我们可以看到，这个 fetch 请求也被用作心跳来确定 Leader 的活跃度。

#### 拉取与推送方式复制数据的对比

与 Raft 文献中基于推送的模型相比，KRaft 中基于拉取的日志复制在日志协调方面更有效，因为 Voter 在提取操作时可以在重新发送下一次提取之前直接截断到可行的偏移量。在基于推送的模型中，需要很多的 "ping-pong" 交互(确认链接)，自从 Leader 推送数据开始就需要确认正确的目标日志的位置。

基于拉取的 KRaft 也更不易于收到服务器损坏的影响，例如：旧的 Voter 不知道它已被移除出 Quorum ，比方说经历了成员的重新配置。如果这些旧 Voter 继续向基于拉取的模型中的 Leader 发送 fetch 请求，则 Leader 可以使用特殊的错误代码进行响应，告诉他们他们已从仲裁中删除，并且可以转换为观察者。在原始推送模型的 Raft 中则正相反，推送数据的 Leader 并不知道哪一个 Voter 会变成 [disruptive servers](https://dl.acm.org/doi/10.1145/2723872.2723876) 。自从被移除的节点没有获取到 Larder 任何推送的数据后，他们就会尝试选举自己作为新的 Leader，从而中断原始进程。

另一个选用拉取模型的 Raft 协议的动机是 Kafka 作为基石的日志复制层已经是基于拉取模型建立的，因此可以更多的实现重用。

但是这样做的好处是有代价的：新的 Leader 需要声明一个新的起始 Epoch API 来通知 Quorum 用于区分。在 Raft 模型中，此推送可以由 Leader 的 push data API 携带。此外为了向 Quorum 提交记录且被大多数节点认可，Leader 需要等待下一个 fetch 请求来推进 offset。这对于解决 disruptive servers 问题来说都是值得的。此外，利用现有的基于 Kafka 拉取的数据复制模型(“不造轮子”)节省了数千行代码。

要了解有关 KRaft 实现设计的其他详细信息（如元数据快照和基于 KRaft 日志构建的状态机 API）的更多信息，请务必阅读 [KIP-500](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500%3A+Replace+ZooKeeper+with+a+Self-Managed+Metadata+Quorum)、[KIP-595](https://cwiki.apache.org/confluence/display/KAFKA/KIP-595%3A+A+Raft+Protocol+for+the+Metadata+Quorum) 和 [KIP-630](https://cwiki.apache.org/confluence/display/KAFKA/KIP-630%3A+Kafka+Raft+Snapshot) 的参考文档。

#### Controller

使用 KRaft 之后和 ZooKeeper 一样选举出的 Leader 也会作为 Controller。其会负责接受新的 Broker 注册，检测 Broker 故障以及接收所有会更改集群元数据的请求。所有这些操作都可以按其相应的更改事件追加到元数据日志的时间进行管道传输和排序。Quorum 中的其他 Voter 会主动复制元数据日志，以便提交新追加的记录。

> 注：使用 KRaft 之后就不再有 ISR 的概念，因为所有数据都会经过 Quorum 的仲裁。且元数据也会生成快照用于快速恢复。

### 参考资料

[Why ZooKeeper Was Replaced with KRaft – The Log of All Logs](https://www.confluent.io/blog/why-replace-zookeeper-with-kafka-raft-the-log-of-all-logs/)

[Getting Started with the KRaft Protocol](https://www.confluent.io/blog/what-is-kraft-and-how-do-you-use-it/)

[KIP-500](https://cwiki.apache.org/confluence/display/KAFKA/KIP-500%3A+Replace+ZooKeeper+with+a+Self-Managed+Metadata+Quorum)

[KIP-595](https://cwiki.apache.org/confluence/display/KAFKA/KIP-595%3A+A+Raft+Protocol+for+the+Metadata+Quorum)

[KIP-630](https://cwiki.apache.org/confluence/display/KAFKA/KIP-630%3A+Kafka+Raft+Snapshot)
