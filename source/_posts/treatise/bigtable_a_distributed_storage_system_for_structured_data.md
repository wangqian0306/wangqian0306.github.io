---
title: Bigtable A Distributed Storage System for Structured Data 中文翻译版
date: 2021-06-10 22:26:13
tags: "论文"
id: bigtable_a_distributed_storage_system_for_structured_data
no_word_count: true
no_toc: false
categories: 大数据
---

## Bigtable: A Distributed Storage System for Structured Data 中文翻译版

### 摘要

Bigtable 是一个分布式的结构化数据存储系统，它被设计用来处理海量数据：通常是分布在数千台普通服务器上的 PB 级的数据。
Google 的很多项目使用 Bigtable 存储数据，包括 Web 索引、Google Earth、Google Finance。
这些应用对 Bigtable 提出的要求差异非常大，无论是在数据量上(从 URL 到网页到卫星图像)还是在响应速度上(从后端的批量处理到实时数据服务)。
尽管应用需求差异很大，但是，针对 Google 的这些产品，Bigtable 还是成功的提供了一个灵活的、高性能的解决方案。
本论文描述了 Bigtable 提供的简单的数据模型，利用这个模型，用户可以动态的控制数据的分布和格式；我们还将描述 Bigtable 的设计和实现。

### 1 引言

在过去的两年半中我们在 Google 设计实现并部署了一个分布式系统来管理结构数据，这个系统被称为 Bigtable。
Bigtable 被设计用来可靠并可扩展的在数千台设备上存储 PB 级别的数据。
Bigtable 完成了一下几项目标：广泛的适用性、可伸缩性、高性能和高可用性。
Bigtable 被 16 项 Google 的产品和项目使用，其中包含 Google Analytics,
Google Finance, Orkut, Personalized Search, Writely, 和 Google Earth。
这些产品将 Bigtable 用于各种苛刻的工作负载，例如面向吞吐量的批处理作业和对延迟敏感的向最终用户提供数据服务。
这些产品使用的 Bigtable 集群的配置范围很广，从少数服务器到数千台服务器，最多可存储几百 TB 的数据。

在许多方面，Bigtable 类似于一个数据库：它与数据库共享许多实现策略。
并行数据库 `[14]` 和内存数据库 `[13]` 已经实现了可伸缩性和高性能，但是 Bigtable 提供了与这类系统不同的接口。
Bigtable 不支持完整的关系数据模型；相反，它为客户机提供了一个简单的数据模型，支持对数据布局和格式的动态控制，
并允许客户机对底层存储中表示的数据的局部性属性进行推理。
数据的索引使用可以是任意的行和列的字符串。
Bigtable 还将数据视为字符串，尽管客户机通常将各种形式的结构化和半结构化数据序列化到这些字符串中。
通过仔细选择数据的模式，客户可以控制数据的位置相关性。
最后，可以通过 BigTable 的模式参数来控制数据是存放在内存中、还是硬盘上。

第 2 节更详细地描述了数据模型，第 3 节概述了客户端 API。
第 4 节简要描述了 Bigtable 所依赖的 Google 基础设施。
第 5 节描述了 Bigtable 实现的基本原理，
第 6 节描述了我们为提高 Bigtable 性能所做的一些改进。
第 7 节提供了 Bigtable 性能的数据。
我们在第 8 节中描述了 Bigtable 在 Google 内部使用的例子，
并在第 9 节中讨论了我们在设计和支持 Bigtable 时学到的一些经验教训。
最后，第 10 节描述了相关工作，第 11 节给出了我们的结论。

### 2 数据模型

Bigtable是一个稀疏的、分布式的、持久的多维排序的 Map。
这个 Map 使用 row key, column key, timestamp 作为索引；每个值在 Map 中都是一段未解释的字节数组。

```text
(row:string, column:string, time:int64) → string
```

