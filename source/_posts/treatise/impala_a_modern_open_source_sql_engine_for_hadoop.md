---
title: "Impala: A Modern, Open-Source SQL Engine for Hadoop 中文翻译"
date: 2022-01-12 22:26:13
tags:
- "论文"
- "Impala"
id: impala_a_modern_open_source_sql_engine_for_hadoop
no_word_count: true
no_toc: false
categories: 大数据
---

## Impala: A Modern, Open-Source SQL Engine for Hadoop

作者：Marcel Kornacker, Alexander Behm, Victor Bittorf, Taras Bobrovytsky, Casey Ching, Alan Choi, Justin Erickson, Martin Grund, Daniel Hecht, Matthew Jacobs, Ishaan Joshi, Lenni Kuff, Dileep Kumar, Alex Leblang, Nong Li, Ippokratis Pandis, Henry Robinson, David Rorke, Silvius Rus, John Russell, Dimitris Tsirogiannis, Skye Wanderman-Milne, Michael Yoder

### 版权说明

```text
This article is published under a Creative Commons Attribution License(http://creativecommons.org/licenses/by/3.0/), which permits distribution and reproduction in any medium as well as allowing derivative works, provided that you attribute the original work to the author(s) and CIDR 2015. 7th Biennial Conference on Innovative Data Systems Research (CIDR’15) January 4-7, 2015, Asilomar, California, USA
```

### 简介

Cloudera Impala 是一个现代的、开源的 MPP SQL 引擎，专为 Hadoop 数据处理环境而设计。
Impala 为 Hadoop 上的 BI/分析以读取为主的查询提供低延迟和高并发，而不是由 Apache Hive 等批处理框架提供。
本文从用户的角度介绍 Impala，概述其架构和主要组件，并简要展示其与其他流行的 SQL-on-Hadoop 系统相比的卓越性能。

### 1 引言

Impala 是一个开源的、完全集成的、先进的 MPP SQL 查询引擎，专为利用 Hadoop 的灵活性和可扩展性而设计。
Impala 的目标是将熟悉的 SQL 支持和传统分析数据库的多用户性能与 Apache Hadoop 的可扩展性和灵活性以及 Cloudera Enterprise 的生产级安全和管理扩展相结合。
Impala 的 beta 版本于 2012 年 10 月发布，并于 2013 年 5 月 GA 发布。最新版本 Impala 2.0 于 2014 年 10 月发布。Impala 的生态系统势头继续加速，自 GA 以来下载量接近 100 万次。

与其他系统(通常是 Postgres 的分支)不同，Impala 是一个全新的引擎，使用 C++ 和 Java 从头开始编写。
它通过使用标准组件(HDFS、HBase、Metastore、YARN、Sentry)来保持 Hadoop 的灵活性，并且能够读取大多数广泛使用的文件格式(例如 Parquet、Avro、RCFile)。
为了减少延迟，例如使用 MapReduce 或远程读取数据所产生的延迟，Impala 实现了一个基于守护进程的分布式架构，这些进程负责查询执行的所有方面，并且与 Hadoop 基础架构的其余部分在同一台机器上运行。
结果是性能相当或超过商业 MPP 分析 DBMS，具体取决于特定的工作负载。

本文讨论 Impala 为用户提供的服务，然后概述其架构和主要组件。
当今可实现的最高性能需要使用 HDFS 作为底层存储管理器，因此这是本文的重点；当某些技术方面如何与 HBase 一起处理方面存在显着差异时，我们会在文本中说明而不会深入细节。

Impala 是性能最高的 SQL-on-Hadoop 系统，尤其是在多用户工作负载下。
如第 7 节所示，对于单用户查询，Impala 比替代方案快 13 倍，平均快 6.7 倍。 对于多用户查询，差距越来越大：Impala 比替代方案快 27.4 倍，平均快 18 倍——多用户查询的平均速度是单用户查询的近三倍。

