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
此外，序列化顺序满足外部一致性(或等效的线性化 `[Herlihy and Wing 1990]`)：如果事务 T1 在另一个事务 T2 开始之前提交，则 T1 的提交时间戳小于 T2 的。
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

用函数 t<sub>abs</sub>(e) 表示事件 `e` 的绝对时间。
在更正式的情况下，TrueTime 保证对于调用 tt = TT.now()，tt.earliest ≤ t<sub>abs</sub>(e<sub>now</sub>) ≤ tt.latest，其中 e<sub>now</sub> 是调用事件。

TrueTime 使用的基础时间参考是 GPS 和原子钟。
TrueTime 使用两种形式的时间参考，因为它们具有不同的故障模式。
GPS 参考源漏洞包括天线和接收器故障、本地无线电干扰、相关故障(例如，不正确的闰秒处理和欺骗等设计故障)以及 GPS 系统中断。
原子钟可能会以与 GPS 和彼此无关的方式出现故障，并且在很长一段时间内可能会由于频率误差而显着漂移。

TrueTime 由每个数据中心的一组时间主机和每个机器的时间从守护程序实现。
大多数领导节点都有带专用天线的 GPS 接收器；这些主机在物理上是分开的，以减少天线故障、无线电干扰和欺骗的影响。
其余的领导节点(我们称之为世界末日领导节点)配备了原子钟。
原子钟并没有那么贵：世界末日领导节点的成本与 GPS 领导节点的成本相同。
所有领导节点的时间参考都会定期相互比较。
每个主节点还对照自己的本地时钟交叉检查其参考提前时间的速率，如果存在实质性差异，则将自身驱逐。
在同步之间，世界末日领导节点会宣传缓慢增加的时间不确定性，该不确定性源自保守应用的最坏情况时钟漂移。
GPS 主机运行异常的不确定性接近于零。

每个守护进程都会轮询各种 master `[Mills 1981]`，以减少任何一个 master 出错的脆弱性。
有些是从附近的数据中心选择的 GPS 领导节点；其余的是来自更远数据中心的 GPS 领导节点，以及一些世界末日领导节点。
守护进程应用 Marzullo 算法的变体 `[Marzullo 和 Owicki 1983]` 来检测和拒绝说谎者，并将本地机器时钟与非说谎者同步。
为了防止本地时钟中断，出现频率偏移大于从组件规范和操作环境得出的最坏情况界限的机器将被驱逐。
正确性取决于确保执行最坏情况的界限。

在同步期间，守护进程会表现出逐渐增加的时间不确定性。
`ϵ` 是保守情况下最坏的本地时钟漂移。
`ϵ` 还取决于时间主机的不确定性和与时间主机的通信延迟。
在我们的环境当中 `ϵ` 通常是时间的锯齿函数，每个轮询间隔从大约 1 到 7 毫秒不等。
`⋷` 因此就是 4 毫秒。
守护进程的轮询间隔当前为 30 秒，当前应用的漂移率设置为 200 微秒/秒，这加在一起占了 0 到 6 毫秒的锯齿边界。
剩余的 1 ms 来自到时间主机的通信延迟。在出现故障的情况下，可能会偏离此锯齿形边界。
例如，偶尔的时间主机不可用会导致数据中心范围内的 `ϵ` 增加。
同样，设备过载的和网络链接可能会导致偶尔出现 `ϵ` 产生局部峰值。
正确性不受 `ϵ` 方差的影响，因为 Spanner 可以等待不确定性，但如果 `ϵ` 增加太多，性能会下降。

### 4 并发控制

本节介绍如何使用 TrueTime 来保证围绕并发控制的正确性，以及如何使用这些属性来实现过去的外部一致性事务、无锁快照事务和非阻塞读取等特性。
例如，这些功能可以保证在时间戳 t 读取的整个数据库审计将准确看到截至 t 提交的每个事务的影响。

展望未来，区分 Paxos 所见的写入(除非上下文明确，否则我们将其称为 Paxos 写入)与 Spanner 客户端写入将非常重要。
例如，两阶段提交为准备阶段生成一个 Paxos 写入，没有对应的 Spanner 客户端写入。

#### 4.1 时间戳管理

|       操作        | 讨论的章节 | 并发控制方式 |            需求副本             |
|:---------------:|:-----:|:------:|:---------------------------:|
|      读写事务       | 4.1.2 |  悲观锁   |            领导节点             |
|      快照事务       | 4.1.4 |   无锁   | 领导节点需要指定的时间戳，其余任何读取端参见4.1.3 |
| 快照读取，客户端选择的时间戳  |   -   |   无锁   |        任意节点，参见4.1.3         |
| 快照读取，客户端选择的时间区域 | 4.1.3 |   无锁   |        任意节点，参见4.1.3         |

> 表 2：Spanner 中读取和写入的类型，以及它们的对比。

表 2 列出了 Spanner 支持的操作类型。
Spanner 实现支持读写事务、快照事务(预先声明的快照隔离事务)和快照读取。
独立写入作为读写事务实现；快照独立读取作为快照事务实现。
两者都在内部重试(客户端不需要编写自己的重试循环)。

快照事务是一种具有快照隔离性能优势的事务 `[Berenson et al. 1995]`。
快照事务必须预先声明为没有任何写入；它不仅仅是一个没有任何写入的读写事务。
快照事务中的读取在系统选择的时间戳执行而不锁定，因此不会阻止传入的写入。
快照事务中读取的执行可以在任何足够最新的副本上进行(第 4.1.3 节)。

快照读取是过去的快照在没有锁定的情况下执行的读取。
客户端可以为快照读取指定时间戳，也可以提供所需时间戳过时的上限并让 Spanner 选择时间戳。
在任何一种情况下，快照读取的执行都会在任何足够最新的副本上进行。

对于快照事务和快照读取，一旦选择了时间戳，提交就不可避免，除非该时间戳的数据已被垃圾收集。
因此，客户端可以避免在重试循环内缓冲结果。
当服务器出现故障时，客户端可以通过重复时间戳和当前读取位置在内部继续在不同服务器上的查询。

##### 4.1.1 Paxos 领导租期

Spanner 的 Paxos 实现使用定时租约来延长领导权(默认为 10 秒)。
潜在的领导者发送定时租约投票请求；在收到法定人数的租约投票后，领导节点知道它持有租约。
副本在成功写入时隐式地延长其租用投票，如果它们即将到期，领导者会请求租用投票扩展。
定义一个领导者的租用间隔，当它发现它有法定租期时开始，并在它不再有法定租期时结束(因为有些已经过期)。
Spanner 依赖于以下不相交不变量：对于每个 Paxos 组，每个 Paxos 领导节点的租期间隔与其他领导者的租用间隔不相同。
第 4.2.5 节描述了如何强制执行此不变量。

