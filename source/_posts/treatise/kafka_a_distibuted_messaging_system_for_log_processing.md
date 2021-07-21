---
title: Kafka a Distributed Messaging System for Log Processing 中文翻译版
date: 2021-06-17 22:26:13
tags:
- "论文"
- "Kafka"
id: kafka_a_distibuted_messaging_system_for_log_processing
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka: a Distributed Messaging System for Log Processing

作者：

Jay Kreps, Neha Narkhede, Jun Rao

### 原版的版权说明

```text
Permission to make digital or hard copies of all or part of this work for personal or classroom use
is granted without fee provided that copies are not made or distributed for profit or commercial 
advantage and that copies bear this notice and the full citation on the first page. 
To copy otherwise, or republish, to post on servers or to redistribute to lists, 
requires prior specific permission and/or a fee. NetDB'11, Jun. 12, 2011, Athens, Greece.
Copyright 2011 ACM 978-1-4503-0652-2/11/06…$10.00.
```

### 摘要

日志处理已经是消费互联网公司数据管道的关键组成部分。
我们将介绍 Kafka，这是一个分布式消息系统，我们开发该系统是为了以低延迟收集和传递大量日志数据。
我们的系统融合了现有日志聚合和消息传递系统的思想，适合离线和在线消息消费。
我们在 Kafka 中做了很多非传统但实用的设计选择，使我们的系统高效且可扩展。
实验结果表明与两种流行的消息系统相比，Kafka 具有更好的性能。
我们在生产环境中使用 Kafka 已经有一段时间了，它每天要处理数百 GB 的新数据。

#### General Terms

Management, Performance, Design, Experimentation.

#### 关键词

消息、分布式、日志处理、吞吐量、在线。

### 1 引言

任何一家大型互联网公司都会产生大量的“日志”数据。
这些数据通常包括:

1. 与登录、页面浏览、点击、“喜欢”、共享、评论和搜索查询相对应的用户活动事件
2. 操作度量，如服务调用堆栈、调用延迟、错误，以及系统度量，如每台计算机上的CPU、内存、网络或磁盘利用率。

日志数据长期以来一直是用于跟踪用户参与度、系统利用率和其他指标的分析的一个组成部分。
然而，最近互联网应用的趋势使得活动数据成为生产数据管道的一部分并将其直接用于站点上的特定功能。
这些用途包括：

1. 搜索相关性
2. 在活动的数据流中获取流行的或是共性的推荐
3. 广告定位和数据报告
4. 防止垃圾邮件或未经授权的数据抓取等滥用行为的安全应用程序
5. 用户的“朋友”或“联系人”获取用户状态的更新或新闻的功能

这种日志数据的产生、实时使用给数据系统带来了新的挑战，因为它的容量比“真实”数据大几个数量级。
例如，搜索、推荐和广告通常需要计算精确的点击率，这不仅会为每个用户点击生成日志记录，而且还会为每个页面上未点击的几十个项目生成日志记录。
中国移动每天收集 5-8 TB 的通话记录 `[11]`，而 Facebook 则收集了近 6 TB 的各种用户活动事件 `[12]`。

许多用于处理此类数据的早期系统依赖于从生产服务器上物理抓取日志文件进行分析。
近年来，已经构建了几个专门的分布式日志聚合器，包括 Facebook 的 Scribe `[6]`、雅虎的 Data Highway `[4]` 和 Cloudera 的 Flume `[3]`。
这些系统主要设计用于收集日志数据并将其加载到数据仓库或 Hadoop `[8]` 中以供离线使用。

我们为日志处理构建了一个新的消息系统，称为 Kafka `[18]`，它结合了传统日志聚合和消息系统的优点。
一方面，Kafka 是分布式和可扩展的，以此来提供高吞吐量。
另一方面，Kafka 提供了一个类似于消息系统的 API，允许应用程序实时消费日志事件。
Kafka 已经开源并在 LinkedIn 的生产环境中成功使用了 6 个多月。
它极大地简化了我们的基础设施，使我们可以利用一个软件来在线和离线消费所有类型的日志数据。
本文的其余部分安排如下。
我们在第 2 节中会重新审视传统的日志聚合和消息系统。
我们在第 3 节中会描述 Kafka 的架构及其关键设计原则。
我们在第 4 节中描述了我们在 LinkedIn 上部署的 Kafka，在第 5 节中描述了 Kafka 的性能。
我们在第 6 节中进行总结并讨论未来的工作。

