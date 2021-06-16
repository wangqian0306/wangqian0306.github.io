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

在序列写的基准测试中，我们使用的 row key 的范围是 0 到 R-1。
这个 row key 被划分成 10 N 个大小相等的范围。
这些范围由一个中央调度器分配给N个客户机，该调度器在客户机处理完分配给它的上一个范围后，立即将下一个可用范围分配给该客户机。
这种动态分配有助于减轻客户机上运行的其他进程引起的性能变化的影响。
我们在每一 row key 下写了一个字符串。
每个字符串都是随机生成的，因此不可压缩。
随机写基准与此类似，只是在写之前立即对 row key 进行模 R 的散列，以便在基准的整个持续时间内，写负载大致均匀地分布在整个行空间中。



![图 6：每秒读取/写入 1000 字节的个数。下表显示了每台 Tablet 服务器的速率；该图显示了聚合速率。](https://i.loli.net/2021/06/16/6XsqchxAJHfKDu1.png)