Spanner 的实现允许 Paxos 领导节点通过释放其从租约投票来移除从属节点。
为了保持不相交性不变，Spanner 限制了何时允许移除节点。
将 s<sub>max</sub> 定义为领导者使用的最大时间戳。
后续部分将描述何时推进 s<sub>max</sub> 。
在退位之前，领导节点必须等到 TT.after(s<sub>max</sub>) 的返回结果为真。

##### 4.1.2 为 RW 事务分配时间戳

事务读取和写入使用严格的两阶段锁定。
因此，可以在获取所有锁后但在释放任何锁之前的任何时间为它们分配时间戳。
对于给定的事务，Spanner 为其分配 Paxos 分配给代表事务提交的 Paxos 写入的时间戳。

Spanner 依赖于以下单调不变量：在每个 Paxos 组中，Spanner 以单调递增的顺序为 Paxos 写入分配时间戳，甚至跨越领导者。
单个领导副本可以按单调递增的顺序轻松分配时间戳。
这个不变性通过使用不相交不变性在领导节点之间强制执行：领导节点必须只在其领导节点租用的间隔内分配时间戳。
请注意，每当分配时间戳 s 时，s<sub>max</sub> 都会前进到 s 以保持不相交性。

Spanner 还强制执行以下外部一致性不变量：如果事务 T<sub>2</sub> 的开始发生在事务 T <sub>1</sub> 提交之后，则 T<sub>2</sub> 的提交时间戳必须大于 T <sub>1</sub> 的提交时间戳。
我们定义事务 T<sub>i</sub> 的起始时间为 {% mathjax %} e_{i}^{start} {% endmathjax %} 和提交时间为 {% mathjax %} e_{i}^{commit} {% endmathjax %}；并且在 T <sub>i</sub> 事务的提交时间戳为 s <sub>i</sub>。、
我们可以得出如下结论 {% mathjax %} t_{abs}(e_{1}^{commit}) < t_{abs}(e_{2}^{commit}) \Rightarrow s_1 < s_2 {% endmathjax %}。
用于执行事务和分配时间戳的协议遵循两条规则，这两条规则共同保证了该不变量，如下所示。
协调者节点定义了到达时间 T<sub>i</sub> 的提交请求为 {% mathjax %} e_{i}^{server} {% endmathjax %}。

在起始阶段中：协调者节点写入 T<sub>i</sub> 事务时分配的提交时间 s<sub>i</sub> 不得小于在 {% mathjax %} e_{i}^{server} {% endmathjax %} 计算之后的 TT.now().latest。
请注意，是否有领导者作为参与在这里无关紧要；第 4.2.1 节描述了它们如何参与下一条规则的实现。

在提交等待阶段中：协调者节点保证了客户端无法看到任何在 T<sub>i</sub> 时提交的数据，仅当在 TT.after(s<sub>i</sub>) 返回内容为真时才能可见。
提交等待阶段保证了在 s<sub>i</sub> 小于提交时间 T<sub>i</sub>，或者 {% mathjax %} s_{i} < t_{abs}(e_{i}^{commit}) {% endmathjax %}。
第 4.2.1 节描述了提交等待的实现。证明如下：

{% mathjax %} s_1 < t_{abs}(e_{1}^{commit}) {% endmathjax %} (提交等待)

{% mathjax %} t_{abs}(e_{1}^{commit}) < t_{abs}(e_{2}^{start}) {% endmathjax %} (假设)

{% mathjax %} t_{abs}(e_{2}^{start}) \leq t_{abs}(e_{2}^{server}) {% endmathjax %} (因果关系)

{% mathjax %} t_{abs}(e_{2}^{server}) \leq s_{2} {% endmathjax %} (起始)

{% mathjax %} s_{1} < s_{2} {% endmathjax %} (传递性)

##### 4.1.3 在某一时间点的服务器读取

第 4.1.2 节中描述的单调不变性允许 Spanner 确定副本的状态是否足以满足读取的要求。
每个副本都追踪名为 safe time 的参数 t<sub>safe</sub>，此参数说明了副本最大的更新时间戳。
此副本可以安全的被读取，仅需满足读取时间戳为 t ，t <= t<sub>safe</sub>。

定义如下 {% mathjax %} t_safe = min(t_{safe}^{Paxos}, t_{safe}^{TM}) {% endmathjax %} ，Paxos 状态机当中的安全时间为 {% mathjax %}  t_{safe}^{Paxos} {% endmathjax %} 每个事务管理器的安全时间为 {% mathjax %}  t_{safe}^{TM} {% endmathjax %}。
{% mathjax %} t_{safe}^{Paxos} {% endmathjax %} 的计算方式非常简单：它是最新一次通过的 Paxos 写入事件的时间戳。
因为时间戳是单调增加的，并且写入的法令是按顺序通过的，所以在 Paxos 中写入不会低于 {% mathjax %} t_{safe}^{Paxos} {% endmathjax %}。

如果不存在准备(但未提交)的事务(即两阶段提交中处于两个阶段之间的事务)，则复制副本上的 {% mathjax %} t_{safe}^{TM} {% endmathjax %} 是无限大。
对于参与者从属节点，{% mathjax %} t_{safe}^{TM} {% endmathjax %} 实际上是指副本领导节点的事务管理器，从属节点可以通过传递给 Paxos 写入的元数据推断其状态。
如果存在任何此类事务，则受这些事务影响的状态是不确定的：参与者副本尚不知道此类事务是否会提交。
正如我们在第 4.2.1 节中讨论的，提交协议确保每个参与者都知道准备好的事务时间戳的下限。
对于组 g 来说每个参与到过程中的领导节点在事务 T<sub>i</sub> 为准备的数据分配了一个准备时间戳 {% mathjax %} s_{i,g}^{prepare} {% endmathjax %}。
协调领导节点会确保在所有组 g 中的参与者的事务的提交时间戳 {% mathjax %} s_{i} \geq s_{i,g}^{prepare} {% endmathjax %}。
因此，在组 g 中的每一个副本在事务 T<sub>i</sub> 的准备时间都满足公式 {% mathjax %} t_{safe}^{TM} = min_{i}(s_{i,g}^{prepare}) - 1 {% endmathjax %}。

