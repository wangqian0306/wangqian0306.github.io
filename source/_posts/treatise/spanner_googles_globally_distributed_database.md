---
title: "Spanner: Google’s Globally Distributed Database 中文翻译版"
date: 2021-12-15 22:26:13
tags:
- "论文"
id: spanner_googles_globally_distributed_database
no_word_count: true
no_toc: false
categories: 大数据
---

## Spanner: Google’s Globally Distributed Database 中文翻译版

作者：

JAMES C. CORBETT, JEFFREY DEAN, MICHAEL EPSTEIN, ANDREW FIKES,CHRISTOPHER FROST, J. J. FURMAN, SANJAY GHEMAWAT, ANDREY
GUBAREV,CHRISTOPHER HEISER, PETER HOCHSCHILD, WILSON HSIEH,SEBASTIAN KANTHAK, EUGENE KOGAN, HONGYI LI, ALEXANDER
LLOYD,SERGEY MELNIK, DAVID MWAURA, DAVID NAGLE, SEAN QUINLAN, RAJESH RAO,LINDSAY ROLIG, YASUSHI SAITO, MICHAL SZYMANIAK,
CHRISTOPHER TAYLOR,RUTH WANG, and DALE WOODFORD, Google, Inc.

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
tablet 的状态存储在一组类似 B 树的文件和预写日志中，所有这些都存储在 Colossus 分布式文件系统中(Google 文件系统的继任者 `[Ghemawat et al. 2003]`)。

为了支持复制，每个 `spanserver` 在每个 `tablet` 上实现了一个单独的 Paxos 状态机。
(早期的 Spanner 版本支持每个 `tablet` 多个 Paxos 状态机，这允许更灵活的复制配置。但该设计的复杂性导致我们放弃了它。)
每个状态机存储其元数据并写入其相应的 `tablet`。
我们的 Paxos 实现支持具有基于时间的领导者租用的长期领导者，其长度默认为 10 秒。
当前的 Spanner 实现记录每个 Paxos 写入两次：一次在平板电脑的日志中，一次在 Paxos 日志中。
这个选择是出于权宜之计，我们很可能最终会解决这个问题。
我们对 Paxos 的实现是流水线式的，以便在存在 WAN 延迟的情况下提高 Spanner 的吞吐量。
通过“流水线”，我们指的是 Lamport 的“多法令议会” `[Lamport 1998]`，它既分摊了跨多项法令选举领导人的成本，又允许对不同法令进行同时投票。
重要的是要注意，虽然法令可能会被无序批准，但法令是按顺序应用的(我们将在第 4 节中依赖这一事实)。

Paxos 状态机用于实现一致并且具有副本的一组键值对映射。
每个副本的键值映射状态存储在其对应的 `tablet` 中。
写入操作必须在领导者处发起 Paxos 协议；读取操作可以直接访问任何最够新的副本。副本的集合构成了一个 Paxos 组。

在作为领导者的每个副本上，`spanserver` 实现了一个锁表来实现并发控制。
锁表包含两阶段锁定的状态：它将键的范围映射到锁定状态。(请注意，拥有一个长期存在的 Paxos 领导者对于有效管理锁表至关重要。)
在 Bigtable 和 Spanner 中，我们为长期事务(例如，生成报告，可能需要几分钟的时间)，在存在冲突的少量并发控制下表现不佳。
需要同步的操作，比如事务性读，获取锁表中的锁；其他操作绕过(bypass)锁表。
锁表的状态大多是易变的(即不通过 Paxos 复制)：我们解释细节在第 4.2.1 节中。

在作为领导者的每个副本上，每个 `spanserver` 还实现了一个事务管理器来支持分布式事务。
事务管理器用于实现参与者领导者；组中的其他副本将被称为参与者从属。 如果一个事务只涉及一个 Paxos 组(大多数事务都是这种情况)，它可以绕过事务管理器，因为锁表和 Paxos 一起提供了事务性。
如果一个事务涉及多个 Paxos 组，这些组的领导者会协调执行两阶段提交。
选择其中一个参与者组作为协调者：该组的参与者领导者将被称为协调者领导者，而该组的从属则被称为协调者从属。 每个事务管理器的状态都存储在底层 Paxos 组中(因此被复制)。