本文的其余部分结构如下：下一节从用户的角度对 Impala 进行概述，并指出它与传统 RDBMS 的不同之处。
第 3 节介绍了系统的整体架构。第 4 节介绍了前端组件，其中包括基于成本的分布式查询优化器，第 5 节介绍了负责查询执行并使用运行时代码生成的后端组件，第 6 节介绍了资源/工作负载管理组件。
7 节简要评估了 Impala 的性能。第 8 节讨论了未来的路线图，第 9 节得出结论。

### 2 IMPALA 的用户视图

Impala 是一个集成到 Hadoop 环境中的查询引擎，它利用许多标准 Hadoop 组件(Metastore、HDFS、HBase、YARN、Sentry)来提供类似 RDBMS 的体验。 但是，本节的其余部分将提出一些重要的区别。

Impala 专门针对与标准商业智能环境的集成，并为此支持大多数相关的行业标准：客户端可以通过 ODBC 或 JDBC 进行连接；使用 Kerberos 或 LDAP 完成身份验证；授权遵循标准的 SQL 角色和权限。
为了查询 HDFS 驻留的数据，用户通过熟悉的 CREATE TABLE 语句创建表，该语句除了提供数据的逻辑模式外，还指示物理布局，例如文件格式和在 HDFS 目录结构。 然后可以使用标准 SQL 语法查询这些表。

#### 2.1 物理结构设计

创建表时，用户还可以指定一些分区列：

```text
CREATE TABLE T (...) PARTITIONED BY (day int, month int) LOCATION ’<hdfs-path>’ STORED AS PARQUET;
```

对于未分区的表，数据文件默认直接存储在根目录中<3>。对于分区表，数据文件放置在其路径反映分区列值的子目录中。
例如，对于表 T 的第 2 个月第 17 天，所有数据文件都将位于目录 `<root>/day=17/month=2/` 中。
请注意，这种形式的分区并不意味着单个分区的数据的搭配：一个分区的数据文件块随机分布在 HDFS 数据节点上。

> 注 3：但是，位于根目录下的任何目录中的所有数据文件都是表数据集的一部分。这是处理未分区表的常用方法，Apache Hive 也采用了这种方法。

在选择文件格式时，Impala 还为用户提供了很大的灵活性。
它目前支持压缩和未压缩的文本文件、序列文件(文本文件的可拆分形式)、RCFile(传统的列格式)、Avro(二进制行格式)和 Parquet，这是最高性能的存储选项(第 5.3 节会更详细的要论文件类型)。
如上例，用户在 `CREATE TABLE` 或 `ALTER TABLE` 语句中指明存储格式。也可以为每个分区单独选择单独的格式。
例如，可以使用以下命令专门将特定分区的文件格式设置为 Parquet：`ALTER TABLE PARTITION(day=17, month=2) SET FILEFORMAT PARQUET`。

作为一个有用的例子，考虑一个按时间顺序记录数据的表，例如点击日志。当天的数据可能以 CSV 文件的形式出现，并在每天结束时批量转换为 Parquet。

#### 2.2 SQL 支持

Impala 支持大多数 SQL-92 SELECT 语句语法，以及附加的 SQL-2003 分析函数，以及大多数标准标量数据类型：整型和浮点型、STRING、CHAR、VARCHAR、TIMESTAMP 和精度高达 38 位的 DECIMAL。
自定义应用程序逻辑可以通过 Java 和 C++ 中的用户定义函数 (UDF) 以及当前仅在 C++ 中的用户定义聚合函数 (UDA) 进行合并。

由于 HDFS 作为存储管理器的限制，Impala 不支持 UPDATE 或 DELETE，本质上只支持批量插入(INSERT INTO ... SELECT ...) <4>。
与传统 RDBMS 不同，用户只需使用 HDFS 的 API 将数据文件复制/移动到该表的目录位置，即可将数据添加到表中。 或者，同样可以使用 `LOAD DATA` 语句来完成。

> 注 4：我们还应该注意 Impala 支持 VALUES 子句。但是，对于 HDFS 支持的表，这将在每个 INSERT 语句生成一个文件，这会导致大多数应用程序的性能非常差。对于 HBase 支持的表，VALUES 变体通过 HBase API 执行单行插入。