##### 4.1.4 为 RO 事务分配时间戳

快照事务分为两个阶段执行：分配一个时间戳 s<sub>read</sub> `[Chan and Gray 1985]`，然后将事务的读取作为快照读取操作在 s<sub>read</sub> 执行。
快照读取可以在任何足够最新的副本上执行。

在事务开始后的任何时间可以简单分配 s<sub>read</sub> = TT.now().latest，通过类似于第 4.1.2 节中为写入提供的参数来保持外部一致性。
但是，这样的时间戳可能在 s<sub>read</sub> 执行数据读取从而使得 t<sub>safe</sub> 阻塞没有正常执行。
(此外，值得注意的是选择了 s<sub>read</sub> 可能会使 s<sub>max</sub> 产生不相关性。)
为了减少阻塞的产生，Spanner 应该分配最旧的时间戳以保持外部一致性。
4.2.2 节解释了如何选择这样的时间戳。

#### 4.2 实现细节

本节解释了之前省略的读写事务和快照事务的一些实际细节，以及用于实现原子模式更改的特殊事务类型的实现。然后描述了对基本方案的一些改进。

##### 4.2.1 读取和写入事务

与 Bigtable 一样，事务中发生的写入在客户端缓存，直到提交。
因此，事务中的读取不会受到事务写入的影响。
这种设计在 Spanner 中运行良好，因为读取返回任何读取数据的时间戳，而未提交的写入尚未分配时间戳。

读写事务中的读取使用伤害-等待方案 `[Rosenkrantz et al. 1978]` 以避免死锁。
客户端向相应组的领导副本发出读操作，该副本获取读锁，然后读取最新数据。
当客户端事务保持打开状态时，它会发送 keepalive 消息以防止参与的领导节点超时其事务。
当客户端完成所有读取和缓冲写入后，它开始两阶段提交。
客户端选择一个协调者组并向每个参与者的领导节点发送一条提交消息，其中包含协调者的身份和任何缓冲的写入。
让客户端驱动两阶段提交协议可以避免通过广域链接发送数据两次。

非协调者参与领导时首先需要获得写锁。
然后它会选择一个预先准备时间戳，这一时间戳必须大于它被之前分配的所有事务的时间戳(以保持单调性)，并通过 Paxos 记录准备好的数据内容。
之后每个参与者将其准备时间戳通知协调器。

协调器领导者也会首先获得写锁，但跳过准备阶段。
在听取所有其他参与者领导人的意见后，它为整个交易选择一个时间戳。
提交时间戳 s 必须大于或等于所有准备好的时间戳(以满足第 4.1.3 节中讨论的约束)，大于协调器收到其提交消息时的 TT.now().latest ，并且大于任何领导者分配给先前交易的时间戳(再次，为了保持单调性)。
协调器领导然后通过 Paxos 记录提交记录(如果在等待其他参与者时超时，则中止)。

只有 Paxos 领导节点获得锁。锁定状态仅在事务准备期间记录。
如果在准备之前丢失了任何锁(无论是由于避免死锁、超时或 Paxos 领导更改)，参与者将中止运行。
Spanner 确保仅在所有锁仍处于持有状态时才记录准备或提交记录。
在领导者更改的情况下，新领导者会在接受任何新事务之前为准备好的但未提交的事务恢复锁定状态。

在允许任何协调器副本应用提交记录之前，协调器领导者会等待 TT.after(s)，以遵守第 4.1.2 节中描述的提交-等待规则。
因为协调者领导者根据 TT.now ().latest 选择了 s，并且现在一直等到那个时间戳被保证是过去的，所以预期的等待时间至少为 `2*⋷`。
此等待通常与 Paxos 通信重叠。
提交等待后，协调器将提交时间戳发送给客户端和所有其他参与的领导节点。
每个参与者的领导节点通过 Paxos 记录交易的结果。
所有参与者在相同的时间戳申请，然后释放锁定。

##### 4.2.2 快照事务

分配时间戳给多个不同的 Paxos 组需要一个协商阶段。
因此，Spanner 需要为每个快照事务提供一个范围表达式(scope)，该表达式汇总了整个事务将读取的键。
Spanner 自动推断独立查询的范围(scope)。

如果范围的值由单个 Paxos 组提供，则客户端向该组的领导节点发出快照事务。
(当前的 Spanner 实现只为 Paxos 领导者的快照事务选择时间戳。)
这一领导节点分配了 s<sub>read</sub> 并执行了读取操作。
对于单站点读取，Spanner 通常比 TT.now().latest 做得更好。
将 LastTS() 定义为 Paxos 组上最后一次提交写入的时间戳。
如果没有准备好的事务，赋值 s<sub>read</sub>=LastTS() 就简单地满足了外部一致性：事务将看到最后一次写入的结果，因此在它之后排序。

如果范围的值由多个 Paxos 组提供，则有多种选择。
最复杂的选择是与所有组的领导者进行一轮沟通以协商基于 LastTS() 确定 s<sub>read</sub>。Spanner 目前实现了一个更简单的选择。
客户端避免协商回合，只是在 s<sub>read</sub>=TT.now().latest(会等一个安全时间使得时间足够靠后)执行其读取。
事务中的所有读取都可以发送到足够最新的副本。

##### 4.2.3 结构变化事务

TrueTime 使 Spanner 能够支持原子化的结构更改。
使用标准事务是不可行的，因为参与者的数量(数据库中的组数)可能达到以数百万计。
Bigtable 支持在一个数据中心内进行原子的结构更改，但其结构更改会阻止所有操作。

Spanner 结构更改事务通常是标准事务的非阻塞变体。
首先，它被明确分配了一个未来的时间戳，在准备阶段注册。
因此，数千台服务器之间的结构更改可以在对其他并发活动的干扰最小的情况下完成。
其次，读取和写入操作都隐式依赖于结构，并与在时间 t 时任何注册的结构变化进行同步：如果它们的时间戳在 t 之前，它们可以继续，但是如果它们的时间戳在 t 之后，它们必须阻塞在模式更改事务之后。
如果没有 TrueTime，定义在 t 发生的结构更改将毫无意义。

##### 4.2.4 改进

{% mathjax %} t_{safe}^{TM} {% endmathjax %} 在这里的定义时一个缺陷，在单个准备的事务中会阻止 {% mathjax %} t_{safe} {% endmathjax %} 增长。
因此，即使读取与事务没有冲突，在以后的时间戳也不会发生读取。
这样错误的冲突可以通过使用从键范围到准备交易时间戳的细粒度映射来增加 {% mathjax %} t_{safe}^{TM} {% endmathjax %} 的方式消除。
此信息可以存储在锁表中，该表已将键范围映射到锁元数据。
当读取到达时，只需要检查与读取冲突的键范围的细粒度安全时间。

