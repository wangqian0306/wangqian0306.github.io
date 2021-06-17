---
title: Bigtable A Distributed Storage System for Structured Data 中文翻译版
date: 2021-06-10 22:26:13
tags:
- "论文"
- "Bigtable"
- "HBase"
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

每个 Tablet 一次只会分配给一个 Tablet 服务器。
Master 会追踪一系列活动的 Tablet 服务器，以及当前分配给这些服务器上的 Tablet，还有哪些 Tablet 未分配。
如果 Tablet 没有被分配，并且某个 Tablet 服务器有空间容纳此 Tablet，则 Master 会向 Tablet 服务器发送加载请求来分配此 Tablet。

Bigtable 使用 Chubby 来追踪 Tablet 服务器。
当 Tablet 服务器启动时，它会在特定的 Chubby 目录中创建一个唯一命名的文件，并获取该文件的独占锁。
Master 监视此目录（服务器目录）以发现 Tablet 服务器。
Tablet 服务器在获取不到锁的情况下会终止对 Tablet 提供服务，例如由于网络分区异常导致服务器失去 Chubby 连接。
(Chubby 提供了一种有效的机制，允许 Tablet 服务器检查它是否仍然持有锁，而不会增加网络负载。)
只要文件仍然存在，Tablet 服务器就会尝试重新获取其文件上的独占锁。
如果该文件不再存在，那么 Tablet 服务器将无法再次提供服务，因此它会自杀。
每当 Tablet 服务器终止时(例如，由于群集管理系统正在将 Tablet 服务器所在的计算机从群集中删除)，它都会尝试释放其锁，
以便 Master 更快地重新分配其 Tablet。

Master 会负责检测当 Tablet 服务器不在对 Tablet 提供服务时尽快重新分配 Tablet。
为了检测 Tablet 服务器何时不再为其 Tablet 提供服务，主机会定期向每个 Tablet 服务器询问其锁的状态。
如果 Tablet 服务器报告它失去了锁，或者如果 Master 在最近几次尝试中无法访问服务器，则 Master 将尝试获取服务器文件的独占锁。
如果 Master 能够获得锁，那么 Chubby 是活动的，Tablet 服务器要么已经死了，
要么无法访问 Chubby，因此 Master 通过删除其服务器文件来确保 Tablet 服务器不能再次服务。
一旦服务器的文件被删除，Master 可以将以前分配给该服务器的所有 Tablet 移动到未分配的 Tablet 集合中。
为了确保 Bigtable 集群不易受到 Master 和 Chubby 之间的网络问题的影响，
如果其 Chubby 会话过期，主机将自杀。所述，Master 故障不会更改 Tablet 到 Tablet
但是，如上所述，Master 故障不会更改 Tablet 到 Tablet 服务器的分配。

当群集管理系统启动 Master 时，它需要先发现当前的 Tablet 分配，然后才能更改它们。
Master 在启动时执行以下步骤。

1. Master 在 Chubby 中获取一个唯一的锁，这防止了并发的 Master 实例化。
2. Master 扫描 Chubby 中的服务器目录以找到活动服务器。
3. Master 与每个活动的 Tablet 服务器通信，获取目前 Tablet 的分配情况。
4. 主机扫描 `METADATA` 表获取所有 Tablet。
   当主机扫描到未分配的 Tablet 时 Master 会将其放在未分配集合中，从而使该 Tablet 符合分配条件。

一个复杂的问题是，在分配 `METADATA` 表之前，无法对其进行扫描。
因此，在开始此扫描(步骤 4)之前，如果在步骤 3 期间发现根 Tablet 未分配，则 Master 会将根 Tablet 添加到未分配的集合中。
这样就可以确保根 Tablet 的分配。
因为根 Tablet 包含`METADATA` 表中所有 Tablet 的名称，所以在扫描根 Tablet 后，Master 会知道所有 Tablet 的名称。

只有在创建或删除表、合并两个现有 Tablet 以形成一个较大的 Tablet 或将一个现有 Tablet 拆分为两个较小的 Tablet 时，现有 Tablet 集才会更改。
Master 能够跟踪这些更改，因为除了最后一个事件外的两个事件都是由它启动的。
由于 Tablet 拆分是由 Tablet 服务器启动的，因此需要特别处理。
Tablet 服务器通过在 `METADATA` 表中记录新 Tablet 的信息来提交拆分。
当拆分提交时，它会通知 Master。
如果拆分通知丢失(可能是因为 Tablet 服务器或 Master 死亡)，则 Master 会在请求 Tablet 服务器加载已拆分的 Tablet 时检测到新的 Tablet。
Tablet 服务器将通知 Master 拆分，因为它在 `METADATA` 表中找到的 Tablet 条目将只指定 Master 要求它加载的 Tablet 的一部分

#### 5.3 Tablet 服务