### 2 相关内容

传统的企业消息系统 `[1][7][15][17]` 已经存在了很长时间，并且经常作为处理异步数据流的事件总线发挥着关键作用。
但是，有几个原因导致它们往往不适合处理日志。
首先，企业系统提供的功能与目的不匹配。
这些系统通常专注于提供丰富的交付保证。
例如，IBM Websphere MQ `[7]` 具有事务支持，允许应用程序以原子方式将消息插入多个队列。
JMS `[14]` 规范允许在消费后确认每个单独的消息，然而这些消息可能是无序的。
这种交付保证对于收集日志数据来说通常是多余的。
例如，偶尔丢失一些网页浏览事件当然不会造成世界末日。
这些不需要的功能往往会增加 API 和这些系统的底层实现的复杂性。
其次，许多系统并没有像它们的主要设计约束那样强烈关注吞吐量。
例如，JMS 没有在单个请求中批处理多个消息的 API。
这意味着每条消息都需要完整的 TCP/IP 往返，对于我们来说这样的吞吐量无法满足需求。
再次，这些系统在分布式支持方面很弱。
没有简单的方法可以在多台机器上分区和存储消息。
最后，许多消息系统假设消息几乎立即被消费，因此未消费的消息队列总是相当小。
如果允许消息累积，它们的性能会显着下降，对于离线消费者(例如数据仓库应用程序)执行定期大负载而不是连续消费的情况就是如此。

在过去的几年中，已经有了许多专门的日志聚合器。
Facebook 使用名为 Scribe 的系统。
每个前端机器都可以通过 Socket 将日志数据发送到一组 Scribe 机器。
每台 Scribe 机器都会聚合日志条目并定期将它们转储到 HDFS `[9]` 或 NFS 设备。
Yahoo 的 data highway 也有类似的数据流。
一组机器聚合来自客户端的事件并推出“分钟”级别的文件，然后将这些文件添加到 HDFS。
Flume 是 Cloudera 开发的一个相对较新的日志聚合器。
它支持可扩展的“管道”和“接收器”，可以非常灵活的处理流式日志数据。
它还具有更多集成的分布式支持。
然而，这些系统中的大多数都是为离线使用日志数据而构建的，并且经常向消费者不必要地公开实现细节(例如“分钟”级别的文件)。
此外，它们中的大多数使用“推送”模型，其中代理将数据转发给消费者。
在 LinkedIn，我们发现“拉取”模型更适合我们的应用程序，因为每个消费者都可以以它可以维持的最大速率检索消息，并避免被推送速度超过其处理速度的消息淹没。
拉动模型还可以轻松地回滚消费者，我们将在第 3.2 节末尾讨论这一益处。

最近 Yahoo 研究开发了一种新的分布式发布/订阅系统，称为 HedWig `[13]`。
HedWig 具有高度可扩展性和可用性，并提供强大的耐用性保证。
但是，它主要用于传输数据存储的提交日志。

### 3 Kafka 的架构和设计原则

由于现有系统的限制，我们开发了一个新的基于消息的日志聚合器 Kafka。
我们先介绍 Kafka 的基本概念。
特定类型的消息流由主题定义。
生产者可以向主题发布消息。
然后将发布的消息存储在一组称为 Broker 的服务器中。
消费者可以从 Broker 订阅一个或多个主题，并通过从 Broker 拉取数据来消费订阅的消息。

消息传递在概念上很简单，我们试图让 Kafka API 同样简单来反映这一点。
我们没有展示确切的 API，而是展示了一些示例代码来展示如何使用 API。
下面给出了生产者的示例代码。
消息载荷被定义为仅仅可以包含字节。
用户可以选择她最喜欢的序列化方法来对消息进行编码。
为了提高效率，生产者可以在单个发布请求中发送一组消息。

生产者代码样例：

```text
producer = new Producer(…);
message = new Message(“test message str”.getBytes());
set = new MessageSet(message);
producer.send(“topic1”, set);
```