这里定义的 LastTS() 有一个类似的缺陷：如果一个事务刚刚提交，一个非冲突的快照事务仍然必须被分配 s<sub>read</sub> 以便跟随该事务。因此，读取的执行可能会延迟。
可以通过使用从键范围到锁定表中提交时间戳的细粒度映射来增加 LastTS() 来类似地修复此弱点。(我们还没有实现这个优化。)
当快照事务到达时，可以通过取与事务冲突的键范围的 LastTS() 的最大值来分配其时间戳，除非存在冲突的准备事务(可以从细粒度安全时间确定)。

{% mathjax %} t_{safe}^{Paxos} {% endmathjax %} 这里定义的有一个弱点，它不能在没有 Paxos 写入的情况下推进。
也就是说，在 t 读取的快照不能在最后一次写入发生在 t 之前的 Paxos 组上执行。
每个 Paxos 领导者通过保持一个阈值来提高 Paxos 的安全性，高于该阈值将发生未来写入的时间戳：它维护从 Paxos 序列号 n 到可以分配给 Paxos 序列号 n + 1 的最小时间戳的映射 MinNextTS(n)。
当副本通过 n 应用时，它可以将 t Paxos 安全推进到 MinNextTS(n) − 1。

单个领导节点可以轻松执行其 MinNextTS() 承诺。
因为 MinNextTS() 承诺的时间戳位于领导者的租约内，不连接不变量在领导者之间强制执行 MinNextTS() 承诺。
如果领导节点希望在其领导者租约结束后推进 MinNextTS()，则必须首先延长其租期。
请注意，s<sub>max</sub> 始终前进到 MinNextTS() 中的最高值以保留不相交性。

默认情况下，领导者每 8 秒推进一次 MinNextTS() 值。
因此，在没有准备好的事务的情况下，空闲 Paxos 组中的健康从服务器可以在最坏的情况下提供大于 8 秒的 read at 时间戳。
领导节点也可以根据从属节点的要求推进 MinNextTS() 值。

##### 4.2.5 Paxos 领导者-租赁管理

确保 Paxos-leader-lease 间隔不相交的最简单方法是，无论何时，Leader 都会发出租用间隔的同步 Paxos 写入。随后的领导节点将等待该间隔并过去读取。

TrueTime 可用于确保不相交，而无需这些额外的日志写入。
潜在的第 i 个领导节点在开始投票租期副本 r 处于 {% mathjax %} r_{i,r}^{leader} = TT.now().earliest {% endmathjax %} 时保持一个较低的边界，计算在事件 {% mathjax %} e_{i,r}^{send} {% endmathjax %} 之前(定义为在领导节点发送租期请求时)。
每个副本 r 都会在 {% mathjax %} e_{i,r}^{grant} {% endmathjax %} 时获得租期，这一事件会在 {% mathjax %} e_{i,r}^{receive} {% endmathjax %} 之后发生(当副本收到租期请求时); 租期结束于 {% mathjax %} t_{i,r}^{end} = TT.now().latest + lease_length {% endmathjax %}，在 {% mathjax %}  e_{i,r}^{receive} {% endmathjax %} 完成。
一个副本 r 遵循单独投票的规则：它不会授予另一次租期投票，直到 TT.after({% mathjax %} t_{i,r}^{end} {% endmathjax %}) 返回为真时。
在 r 的不同实例中强制执行此规则，Spanner 在授予租期之前在授予副本上记录租期投票；此日志写入可以搭载在现有的 Paxos 协议日志写入上。

当第 i 个领导节点接收到法定人数的投票(关于事件 {% mathjax %} e_{i}^{quorum} {% endmathjax %} )，它会计算它的租期间隔为 `{% mathjax %} lease_{i} = [TT.now().latest,min_{r}(v_{i,r}^{leader}) + lease\_length] {% endmathjax %}`。
若 {% mathjax %} TT.before(min_r(v_{i,r}^{leader}) + lease\_length) {% endmathjax %} 返回为假时租期在领导节点处被视为已到期。
为了证明不相交，我们利用了这样一个事实，即第 i 个和第 (i+1) 个领导节点在他们的法定人数中必须有一个共同的副本。这个副本为 r0，证明如下：

{% mathjax %} lease_i.end = min_r(v_{i,r}^{leader} + lease\_length) {% endmathjax %} (经过定义)

{% mathjax %} min_r(v_{i,r}^{leader}) + lease\_length \leq v_{i,r0}^{leader} + lease\_length {% endmathjax %} (最小值)

{% mathjax %} v_{i,r0}^{leader} + lease\_length \leq t_abs(e_{i,r0}^{receive}) + lease\_length {% endmathjax %} (经过定义)

{% mathjax %} t_{abs}(e_{i,r0}^{send}) + lease\_length \leq t_abs(e_{i,r0}^{receive}) + lease\_length {% endmathjax %} (因果关系)

{% mathjax %} t_{abs}(e_{i,r0}^{receive} + lease\_length \leq t_{i,r0}^{end}) {% endmathjax %} (经过定义)

{% mathjax %} t_{i,r0}^{end} < t_abs(e_{i+1,r0}^{grant}) {% endmathjax %} (单项投票)

{% mathjax %} t_{abs}(e_{i+1,r0}^{grant}) \leq t_abs(e_{i+1}^{quorum}) {% endmathjax %} (因果关系)

{% mathjax %} t_{abs}(e_{i+1}^{quorum}) \leq lease_{i+1}.start {% endmathjax %} (经过定义)

### 5 评估

我们首先衡量 Spanner 在复制、事务和可用性方面的性能。然后我们提供了一些关于 TrueTime 行为的数据，以及我们的第一个客户 F1 的案例研究。

#### 5.1 微基准