#### 2.2 目录和位置

在键值映射包之上，Spanner 实现支持称为目录的分桶抽象，这是一组共享公共前缀的连续键。
(目录这一术语的选择是一个历史意外；更好的术语应该是桶(`bucket`)。)
我们将在 2.3 节解释该前缀的来源。 支持目录允许应用程序通过仔细选择键来控制其数据的位置。

![图 3：目录是 Paxos 组之间移动数据的基本单位](https://s2.loli.net/2021/12/16/GTzmR3egoNFHuLq.png)

目录是数据放置的单位。
目录中的所有数据都具有相同的复制配置。
当数据在 Paxos 组之间移动时，它会逐个目录移动，如图 3 所示。
Spanner 可能会移动一个目录以减轻 Paxos 组的负载；将经常访问的目录放在同一组中；或者将目录移动到更接近其访问者的组中。
Paxos 组可能包含多个目录的事实意味着 Spanner `tablet` 与 Bigtable `tablet`不同：前者不一定是行空间的按字典顺序排列的单个分区。
相反，Spanner `tablet` 是一个容器，可以在行内的空间封装多个分区。我们做出这个决定是为了可以将多个经常一起访问的目录一起放置。

Movedir 是用于在 Paxos 组之间移动目录的后台任务 `[Douceur and Howell 2006]`。
Movedir 还可以通过将组内的所有数据移动到具有所需配置的新组，从而在 Paxos 组中添加或删除副本 `[Lorch et al. 2006]`(因为 Spanner 尚不支持在 Paxos 中更改配置)。
Movedir 不是作为单个事务实现的，以避免在大量数据移动时阻塞正在进行的读取和写入。
相反，Movedir 记录了它开始移动数据的事件并在后台移动数据的事实。当它移动了除指定数量之外的所有数据时，它使用事务来原子地移动名义数量并更新两个 Paxos 组的元数据。

目录也是应用程序可以指定其地理复制属性(或简称放置)的最小单元。
我们的放置规范语言的设计将管理复制配置的职责分开。
管理员控制两个维度：副本的数量和类型，以及这些副本的地理位置。
他们在这两个维度中创建了一个命名选项菜单(例如，北美，用 1 个见证者(witness)复制了 5 种数据)。
应用程序通过使用这些选项的组合标记每个数据库和/或单个目录来控制数据的复制方式。
例如，应用程序可能将每个最终用户的数据存储在其自己的目录中，这将使用户 A 的数据在欧洲拥有三个副本，而用户 B 的数据在北美拥有五个副本。

为了说明的清晰，我们过度简化了实际情况。
实际上，如果目录变得太大，Spanner 会将目录分片成多个片段。
而片段可能来自不同的 Paxos 组(因此也可能来自不同的服务器)。
Movedir 实际上在组之间移动片段，而不是整个目录。

#### 2.3 数据模型

Spanner 向应用程序公开了以下数据特性集：基于模式化半关系表的数据模型、查询语言和通用事务。 有很多因素为上述功能做了支持和驱动。
Megastore 的流行支持了支持模式化半关系表和同步复制的需求 `[Baker et al. 2011]`。
Google 内部至少有 300 个应用程序使用 Megastore(尽管其性能相对较低)，因为它的数据模型比 Bigtable 的更易于管理，并且支持跨数据中心的同步复制。
(Bigtable 仅支持跨数据中心的最终一致性复制。)
使用 Megastore 的著名 Google 应用程序示例包括 Gmail、Picasa、Calendar、Android Market 和 AppEngine。
考虑到 Dremel `[Melnik et al.2010]`作为交互式数据分析工具的流行，在 Spanner 中支持类似 SQL 的查询语言的需求也很明显。
最后，Bigtable 缺少跨行事务导致投诉频繁； Percolator `[Peng and Dabek 2010]` 部分是为了解决这个失败。
一些作者声称，由于它带来的性能或可用性问题，一般两阶段提交的成本太高而无法支持 `[Chang et al. 2008; Cooper et al. 2008; Helland 2007]`。
我们认为最好让应用程序开发者处理由于出现瓶颈时过度使用事务而导致的性能问题，而不是总是围绕缺少事务进行编码。
在 Paxos 上运行两阶段提交可以缓解可用性问题。

应用程序数据模型位于实现支持的目录(桶)键值映射之上。
应用程序在一个 Universe 中创建一个或多个数据库。每个数据库可以包含无限数量的模式化表。 表看起来像关系型数据库的表，具有行、列和版本值。
我们不会详细介绍 Spanner 的查询语言。它看起来像带有一些扩展的 SQL，以支持协议缓冲区值(protocol-buffer-valued) `[Google 2008]` 字段。

Spanner 的数据模型不是纯粹的关系型，因为行必须有名称。
更准确地说，每个表都需要有一组有序的一个或多个主键列。
这个要求是 Spanner 仍然看起来像一个键值存储的地方：主键形成行的名称，每个表定义从主键列到非主键列的映射。
仅当为行的键定义了某个值(即使它是 NULL)时，该行才存在。
强加这种结构很有用，因为它让应用程序可以通过它们对键的选择来控制数据局部性。

```text
CREATE TABLE Users {
    uid INT64 NOT NULL, email STRING
} PRIMARY KEY (uid), DIRECTORY;

CREATE TABLE Albums {
    uid INT64 NOT NULL, aid INT64 NOT NULL,
    name STRING
} PRIMARY KEY (uid, aid),
    INTERLEAVE IN PARENT Users ON DELETE CASCADE;
```

![图 4：Spanner 上关于照片的元数据示例结构，以及经过 `INTERLEAVE IN` 限制的关联关系](https://s2.loli.net/2021/12/16/RElIAJsvgm9SfdU.png)

图 4 包含一个示例 Spanner 数据模型，用于在每个用户、每个相册的基础上存储照片元数据。
建表语句类似于 Megastore 但附加要求是每个 Spanner 数据库必须由客户端划分为一个或多个表层次结构。
客户端应用程序通过 INTERLEAVE IN 声明在数据库模式中声明层次结构。
表的层次结构顶部的是目录表。
具有键 K 的目录表中的每一行，连同按字典顺序以 K 开头的后代表中的所有行，形成一个目录。
ON DELETE CASCADE 表示删除目录表中的一行会删除任何关联的子行。
该图还说明了示例数据库的交错布局：例如，`Albums(2,1)` 表示用户 ID 为 2、相册 ID 为 1 的相册表中的行。
这种将表交错以形成目录非常重要，因为它允许客户端描述多个表之间存在的位置关系，这对于在分片分布式数据库中获得良好性能是必要的。
没有它，Spanner 就不会知道最重要的位置关系。

### 3 TrueTime

|       方法       |               返回数据                |
|:--------------:|:---------------------------------:|
|   `TT.now()`   | `TTinterval: [ earliest, latest]` |
| `TT.after(t)`  |         如果 t 已经大于当前时间则返回真         |
| `TT.before(t)` |         如果 t 已经小于当前时间则返回真         |

> 表 1：TrueTime API。参数 t 的类型是 TTstamp。

本节介绍 TrueTime API 并概述其实现。
我们将大部分细节留给另一篇文章：我们的目标是展示拥有这样一个 API 的好处。
表 I 列出了 API 的方法。
TrueTime 明确地将时间表示为 TTinterval，这是一个具有有限时间不确定性的间隔(不同于标准时间接口，它给客户端没有不确定性的概念)。
TTinterval 的端点属于 TTstamp 类型。
TT.now() 方法返回一个 TTinterval，它保证包含调用 TT.now() 的绝对时间。
时间纪元类似于带有闰秒拖尾的 UNIX 时间。
定义瞬时误差界为 `ϵ`，它是区间宽度的一半，平均误差界为 `⋷`。
TT.after() 和 TT.before() 方法是围绕 TT.now() 的便捷包装器。

用函数 t <sub>abs</sub>(e) 表示事件 `e` 的绝对时间。
在更正式的情况下，TrueTime 保证对于调用 tt = TT.now()，tt.earliest ≤ t <sub>abs</sub>(e <sub>now</sub>) ≤ tt.latest，其中 e <sub>now</sub> 是调用事件。

