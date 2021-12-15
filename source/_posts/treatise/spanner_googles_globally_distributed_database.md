---
title: "Spanner: Google’s Globally Distributed Database 中文翻译版"
date: 2021-12-15 22:26:13
tags:
- "论文"
- "HBase"
id: spanner_googles_globally_distributed_database
no_word_count: true
no_toc: false
categories: 大数据
---

## Spanner: Google’s Globally Distributed Database 中文翻译版

作者：

JAMES C. CORBETT, JEFFREY DEAN, MICHAEL EPSTEIN, ANDREW FIKES,CHRISTOPHER FROST, J. J. FURMAN, SANJAY GHEMAWAT, ANDREY GUBAREV,CHRISTOPHER HEISER, PETER HOCHSCHILD, WILSON HSIEH,SEBASTIAN KANTHAK, EUGENE KOGAN, HONGYI LI, ALEXANDER LLOYD,SERGEY MELNIK, DAVID MWAURA, DAVID NAGLE, SEAN QUINLAN, RAJESH RAO,LINDSAY ROLIG, YASUSHI SAITO, MICHAL SZYMANIAK, CHRISTOPHER TAYLOR,RUTH WANG, and DALE WOODFORD, Google, Inc.

### 原版的版权说明

```text
This article is essentially the same (with minor reorganizations, corrections, and additions) as the paper of
the same title that appeared in the Proceedings of OSDI 2012.
Authors’ address: J. C. Corbett, J. Dean, M. Epstein, A. Fikes, C. Frost, J. J. Furman, S. Ghemawat,
A. Gubarev, C. Heiser, P. Hochschild, W. Hsieh (corresponding author), S. Kanthak, E. Kogan, H. Li,
A. Lloyd, S. Melnik, D. Mwaura, D. Nagle, S. Quinlan, R. Rao, L. Rolig, Y. Saito, M. Szymaniak,
C. Taylor, R. Wang, and D. Woodford, Google, Inc. 1600 Amphitheatre Parkway, Mountain View, CA 94043;
email: wilsonh@google.com.
Permission to make digital or hard copies of part or all of this work for personal or classroom use is granted
without fee provided that copies are not made or distributed for profit or commercial advantage and that
copies bear this notice and the full citation on the first page. Copyrights for third-party components of this
work must be honored. For all other uses contact the Owner/Author.
2013 Copyright is held by the author/owner(s).
0734-2071/2013/08-ART8
DOI:http://dx.doi.org/10.1145/2491245
```

### 摘要

Spanner 是 Google 的一种数据库，它具有：可扩展，多版本，全球分布式部署，同步复制的特性。
它是第一个在全球范围内分发数据并支持外部一致性的分布式事务的系统。
这篇文章描述了 Spanner 是如何设计的，它的特性，各种设计决策的基本原理，以及一个暴露时钟不确定性的新的时间 API。
该 API 及其实现对于支持外部一致性和各种强大功能至关重要：过去的非阻塞读取、无锁快照事务和原子模式更改，这些功能跨越了整个 Spanner。

#### General Terms

Design, Algorithms, Performance

#### 关键词

分布式数据库，并发控制，副本集，事务性，时间管理。

### 1 引言

Spanner 是一个可扩展的全球分布式数据库，由 Google 设计、实施和部署。
在最高的抽象层次上，它是一个数据库，可以在遍布世界各地的数据中心的多组 Paxos `[Lamport 1998]` 状态机上分割数据。
在全球的数据中心上进行复制来满足本地的使用需求，客户端可以自动在副本之间进行故障切换。
Spanner 会随着数据量或服务器数量的变化自动而跨机器重新对数据进行分片，并自动跨机器（甚至跨数据中心）迁移数据以平衡负载和响应故障。
Spanner 在设计之初的目标是扩展至数百个数据中心中的百万台设备上支持数兆(万亿)行数据的存储。