与批量插入类似，Impala 通过删除表分区(ALTER TABLE DROP PARTITION)支持批量数据删除。因为不可能就地更新 HDFS 文件，所以 Impala 不支持 UPDATE 语句。
相反，用户通常会重新计算部分数据集以合并更新，然后替换相应的数据文件，通常是通过删除和重新添加分区。

在初始数据加载之后，或者每当表的大部分数据发生变化时，用户应该运行 `COMPUTE STATS <table>` 语句，该语句指示 Impala 收集表的统计信息。这些统计信息随后将在查询优化期间使用。

### 3 架构

![image.png](https://s2.loli.net/2022/01/13/jJmE7fdDGSbruZt.png)

Impala 是一个大规模并行查询执行引擎，它运行在现有 Hadoop 集群中的数百台机器上。
它与底层存储引擎分离，与传统的关系数据库管理系统不同，后者的查询处理和底层存储引擎是单个紧密耦合系统的组件。Impala 的高级架构如图 1 所示。

Impala 部署由三个服务组成。Impala 守护进程 (impalad) 服务双重负责接受来自客户端进程的查询并协调它们在集群中的执行，以及代表其他 Impala 守护进程执行单个查询片段。
当 Impala 守护进程通过管理查询执行以第一个角色运行时，它被称为该查询的协调者。然而，所有 Impala 守护进程都是对称的；他们可能都扮演所有角色。此属性有助于容错和负载平衡。

一个 Impala 守护进程部署在集群中的每台机器上，这些机器也运行一个 datanode 进程——底层 HDFS 部署的块服务器——因此每台机器上通常都有一个 Impala 守护进程。
这使 Impala 可以利用数据局部性，并从文件系统中读取块，而无需使用网络。

Statestore 守护进程(statestored)是 Impala 的元数据发布订阅服务，它将集群范围的元数据传播到所有 Impala 进程。
有一个单独的 statestored 实例，在下面的 3.1 节中有更详细的描述。

最后，3.2 节中描述的目录守护进程（catalogd）用作 Impala 的目录存储库和元数据访问网关。
通过 catalogd，Impala 守护程序可以执行反映在外部目录存储（例如 Hive Metastore）中的 DDL 命令。对系统目录的更改通过 statestore 广播。

所有这些 Impala 服务以及几个配置选项，例如资源池的大小、可用内存等。
(有关资源和工作负载管理的更多详细信息，请参阅第 6 节)也暴露给 Cloudera Manager，这是一个复杂的 集群管理应用。
Cloudera Manager 不仅可以管理 Impala，还可以管理几乎所有服务，以全面了解 Hadoop 部署。

#### 3.1 状态分发

旨在在数百个节点上运行的 MPP 数据库设计中的一个主要挑战是集群范围元数据的协调和同步。
Impala 的对称节点架构要求所有节点都必须能够接受和执行查询。因此，所有节点都必须拥有最新版本的系统目录和 Impala 集群成员的最新视图，以便可以正确安排查询。

我们可以通过部署一个单独的集群管理服务来解决这个问题，其中包含所有集群范围元数据的真实版本。
Impala 守护进程可以延迟查询这个存储(即仅在需要时)，这将确保所有查询都得到最新的响应。
然而，Impala 设计的一个基本原则是在任何查询的关键路径上尽可能避免同步 RPC。
在没有密切关注这些成本的情况下，我们发现查询延迟通常会因建立 TCP 连接或加载某些远程服务所花费的时间而受到影响。
相反，我们将 Impala 设计为向所有相关方推送更新，并设计了一个名为 statestore 的简单发布-订阅服务来将元数据更改传播给一组订阅者。

statestore 维护一组主题，它们是(键、值、版本)三元组的数组，称为条目，其中“键”和“值”是字节数组，“版本”是 64 位整数。
主题由应用程序定义，因此 statestore 不了解任何主题条目的内容。主题在 statestore 的整个生命周期中都是持久的，但不会在服务重新启动时持久。
希望接收任何主题更新的进程称为订阅者，并通过在启动时向 statestore 注册并提供主题列表来表达他们的兴趣。
statestore 通过向订阅者发送每个已注册主题的初始主题更新来响应注册，其中包含当前在该主题中的所有条目。

注册后，statestore 会定期向每个订阅者发送两种消息。第一种消息是主题更新，包括自上次更新成功发送给订阅者以来对主题的所有更改(新条目、修改的条目和删除)。
每个订阅者都维护一个每个主题的最新版本标识符，它允许 statestore 仅在更新之间发送增量。作为对主题更新的响应，每个订阅者都会发送一份希望对其订阅主题进行更改的列表。
保证在收到下一次更新时已应用这些更改。

第二种 statestore 消息是 keepalive。statestore 使用 keepalive 消息来维护与每个订阅者的连接，否则订阅会超时并尝试重新注册。
以前版本的 statestore 将主题更新消息用于这两个目的，但随着主题更新规模的增长，很难确保及时向每个订阅者传递更新，从而导致订阅者的故障检测过程中出现误报。

如果 statestore 检测到失败的订阅者(例如，通过重复失败的 keepalive 交付)，它将停止发送更新。
一些主题条目可能被标记为“临时”，这意味着如果他们的“拥有”订阅者失败，他们将被删除。
这是一个自然的原语，用于在专用主题中维护集群的活跃度信息，以及每个节点的负载统计信息。

statestore 提供了非常弱的语义：订阅者可能以不同的速率更新(尽管 statestore 尝试公平地分发主题更新)，因此可能对主题内容有非常不同的看法。
但是，Impala 仅使用主题元数据在本地做出决策，而无需跨集群进行任何协调。
例如，查询计划是基于目录元数据主题在单个节点上执行的，一旦计算出完整的计划，执行该计划所需的所有信息都会直接分发给执行节点。
执行节点不需要知道目录元数据主题的相同版本。

尽管现有 Impala 部署中只有一个 statestore 进程，但我们发现它可以很好地扩展到中型集群，并且通过一些配置，可以服务于我们最大的部署。
statestore 不会将任何元数据保存到磁盘：所有当前元数据都由实时订阅者推送到 statestore(例如加载信息)。
因此，如果 statestore 重新启动，它的状态可以在初始订阅者注册阶段恢复。
或者，如果运行 statestore 的机器发生故障，则可以在其他地方启动新的 statestore 进程，并且订阅者可能会故障转移到它。
Impala 中没有内置的故障转移机制，而是部署通常使用可重定向的 DNS 条目来强制订阅者自动移动到新的流程实例。

#### 3.2 目录服务

Impala 的目录服务通过 statestore 广播机制为 Impala 守护进程提供目录元数据，并代表 Impala 守护进程执行 DDL 操作。
目录服务从第三方元数据存储(例如，Hive Metastore 或 HDFS Namenode)中提取信息，并将该信息聚合到 Impala 兼容的目录结构中。
这种架构允许 Impala 对其所依赖的存储引擎的元数据存储相对不可知，这允许我们相对快速地将新的元数据存储添加到 Impala(例如 HBase 支持)。
对系统目录的任何更改(例如，当加载新表时)都会通过 statestore 传播。

目录服务还允许我们使用特定于 Impala 的信息来扩充系统目录。
例如，我们仅向目录服务注册用户定义的函数(例如，不将其复制到 Hive Metastore)，因为它们特定于 Impala。

由于目录通常非常大，而且对表的访问很少是统一的，因此目录服务只会为它在启动时发现的每个表加载一个框架条目。
更详细的表元数据可以从其第三方商店在后台延迟加载。如果在完全加载之前需要一个表，Impala 守护程序将检测到这一点并向目录服务发出优先级请求。此请求会阻塞，直到表完全加载。

### 4 前端

Impala 前端负责将 SQL 文本编译成 Impala 后端可执行的查询计划。它是用 Java 编写的，由功能齐全的 SQL 解析器和基于成本的查询优化器组成，所有这些都是从头开始实现的。
除了基本的 SQL 功能(select、project、join、group by、order by、limit)之外，Impala 还支持内联视图、不相关和相关子查询(被重写为连接)、外连接的所有变体以及显式左/右 半链接和反连接，以及分析窗口函数。

查询编译过程遵循传统的分工：查询解析、语义分析和查询规划/优化。我们将专注于查询编译中最具挑战性的后者部分。
Impala 查询计划器作为输入提供一个解析树以及在语义分析期间组装的查询全局信息(表/列标识符、等价类等)。
可执行查询计划的构建分为两个阶段：（1）单节点计划和（2）计划并行化和分片。    

第一阶段，解析树被翻译成一个不可执行的单节点计划树，由以下计划节点组成：HDFS/HBase scan、hash join、cross join、union、hash aggregation、sort、top-n、分析评估。
此步骤负责在可能的最低损耗的节点分配谓词、基于等价类推断谓词、修剪表分区、设置限制/偏移量、应用列投影，以及执行一些基于成本的计划优化，例如排序和合并分析 窗口函数和连接重新排序以最小化总评估成本。
成本估算基于表/分区基数加上每列的不同值计数<6>；直方图目前不是统计数据的一部分。Impala 使用简单的启发式方法来避免在常见情况下详尽地枚举和计算整个连接顺序空间。

> 注 6：我们使用 HyperLogLog 算法 `[5]` 进行不同的估值。

第二阶段将单节点计划作为输入，并产生一个分布式执行计划。总体目标是最小化数据移动并最大化扫描局部性：在 HDFS 中，远程读取比本地读取慢得多。
通过根据需要在计划节点之间添加交换节点，并通过添加额外的非交换计划节点来最小化跨网络的数据移动(例如，本地聚合节点)，从而使计划成为分布式的。
在第二阶段，我们决定每个连接节点的连接策略(此时连接顺序是固定的)。支持的连接策略是广播和分区的。
前者将连接的整个构建端复制到所有执行探测的集群机器上，后者在连接表达式上重新分配构建端和探测端。
Impala 选择估计的任何策略以最小化通过网络交换的数据量，同时利用连接输入的现有数据分区。

所有聚合当前都作为本地预聚合执行，然后合并聚合操作。对于分组聚合，预聚合输出在分组表达式上进行分区，合并聚合在所有参与节点上并行完成。
对于非分组聚合，合并聚合在单个节点上完成。sort 和 top-n 以类似的方式并行化：分布式本地排序/top-n 之后是单节点合并操作。
分析表达式评估是基于 partition-by 表达式并行化的。它依赖于根据 partition-by/order-by 表达式对输入进行排序。
最后，分布式计划树在交换边界处被拆分。计划的每个这样的部分都放置在计划片段中，即 Impala 的后端执行单元。
计划片段封装了计划树的一部分，该部分在单台机器上的相同数据分区上运行。

![图 2：两阶段的查询优化示例](https://s2.loli.net/2022/01/13/4YhXSzxfjBdJ5F9.png)

图 2 举例说明了查询计划的两个阶段。该图的左侧显示了一个查询的单节点计划，该查询连接了两个 HDFS 表(t1，t2)和一个 HBase 表(t3)，然后是一个聚合和 `order by with limit(top-n)`。
右侧显示了分散的、分散的计划。圆角矩形表示片段边界和箭头数据交换。表 t1 和 t2 通过分区策略连接。
扫描位于它们自己的片段中，因为它们的结果会立即交换给消费者(连接节点)，消费者(连接节点)在基于散列的数据分区上运行，而表数据是随机分区的。
以下与 t3 的连接是广播连接，与 t1 和 t2 之间的连接放置在同一片段中，因为广播连接保留了现有的数据分区(连接 t1、t2 和 t3 的结果仍然是基于连接键的哈希分区 t1 和 t2)。
在连接之后，我们执行两阶段分布式聚合，其中预聚合在与最后一个连接相同的片段中计算。预聚合结果基于分组键进行哈希交换，然后再次聚合以计算最终聚合结果。
相同的两阶段方法应用于 top-n，最后的 top-n 步骤在协调器处执行，协调器将结果返回给用户。