![图 1：一个 Web 页面示例表的切片](https://i.loli.net/2021/06/11/Mm7GQIqlyT4sCtn.png)

> 注：行的名称是逆序的 URL。contents column family 包含了整个页面的内容，anchor column family 包含了引用(anchor `HTML <a>`)本页的所有文本。
> CNN 的主页被 Sports Illustrated 和 MY-look主页引用，所以这一行就会有两个列分别是
> `anchor:cnnsi.com` 和 `anchor:my.look.ca` 。
> 每个 anchor 单元含有一个版本，content 列含有三个版本，时间戳分别为 t3, t5 和 t6 。

在研究了 Bigtable 系统的各种潜在用途之后，我们确定了这个数据模型。
作为一个具体的例子，驱动我们的一些设计决策，假设我们想保留一个网页和相关信息的大集合的副本，
可以由许多不同的项目使用；让我们把这个特殊的表称为 `Webtable` 。
在 `Webtable` 中，我们将使用 url 作为行键，将 Web 页面的各个方面作为列名，
并将 Web 页面的内容存储在 `contents:column` 中，在获取这些内容时将其存储在时间戳下，如图 1 所示。

#### 行

表中的 row key 是任意字符串(当前大小高达 64 KB, 但对于大多数用户来说 10-100 bytes 应该是一个典型的大小)
在同一个 row key 下读取或者写入的每个数据都是具有原子性的(不管在该行中读取或写入不同列的数量)，
这是一个设计决策，可以让客户很容易的理解程序在对同一个行进行并发更新操作时的行为。

Bigtable 按 row key 的字典顺序维护数据。
表的行范围是动态分区的。
每行范围称为 Tablet，它是分布和负载平衡的单位。
因此，短行范围的读取是有效的，并且通常只需要与少量机器进行通信。
客户机可以通过选择其行键来利用此属性，以便获得数据访问的良好位置。
例如，在 `Webtable` 中，通过反转 URL 的主机名，可以将同一域中的页面分组到相邻的行中。
例如，我们将 maps.google.com/index.html 的数据存储在 com.google.maps/index.html 键下方。
将来自同一个域的页面彼此相邻地存储在一起会使某些主机和领域分析更有效。

#### Column Families

column key 的集合被称为 column families，这些集合构成了访问控制的基本单元。
存储在同一 column family 中的所有数据通常都是相同类型的(我们将同一 column family 中的数据压缩在一起)。
必须先创建 column family 才能在其下存储数据，创建 column family 后可以使用其下的所有 column key。
我们的目的是表中不同 column family 的数量要少 (最多几百个)，并且其在操作过程中很少改变。
与之相对应的，一张表可以有无限多个列。

column key 使用以下语法命名：family:qualifier。
column family 的名称必须是可以打印的，但 qualifier 可以是任意字符串。
`Webtable` 的一个示例 column family 是 language，它存储编写网页时使用的语言。
我们在 language column family 中只使用一个 column key，它存储每个网页的语言 ID。
这个表的另一个有用的 column family 是 anchor；这个 column family 中的每个 column key 表示一个anchor，如图 1 所示。

访问控制以及磁盘和内存统计都是在 column family 级别执行的。
在我们的 `Webtable` 示例中，这些控件允许我们管理几种不同类型的应用程序：
一些添加新的基础数据，一些读取基础数据并创建派生 column family，
还有一些只允许查看现有数据(出于隐私原因，甚至可能不允许查看所有现有的 column family)。

#### 时间戳

Bigtable 中的每个单元格可以包含相同数据的多个版本；这些版本按时间戳进行索引。
Bigtable 的时间戳是 64 位整型。
它们可以由 Bigtable 分配，在这种情况下，它们以微秒表示“实时”，也可以由客户端应用程序显式分配。
需要避免冲突的应用程序必须自己生成唯一的时间戳。
单元格的不同版本按时间戳降序存储，以便可以先读取最新版本。

为了使版本化数据的管理不那么繁重，我们支持每个 column family 有两个设置参数，触发 Bigtable 自动垃圾收集机制。
客户端可以指定只保留单元格的最后 n 个版本，或者只保留足够新的版本 (例如，只保留在过去7天内写入的值)。

在我们的 `Webtable` 示例中，我们将 contents 列中存储的已爬网页面的时间戳设置为实际爬网这些页面版本的时间。
上面描述的垃圾收集机制允许我们只保留每个页面的最新三个版本。

### 3 API

Bigtable API 提供了创建和删除表和 column family 的函数。
它还提供了更改集群、表和 column family 元数据的功能，例如访问控制权限。

```text
// Open the table
Table *T = OpenOrDie("/bigtable/web/webtable");

// Write a new anchor and delete an old anchor
RowMutation r1(T, "com.cnn.www");
r1.Set("anchor:www.c-span.org", "CNN");
r1.Delete("anchor:www.abc.com");
Operation op;
Apply(&op, &r1);
```

> 图 2：写入数据至 Bigtable

客户机应用程序可以在 Bigtable 中写入或删除值，从单个行中查找值，或者迭代表中的数据子集。
图 2 显示了使用 RowMutation 抽象来执行一系列更新的 C++ 代码。
(为了简短起见，不相关的细节被省略了。)
调用 Apply 函数对 `Webtable` 进行了一个原子修改操作：它为 www.cnn.com 增加了一个 anchor，同时删除了另外一个 anchor。

```text
Scanner scanner(T);
ScanStream *stream;
stream = scanner.FetchColumnFamily("anchor");
stream->SetReturnAllVersions();
scanner.Lookup("com.cnn.www");
for (; !stream->Done(); stream->Next()) {
    printf("%s %s %lld %s\n",
        scanner.RowName(),
        stream->ColumnName(),
        stream->MicroTimestamp(),
        stream->Value());
}
```

> 图 3：从 Bigtable 读取数据

图 3 为 C++ 代码，它使用扫描仪抽象来迭代特定行中的所有 anchor。
客户机可以迭代多个 column family，并且有几种机制限制扫描产生的行、列和时间戳。
例如，我们可以将上面的扫描限制为只生成列与正则表达式 anchor:*.cnn.com 匹配的 anchor，或者只生成时间戳在当前时间 10 天内的 anchor。

Bigtable 支持了一系列特性让用户可以对数据进行复杂的处理。
首先，Bigtable 支持单行的事务，这样一来就支持了对单个 row key 原子性的读取修改写入序列操作。
Bigtable 目前并不支持跨 row key 的事务，不过它提供了一个接口，用于在客户端进行批处理写操作。
其次，Bigtable 允许将单元格用作整数计数器。
最后，Bigtable 支持在服务器的地址空间中执行客户端提供的脚本。
这些脚本是用Google为处理数据而开发的一种语言 Sawzall 编写的 `[28]`。
目前，我们基于 Sawzall 的 API 不允许客户端脚本写回 Bigtable，但是它允许各种形式的数据转换、基于任意表达式的过滤以及通过各种操作符进行汇总。

Bigtable 可以和 MapReduce `[12]` 一起使用，MapReduce 是 Google 开发的大规模并行计算框架。
我们已经开发了一些 Wrapper 类，通过使用这些 Wrapper 类，Bigtable 可以作为 MapReduce 框架的输入和输出。

### 4 构件

Bigtable 是建立在其它的几个 Google 基础设施上的。
Bigtable 使用分布式的 Google File System (GFS) `[17]` 来存储日志和数据文件。
BigTable 集群通常运行在一个共享的机器池中，池中的机器还会运行其它的各种各样的分布式应用程序，BigTable 的进程经常要和其它应用的进程共享机器。
BigTable 依赖集群管理系统来调度任务、管理共享的机器上的资源、处理机器的故障、以及监视机器的状态。

BigTable 内部存储数据的文件是 GoogleSSTable 格式的。
SSTable 是一个持久化的、排序的、不可更改的 Map 结构，而 Map 是一个键/值映射的数据结构，键和值都是任意的 Byte 串。
操作用于查找与指定键关联的值，并在指定键范围内迭代所有键/值对。
在内部，每个 SSTable 包含一个块序列(通常每个块的大小为 64 KB，但这是可配置的)。
块索引(存储在SSTable的末尾)用于定位块；当 SSTable 打开时，索引被加载到内存中。

Bigtable 依赖于一个名为 Chubby `[8]` 的高可用性和持久性分布式锁服务。
Chubby 服务由五个活动副本组成，其中一个被选为主副本并主动服务请求。
当大多数副本都在运行并且可以相互通信时，该服务是实时的。
Chubby 使用 Paxos 算法 `[9，23]` 在失败时保持其副本的一致性。
Chubby 提供了一个由目录和小文件组成的命名空间。
每个目录或文件都可以用作锁，对文件的读写是原子的。
Chubby 客户端库提供了对 Chubby 文件的一致缓存。
每个 Chubby 客户机都维护一个与 Chubby 服务的会话。
如果客户端的会话在租约到期时间内无法续订，则会话将到期。
当客户端会话过期时，它将丢失所有锁和打开的句柄。
Chubby 客户端还可以注册对 Chubby 文件和目录的回调，以通知更改或会话过期。

Bigtable 使用 Chubby 执行以下任务：
确保在任何时候最多有一个活动的主控器；
存储 Bigtable 数据的引导位置(参见第 5.1 节)；
发现 Tablet 服务器并终止 Tablet 服务器(见第 5.2 节)；
存储 Bigtable 结构数据(每个表的 column family 信息)；
以及存储访问控制列表。

如果 Chubby 长时间不可用，Bigtable 将不可用。
我们最近在 14 个集群中测量了这种效应，这些集群跨越 11 个 Chubby 实例。
由于 Chubby 不可用而导致 BigTable 中的部分数据不能访问的平均比率是 0.0047% (Chubby 不能访问的原因可能是 Chubby 本身失效或者网络问题)。
单个集群受 Chubby 的不可用性影响最大的百分比为 0.0326%。

### 5 实现方式

Bigtable 由以下 3 个主要组件构成：链接到每个客户机的库，一个 Master 服务器和许多 Tablet 服务器。
Tablet 服务器可以从集群中动态添加(或删除)，以适应工作负载的变化。

Master 服务器负责将 Tablet 分发给 Tablet 服务器，并对 Tablet 服务器进行添加和过期，平衡负载并在 GFS 中对文件进行垃圾收集。
此外，它会还处理结构更改，例如创建表和 column family。

每个 Tablet 服务器管理一组 Tablet (通常一个服务器会管理 10-1000个 Tablet)。
Tablet 服务器处理对已加载的 Tablet 的读写请求，还可以拆分过大的 Tablet。

与许多单主机分布式存储系统一样 `[17，21]` ，客户机数据不会通过 Master 移动：客户机直接与 Tablet 服务器进行读写通信。
由于 Bigtable 客户端不依赖 Maser 获取 Tablet 服务器的位置信息，因此大多数客户端从不与 Master 通信。
因此，Master 在实即使用中是轻负载的。

一个 BigTable 集群存储了很多表，每个表包含了一个 Tablet 的集合，而每个 Tablet 包含了某个范围内的行的所有相关数据。
初始状态下，一个表只有一个 Tablet。
随着表中数据的增长，它被自动分割成多个 Tablet ，默认情况下，每个 Tablet 的尺寸大约是 100 MB到 200 MB。

#### 5.1 Tablet 存储路径

![图 4：Tablet 位置的层次体系](https://i.loli.net/2021/06/15/KNSQ9EsqkOPRMU8.png)

我们使用类似于 B+ `[10]` 树的三层结构来存储 Tablet 的位置信息(图 4)。

第一级是存储在 Chubby 中的文件，其中包含根 Tablet 的位置。
根 Tablet 在 `METADATA` 表中存储了所有 Tablet 的地址。
每个 `METADATA` 表中存储了用户的 Tablet 的地址。
根 Tablet 只是在 `METADATA` 表中的第一个 Tablet，
但是经过了特殊的处理，它永远不会被拆分，以确保 Tablet 的层次体系永远不超过三层。

`METADATA` 表将 Tablet 的位置存储在 row key 下，row key 是由 Tablet 所在的表的标识符和 Tablet 的最后一行编码而成的。
每个 `METADATA` 行在内存中大约需要 1 KB的空间。
每个 `METADATA` 表的限制大小一般为 128 MB，我们三层的层次体系足以支持 2^34 个 Tablet 的地址(或者说 261 bytes 在 128 MB 的 Tablet)。

链接到每个客户机的库中缓存了 Tablet 的位置。
如果客户端不知道 Tablet 的位置，或者发现缓存的位置信息不正确，则会递归地向上移动查找 Tablet 层次体系。
如果客户机的缓存是空的，那么定位算法需要三次网络请求，包括一次从 Chubby 读取。
如果客户机的缓存是过时的，那么定位算法可能需要多达六次请求，因为过时的缓存项只在未命中时才能被发现(假设 `METADATA` 表不经常移动)。
尽管 Tablet 的位置存储在内存中，因此不需要访问 GFS，但是我们通过让链接到客户机的库预取 Tablet 位置来进一步降低这种成本：
每当它读取 `METADATA` 表时，它都会读取多个 Tablet 的元数据。

在 `METADATA` 表中还存储了次级信息，包括每个 Tablet 的事件日志
(例如，什么时候一个服务器开始为该 Tablet 提供服务)。
这些信息有助于排查错误和性能分析。

#### 5.2 Tablet 分配