应用程序可以使用 Spanner 的高可用性，即使在面临广域自然灾害时，通过在大陆内甚至跨大陆复制其数据也是如此。
我们最初的客户是 F1 `[Shute et al. 2012]`，重写了谷歌的广告后端。
F1 使用分布在美国各地的五个副本。
大多数其他应用程序可能会在一个地理区域的 3 到 5 个数据中心之间复制其数据，但具有相对独立的故障模式。
也就是说，大多数应用程序将选择更低的延迟而不是更高的可用性，只要它们能够在 1 或 2 个数据中心故障中幸存下来。

Spanner 的主要重点是管理跨数据中心的复制数据，但我们也花了大量时间在分布式系统基础架构之上设计和实现重要的数据库功能。
尽管许多项目很乐意使用 Bigtable `[Chang et al. 2008]`，我们还不断收到用户抱怨 Bigtable 可能难以用于某些类型的应用程序：那些具有复杂的、不断发展的模式的应用程序，或者那些在存在广域复制的情况下需要强一致性的应用程序。
(其他作者也提出了类似的主张 `[Stonebraker 2010b]`。)
Google 的许多应用程序都选择使用 Megastore `[Baker et al. 2011]` 因为它的半数据模型和对同步复制的支持，尽管它的写入吞吐量相对较差。
因此，Spanner 已从类似 Bigtable 的版本化键值存储演变为时态多版本数据库。
数据存储在模式化的半关系表中；数据是版本化的，每个版本都会自动加上其提交时间的时间戳；旧版本的数据受可配置的垃圾收集策略的约束；应用程序可以读取旧时间戳的数据。
Spanner 支持通用事务，并提供基于 SQL 的查询语言。

作为一个全球分布式数据库，Spanner 提供了几个有趣的特性。
首先，数据的复制配置可以由应用程序进行细粒度动态控制。
应用程序可以指定约束来控制哪些数据中心包含哪些数据、数据与其用户的距离(以控制读取延迟)、副本彼此之间的距离(以控制写入延迟)以及维护的副本数量(以控制持久性、可用性和读取性能)。
系统还可以在数据中心之间动态透明地移动数据，以平衡数据中心之间的资源使用。
其次，Spanner 有两个难以在分布式数据库中实现的特性：它提供外部一致的 `[Gifford 1982]` 读取和写入，以及跨数据库同一时间戳的一致性读取。
这些功能使 Spanner 能够支持一致的备份、一致的 MapReduce 执行 `[Dean and Ghemawat 2010]` 和原子性的更新，所有这些都在全球范围内，甚至在正在进行的事务的情况下。