| 副本数量 |  写入延迟(ms)  | 快照事务延迟(ms) |  快照读取(ms)  | 写入吞吐量(千次操作/秒) |  快照事务吞吐量   |  快照读取吞吐量   |
|:----:|:----------:|:----------:|:----------:|:-------------:|:----------:|:----------:|
|  1D  | 10.1 ± 0.3 |     -      |     -      |  4.2 ± 0.03   |     -      |     -      |
|  1   | 14.1 ± 1.0 | 1.3 ± 0.04 | 1.3 ± 0.02 |  4.2 ± 0.07   | 10.7 ± 0.6 | 11.4 ± 0.2 |
|  3   | 14.3 ± 0.5 | 1.4 ± 0.08 | 1.4 ± 0.08 |  1.8 ± 0.03   | 11.2 ± 0.4 | 32.0 ± 1.8 |
|  5   | 15.4 ± 2.3 | 1.4 ± 0.07 | 1.6 ± 0.04 |   1.2 ± 0.2   | 11.1 ± 0.5 | 46.8 ± 5.8 |

> 表 3：操作微基准，10 次运行的平均值和标准偏差。1D 表示禁用提交等待的一个副本。

表 3 列出了 Spanner 的一些微基准测试。
这些测量是在分时机器上进行的：每个 spanserver 在 4GB RAM 和 4 个内核(AMD Barcelona 2200MHz)上运行。
客户端在不同的机器上。每个 zone 包含一个 spanserver。
客户端和 zone 被放置在一组网络距离小于 1ms 的数据中心中。
(这样的布局应该是司空见惯的：大多数应用程序不需要在全球范围内分发所有数据。)
测试数据库由 50 个 Paxos 组和 2500 个目录。
操作是独立的 4KB 读取和写入。
压缩后，所有读取都在内存外提供，因此我们只测量 Spanner 调用堆栈的开销。
此外，首先进行一轮未测量的读取操作以预热任何位置缓存。

对于延迟实验，客户端发出足够少的操作以避免在服务器上排队。
从单个副本的实验来看，提交(commit)等待时间大约为 4ms，Paxos 延迟大约为 10ms。
随着副本数量的增加，延迟会略有增加，因为 Paxos 必须提交更多副本。
因为 Paxos 在组的副本上并行执行，所以增加是次线性的：延迟取决于仲裁中最慢的成员。
我们可以在写入延迟中看到最多的测量噪声。

对于吞吐量实验，客户端发出足够多的操作以使服务器的 CPU 饱和。
此外，Paxos 领导者节点固定在一个 zone ，以便在整个实验中保持恒定的领导节点运行的机器数量。
快照读取可以在任何最新的副本上执行，因此它们的吞吐量随着副本数量的增加而增加。
单读快照事务仅在领导节点处执行，因为时间戳分配必须发生在领导节点处。
因此，快照事务吞吐量与副本数量大致保持不变。
最后，写入吞吐量随着副本数量的增加而降低，因为 Paxos 工作量随副本数量线性增加。
同样，由于我们在生产数据中心运行，因此我们的测量中存在大量噪声：我们不得不丢弃一些只能通过其他作业的干扰来解释的数据。

| 参与者数量 |    平均延迟     |  第 99 个百分位的延迟  |
|:-----:|:-----------:|:--------------:|
|   1   | 14.6 ± 0.2  |  26.550 ± 6.2  |
|   2   | 20.7 ± 0.4  |  31.958 ± 4.1  |
|   5   | 23.9 ± 2.2  |  46.428 ± 8.0  |
|  10   | 22.8 ± 0.4  |  45.931 ± 4.2  |
|  25   | 26.0 ± 0.6  |  52.509 ± 4.3  |
|  50   | 33.8 ± 0.6  |  62.420 ± 7.1  |
|  100  | 55.9 ± 1.2  |  88.859 ± 5.9  |
|  200  | 122.5 ± 6.7 | 206.443 ± 15.8 |

> 表 4：两阶段提交可扩展性。10 次运行的平均偏差和标准偏差

表 4 显示了两阶段提交可以扩展到合理数量的参与者：它是对一系列实验的总结，这些实验运行在 3 个 zone 上，每个 zone 具有 25 个 spanserver。
扩展到 50 个参与者，无论在平均值还是第 99 个百分位方面，都是合理的。在100个参与者的情形下，延迟开始明显增加。

#### 5.2 可用性

