---
title: 大数据平台常见文件格式 date: 2021-07-16 22:26:13 tags:

- "Parquet"
- "Avro"
  id: filetype no_word_count: true no_toc: false categories: 大数据

---

## 大数据平台常见文件格式

### 简介

在大数据平台中除了日常使用的 `CSV`, `JSON`, `XML` 等格式外，还有一些经常使用的文件类型，例如：

- Parquet
- Avro
- RCFile
- ORC File
- SequenceFile
- ......

下面我们针对每种类型的数据格式进行简单说明。

### Parquet

[项目官网](https://github.com/apache/parquet-format)

Parquet 是一种支持嵌套数据的列式存储格式。元数据使用 Apache Thrift 进行编码，如果想要理解这部分内容需要参照 Thrift 相关文档。

Parquet 使用了 Google 的 `Dremel: Interactive Analysis of Web-Scale Datasets` 论文中的记录的拆散和组装算法(record shredding and assembly
algorithm)。

> 注：[论文原文](https://storage.googleapis.com/pub-tools-public-publication-data/pdf/36632.pdf)

Parquet 将文件分割成了 N 列，然后将每一列分成 M 和行组。 使用文件元数据记录所有列元数据的起始未知。 读取段可以先查找元数据来定位想要读取的列块，然后顺序读取内容。

> 注：Parquet 是由 Cloudera 和 Twitter 研发的。

### Avro

Apache Avro 是一个数据序列化系统。

Avro 提供：

- 丰富的数据结构。
- 一种紧凑、快速的二进制数据格式。
- 一个容器文件，用于存储持久数据。
- 远程过程调用 (RPC)。
- 与动态语言的简单集成。代码生成不需要读取或写入数据文件，也不需要使用或实现 RPC 协议。代码生成作为一种可选的优化，只值得为静态类型语言实现。

Avro 文件带有结构。 读取 Avro 数据时，写入时配置的结构将始终存在。 这种方式使得应用可以不花费额外的开销写入数据，从而使快速高效完成序列化。 同样也便于使用动态脚本语言，因为数据及其结构已经事先规定好了。 当 Avro
数据存储在文件中时，它的结构也随之存储，以便任何程序稍后可以处理文件。 如果读取程序需要不同的数据结构(类型)，这样的问题也很容易解决，我们可以让数据可以支持用户定义的类型。 在 RPC 中使用 Avro
时，客户端和服务器在连接握手中改变结构。
(此处内容可以优化，在大多数情况下，没有实际的类型经过了传输。)
由于客户端和服务器都具有对方的完整结构，因此可以轻松解决相同命名字段之间的对应关系、缺失字段、额外字段等问题. Avro 的数据结构是用 JSON 定义的。

> 注：Avro 是由 Hortonworks 和 Facebook 研发的。

### RCFile 和 ORC File (Hive)

#### RCFile

RCFile(Record Columnar File)是一种数据结构，它决定了如何在计算机集群上存储关系表。 它是为使用 MapReduce 框架的系统设计的。 RCFile 结构包括数据存储格式、数据压缩方法和数据读取优化技术。
它能够满足数据放置的四个要求：

1. 数据加载速度快
2. 查询处理速度快
3. 存储空间利用率高
4. 对动态数据访问模式的适应性强。

#### ORC Files

ORC(Optimized Row Columnar) File 提供了一种高效存储 Hive 数据的文件格式。 这种文件格式的设计初衷是打破现有 Hive 数据文件的相关限制。 使得在读取，写入和处理数据时能提供更高的效率。

与原始的 RCFile 格式相比，ORC 有很多的优点：

- 单个文件作为每个任务的输出，减少了 NameNode 的负载
- Hive 类型支持，包括日期时间、十进制和复杂类型（结构、列表、映射和联合）
- 存储在文件中的轻量级索引
    - 跳过未通过谓词过滤的行组
    - 寻找给定的行
- 基于数据类型的块模式压缩
    - 整数列的运行长度编码
    - 字符串列的字典编码
- 使用单独的 RecordReaders 并发读取同一文件
- 无需扫描标记即可拆分文件的能力
- 限制读取或写入所需的内存量
- 使用协议缓冲区存储的元数据，允许添加和删除字段

ORC 文件包含称为条带的行数据组，以及文件页脚中的辅助信息。在文件末尾，附言包含压缩参数和压缩页脚的大小。 默认条带大小为 250 MB。大条带大小支持从 HDFS 进行大而高效的读取。
文件页脚包含文件中的条带列表、每个条带的行数以及每列的数据类型。它还包含列级聚合计数、最小值、最大值和总和。

### SequenceFile (MapReduce)

SequenceFile 是一个由二进制键/值对组成的平面文件。 它在 MapReduce 中广泛用作输入/输出格式。 还值得注意的是，在内部，Map 操作的临时输出是使用 SequenceFile 进行存储的。 该
SequenceFile 提供了一个写入者，读取者和分拣机类来分别实现写入，读取和排序。

共有 3 种不同的 SequenceFile 格式：

1. 未压缩的键/值记录
2. 记录压缩的键/值记录——这里只压缩“值”
3. 块压缩键/值记录 - 键和值都分别收集在“块”中并进行压缩。