这些功能是由 Spanner 为事务分配全局有意义的提交时间戳这一事实所启用的，即使事务可能是分布式的。
时间戳反映了序列化顺序。
此外，序列化顺序满足外部一致性(或等效的线性化 `[Herlihy and Wing 1990])：如果事务 T1 在另一个事务 T2 开始之前提交，则 T1 的提交时间戳小于 T2 的。
Spanner 是第一个在全球范围内提供此类保证的系统。

这些属性的关键促成因素是新的 TrueTime API 及其实现。
API 直接暴露了时钟不确定性，对 Spanner 时间戳的保证取决于实现提供的边界。
如果不确定性很大，Spanner 会放慢速度以等待不确定性消失。
Google 的集群管理软件提供了 TrueTime API 的实现。
此实现通过使用多个现代时钟参考(GPS 和原子钟)将不确定性保持在很小(通常小于 10 毫秒)。
保守地报告不确定性对于正确性是必要的； 保持对不确定性的限制很小对于性能来说是必要的。

第 2 节描述了 Spanner 实现的结构、它的特性集，以及在设计过程中的方案。
第 3 节描述了我们新的 TrueTime API 并概述了它的实现。
第 4 节描述了 Spanner 如何使用 TrueTime 实现外部一致性分布式事务、无锁快照事务和原子模式更新。
第 5 节提供了有关 Spanner 性能和 TrueTime 行为的一些基准，并讨论了 F1 的经验。
第 6、7 和 8 节描述了相关和未来的工作，并总结了我们的结论。

### 2 实现方式

本节描述 Spanner 实现的结构和基本原理。
然后描述目录的抽象过程，将其用于管理副本和存储位置，并将目录作为数据移动的基本单元。
最后，它描述了我们的数据模型，为什么 Spanner 看起来像关系数据库而不是键值存储，以及应用程序如何控制数据的存储地点。

一个 Spanner 部署的实例被称为 Universe。
鉴于 Spanner 在全球范围内管理数据，因此只有少数几个正在运行的 Universe。
目前有一个测试环境，一个研发/生产环境，一个只用于生产的环境。

Spanner 被组织为一组区域(zone)，其中每个区域都是 Bigtable 服务器部署的粗略模拟 `[Chang et al. 2008]`。
区域是管理部署的单位。
区域集也是可以复制数据的位置集。
当新数据中心投入使用和旧数据中心关闭时，可以分别在正在运行的系统中添加或删除区域。
区域也是物理隔离的单位：一个数据中心内可能有一个或多个区域，例如，如果不同应用程序的数据必须在同一数据中心内的不同服务器组之间进行分区。

![图 1：Spanner 服务器的组织架构](https://s2.loli.net/2021/12/15/uo9SCW8LgnOhwDf.png)

图 1 说明了 Spanner Universe 中的服务器组织架构。
一个区域有一个 `zonemaster` 和一百到几千个 `spanserver`。
前者将数据分配给 `spanservers`；后者为客户提供数据。
客户端使用每个区域的位置代理来定位分配给其数据的跨服务器。
Universe 主控(`universe master`)和布局驱动程序(`placement driver`)目前是单例的。
Universe 主控器主要是一个控制台，用于显示有关所有区域的状态信息以进行交互式调试。
布局驱动程序以分钟为单位处理跨区域的自主数据移动。
布局驱动程序定期与 `spanserver` 通信以查找需要移动的数据，以满足更新的复制约束或平衡负载。
由于篇幅原因，我们只会详细描述 `spanserver` 。

#### 2.1 Spanserver 软件栈

![图 2：Spanserver 软件栈](https://s2.loli.net/2021/12/15/OuafjqnwHgJE7Me.png)

本节重点介绍 `spanserver` 实现，以说明复制如何分布式事务已分层到我们基于 Bigtable 的实现中。
软件堆栈如图 2 所示。
在底部，每个 `spanserver` 负责一个称为 `tablet` 的数据结构的 100 到 1000 个实例。
`tablet` 类似于 Bigtable 的 `tablet` 抽象，因为它实现了以下映射的包。

```text
(key:string, timestamp:int64) → string
```

与 Bigtable 不同，Spanner 为数据分配时间戳，这使 Spanner 更像是一个多版本数据库而不是键值存储工具。
tablet 的状态存储在一组类似 B 树的文件和预写日志中，所有这些都存储在 Colossus 分布式文件系统中(Google 文件系统的继任者 [Ghemawat et al. 2003])。

为了支持复制，每个 `spanserver` 在每个 `tablet` 上实现了一个单独的 Paxos 状态机。
(早期的 Spanner 版本支持每个 `tablet` 多个 Paxos 状态机，这允许更灵活的复制配置。但该设计的复杂性导致我们放弃了它。)
每个状态机存储其元数据并写入其相应的 `tablet`。
我们的 Paxos 实现支持具有基于时间的领导者租用的长期领导者，其长度默认为 10 秒。
当前的 Spanner 实现记录每个 Paxos 写入两次：一次在平板电脑的日志中，一次在 Paxos 日志中。
这个选择是出于权宜之计，我们很可能最终会解决这个问题。
我们对 Paxos 的实现是流水线式的，以便在存在 WAN 延迟的情况下提高 Spanner 的吞吐量。
通过“流水线”，我们指的是 Lamport 的“多法令议会” `[Lamport 1998]`，它既分摊了跨多项法令选举领导人的成本，又允许对不同法令进行同时投票。
重要的是要注意，虽然法令可能会被无序批准，但法令是按顺序应用的(我们将在第 4 节中依赖这一事实)。