![图 5：关闭服务器对吞吐量的影响](https://s2.loli.net/2021/12/24/S8vobkhjHtCViU4.png)

图 5 说明了在多个数据中心运行 Spanner 的可用性优势。
它显示了在存在数据中心故障的情况下对吞吐量进行的三个实验的结果，所有这些实验都覆盖在相同的时间尺度上。
测试域由 5 个 zone Zi 组成，每个 zone 有 25 个 span server。
测试数据库被分成 1250 个 Paxos 组，100 个测试客户端以 50K 读取/秒的聚合速率不断发出非快照读取。
所有的领导节点都明确地放在 Z1 中。
每次测试 5 秒后，一个区域内的所有服务器都被杀死：非领导者关闭 Z<sub>2</sub>；领导节点强制关闭 Z<sub>1</sub>；领导节点软关闭 Z<sub>1</sub>，但它会通知所有服务器，他们应该首先移交领导权。

关闭 Z<sub>2</sub> 不会影响读取吞吐量。
在给领导节点时间将领导权移交给不同 zone 的同时关闭 Z<sub>1</sub> 有一个较小的影响：吞吐量下降在图中不可见，但约为 3-4%。
另一方面，在没有警告的情况下关闭 Z<sub>1</sub> 会产生严重的影响：完成率几乎下降到 0。
然而，由于领导节点被重新选择，系统的吞吐量升至大约十万次读取/秒，因为我们的实验存在者两个特征：系统中存在额外的容量，并且在领导者不可用时，操作会排队。
结果就是系统的吞吐量上升，然后再次稳定在其稳态速率。

我们还可以看到 Paxos 领导节点租期设置为 10 秒这一事实的影响。
当我们杀死 zone 时，组内的领导节点租期时间应该在接下来的 10 秒内均匀分布。
在一个关闭的领导节点的租约到期后不久，就会选出一个新的领导节点。
在关闭后大约 10 秒，所有组都有领导节点并且吞吐量已经恢复。
更短的租期将减少服务器关闭对可用性的影响，但需要更多的租期更新网络流量。
我们正在设计和实施一种机制，该机制将导致从属节点在领导节点关闭时释放 Paxos 领导租约。

#### 5.3 TrueTime

关于 TrueTime，有两个问题必须回答：`ϵ` 是否就是时钟不确定性的边界？`ϵ`在最差的情况下会怎么样？
对于前者，最严重的问题是如果本地时钟的漂移大于 200 us/sec：这将打破 TrueTime 的假设。
我们的机器统计数据显示，CPU 损坏的可能性是时钟损坏的 6 倍。
也就是说，相对于更严重的硬件问题，时钟问题非常罕见。
因此，我们相信 TrueTime 的实现与 Spanner 所依赖的任何其他软件一样值得信赖。

![image.png](https://s2.loli.net/2021/12/27/NzGPFkDm83UeIgf.png)

图 6 显示了在相距最远 2200 公里的数据中心内的数千个 spanserver 机器上获取的 TrueTime 数据。
它绘制了 `ϵ` 的第 90 个、第 99 个和第 99.9 个百分位数，在轮询时间主进程后立即在时间从进程中采样。
由于本地时钟的不确定性，这种采样消除了 `ϵ` 中的锯齿波，因此测量时间主控器的不确定性（通常为 0）加上与时间主控器的通信延迟。

数据表明，这两个因素在确定 `ϵ` 的基值时一般不成问题。
然而，可能存在导致 `ϵ` 值较高的显着尾部延迟问题。
从 3 月 30 日开始，尾部延迟的减少是由于网络改进减少了瞬态网络链路拥塞。
4 月 13 日的 `ϵ` 出现了升高，持续时间约为 1 小时，原因是数据中心的 2 次主站关闭进行日常维护。
我们将继续调查并消除 TrueTime 峰值的原因。

#### 5.4 F1

Spanner 于 2011 年初开始在生产工作负载下进行实验评估，作为重写 Google 广告后端 F1 的一部分 `[Shute et al. 2012]`。
这个后端最初是基于一个手动分片的 MySQL 数据库。
未压缩的数据集有数十 TB，与许多 NoSQL 实例相比很小，但大到足以导致分片 MySQL 出现问题。
MySQL 分片方案将每个客户和所有相关数据分配到一个固定分片。
这种布局允许在每个客户的基础上使用索引和复杂的查询处理，但需要一些应用程序业务逻辑中的分片知识。
随着客户数量和数据规模的增长，重新分配这个对收入至关重要的数据库的成本非常高。
上一次重新分片花费了两年的努力，涉及数十个团队之间的协调和测试，以最大限度地降低风险。
此操作过于复杂，无法定期执行：因此，团队不得不通过将一些数据存储在外部 Bigtable 中来限制 MySQL 数据库的增长，但这会损害事务行为和查询所有数据的能力。

F1 团队选择使用 Spanner 有几个原因。
首先，Spanner 无需手动重新分片。
其次，Spanner 提供同步复制和自动故障转移。
使用 MySQL 主从复制，故障转移很困难，并且有数据丢失和停机的风险。
第三，F1 需要强大的事务语义，这使得使用其他 NoSQL 系统不切实际。
应用程序语义需要跨任意数据的事务，和一致性的读取功能。
F1 团队还需要对他们的数据进行二级索引(因为 Spanner 尚未提供对二级索引的自动支持)，并且能够使用 Spanner 事务实现自己的一致全局索引。

所有应用程序写入现在默认通过 F1 发送到 Spanner，而不是基于 MySQL 的应用程序栈。
F1在美国西海岸有 2 个副本，在东海岸有 3 个。
选择副本站点是为了应对潜在的重大自然灾害造成的中断，以及他们前端站点的选择。
有趣的是，他们几乎看不到 Spanner 的自动故障转移。
在过去的几个月中，尽管有不在计划内的机群失效，但是，F1团队最需要做的工作仍然是更新他们的数据库模式，来告诉 Spanner 在哪里放置 Paxos 领导节点，从而使得它们尽量靠近应用前端。

Spanner 的时间戳语义使 F1 能够有效地维护从数据库状态计算出的内存中数据结构。
F1 维护所有更改的逻辑历史日志，该日志作为每个事务的一部分写入 Spanner 本身。
F1 在时间戳上获取数据的完整快照以初始化其数据结构，然后读取增量更改以更新它们。

|   片段    |  目录   |
|:-------:|:-----:|
|    1    | >100M |
|   2-4   |  341  |
|   5-9   | 5336  |
|  10-14  |  232  |
|  15-99  |  34   |
| 100-500 |   7   |

> 表 5：F1 中目录片段计数的分布。

表 5 说明了 F1 中每个目录的片段数量分布。
每个目录通常对应于 F1 之上的应用程序堆栈中的一个客户。
绝大多数目录（以及客户）仅包含 1 个片段，这意味着对这些客户数据的读取和写入保证仅发生在单个服务器上。
超过 100 个分片的目录都是包含 F1 二级索引的表：写入这些表的多个分片是非常罕见的。
F1 团队仅在将批量数据加载作为事务进行调优时才看到这种行为。

|  操作  | 平均延迟(ms) | 延迟标准差 |  总大小  |
|:----:|:--------:|:-----:|:-----:|
| 所有读取 |   8.7    | 376.4 | 21.5B |
| 单点提交 |   72.3   | 112.8 | 31.2M |
| 多点提交 |  103.0   | 52.2  | 32.1M |

> 表 6：F1-24 小时内测量的可感知操作延迟。

表 6 显示了从 F1 服务器测量的 Spanner 操作延迟。
东海岸数据中心的副本在选择 Paxos 领导节点时具有更高的优先级。
表中的数据是从这些数据中心的 F1 服务器测量的。
写入延迟的大标准偏差是由于锁冲突导致的肥尾效应(pretty fat tail)造成的。
读取延迟更大的标准偏差部分是由于 Paxos 的领导节点分布在两个数据中心，其中只有一个有配备 SSD 的机器。
此外，测量包括系统中来自两个数据中心的每次读取：读取的字节的平均值和标准差分别约为 1.6KB 和 119KB。

### 6 相关工作

跨数据中心的一致复制作为存储服务已由 Megastore 和 DynamoDB 提供 `[Baker et al. 2011]`。
DynamoDB 呈现一个key-value 接口，并且只在一个区域内复制。
Spanner 跟随 Megastore 提供了一个半关系数据模型，甚至是一种类似的模式语言。
Megastore 没有实现高性能。 它位于 Bigtable 之上，这带来了高昂的通信成本。
它也不支持长时间的领导节点：多个副本可能会启动写入。
来自不同副本的所有写入都必然会在 Paxos 协议中发生冲突，即使它们在逻辑上没有冲突：Paxos 组的吞吐量会以每秒多次写入的速度崩溃。
Spanner 提供更高的性能、通用事务和外部一致性。

Pavlo et al. `[2009]` 比较了数据库和 MapReduce `[Dean and Ghemawat 2010]` 的性能。
他们指出了为探索分布式键值存储分层的数据库功能而做出的其他一些努力 `[Abouzeidet al. 2009; Armbrust et al. 2011; Brantner et al. 2008; Thusoo et al. 2010]` 二者可以实现充分的融合。
我们同意这个结论，但证明集成多个层有其优势：例如，将并发控制与复制集成降低了 Spanner 中的提交等待成本。

在复制存储之上分层交易的概念至少可以追溯到 Gifford 的论文 `[Gifford 1982]`。
Scatter `[Glendenning et al. 2011]` 是最近的基于 DHT 的键值存储，它在一致复制之上分层事务。
Spanner 专注于提供比 Scatter 更高级别的接口。
Gray 和 Lamport [2006] 描述了一种基于 Paxos 的非阻塞提交协议。
他们的协议比两阶段提交产生更多的消息传递成本，这会加剧广泛分布的组的提交成本。
Walter `[Sovran et al. 2011]` 提供了一种在数据中心内但不能跨数据中心工作的快照隔离变体。
相比之下，我们的快照事务提供了更自然的语义，因为我们支持外部一致性整体操作。

最近有大量关于减少或消除锁定开销的工作。
Calvin `[Thomson et al. 2012]` 消除了并发控制：它会重新分配时间戳，然后以时间戳的顺序执行事务。
H-Store `[Stonebraker et al.2007]` 和 Granola `[Cowling and Liskov 2012]` 都支持他们自己的交易类型分类，其中一些可以避免锁定。
这些系统都没有提供外部一致性。 Spanner 通过提供对快照隔离的支持来解决争用问题。

VoltDB `[2012]` 是一个分片内存数据库，它支持大范围内的主从复制以进行灾难恢复，但不支持更通用的复制配置。
它是所谓的 NewSQL 的一个实例，这是实现可扩展的 SQL 的强大的市场推动力 `[Stonebraker 2010a]`。
许多商业数据库过去都实现了读取功能，例如 MarkLogic `[2012]` 和 Oracle 的 Total Recall `[Oracle2012]`。
Lomet 和 Li `[2009]` 描述了这种时态数据库的实现策略。

Farsite 衍生出的时钟不确定性边界(比 TrueTime 更宽松)相对于受信任的时钟参考 `[Douceur and Howell 2003]`：Farsite 中的服务器租用与 Spanner 维护 Paxos 租期的方式相同。
在先前的工作中，松散同步的时钟已被用于并发控制目的 `[Adya et al.1995; Liskov 1993]`。
我们已经证明 TrueTime 可以让一个关于跨 Paxos 状态机集的全局时间的原因。

### 7 未来的工作

我们去年大部分时间都在与 F1 团队合作，将 Google 的广告后端从 MySQL 过渡到 Spanner。
我们正在积极改进其监控和支持工具，并调整其性能。
此外，我们一直致力于改进备份/恢复系统的功能和性能。
Wear 目前正在实施 Spanner 模式语言、二级索引的自动维护和基于负载的自动重新分片。
从长远来看，我们计划研究几个功能。
乐观地并行读取可能是一种有价值的策略，但最初的实验表明，正确的实现并非易事。
此外，我们计划最终支持 Paxos 配置的直接更改 `[Lamport et al. 2010; Shraer et al. 2012]`。

鉴于我们预计许多应用程序会在彼此相对靠近的数据中心之间复制其数据，TrueTime `ϵ` 可能会显着影响性能。我们认为将 `ϵ` 降低到 1 毫秒以下没有不可逾越的障碍。
可以减少时间主查询间隔，并且更好的时钟晶体相对便宜。
时间主查询延迟可以通过改进的网络技术来减少，或者甚至可以通过替代时间分配技术来避免。

最后，还有明显需要改进的地方。
尽管 Spanner 在节点数量上具有可扩展性，但节点本地数据结构在复杂 SQL 查询上的性能相对较差，因为它们是为简单的键值访问而设计的。
DB 文献中的算法和数据结构可以大大提高单节点性能。
其次，在数据中心之间自动移动数据以响应客户端负载的变化一直是我们的目标，但为了使该目标有效，我们还需要能够以自动化、协调的方式在数据中心之间移动客户端应用程序进程。
移动进程带来了更困难的问题，即管理数据中心之间的资源获取和分配。

### 8 结论

总而言之，Spanner 结合并扩展了来自两个研究社区的想法：来自数据库社区、熟悉的、易于使用的半关系界面、事务和基于 SQL 的查询语言；来自系统社区、可扩展性、自动分片、容错、一致复制、外部一致性和广域分布。
自 Spanner 成立以来，我们已经用了 5 年多的时间来迭代到当前的设计和实现。
这个漫长的迭代阶段的一部分是因为人们缓慢地意识到 Spanner 不仅应该解决全局复制命名空间的问题，还应该关注 Bigtable 缺少的数据库功能。

我们设计的一个方面脱颖而出：Spanner 功能集的关键是 TrueTime。
我们已经证明，在时间 API 中具体化时钟不确定性使得构建具有更强时间语义的分布式系统成为可能。
此外，随着底层系统对时钟不确定性实施更严格的界限，更强语义的开销减少。
作为一个社区，我们在设计分布式算法时不应再依赖松散同步的时钟和弱时间 API。

### 致谢

```text
Many people have helped to improve this article: our shepherd Jon Howell, who went above and beyond hisresponsibilities;
 the anonymous referees; and many Googlers: Atul Adya, Fay Chang, Frank Dabek, SeanDorward, Bob Gruber, David Held, 
 Nick Kline, Alex Thomson, and Joel Wein. Our management has beenvery supportive of both our work and of publishing this article: 
 Aristotle Balogh, Bill Coughran, Urs H¨olzle,Doron Meyer, Cos Nicolaou, Kathy Polizzi, Sridhar Ramaswany, and Shivakumar Venkataraman. 
 We havebuilt upon the work of the Bigtable and Megastore teams. The F1 team, and Jeff Shute in particular,
 workedclosely with us in developing our data model and helped immensely in tracking down performance andcorrectness bugs.
 The Platforms team, and Luiz Barroso and Bob Felderman in particular, helped to makeTrueTime happen.
 Finally, a lot of Googlers used to be on our team: Ken Ashcraft, Paul Cychosz, KrzysztofOstrowski, Amir Voskoboynik,
 Matthew Weaver, Theo Vassilakis, and Eric Veach; or have joined our teamrecently: Nathan Bales, Adam Beberg, Vadim Borisov,
 Ken Chen, Brian Cooper, Cian Cullinan, Robert-JanHuijsman, Milind Joshi, Andrey Khorlin, Dawid Kuroczko, Laramie Leavitt,
 Eric Li, Mike Mammarella,Sunil Mushran, Simon Nielsen, Ovidiu Platon, Ananth Shrinivas, Vadim Suvorov, and Marcel van der Holst.
```

### 参考资料

[1] Azza Abouzeid et al. “HadoopDB: an architectural hybrid of MapReduce and DBMS technologies for analytical workloads”. Proc. of VLDB. 2009, pp. 922–933.

[2] A. Adya et al. “Efficient optimistic concurrency control using loosely synchronized clocks”. Proc. of SIGMOD. 1995, pp. 23–34.

[3] Amazon. Amazon DynamoDB. 2012.

[4] Michael Armbrust et al. “PIQL: Success-Tolerant Query Processing in the Cloud”. Proc. of VLDB. 2011, pp. 181–192.

[5] Jason Baker et al. “Megastore: Providing Scalable, Highly Available Storage for Interactive Services”. Proc. of CIDR. 2011, pp. 223–234.

[6] Hal Berenson et al. “A critique of ANSI SQL isolation levels”. Proc. of SIGMOD. 1995, pp. 1–10.

[7] Matthias Brantner et al. “Building a database on S3”. Proc. of SIGMOD. 2008, pp. 251–264.

[8] A. Chan and R. Gray. “Implementing Distributed Read-Only Transactions”. IEEE TOSE SE-11.2 (Feb. 1985), pp. 205–212.

[9] Fay Chang et al. “Bigtable: A Distributed Storage System for Structured Data”. ACM TOCS 26.2 (June 2008), 4:1–4:26.

[10] Brian F. Cooper et al. “PNUTS: Yahoo!’s hosted data serving platform”. Proc. of VLDB. 2008, pp. 1277–1288.

[11] James Cowling and Barbara Liskov. “Granola: Low-Overhead Distributed Transaction Coordination”. Proc. of USENIX ATC. 2012, pp. 223–236.

[12] Jeffrey Dean and Sanjay Ghemawat. “MapReduce: a flexible data processing tool”. CACM 53.1 (Jan. 2010), pp. 72–77.

[13] John Douceur and Jon Howell. Scalable Byzantine-Fault-Quantifying Clock Synchronization. Tech. rep. MSR-TR-2003-67. MS Research, 2003.

[14] John R. Douceur and Jon Howell. “Distributed directory service in the Farsite file system”. Proc. of OSDI. 2006, pp. 321–334.

[15] Sanjay Ghemawat, Howard Gobioff, and Shun-Tak Leung. “The Google file system”. Proc. of SOSP. Dec. 2003, pp. 29–43.

[16] David K. Gifford. Information Storage in a Decentralized Computer System. Tech. rep. CSL-81-8. PhD dissertation. Xerox PARC, July 1982.

[17] Lisa Glendenning et al. “Scalable consistency in Scatter”. Proc. of SOSP. 2011.

[18] Jim Gray and Leslie Lamport. “Consensus on transaction commit”. ACM TODS 31.1 (Mar. 2006), pp. 133–160.

[19] Pat Helland. “Life beyond Distributed Transactions: an Apostate’s Opinion”. Proc. of CIDR. 2007, pp. 132–141.

[20] Maurice P. Herlihy and Jeannette M. Wing. “Linearizability: a correctness condition for concurrent objects”. ACM TOPLAS 12.3 (July 1990), pp. 463–492.

[21] Leslie Lamport. “The part-time parliament”. ACM TOCS 16.2 (May 1998), pp. 133–169.

[22] Leslie Lamport, Dahlia Malkhi, and Lidong Zhou. “Reconfiguring a state machine”. SIGACT News 41.1 (Mar. 2010), pp. 63–73.

[23] Barbara Liskov. “Practical uses of synchronized clocks in distributed systems”. Distrib. Comput. 6.4 (July 1993), pp. 211–219.

[24] David B. Lomet and Feifei Li. “Improving Transaction-Time DBMS Performance and Functionality”. Proc. of ICDE (2009), pp. 581–591.

[25] Jacob R. Lorch et al. “The SMART way to migrate replicated stateful services”. Proc. of EuroSys. 2006, pp. 103–115.

[26] MarkLogic. MarkLogic 5 Product Documentation. 2012.

[27] Keith Marzullo and Susan Owicki. “Maintaining the time in a distributed system”. Proc. of PODC. 1983, pp. 295–305.

[28] Sergey Melnik et al. “Dremel: Interactive Analysis of Web-Scale Datasets”. Proc. of VLDB. 2010, pp. 330–339.

[29] D.L. Mills. Time synchronization in DCNET hosts. Internet Project Report IEN–173. COMSAT Laboratories, Feb. 1981.

[30] Oracle. Oracle Total Recall. 2012.

[31] Andrew Pavlo et al. “A comparison of approaches to large-scale data analysis”. Proc. of SIGMOD. 2009, pp. 165–178.

[32] Daniel Peng and Frank Dabek. “Large-scale incremental processing using distributed transactions and notifications”. Proc. of OSDI. 2010, pp. 1–15.

[33] Daniel J. Rosenkrantz, Richard E. Stearns, and Philip M. Lewis II. “System level concurrency control for distributed database systems”. ACM TODS 3.2 (June 1978), pp. 178–198.

[34] Alexander Shraer et al. “Dynamic Reconfiguration of Primary/Backup Clusters”. Proc. of  SENIX ATC. 2012, pp. 425–438.

[35] Jeff Shute et al. “F1—The Fault-Tolerant Distributed RDBMS Supporting Google’s Ad Business”. Proc. of SIGMOD. May 2012, pp. 777–778.

[36] Yair Sovran et al. “Transactional storage for geo-replicated systems”. Proc. of SOSP. 2011, pp. 385–400.

[37] Michael Stonebraker. Why Enterprises Are Uninterested in NoSQL. 2010.

[38] Michael Stonebraker. Six SQL Urban Myths. 2010.

[39] Michael Stonebraker et al. “The end of an architectural era: (it’s time for a complete rewrite)”. Proc. of VLDB. 2007, pp. 1150–1160.

[40] Alexander Thomson et al. “Calvin: Fast Distributed Transactions for Partitioned Database Systems”. Proc. of SIGMOD.2012, pp. 1–12.

[41] Ashish Thusoo et al. “Hive — A Petabyte Scale Data Warehouse Using Hadoop”. Proc. of ICDE. 2010, pp. 996–1005.

[42] VoltDB. VoltDB Resources. 2012.