![图 5：Tablet 表现形式](https://i.loli.net/2021/06/16/tnEqh8rSyvX35sk.png)

Tablet 的持久化存储在 GFS 中，如图 5 所示。
更新操作提交到 REDO 日志中。
在这些更新中，最近提交的更新被存储在内存中一个称为 memtable 的排序缓冲区中;
旧的更新存储在一系列 SSTables 中。
要恢复 Tablet ， Tablet 服务器从 `METADATA` 表中读取其元数据。
此元数据包含 SSTables 的列表，SSTables 中包含一个 Tablet 和一组 REDO 点，
它们是指向可能包含 Tablet 数据的任何提交日志的指针。
服务器将 SSTables 的索引读入内存，并通过应用自 REDO 点以来提交的所有更新来重建 memtable。

当写入操作到达 Tablet 服务器时，服务器会检查其格式是否正确，以及发送方是否有权执行该操作。
授权是通过从一个 Chubby 文件(客户机几乎总是命中 Chubby 缓存中的文件)中读取允许写入程序的列表来执行的。
将有效的变更写入提交日志。
组提交操作用于提高许多小变更的吞吐量 `[13，16]`。
提交写操作后，其内容将插入 memtable。

当读取操作到达 Tablet 服务器时，同样会检查其格式是否良好以及授权是否正确。
有效的读取操作会对 SSTables 和 memtable 序列的合并视图进行检索。
由于 SSTables 和 memtable 是按字典顺序排序的数据结构，因此可以高效地形成合并视图。

当进行 Tablet 的合并和拆分时，正在进行的读写操作能够继续执行。

#### 5.4 压缩

当执行写操作时，memtable 的大小会增加。
当 memtable 大小达到阈值时，memtable 被冻结，创建一个新的 memtable，冻结的 memtable 被转换成 SSTable 并写入 GFS。
这个小型压缩过程有两个目标：它会收缩 Tablet 服务器的内存使用量，并且在恢复过程中，如果该服务器死机，它可以减少必须从提交日志中读取的数据量。
当压缩发生时，传入的读写操作可以继续执行。

每一次轻微的压缩都会创建一个新的 SSTable。
轻微的压缩过程不停滞的持续进行，则读取操作可能需要合并任意数量的 SSTable 中的更新。
恰恰相反的是，我们通过在后台定期执行合并压缩来限制这样的文件的数量。
合并压缩读取几个 SSTable 和 memtable 的内容，并写出一个新的 SSTable。
压缩完成后，可以立即丢弃输入的 SSTables 和 memtable。

将所有 SSTable 重写为一个 SSTable 的合并压缩称为主压缩。
由非主要压缩生成的 SSTable 可以包含特殊的删除条目，这些条目抑制仍然有效的旧 SSTable 中删除的数据。
另一方面，主压缩会生成一个不包含删除信息或删除数据的 SSTable。
Bigtable 在其所有的 Tablet 中循环使用，并定期对它们进行主压缩。
这些主压缩允许 Bigtable 回收已删除数据使用的资源，还允许 Bigtable 确保已删除的数据及时从系统中消失，这对于存储敏感数据的服务非常重要。

### 6 改进

上一节中描述的实现需要许多改进，以实现用户所需的高性能、可用性和可靠性。
本节更详细地描述了实现的各个部分，以突出这些改进。

#### 局部组

客户机可以将多个 column family 组合到一个局部组中。
将每个 Tablet 中的每个局部组生成一个单独的 SSTable。
将通常不能一起访问的 column family 分离到单独的局部组中可以实现更高效的读取。
例如，Webtable 中的页面元数据(如语言和校验和)可以位于一个局部组中，而页面的内容可以位于另一个组中：希望读取元数据的应用程序不需要读取所有页面内容。

此外，可以在每个局部组的基础上指定一些有效的调优参数。
例如，可以将局部组声明为在内存中。
内存中局部组的 SSTables 被延迟加载到 Tablet 服务器的内存中。
加载后，可以在不访问磁盘的情况下读取属于此类局部组的 column family。
此功能对于频繁访问的小块数据非常有用：我们在内部将其用于 `METADATA` 表中的存储地址 column family。

#### 数据压缩

客户可以控制是否压缩局部组的 SSTable 以及使用哪种压缩格式。
用户指定的压缩格式应用于每个 SSTable 块(其大小可通过特定于局部组的调优参数控制)。
虽然我们通过单独压缩每个块而损失了一些空间，但我们的优势在于，可以读取 SSTable 的一小部分，而无需解压整个文件。
许多客户使用双通道自定义压缩方案。
第一个过程使用 Bentley-McIlroy 算法 `[6]` ，它通过一个大窗口压缩长的公共字符串。
第二步使用快速压缩算法，在一个小的 16 KB 的数据窗口中寻找重复数据。
这两种压缩过程都非常快，它们在现代机器上的编码速度为 100–200 MB/s，解码速度为 400–1000 MB/s。

尽管我们在选择压缩算法时强调的是速度而不是空间缩减，但这种两遍压缩方案的性能却出人意料地好。
例如，在 Webtable 中，我们使用这种压缩方案来存储网页内容。
在一次实验中，我们将大量文档存储在一个压缩的局部组中。
为了实验的目的，我们将每个文档的版本限制为一个，而不是存储所有可用的版本。
该方案实现了 10 比 1 的空间缩减。
这比 HTML 页面上典型的 Gzip 减少 3 比 1 或 4 比 1 要好得多，因为 Webtable 行的布局方式是：来自单个主机的所有页面都彼此靠近地存储。
这使得 Bentley-McIlroy 算法能够识别来自同一主机的页面中的大量共享样板文件。
许多应用程序(不仅仅是 Webtable)选择合适的 row 名称，这样类似的数据最终会聚集在一起，从而获得非常好的压缩比。
当我们在 Bigtable 中存储相同值的多个版本时，压缩比会更好。

#### 缓存以提高读取性能

Tablet 服务器采用了两级缓存的方式来提高读取性能。
扫描缓存是第一级缓存，主要缓存 Tablet 服务器通过 SSTable 接口获取的键值对。
块缓存是第二级缓存，用于缓存从 GFS 读取的 SSTables 块。
扫描缓存对于倾向于重复读取相同数据的应用程序最为有用。
块缓存对于倾向于读取与其最近读取的数据接近的数据的应用程序非常有用(例如，连续读取，或对热点行中同一位置组中不同列的随机读取)。

#### 布隆过滤器

如第 5.3 节所述，读取操作必须从构成 Tablet 状态的所有 SSTable 中读取。
如果这些 SSTable 不在内存中，我们可能会进行许多次磁盘访问。
我们允许客户机指定应该为特定位置组中的 SSTable 创建布隆过滤器 `[7]` ，从而减少访问次数。
布隆过滤器允许我们询问 SSTable 是否包含指定行/列对的任何数据。
对于某些特定应用程序，我们只付出了少量的、用于存储布隆过滤器的内存的代价，就换来了读操作显著减少的磁盘访问的次数。
我们对布隆过滤器的使用还意味着对不存在的行或列的大多数查找不需要接触磁盘。

#### 提交日志的实现

如果我们将每个 Tablet 的提交日志保存在一个单独的日志文件中，那么在 GFS 中会同时写入大量的文件。
根据每个 GFS 服务器上的底层文件系统实现，这些写入操作可能会导致大量磁盘查找写入不同的物理日志文件。
此外，每个 Tablet 有单独的日志文件也会降低组提交优化的效率，因为组往往会更小。
为了解决这些问题，我们将变更附加到每个 Tablet 服务器的单个提交日志中，将不同 Tablet 的变更混合在同一个物理日志文件中 `[18，20]`。

使用一个日志文件可以在正常操作期间提供显著的性能优势，但会使恢复复杂化。
当 Tablet 服务器死机时，它所服务的 Tablet 将被移动到大量其他 Tablet 服务器上：
每台服务器通常装载少量原始服务器的 Tablet。
要恢复 Tablet 的状态，新的 Tablet 服务器需要从原始 Tablet 服务器编写的提交日志中重新应用该 Tablet 的变更。
然而，这些 Tablet 的变更被混合在同一个物理日志文件中。
一种方法是让每个新的 Tablet 服务器读取这个完整的提交日志文件，并只应用它需要恢复的 Tablet 所需的条目。
然而，在这样一种方案下，如果 100 台机器从一台发生故障的 Tablet 服务器上分别分配一个 Tablet，那么日志文件将被读取100次(每台服务器读取一次)。

我们首先按关键字(table、行名称、日志序列号)的顺序对提交日志条目进行排序，以避免重复日志读取。
在排序的输出中，特定 Tablet 的所有变更都是连续的，因此可以通过一次磁盘寻道和一次顺序读来有效地读取。
为了并行排序，我们将日志文件划分为 64MB 的段，并在不同的 Tablet 服务器上对每个段进行并行排序。
此排序过程由 Master 协调，并在 Tablet 服务器指示需要从某个提交日志文件中恢复变更时启动。

将提交日志写入 GFS 有时会由于各种原因导致性能波动
(例如，参与写入的 GFS 服务器崩溃，或为到达特定的一组三个 GFS 服务器而遍历的网络路径遇到网络拥塞，或负载过重)。
为了防止 GFS 延迟峰值的巨变，每个 Tablet 服务器实际上有两个日志写入线程，每个线程都写入自己的日志文件；并且在任何时刻，只有一个线程是工作的。
如果对活动日志文件的写入执行得不好，则将切换到另一个线程，并且提交日志队列中的变更将由新的线程写入。
日志条目包含序列号，以允许恢复过程删除此日志切换过程产生的重复条目。

#### 加速 Tablet 的恢复

如果 Master 将 Tablet 从一个 Tablet 服务器移动到另一个服务器，则源 Tablet 服务器首先对该 Tablet 进行轻微的压缩。
这种压缩通过减少 Tablet 服务器提交日志中未压缩状态的数量来减少恢复时间。
完成此压缩后，Tablet 服务器将停止为对应 Tablet 提供服务。
在实际卸载 Tablet 之前，Tablet 服务器会执行另一次(通常非常快)轻微的压缩，以消除在执行第一次轻微的压缩时到达的 Tablet 服务器日志中任何剩余的未压缩状态。
完成第二次轻微的压缩后，可以将 Tablet 加载到另一台 Tablet 服务器上，而无需恢复任何日志条目。

#### 利用不变性

除了 SSTable 缓存之外，Bigtable 系统的其他各个部分也被简化了，因为我们生成的所有 SSTable 都是不可变的。
例如，在读取 SSTables 时，我们不需要对文件系统的访问进行任何同步。
因此，可以非常有效地实现对行的并发控制。
读写都可以访问的唯一可变数据结构是 memtable。
为了减少 memtable 读取过程中的争用，我们在写入时复制每个 memtable 行，并允许读写并行进行。

由于 SSTables 是不可变的，永久删除已删除数据的问题就转化为 SSTables 的垃圾回收问题。、
每个 Tablet 的 SSTables 都注册在 `METADATA` 表中。

最后，SSTables 的不变性使我们能够快速拆分 Tablet。
我们让子 Tablet 共享父 Tablet 的 SSTable，而不是为每个子 Tablet 生成一组新的 SSTable。

### 7 性能评估

我们建立了一个包含 N 台 Tablet 服务器的 Bigtable 集群来衡量它的性能和可扩展性。
Tablet 服务器配置为使用 1 GB 内存，并写入一个 GFS 单元，该单元由 1786 台机器组成，每台机器有两个 400 GB IDE 硬盘。
N 台客户端计算机生成了用于这些测试的 Bigtable 负载。
(我们使用与 Tablet 服务器相同数量的客户端，以确保客户端不会成为瓶颈。)
每台机器有两个双核 Opteron 2 GHz 芯片，足够的物理内存来容纳所有运行进程的工作集，还有一个千兆以太网链路。
这些机器被安排在一个两级树形交换网络中，根节点的总带宽约为 100-200 gbps。
所有的机器都在同一个托管设施中，因此任何一对机器之间的往返时间都不到一毫秒。

Tablet 服务器和 Master、测试客户端以及 GFS 服务器都在同一组机器上运行。
每台机器都运行一个 GFS 服务器。
其它的机器要么运行 Tablet 服务器、要么运行客户程序、要么运行在测试过程中，使用这组机器的其它的任务启动的进程。
R 是在测试中所涉及的 Bigtable row key 的不同数目。
我们精心选择 R 的值，保证每次基准测试对每台 Tablet 服务器读/写的数据量都在 1 GB 左右。

在序列写的基准测试中，我们使用的 row key 的范围是 0 到 R-1。 这个 row key 被划分成 10 N 个大小相等的范围。
这些范围由一个中央调度器分配给N个客户机，该调度器在客户机处理完分配给它的上一个范围后，立即将下一个可用范围分配给该客户机。 这种动态分配有助于减轻客户机上运行的其他进程引起的性能变化的影响。 我们在每一 row key 下写了一个字符串。
每个字符串都是随机生成的，因此不可压缩。 随机写基准与此类似，只是在写之前立即对 row key 进行模 R 的散列，以便在基准的整个持续时间内，写负载大致均匀地分布在整个行空间中。

顺序读取的性能基准和顺序写入的基准采用完全相同的方式生成 row key，但它不在 row key 下写入， 而是读取存储在 row key 下的字符串(该字符串是通过先前调用顺序写入基准编写的)。
同样的，随机读的基准测试和随机写是类似的。

扫描的基准与顺序读取基准类似，但使用 Bigtable API 提供的支持来扫描行范围中的所有值。 单个 RPC 从 Tablet 服务器获取大量的值序列，因此可以减少由基准执行的 RPC 的数量。

随机读取(内存)基准与随机读取基准类似，但是包含基准数据的位置组被标记为内存中，因此从 Tablet 服务器的内存中就可以完成读取，而不需要读取 GFS。 对于这个基准测试，我们将每个 Tablet 服务器的数据量从 1 GB 减少到
100 MB，这样就可以轻松地放入 Tablet 服务器可用的内存中。

![图 6：每秒读取/写入 1000 字节的个数。下表显示了每台 Tablet 服务器的速率；该图显示了聚合速率。](https://i.loli.net/2021/06/16/6XsqchxAJHfKDu1.png)

图 6 显示了在 Bigtable 中读写 1000 字节值时我们的基准性能的两个图表。 在表格中显示了每个 Tablet 服务器每秒的操作数；在图中显示了每秒的操作总数。

#### 单个 Tablet 服务器的性能

让我们首先考虑一下只有一台 Tablet 服务器的性能。 随机读取比所有其他操作慢一个数量级或更多。 每次随机读取都涉及通过网络将 64 KB 的 SSTable 块从 GFS 传输到 Tablet 服务器，其中仅使用单个 1000
字节的值。 Tablet 服务器每秒执行大约 1200 次读取，也就是说读取 GFS 的速度大约为 75MB/s。 由于我们的网络堆栈、SSTable 解析和 Bigtable 代码中的开销，这样会使 Tablet 服务器 CPU 满载，
并且几乎满载我们系统中的网络链接。 大多数具有这种访问模式的 Bigtable 应用程序将块大小减小到较小的值，通常为 8 KB。

从内存中随机读取的速度要快得多，因为从 Tablet 服务器的本地内存中读取的每 1000 字节内容都能得到满足，而无需从 GFS 中获取一个 64 kb 的快。

随机写入和顺序写入的性能优于随机读取，因为每个 Tablet 服务器都将所有传入的写入附加到单个提交日志中，并使用组提交将这些写入高效地流式传输到 GFS。 随机写入和顺序写入的性能没有显著差异；在这两种情况下，对 Tablet
服务器的所有写入都记录在同一个提交日志中。

顺序读取的性能比随机读取好，因为从 GFS 获取的每个 64 KB SSTable 块都存储在块缓存中来服务接下来的 64 个读取请求。

扫描速度更快，因为 Tablet 服务器可以返回大量值来响应单个客户端，因此 RPC 的开销会分摊到大量值上。

#### 扩展性

当我们将系统中的 Tablet 服务器数量从 1 增加到 500 时，聚合吞吐量会急剧增加，增加了超过 100 倍，随着 Tablet 服务器数量增加 500 倍， 内存随机读取的性能几乎增加了 300 倍。

但是，性能并不是线性增长的。 对于大多数基准测试，从 1 台 Tablet 服务器增加到 50 台 Tablet 服务器时，每台服务器的吞吐量会显著下降。 这种下降是由多个服务器配置中的负载不平衡引起的，通常是由于其他进程争夺 CPU
和网络。 我们的负载平衡算法试图处理这种不平衡，但由于以下两个主要原因而无法完成完美的工作： 一个是尽量减少 Tablet 的移动导致重新负载均衡能力受限(如果 Tablet 被移动了，那么通常是 1 秒内，这个 Tablet
是暂时不可用的)， 另一个是我们的基准测试程序产生的负载会有波动。

随机读取基准测试显示了最糟糕的伸缩性(服务器数量增加 500 倍时，聚合吞吐量只增加了 100 倍)。 发生这种行为的原因是(如上所述)每读取 1000 字节，我们就在网络上传输一个 64 KB 的大数据块。 这种传输使我们网络中的共享的
1 GB 链路满载，因此，随着机器数量的增加，每服务器的吞吐量显著下降。

### 8 真实应用

|Tablet 服务器数量|集群数量|
|:---:|:---:|
|     0 .. 19|259|
|    20 .. 49|47|
|    50 .. 99|20|
|   100 .. 499|50|
| > 500             |12|

> 表 1：Bigtable 集群中 Tablet 服务器数量的分布。

截止到 2006 年 8 月，Google 内部一共有 388 个非测试用的 Bigtable 集群运行在各种各样的服务器集群上，合计大约有 24500 个 Tablet 服务器。 表 1 显示了每个集群上 Tablet
服务器的大致分布情况。 这些集群中，许多用于开发目的，因此会有一段时期比较空闲。 通过观察一个由 14 个集群、8069 个 Tablet 服务器组成的群组，我们看到整体的吞吐量超过了每秒 1200000 次请求， 发送到系统的 RP
C请求导致的网络负载达到了 741 MB/s，系统发出的 RPC 请求网络负载大约是 16 GB/s。

|项目名|表的大小(TB)|压缩比例|元素个数|column family 个数|局域组个数|存储于内存|对延迟敏感|
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
|Crawl|800|11%|1000|16|8|0%|否|
|Crawl|50|33%|200|2|2|0%|否|
|Google Analytics|20|29%|10|1|1|0%|是|
|Google Analytics|200|14%|80|1|1|0%|是|
|Google Base|2|31%|10|29|3|15%|是|
|Google Earth|0.5|64%|8|7|2|33%|是|
|Google Earth|70|-|9|8|3|0%|否|
|Orkut|9|-|0.9|8|5|1%|是|
|Personalized Search|4|47%|6|93|11|5%|是|

> 表 2：生产使用中几个表的特点。表的大小(压缩前测量)，元素个数取近似值，对于禁止压缩的表不提供压缩比例。

表 2 提供了一些目前正在使用的表的相关数据。 一些表存储的是用户相关的数据，另外一些存储的则是用于批处理的数据；这些表在总的大小、每个数据项的平均大小、从内存中读取的数据的比例、表的结构的复杂程度上都有很大的差别。
本节的其余部分，我们将主要描述三个产品研发团队如何使用 Bigtable 的。

#### 8.1 Google Analytics

Google Analytics 是用来帮助 Web 站点的管理员分析他们网站的流量模式的服务。 它提供了整体状况的统计数据，比如每天的独立访问的用户数量、每天每个 URL
的浏览次数；它还提供了用户使用网站的行为报告，比如根据用户之前访问的某些页面，统计出几成的用户购买了商品。

为了使用这个服务，Web 站点的管理员只需要在他们的 Web 页面中嵌入一小段 JavaScript 脚本就可以了。 这个 Javascript 程序在页面被访问的时候调用。 它记录了各种 Google Analytics
需要使用的信息，比如用户的标识、获取的网页的相关信息。 Google Analytics 汇总这些数据，之后提供给 Web 站点的管理员。

我们粗略的描述一下 Google Analytics 使用的两个表。 Row Click 表(大约有 200 TB 数据)的每一行存放了一个最终用户的会话。 行的名字是一个包含 Web 站点名字以及用户会话创建时间的元组。
这种模式保证了对同一个 Web 站点的访问会话是顺序的，会话按时间顺序存储。 这个表可以压缩到原来尺寸的 14%。

Summary 表(大约有 20 TB 的数据)包含了关于每个 Web 站点的、各种类型的预定义汇总信息。 一个周期性运行的 MapReduce 任务根据 Raw Click 表的数据生成 Summary 表的数据。 每个
MapReduce 工作进程都从 Raw Click 表中提取最新的会话数据。 系统的整体吞吐量受限于 GFS 的吞吐量。 这个表的能够压缩到原有尺寸的 29%。

#### 8.2 Google Earth

Google 通过一组服务为用户提供了高分辨率的地球表面卫星图像，访问的方式可以使通过基于 Web 的 Google Maps 访问接口(maps.google.com)， 也可以通过 Google Earth 定制的客户端软件访问。
这些软件产品允许用户浏览地球表面的图像：用户可以在不同的分辨率下平移、查看和注释这些卫星图像。 这个系统使用一个表存储预处理数据，使用另外一组表存储用户数据。

数据预处理流水线使用一个表存储原始图像。 在预处理过程中，图像被清除，图像数据合并到最终的服务数据中。 这个表包含了大约 70 TB 的数据，所以需要从磁盘读取数据。 图像已经被高效压缩过了，因此存储在 Bigtable 后不需要再压缩了。

Imagery 表的每一行都代表了一个单独的地理区域。 行都有名称，以确保毗邻的区域存储在了一起。 Imagery 表中有一个 column family 用来记录每个区域的数据源。 这个 column family
包含了大量的列：基本上市每个列对应一个原始图片的数据。 由于每个地理区域都是由很少的几张图片构成的，因此这个 column family 是非常稀疏的。

数据预处理流水线高度依赖运行在 Bigtable 上的 MapReduce 任务传输数据。 在运行某些 MapReduce 任务的时候，整个系统中每台 Tablet 服务器的数据处理速度是 1 MB/s。

这个服务系统使用一个表来索引 GFS 中的数据。 这个表相对较小(大约是 500 GB)，但是这个表必须在保证较低的响应延时的前提下，针对每个数据中心，每秒处理几万个查询请求。 因此，这个表必须在上百个 Tablet
服务器上存储数据，并且将 column family 存储在内存中。

#### 个性化查询

个性化查询(www.google.com/psearch)是一个双向服务；这个服务记录用户的查询和点击，涉及到各种 Google 的服务，比如 Web 查询、图像和新闻。
用户可以浏览他们查询的历史，重复他们之前的查询和点击；用户也可以定制基于 Google 历史使用习惯模式的个性化查询结果。

个性化查询使用 Bigtable 存储每个用户的数据。 每个用户都有一个唯一的用户 ID，每个用户 ID 和一个列名绑定。 一个单独的 column family 被用来存储各种类型的行为(比如，有个 column family
可能是用来存储所有的 Web 查询的)。 每个数据项都被用作 Bigtable 的时间戳，记录了相应的用户行为发生的时间。 个性化查询使用以 Bigtable 为存储的 MapReduce 任务生成用户的数据图表。
这些用户数据图表用来个性化当前的查询结果。

个性化查询的数据会复制到几个 Bigtable 的集群上，这样就增强了数据可用性，同时减少了由客户端和 Bigtable 集群间的“距离”造成的延时。 个性化查询的开发团队最初建立了一个基于 Bigtabl
e的、“客户侧”的复制机制为所有的复制节点提供一致性保障。 现在的系统则使用了内建的复制子系统。

个性化查询存储系统的设计允许其它的团队在它们自己的列中加入新的用户数据， 因此，很多 Google 服务使用个性化查询存储系统保存用户级的配置参数和设置。 在多个团队之间分享数据的结果是产生了大量的 column family。
为了更好的支持数据共享，我们加入了一个简单的配额机制限制用户在共享表中使用的空间； 配额也为使用个性化查询系统存储用户级信息的产品团体提供了隔离机制。

### 9 经验教训

在设计、实现、维护和支持 Bigtable 的过程中，我们获得了一些有用的经验，并吸取了一些有趣的教训。

我们学到的一个教训是，大型分布式系统易受多种故障的影响，而不仅仅是标准网络分区故障还有许多分布式协议中假定的 fail-stop 类型故障。
比如，我们遇到过下面这些类型的错误导致的问题：内存数据损坏、网络中断、时钟偏差、机器挂起、扩展的和非对称的网络分区、 我们正在使用的其他系统中的错误(例如Chubby)、GFS 配额溢出以及计划内和计划外的硬件维护。
随着我们在这些问题上积累了更多的经验，我们通过改变各种协议来解决这些问题。 例如，我们在 RPC 机制中添加了校验和。 我们在设计系统的部分功能时，不对其它部分功能做任何的假设，这样的做法解决了其它的一些问题。 例如，我们不再假设给定的
Chubby 操作只能返回一组固定错误中的一个。

我们学到的另一个教训是，在清楚如何使用新特性之前，推迟添加新特性是很重要的。 例如，我们最初计划在 API 中支持通用事务。 因为我们没有立即使用它们所以没有实现。 现在我们有许多实际的应用程序在 Bigtable
上运行，我们已经能够检查它们的实际需求，并且发现大多数应用程序只需要单行事务。 当人们请求分布式事务时，最重要的用途是维护二级索引，我们计划添加一个专门的机制来满足这一需求。 与分布式事务相比，新机制的通用性较差，但效率更高(
特别是对于跨越数百行或更多行的更新)，而且非常符合我们的“跨数据中心”复制方案的优化策略。

我们从支持 Bigtable 中学到的一个实际教训是正确的系统级监视的重要性(即，监视 Bigtable 本身以及使用 Bigtable 的客户机进程)。 例如，我们扩展了 RPC 系统，以便对于 RPC 的一个示例，它保留代表该 RPC
执行的重要操作的详细跟踪。 这个特性允许我们检测和修复许多问题，比如 Tablet 数据结构上的锁争用、提交 Bigtable 变更时对 GFS 的写入速度慢， 以及 `METADATA` Tablet 不可用时对 `METADATA`
表的访问受阻。 另一个有用的监视示例是，每个 Bigtable 集群都在 Chubby 中注册。 这允许我们跟踪所有集群，发现它们有多大，查看它们运行的软件版本，它们接收的流量，以及是否存在诸如意外的大延迟之类的问题。

我们学到的最重要的一课是简单设计的价值。 考虑到我们系统的大小(大约十万行非测试代码)，以及代码以意想不到的方式随时间演化的事实，我们发现代码和设计的清晰性对代码维护和调试有巨大的帮助。 一个例子是我们的 Tablet 服务器成员协议。
我们的第一个协议很简单：Master 定期向 Tablet 服务器发出租约，如果租约到期，Tablet 服务器就会自杀。 不幸的是，该协议在出现网络问题时显著降低了可用性，并且对 Master 恢复时间也很敏感。
我们重新设计了好几次协议，直到我们有了一个性能良好的协议。 然而，产生的协议过于复杂，并且依赖一些 Chubby 很少被用到的特性。 我们发现我们浪费了大量的时间在调试一些古怪的问题，有些是 Bigtable 代码的问题，有些是
Chubby 代码的问题。 最终，我们放弃了这个协议，转而使用一个新的更简单的协议，它完全依赖于广泛使用的 Chubby 特性。

### 10 相关工作

Boxwood 项目 `[24]` 的组件在某些方面与 Chubby、GFS 和 Bigtable 重叠，因为它提供了分布式协议、锁定、分布式块存储和分布式 B-tree 存储。 在每一个有重叠的情况下，似乎 Boxwood
的组件的目标级别都比相应的 Google 服务更底层。 Boxwood 项目的目标是为构建更高级别的服务(如文件系统或数据库)提供基础设施，而 Bigtable 的目标是直接支持希望存储数据的客户端应用程序。

最近的许多项目都解决了在广域网上提供分布式存储或更高级别服务的问题，通常是在“互联网规模”上。 这其中包括了分布式的哈希表，这项工作由一些类似 CAN `[29]` 、Chord `[32]` 、Tapestry `[37]` 和
Pastry `[30]` 的项目率先发起。 些系统的主要关注点和 Bigtable 不同，比如应对各种不同的传输带宽、不可信的协作者、频繁的更改配置等； 另外，去中心化和 Byzantine 灾难冗余也不是 Bigtable 的目的。

> 注：Byzantine 灾难冗余(一个决策算法可以容忍多少百分比的骗子，然后仍然能够正确确定共识?)

就可能提供给应用程序开发人员的分布式数据存储模型而言，我们认为由分布式 B 树或分布式哈希表提供的密钥-值对模型有很大的局限性。 键值对是一个有用的组件，但它们不应该是提供给开发人员的唯一组件。
我们选择的模型比简单的键值对更丰富，并且支持稀疏的半结构化数据。 尽管如此，它仍然非常简单，可以非常高效地表示平面文件，并且它足够透明(通过局域组)，允许用户调整系统的重要行为。

一些数据库供应商已经开发了能够存储大量数据的并行数据库。 Oracle 的 Real Application Cluster 数据库 `[27]` 使用共享磁盘存储数据(Bigtable 使用 GFS)和分布式锁管理器(Bigtable
使用 Chubby)。 IBM 的 DB2 并行版 `[4]` 基于类似于 Bigtable 的无共享 `[33]` 体系结构。 每个 DB2 服务器负责一个表中的行的子集，该表存储在本地关系数据库中。
这两种产品都提供了一个完整的事务关系模型。

Bigtable 局域组提供了类似于基于列的存储方案在压缩和磁盘读取方面具有的性能；这些以列而不是行的方式组织数据的方案包括 C-Store `[1,34]`
和商业产品如 Sybase IQ `[15,36]`、SenSage `[31]`、KDB+ `[22]` 以及 MonetDB/X100 中的 ColumnBM存储层 `[38]`。
另一个将垂直和水平数据分割成平面文件并获得良好数据压缩比的系统是 AT&T 的 Daytona 数据库 `[19]` 。 局域组不支持CPU缓存级别的优化，如 Ailamaki `[2]` 所描述的优化。

Bigtable使用 memtables 和 SSTables 存储 Tablet 更新的方式类似于日志结构的合并树 `[26]` 存储索引数据更新的方式。
在这两种系统中，排序后的数据在写入磁盘之前都会缓冲在内存中，读取时必须合并内存和磁盘中的数据。

C-Store 和 Bigtable 有很多相似点：两个系统都采用 Shared-nothing 架构，都有两种不同的数据结构， 一种用于当前的写操作，另外一种存放“长时间使用”的数据， 并且提供一种机制在两个存储结构间搬运数据。
两个系统在 API 接口函数上有很大的不同：C-Store 操作更像关系型数据库，而 Bigtable 提供了低层次的读写操作接口， 并且设计的目标是能够支持每台服务器每秒数千次操作。 C-Store
同时也是个“读性能优化的关系型数据库”，而 Bigtable 对读和写密集型应用都提供了很好的性能。

Bigtable 的负载均衡器必须解决一些与 shared-nothing 数据库相同的负载和内存平衡问题(例如，`[11，35]`)。 我们的问题稍微简单一点：

1. 我们不考虑同一数据的多个副本的可能性(可能由于视图或索引的原因而以其他形式存在)
2. 我们让用户告诉我们哪些数据属于内存，哪些数据应该留在磁盘上，而不是试图动态地确定这一点
3. 我们没有要执行或优化的复杂查询

### 11 结论

我们已经描述了 Bigtable，一个在 Google 存储结构化数据的分布式系统。 Bigtable 集群自 2005 年 4 月开始投入生产使用，在此之前，我们花了大约 7个人/年的时间来进行设计和实现。 截至 2006 年 8
月，超过 60 个项目正在使用 Bigtable。 我们的用户喜欢 Bigtable 实现提供的性能和高可用性，他们可以通过简单地向系统中添加更多的机器来扩展集群的容量， 因为随着时间的推移，他们的资源需求会发生变化。

考虑到 Bigtable 的不同寻常的接口，一个有趣的问题是我们的用户适应它有多困难。 新用户有时不确定如何最好地使用 Bigtable 接口，特别是当他们习惯于使用支持通用事务的关系数据库时。 尽管如此，许多 Google 产品成功地使用
Bigtable 的事实表明，我们的设计在实践中运行良好。

我们正在实施几个额外的 Bigtable 功能，例如支持辅助索引和基础设施，以及支持多 Master 节点的、跨数据中心复制的 Bigtable 的基础组件。 我们还开始将 Bigtable
作为服务部署到产品组中，这样各个组就不需要维护自己的集群。 随着服务集群的扩展，我们需要在 Bigtable 本身中处理更多的资源共享问题 `[3,5]`。

最后，我们发现在 Google 构建我们自己的存储解决方案有很大的优势。 我们从为 Bigtable 设计自己的数据模型中获得了很大的灵活性。 此外，我们对 Bigtable 实现的控制，以及 Bigtable 所依赖的其他 Google
基础设施，意味着我们可以在瓶颈和低效出现时消除它们。

### 致谢

We thank the anonymous reviewers, David Nagle, and our shepherd Brad Calder, for their feedback on this paper. The
Bigtable system has benefited greatly from the feedback of our many users within Google. In addition, we thank the
following people for their contributions to Bigtable: Dan Aguayo, Sameer Ajmani, Zhifeng Chen, Bill Coughran, Mike
Epstein, Healfdene Goguen, Robert Griesemer, Jeremy Hylton, Josh Hyman, Alex Khesin, Joanna Kulik, Alberto Lerner,
Sherry Listgarten, Mike Maloney, Eduardo Pinheiro, Kathy Polizzi, Frank Yellin, and Arthur Zwiegincew.

### 参考资料

[1] ABADI, D. J., MADDEN, S. R., AND FERREIRA, M. C. Integrating compression and execution in columnoriented database
systems. Proc. of SIGMOD (2006).

[2] AILAMAKI, A., DEWITT, D. J., HILL, M. D., AND SKOUNAKIS, M. Weaving relations for cache performance. In The VLDB
Journal (2001), pp. 169–180.

[3] BANGA, G., DRUSCHEL, P., AND MOGUL, J. C. Resource containers:
A new facility for resource management in server systems. In Proc. of the 3rd OSDI (Feb. 1999), pp. 45–58.

[4] BARU, C. K., FECTEAU, G., GOYAL, A., HSIAO, H., JHINGRAN, A., PADMANABHAN, S., COPELAND,G. P., AND WILSON, W. G. DB2
parallel edition. IBM Systems Journal 34, 2 (1995), 292–322

[5] BAVIER, A., BOWMAN, M., CHUN, B., CULLER, D., KARLIN, S., PETERSON, L., ROSCOE, T., SPALINK, T., AND WAWRZONIAK, M.
Operating system support for planetary-scale network services. In Proc. of the 1st NSDI(Mar. 2004), pp. 253–266.

[6] BENTLEY, J. L., AND MCILROY, M. D. Data compression using long common strings. In Data Compression Conference (1999)
, pp. 287–295.

[7] BLOOM, B. H. Space/time trade-offs in hash coding with allowable errors. CACM 13, 7 (1970), 422–426.

[8] BURROWS, M. The Chubby lock service for looselycoupled distributed systems. In Proc. of the 7th OSDI(Nov. 2006).

[9] CHANDRA, T., GRIESEMER, R., AND REDSTONE, J. Paxos made live — An engineering perspective. In Proc. of PODC (2007).

[10] COMER, D. Ubiquitous B-tree. Computing Surveys 11, 2
(June 1979), 121–137.

[11] COPELAND, G. P., ALEXANDER, W., BOUGHTER, E. E., AND KELLER, T. W. Data placement in Bubba. In Proc. of SIGMOD (
1988), pp. 99–108.

[12] DEAN, J., AND GHEMAWAT, S. MapReduce: Simplified data processing on large clusters. In Proc. of the 6th OSDI(Dec.
2004), pp. 137–150.

[13] DEWITT, D., KATZ, R., OLKEN, F., SHAPIRO, L., STONEBRAKER, M., AND WOOD, D. Implementation techniques for main
memory database systems. In Proc. of SIGMOD (June 1984), pp. 1–8.

[14] DEWITT, D. J., AND GRAY, J. Parallel database systems: The future of high performance database systems. CACM 35,
6 (June 1992), 85–98.

[15] FRENCH, C. D. One size fits all database architectures do not work for DSS. In Proc. of SIGMOD (May 1995), pp.
449–450.

[16] GAWLICK, D., AND KINKADE, D. Varieties of concurrency control in IMS/VS fast path. Database Engineering Bulletin 8,
2 (1985), 3–10.

[17] GHEMAWAT, S., GOBIOFF, H., AND LEUNG, S.-T. The Google file system. In Proc. of the 19th ACM SOSP (Dec. 2003), pp.
29–43.

[18] GRAY, J. Notes on database operating systems. In Operating Systems — An Advanced Course, vol. 60 of Lecture Notes
in Computer Science. Springer-Verlag, 1978.

[19] GREER, R. Daytona and the fourth-generation language Cymbal. In Proc. of SIGMOD (1999), pp. 525–526.

[20] HAGMANN, R. Reimplementing the Cedar file system using logging and group commit. In Proc. of the 11th SOSP (Dec.
1987), pp. 155–162.

[21] HARTMAN, J. H., AND OUSTERHOUT, J. K. The Zebra striped network file system. In Proc. of the 14th SOSP
(Asheville, NC, 1993), pp. 29–43.

[22] KX.COM. kx.com/products/database.php. Product page.

[23] LAMPORT, L. The part-time parliament. ACM TOCS 16, 2 (1998), 133–169.

[24] MACCORMICK, J., MURPHY, N., NAJORK, M., THEKKATH, C. A., AND ZHOU, L. Boxwood:
Abstractions as the foundation for storage infrastructure. In Proc. of the 6th OSDI (Dec. 2004), pp. 105–120.

[25] MCCARTHY, J. Recursive functions of symbolic expressions and their computation by machine. CACM 3, 4 (Apr. 1960),
184–195.

[26] O’NEIL, P., CHENG, E., GAWLICK, D., AND O’NEIL, E. The log-structured merge-tree (LSM-tree). Acta Inf. 33, 4 (1996)
, 351–385.

[27] ORACLE.COM. www.oracle.com/technology/products/-database/clustering/index.html. Product page.

[28] PIKE, R., DORWARD, S., GRIESEMER, R., AND QUINLAN, S. Interpreting the data: Parallel analysis with Sawzall.
Scientific Programming Journal 13, 4 (2005), 227–298.

[29] RATNASAMY, S., FRANCIS, P., HANDLEY, M., KARP, R., AND SHENKER, S. A scalable content-addressable network. In Proc.
of SIGCOMM (Aug. 2001), pp. 161–172.

[30] ROWSTRON, A., AND DRUSCHEL, P. Pastry:
Scalable, distributed object location and routing for largescale peer-to-peer systems. In Proc. of Middleware 2001 (Nov.
2001), pp. 329–350.

[31] SENSAGE.COM. sensage.com/products-sensage.htm. Product page.

[32] STOICA, I., MORRIS, R., KARGER, D., KAASHOEK, M. F., AND BALAKRISHNAN, H. Chord: A scalable peer-to-peer lookup
service for Internet applications. In Proc. of SIGCOMM (Aug. 2001), pp. 149–160.

[33] STONEBRAKER, M. The case for shared nothing. Database Engineering Bulletin 9, 1 (Mar. 1986), 4–9.

[34] STONEBRAKER, M., ABADI, D. J., BATKIN, A., CHEN, X., CHERNIACK, M., FERREIRA, M., LAU, E., LIN, A., MADDEN, S.,
O’NEIL, E., O’NEIL, P., RASIN, A., TRAN, N., AND ZDONIK, S. C-Store:
A columnoriented DBMS. In Proc. of VLDB (Aug. 2005), pp. 553–564.

[35] STONEBRAKER, M., AOKI, P. M., DEVINE, R., LITWIN, W., AND OLSON, M. A. Mariposa: A new architecture for distributed
data. In Proc. of the Tenth ICDE
(1994), IEEE Computer Society, pp. 54–65.

[36] SYBASE.COM. www.sybase.com/products/databaseservers/sybaseiq. Product page.

[37] ZHAO, B. Y., KUBIATOWICZ, J., AND JOSEPH, A. D. Tapestry: An infrastructure for fault-tolerant wide-area location
and routing. Tech. Rep. UCB/CSD-01-1141, CS Division, UC Berkeley, Apr. 2001.

[38] ZUKOWSKI, M., BONCZ, P. A., NES, N., AND HEMAN, S. MonetDB/X100 — A DBMS in the CPU cache. IEEE Data Eng. Bull. 28,
2 (2005), 17–22.