要订阅一个主题，消费者首先要为该主题创建一个或多个消息流。
发布到该主题的消息将均匀分布到这些子流中。
Kafka 如何分发消息的细节将在 3.2 节中描述。
每个消息流都为正在生成的连续消息流提供了一个迭代器接口。
然后，消费者遍历流中的每条消息并处理消息的有效负载。
与传统迭代器不同，消息流迭代器永远不会终止。
如果当前没有更多消息要消费，迭代器会阻塞，直到新消息发布到主题。
我们支持多个消费者共同消费一个主题中所有消息的单个副本的点对点交付模型，以及多个消费者各自检索自己的主题副本的发布/订阅模型。

生产者代码样例：

```text
streams[] = Consumer.createMessageStreams(“topic1”, 1)
for (message : streams[0]) {
    bytes = message.payload();
    // do something with the bytes
}
```

![图 1: Kafka 的系统架构](https://i.loli.net/2021/06/21/wS6VP2IsZ5Cjz47.png)

Kafka 的整体架构如 图 1 所示。
由于 Kafka 本质上是分布式的，一个 Kafka 集群通常由多个 Broker 组成。
为了平衡负载，一个主题被分成多个分区，每个 Broker 存储一个或多个分区。
多个生产者和消费者可以同时发布和检索消息。
在第 3.1 节中，我们描述了 Broker 上单个分区的布局以及我们选择的一些设计选择，以提高访问分区的效率。
在第 3.2 节中，我们描述了生产者和消费者如何在分布式环境中与多个 Broker 交互。
在第 3.2 节中，我们描述了 Kafka 的交付保证。

#### 3.1 单个分区的效率

我们在 Kafka 中做出了一些决定，以使系统高效。

**简单的存储**：
Kafka 有一个非常简单的存储布局。
一个主题的每个分区对应一个逻辑日志。
在物理上，日志被实现为一组大小大致相同(例如，1 GB)的分段文件。
每次生产者向分区发布消息时，Broker 只需将消息附加到最后一个分段文件。
为了获得更好的性能，我们仅在发布了可配置数量的消息或经过一定时间后才将分段文件刷新到磁盘。
消息只有在刷新后才会暴露给消费者。

与典型的消息系统不同，存储在 Kafka 中的消息没有明确的消息 ID。
相反，每条消息都由其在日志中的逻辑偏移量(offset)寻址。
这避免了维护将消息 ID 映射到实际消息位置的辅助、搜索密集型随机访问索引结构的开销。
请注意，我们的消息 ID 是正在增加但不是连续的。
要计算下一条消息的 ID，我们必须将当前消息的长度加到它的 ID 上。
从现在开始，我们将交替使用消息 ID 和偏移量。

![图 2: Kafka 日志文件](https://i.loli.net/2021/06/21/CQPwzd2hlxSI9Ef.png)

消费者总是按顺序消费来自特定分区的消息。
如果消费者确认特定的消息偏移量，则意味着消费者已收到分区中该偏移量之前的所有消息。
在后台，消费者向 Broker 发出异步拉取请求，以准备好数据缓冲区供应用程序使用。
每个拉取请求都包含开始消费的消息的偏移量和可接受的要获取的字节数。
每个 Broker 在内存中保存一个排序的偏移列表，包括每个分段文件中第一条消息的偏移。
Broker 通过查找偏移量列表来定位请求消息所在的分段文件，并将数据发送回消费者。
消费者收到一条消息后，计算下一条要消费的消息的偏移量，并在下一个拉取请求中使用它。
Kafka 日志和内存中索引的布局如图 2 所示。
其中每个框显示消息的偏移量。

**传输效率**：
我们非常小心地将数据传入和传出 Kafka。
早些时候，我们已经说明了生产者可以在单个发送请求中提交一组消息。
尽管最终消费者 API 一次迭代一条消息，但在后台，来自消费者的每个拉取请求也会检索到特定大小(通常为数百 KB)的多条消息。

我们做出的另一个非常规选择是避免在 Kafka 层的内存中显式缓存消息。
相反，我们依赖底层文件系统页面缓存。
这具有避免双缓冲的主要好处——消息仅缓存在页面缓存中。
即使在 Broker 进程重新启动时，这也具有保留热缓存的额外好处。
由于 Kafka 根本不缓存进程中的消息，因此它在垃圾收集内存方面的开销很小，这使得在基于 VM 的语言中的高效实现变得可行。
最后，由于生产者和消费者都按顺序访问分段文件，消费者通常会落后于生产者少量，因此正常的操作系统缓存启发式方法非常有效
(特别是直写缓存和预读)。
我们发现生产和消费都具有与数据大小成线性关系的一致性能，最高可达数 TB 的数据。

此外，我们优化了消费者的网络访问。
Kafka 是一个多订阅者系统，一条消息可能会被不同的消费者应用程序多次消费。
将字节从本地文件发送到远程 Socket 的典型方法包括以下步骤：

1. 从存储介质中读取数据到 OS 中的页面缓存
2. 将页缓存中的数据复制到应用程序缓冲区中
3. 将应用程序缓冲区复制到另一个内核缓冲区
4. 将内核缓冲区发送到 Socket

这包括 4 个数据复制和 2 个系统调用。
在 Linux 和其他 Unix 操作系统上，存在一个发送文件 API `[5]`，可以直接将字节从文件通道传输到 Socket 通道。
这通常避免了在步骤(2)和(3)中引入的 2 个副本和 1 个系统调用。
Kafka 利用发送文件 API 有效地将日志分段文件中的字节从 Broker 传送到消费者。

**无状态 Broker**：
与大多数其他消息系统不同，在 Kafka 中，每个消费者消费了多少的信息不是由 Broker 维护，而是由消费者自己维护。
这样的设计降低了 Broker 的很多复杂性和开销。
然而，这使得删除消息变得棘手，因为代理不知道是否所有订阅者都消费了该消息。
Kafka 通过为保留策略使用简单的基于时间的 SLA 解决了这个问题。
如果消息在代理中保留的时间超过一定时间(通常为 7 天)，则会自动删除。
该解决方案在实践中运行良好。
大多数消费者，包括线下消费者，每天、每小时或实时完成消费。
Kafka 的性能不会随着数据量的增加而降低，这一事实使得这种长时间的保留是可行的。

这种设计有一个重要的附带好处。
消费者可以故意倒回到旧的偏移量并重新消费数据。
这违反了队列的共同契约，但被证明是许多消费者的基本特征。
例如，当消费者的应用程序逻辑出现错误时，应用程序可以在错误修复后重新播放某些消息。
这对于将 ETL 数据加载到我们的数据仓库或 Hadoop 系统中尤为重要。
作为另一个例子，消耗的数据可以仅定期刷新到持久存储(例如，全文索引器)。
如果消费者崩溃，则未刷新的数据将丢失。
在这种情况下，消费者可以检查未刷新消息的最小偏移量，并在重新启动时从该偏移量重新消费。
我们注意到，在拉模型中比推模型更容易支持回退消费者。

#### 3.2 分布式协调

我们现在描述生产者和消费者在分布式环境中的行为。
每个生产者可以将消息发布到随机选择的分区或由分区键和分区函数语义确定分区。
我们将关注消费者如何与 Broker 互动。

Kafka 有消费组的概念。
每个消费组由一个或多个共同消费一组订阅主题的消费者组成，即每条消息仅传递给组内的一个消费者。
不同的消费者组各自独立地使用完整的订阅消息集，并且不需要跨消费组进行协调。
同一组内的消费者可以在不同的进程或不同的机器上。
我们的目标是将存储在 Broker 中的消息平均分配给消费者，而不会引入过多的协调开销。

我们的第一个决定是使主题内的分区成为并行度的最小单位。
这意味着在任何给定时间，来自一个分区的所有消息仅由每个消费者组中的一个消费者消费。
如果我们允许多个消费者同时消费一个分区，他们将不得不协调谁消费什么消息，这需要锁定和状态维护开销。
相比之下，在我们的设计中，消费流程只需要在消费者重新平衡负载时进行协调，这是一种罕见的事件。
为了真正平衡负载，我们需要一个主题中的分区比每个组中的消费者多得多。
我们可以通过对主题进行过度分区来轻松实现这一点。

我们做出的第二个决定是没有中央 “master” 节点，而是让消费者以去中心化的方式相互协调。
添加 master 会使系统复杂化，因为我们必须进一步担心 master 故障。
为了促进协调，我们采用了高度可用的共识服务 Zookeeper `[10]`。
Zookeeper 有一个非常简单的文件系统，类似于 API。
它可以创建路径、设置路径的值、读取路径的值、删除路径以及列出路径的子项。
此外 Zookeeper 还做了一些更有趣的事情：

1. 可以在路径上注册一个观察者，并在路径的子路径或路径的值发生变化时得到通知
2. 可以将路径创建为 ephemeral (与持久性相反,临时路径)，这意味着如果创建的客户端消失了，Zookeeper 服务器会自动删除该路径
3. Zookeeper 将其数据复制到多个服务器，这使得数据高度可靠和可用

Kafka 使用 Zookeeper 完成以下任务：

1. 检测 Broker 和消费者的添加和删除 
2. 当上述事件发生时，在每个消费者中触发重新平衡过程
3. 维护消费关系并跟踪每个分区的消耗偏移量

具体来说，当每个 Broker 或消费者启动时，它会将其信息存储在 Zookeeper 中的 Broker 或消费者注册表中。
Broker 注册表包含 Broker 的主机名和端口，以及存储在其上的一组主题和分区。
消费者注册表包括消费者所属的消费组及其订阅的主题集。
每个消费组都与 Zookeeper 中的一个所有权注册表和一个偏移注册表相关联。
所有权注册表对于每个订阅的分区都有一个路径，路径值是当前从该分区消费的消费者的 ID (我们使用消费者拥有该分区的术语)。
偏移注册表为每个订阅的分区存储分区中最后消费的消息的偏移量。

Zookeeper 中创建的路径对于 Broker 注册表、消费者注册表和所有权注册表是短暂的，对于偏移注册表是持久的。
如果 Broker 故障，其上的所有分区都会自动从 Broker 注册表中删除。
消费者的失败会导致它丢失其在消费者注册表中的条目以及它在所有权注册表中拥有的所有分区。
每个消费者都会在 Broker 注册中心和消费者注册中心注册一个 Zookeeper 观察者，并且会在 Broker 集或消费者组发生变化时收到通知。

算法 1: 在 G 消费组中重新平衡 C<sub>i</sub> 的过程

---

for (每个 C<sub>i</sub> 订阅的话题 T) {

&nbsp;&nbsp;&nbsp;&nbsp;在所有权注册表中移除被 C<sub>i</sub> 拥有的分片(partition)

&nbsp;&nbsp;&nbsp;&nbsp;从 Zookeeper 读取代理和消费者注册表

&nbsp;&nbsp;&nbsp;&nbsp;计算 P<sub>T</sub> = 主题 T 下所有 Broker 中可用的分区

&nbsp;&nbsp;&nbsp;&nbsp;计算 C<sub>T</sub> = G 消费组中订阅主题 T 的所有消费者

&nbsp;&nbsp;&nbsp;&nbsp;对 P<sub>T</sub> 和 C<sub>T</sub> 进行排序

&nbsp;&nbsp;&nbsp;&nbsp;令 j 为 C<sub>i</sub> 在 C<sub>T</sub> 中的索引位置，令 N = | P<sub>T</sub> | / | C <sub>T</sub> |

&nbsp;&nbsp;&nbsp;&nbsp;将 P<sub>T</sub> 中从 j*N 到 (j+1)*N-1 的分区分配给消费者 C<sub>i</sub>

&nbsp;&nbsp;&nbsp;&nbsp;for (每个分配的分片 p){

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;在所有权注册表中将 p 的所有权设定为 C<sub>i</sub>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;令 O<sub>p</sub> = 存储在偏移注册表中的分区 p 的偏移量

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;调用一个线程从偏移量 O<sub>p</sub> 中拉取分区 p 中的数据

&nbsp;&nbsp;&nbsp;&nbsp;}

}

---

在消费者的初始启动期间，或者当消费者通过观察者收到有关 Broker/消费者更改的通知时，消费者会启动重新平衡过程以确定它应该从中消费的新分区子集。
该过程在算法 1 中描述。
通过从 Zookeeper 读取 Broker 和消费者注册表，
消费者首先计算每个订阅主题 T 可用的分区集( P<sub>T</sub> )和订阅 T 的消费者集( C<sub>T</sub> )。
然后将 P<sub>T</sub> 范围划分为 |C<sub>T</sub>| 块并确定性地选择一个块来拥有。
对于消费者选择的每个分区，它在所有权注册表中将自己写入为分区的新所有者。
最后，消费者开始一个线程从每个拥有的分区中提取数据，从存储在偏移注册表中的偏移开始。
当消息从分区中提取时，消费者会定期更新偏移注册表中最新使用的偏移量。

> 注：在最新版本 2.8.0 中已经开始尝试逐步移除 Zookeeper 

当一个消费组中有多个消费者时，他们每个人都会收到 Broker 或消费者更改的通知。
但是，通知可能会在不同的事件送达给每个消费者。
因此，有可能一个消费者试图获得另一个消费者仍然拥有的分区的所有权。
发生这种情况时，第一个使用者只需释放其当前拥有的所有分区，稍等片刻并重试重新平衡过程。
在实践中，重新平衡过程通常只在几次重试后就稳定下来。

创建新的消费者组时，偏移注册表中没有可用的偏移。
在这种情况下，消费者将使用我们在 Broker 上提供的 API 从每个订阅分区上可用的最小或最大偏移量(取决于配置)开始消费。

#### 3.3 送达保证

一般来说，Kafka 只保证至少一次交付。
确当一次交付通常需要两阶段提交，对于我们的应用程序来说不是必需的。
大多数情况下，一条消息只传递给每个消费者组一次。
然而，在消费者进程在没有干净关闭的情况下崩溃的情况下，接管失败消费者拥有的那些分区的消费者进程可能会收到一些重复的消息，
这些消息在成功提交给 Zookeeper 的最后一个偏移之后。
如果应用程序关心重复，它必须添加自己的重复数据删除逻辑，要么使用我们返回给消费者的偏移量，要么使用消息中的某个唯一键。
这通常是比使用两阶段提交更具成本效益的方法。

Kafka 保证来自单个分区的消息按顺序传递给消费者。
但是，无法保证来自不同分区的消息的顺序。

为了避免日志损坏，Kafka 为日志中的每条消息存储了一个 CRC。
如果 Broker 上出现任何 I/O 错误，Kafka 会运行恢复过程以删除那些具有不一致 CRC 的消息。
在消息级别拥有 CRC 还允许我们在生成或使用消息后检查网络错误。

如果 Broker 宕机，存储在其上的任何尚未消费的消息将变得不可用。
如果 Broker 上的存储系统永久损坏，则任何未使用的消息将永远丢失。
未来，我们计划在 Kafka 中添加内置复制功能，将每条消息冗余存储在多个代理上。

> 注：副本功能已经实现，默认三个副本，而送达保证消费者部分描述详细内容参见 [官方文档](http://kafka.apache.org/documentation.html#semantics)

### 4 LinkedIn 使用 Kafka 的方式

![图 3：Kafka 部署图](https://i.loli.net/2021/06/21/Zw4qgzfkTKxtcur.png)

在本节中，我们将描述我们如何在 LinkedIn 上使用 Kafka。
图 3 显示了我们部署的简化版本。
我们有一个 Kafka 集群，与我们面向用户的服务运行的每个数据中心位于同一位置。
前端服务生成各种日志数据，批量发布到本地的 Kafka Broker。
我们依靠硬件负载平衡器将发布请求均匀地分发到一组 Kafka Broker。
Kafka 的在线消费者在同一数据中心内的服务中运行。

我们还在单独的数据中心部署了一个 Kafka 集群，用于离线分析，地理位置靠近我们的 Hadoop 集群和其他数据仓库基础设施。
这个 Kafka 实例运行一组嵌入式消费者，以从实时数据中心的 Kafka 实例中提取数据。
然后我们运行数据加载作业，将数据从这个 Kafka 副本集群中提取到 Hadoop 和我们的数据仓库中，在那里我们对数据运行各种报告作业和分析过程。
我们还使用这个 Kafka 集群进行原型设计，并能够针对原始事件流运行简单的脚本以进行临时查询。
无需过多调整，整个管道的端到端延迟平均约为 10 秒，足以满足我们的要求。

目前，Kafka 每天累积数百 GB 的数据和接近 10 亿条消息，随着我们完成对遗留系统的转换以利用 Kafka，我们预计这些数据会显着增长。
将来会添加更多类型的消息。
当操作人员启动或停止 Broker 进行软件或硬件维护时，重新平衡过程能够自动重定向消耗。

我们的跟踪还包括一个审计系统，以验证整个管道没有数据丢失。
为方便起见，每条消息在生成时都带有时间戳和服务器名称。
我们检测每个生产者，使其定期生成一个监控事件，该事件记录该生产者在固定时间窗口内为每个主题发布的消息数量。
生产者在单独的主题中将监控事件发布到 Kafka。
然后，消费者可以计算他们从给定主题收到的消息数量，并使用监控事件验证这些计数以验证数据的正确性。

加载到 Hadoop 集群是通过实现一种特殊的 Kafka 输入格式来完成的，该格式允许 MapReduce 作业直接从 Kafka 读取数据。
MapReduce 作业加载原始数据，然后对其进行分组和压缩，以便将来进行高效处理。
消息偏移的无状态 Broker 和客户端存储在这里再次发挥作用，允许 MapReduce 任务管理(允许任务失败并重新启动)以自然的方式处理数据负载，
而不会在发生任务重启的情况时复制或丢失消息。
只有在作业成功完成后，数据和偏移量才会存储在 HDFS 中。

我们选择使用 Avro `[2]` 作为我们的序列化协议，因为它高效且支持模式演化。
对于每条消息，我们将其 Avro 架构的 ID 和序列化字节存储在有效负载中。
这种模式允许我们强制执行契约以确保数据生产者和消费者之间的兼容性。
我们使用轻量级架构注册服务将架构 ID 映射到实际架构。
当消费者收到一条消息时，它会在模式注册表中查找以检索模式，该模式用于将字节解码为对象(每个模式只需进行一次此查找，因为值是不可变的)。

### 5 实验结果

我们进行了一项实验研究，比较了 Kafka 与 Apache ActiveMQ v5.4 `[1]`(一种流行的 JMS 开源实现)和
RabbitMQ v2.4 `[16]` (一种以其性能而闻名的消息系统)的性能。
我们使用了 ActiveMQ 的默认持久消息存储 KahaDB。
虽然这里没有介绍，但我们也测试了一个替代的 AMQ 消息存储，发现它的性能与 KahaDB 非常相似。
只要有可能，我们都会尝试在所有系统中使用可比较的设置。

我们在 2 台 Linux 机器上进行了实验，每台机器都有 8 个 2GHz 内核、16GB 内存、6 个 RAID 10 磁盘。
两台机器通过 1Gb 网络链接连接。
其中一台机器用作 Broker，另一台机器用作生产者或消费者。

![图 4：生产者性能测试](https://i.loli.net/2021/06/21/Ip2UiPArJShc5zb.png)

**生产者测试**：
我们将所有系统中的 Broker 配置为将消息异步刷新到其持久性存储。
对于每个系统，我们运行一个生产者来发布总共 1000 万条消息，每条消息 200 字节。
我们将 Kafka 生产者配置为分批发送大小为 1 和 50 的消息。
ActiveMQ 和 RabbitMQ 似乎没有一种简单的方法来批处理消息，我们假设它使用的批处理大小为 1。
结果如图 4 所示。x 轴表示随着时间的推移发送到代理的数据量(以 MB 为单位)，y 轴对应于每秒消息的生产者吞吐量。
平均而言，Kafka 可以分别以每秒 50,000 和 400,000 条消息的速率发布消息，批量大小分别为 1 和 50。
这些数字比 ActiveMQ 高出几个数量级，至少比 RabbitMQ 高出2倍。

Kafka 表现更好的原因有几个。
首先，Kafka 生产者目前不会等待来自 Broker 的确认，而是以代理可以处理的速度发送消息。
这显着增加了发布者的吞吐量。
批量处理大小设置为 50 时，单个 Kafka 生产者几乎饱和了生产者和代理之间的 1Gb 链接。
这是对日志聚合情况的有效优化，因为数据必须异步发送以避免在实时流量服务中引入任何延迟。
我们注意到，生产者不进行确认监测，就不能保证每条发布的消息实际上都被 Broker 收到了。
对于许多类型的日志数据，只要丢弃的消息数量相对较少，就需要用持久性来换取吞吐量。
但是，我们确实计划在未来解决更关键数据的持久性问题。

> 注：确认监测参数可以进行配置，详情参见 [官方文档](http://kafka.apache.org/documentation.html#producerconfigs_acks)

**消费者测试**：

![图 5：消费者性能测试](https://i.loli.net/2021/06/21/szZV74D6FbBpg2w.png)

在第二个实验中，我们测试了消费者的表现。
同样，对于所有系统，我们使用一个消费者来检索总共 1000 万条消息。
我们配置了所有系统，以便每个拉取请求应该预取大约相同数量的数据——最多 1000 条消息或大约 200 KB。
对于 ActiveMQ 和 RabbitMQ，我们将消费者确认模式设置为自动。
由于所有消息都能暂时存放在内存中，因此所有系统都从底层文件系统的页面缓存或一些内存缓冲区中提供数据。
结果如图 5 所示。

Kafka 平均每秒消费 22,000 条消息，是 ActiveMQ 和 RabbitMQ 的 4 倍以上。
我们可以想到几个原因。
首先，由于 Kafka 具有更高效的存储格式，因此在 Kafka 中从 Broker 传输到消费者的字节更少。
其次，ActiveMQ 和 RabbitMQ 中的 broker 都必须维护每条消息的传递状态。
我们观察到，在此测试期间，一个 ActiveMQ 线程正忙于将 KahaDB 页面写入磁盘。
相比之下，Kafka 代理上没有磁盘写入活动。
最后，通过使用文件发送 API，Kafka 减少了传输开销。

我们通过指出实验的目的不是表明其他消息传递系统不如 Kafka 来结束本节。
毕竟，ActiveMQ 和 RabbitMQ 的功能都比 Kafka 多。
重点是说明专用系统可以实现的潜在性能增益。

### 6 结论与未来的工作

我们提出了一个名为 Kafka 的新系统，用于处理大量日志数据流。
与消息传递系统一样，Kafka 采用基于拉取的消费模型，该模型允许应用程序以自己的速率消费数据，并在需要时回滚消费。
通过专注于日志处理应用程序，Kafka 实现了比传统消息传递系统更高的吞吐量。
它还提供集成的分布式支持并且可以横向扩展。
我们一直在 LinkedIn 上成功地将 Kafka 用于离线和在线应用程序。

未来有很多方向是我们想要的。
首先，我们计划添加跨多个 Broker 的内置消息复制，即使在不可恢复的机器故障的情况下也能保证持久性和数据可用性。
我们希望同时支持异步和同步复制模型，以允许在生产者延迟和提供的保证强度之间进行一些权衡。
应用程序可以根据其对持久性、可用性和吞吐量的要求选择正确的冗余级别。
其次，我们想在 Kafka 中添加一些流处理能力。
从 Kafka 检索消息后，实时应用程序通常会执行类似的操作，例如基于窗口的计数并将每条消息与二级存储中的记录或另一个流中的消息连接起来。
在最低级别，这是通过在发布期间在连接键上对消息进行语义分区来支持的，以便使用特定键发送的所有消息都转到同一分区，从而到达单个消费者进程。
这为跨消费者机器集群处理分布式流提供了基础。
最重要的是，我们认为一个有用的流处理程序库，提供例如不同的窗口函数或连接技术，将对此类应用程序有很大益处。

### 7 参考资料

`[1]` http://activemq.apache.org/

`[2]` http://avro.apache.org/

`[3]` Cloudera’s Flume, https://github.com/cloudera/flume

`[4]` http://developer.yahoo.com/blogs/hadoop/posts/2010/06/enabling_hadoop_batch_processi_1/

`[5]` Efficient data transfer through zero copy: https://www.ibm.com/developerworks/linux/library/jzerocopy/

`[6]` Facebook’s Scribe, http://www.facebook.com/note.php?note_id=32008268919

`[7]` IBM Websphere MQ: http://www01.ibm.com/software/integration/wmq/

`[8]` http://hadoop.apache.org/

`[9]` http://hadoop.apache.org/hdfs/

`[10]` http://hadoop.apache.org/zookeeper/

`[11]` http://www.slideshare.net/cloudera/hw09-hadoop-baseddata-mining-platform-for-the-telecom-industry

`[12]` http://www.slideshare.net/prasadc/hive-percona-2009

`[13]` https://issues.apache.org/jira/browse/ZOOKEEPER-775

`[14]` JAVA Message Service:http://download.oracle.com/javaee/1.3/jms/tutorial/1_3_1-fcs/doc/jms_tutorialTOC.html.

`[15]` Oracle Enterprise Messaging Service: http://www.oracle.com/technetwork/middleware/ias/index093455.html

`[16]` http://www.rabbitmq.com/

`[17]` TIBCO Enterprise Message Service: http://www.tibco.com/products/soa/messaging/

`[18]` Kafka, http://sna-projects.com/kafka/