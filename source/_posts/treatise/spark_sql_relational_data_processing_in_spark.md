---
title: Spark SQL - Relational Data Processing in Spark 中文翻译
date: 2021-06-29 22:26:13
tags:
- "论文"
- "Spark"
id: spark_sql_relational_data_processing_in_spark
no_word_count: true
no_toc: false
categories: 大数据
---

## Spark SQL: Relational Data Processing in Spark

作者：

Michael Armbrust, Reynold S. Xin , Cheng Lian, Yin Huai, Davies Liu, Joseph K. Bradley, Xiangrui Meng,
Tomer Kaftan, Michael J. Franklin, Ali Ghodsi, Matei Zaharia

### 版权说明

```text
Permission to make digital or hard copies of all or part of this work for personal or
classroom use is granted without fee provided that copies are not made or distributed
for profit or commercial advantage and that copies bear this notice and the full cita-
tion on the first page. Copyrights for components of this work owned by others than
ACM must be honored. Abstracting with credit is permitted. To copy otherwise, or re-
publish, to post on servers or to redistribute to lists, requires prior specific permission
and/or a fee. Request permissions from permissions@acm.org.
SIGMOD’15, May 31–June 4, 2015, Melbourne, Victoria, Australia.
Copyright is held by the owner/author(s). Publication rights licensed to ACM.
ACM 978-1-4503-2758-9/15/05 ...$15.00.
http://dx.doi.org/10.1145/2723372.2742797.
```

### 概要

Spark SQL 是 Apache Spark 中的一个新模块，它将关系处理与 Spark 的函数式编程 API 集成在一起。
基于我们使用 Shark 的经验，Spark SQL 使 Spark 程序员可以利用关系处理的优势(例如，声明式查询和优化存储)，
并且可以让 SQL 用户调用 Spark 中的完整分析库(例如，机器学习)。
与以前的系统相比，Spark SQL 增加了两个主要内容。
首先，它通过与过程 Spark 代码集成的声明性 DataFrame API，在关系处理和过程处理之间提供了更紧密的集成。
其次，它包括一个高度可扩展的优化器 Catalyst，它使用 Scala 编程语言的特性构建，可以轻松添加可组合规则、控制代码生成和定义扩展点。
使用 Catalyst，我们构建了各种功能(例如，JSON 的模式推断、机器学习类型和外部数据库的查询联合)，以满足现代数据分析的复杂需求。
我们将 Spark SQL 视为 SQL-on-Spark 和 Spark 本身的演变，提供更丰富的 API 和优化，同时保留 Spark 编程模型的优势。

### 类别和主题描述符

`H.2 [Database Management]: Systems`

### 关键词

数据库；数据仓库；机器学习；Spark；Hadoop

### 1 引言

大数据应用程序需要多种处理技术、数据源和存储格式。
最早为这些工作负载设计的系统，例如 MapReduce，为用户提供了强大但低级的程序编程接口。
对此类系统进行编程是一项繁重的工作，需要用户手动优化以实现高性能。
因此，多个新系统试图通过提供大数据的关系型接口来提供更高效的用户体验。
Pig、Hive、Dremel 和 Shark `[29, 36, 25, 38`]` 等系统都利用声明式查询来提供更丰富的自动优化。

虽然关系系统的流行表明用户通常更喜欢编写声明式查询，但关系方法对于许多大数据应用程序来说是不够的。
首先，用户希望在可能是半结构化或非结构化的各种数据源之间执行 ETL，这种需求得编写具体的代码。
其次，用户希望执行在关系系统中难以表达的高级分析，例如机器学习和图形处理。
在实践中，我们观察到大多数数据管道都可以理想地通过关系查询和复杂程序算法的组合来表达。
不幸的是，这两类系统——关系型系统和程序型系统——到目前为止仍然在很大程度上是不相交的，迫使用户选择一种范式或另一种范式。

本文描述了我们在 Spark SQL 中结合这两种模型的努力，Spark SQL 是 Apache Spark `[39]` 中的一个主要新组件。
Spark SQL 建立在我们早期的 SQL-on-Spark 成果之上，称为 Shark。
然而，Spark SQL 并没有强迫用户在关系型 API 或过程型 API 之间做出选择，而是让用户无缝地混合两者。

Spark SQL 通过两个贡献消除了两种模型之间的差距。
首先，Spark SQL 提供了一个 DataFrame API，可以对外部数据源和 Spark 内置的分布式集合执行关系操作。
此 API 类似于 R `[32]` 中广泛使用的数据框概念，但会延迟评估操作，以便执行关系优化。
其次，为了支持大数据中广泛的数据源和算法，Spark SQL 引入了一种名为 Catalyst 的新型可扩展优化器。
Catalyst 可以轻松为机器学习等领域添加数据源、优化规则和数据类型。

DataFrame API 提供了与 Spark 程序中的丰富的关系/过程方式集成。
DataFrames 是结构化记录的集合，可以使用 Spark 的过程 API 或使用允许更丰富优化的新关系 API 进行操作。
它们可以直接从 Spark 的内置分布式 Java/Python 对象集合中创建，从而在现有 Spark 程序中启用关系处理。
其他 Spark 组件，例如机器学习库，也会获取和生成 DataFrame。
在许多常见情况下，DataFrames 比 Spark 的过程式 API 更方便、更高效。
例如，它们使使用 SQL 语句在一次传递中计算多个聚合变得容易，这在传统的函数式 API 中很难表达。
它们还自动以比 Java/Python 对象更紧凑的列格式存储数据。
最后，与 R 和 Python 中现有的 DataFrame API 不同，Spark SQL 中的 DataFrame 操作通过关系优化器 Catalyst。

为了在 Spark SQL 中支持各种数据源和分析工作负载，我们设计了一个名为 Catalyst 的可扩展查询优化器。
Catalyst 使用 Scala 编程语言的特性(例如模式匹配)来表现图灵完备语言中可组合的规则。
它提供了一个用于转换树的通用框架，我们用它来执行分析、规划和运行时代码生成。
通过这个框架，Catalyst 还可以扩展新的数据源，包括半结构化数据，如 JSON 和可以推送过滤器的“智能”数据存储(例如 HBase)；
具有用户定义的功能；以及用于机器学习等领域的用户定义类型。
众所周知，函数式语言非常适合构建编译器 `[37]`，因此它们使构建可扩展优化器变得容易也就不足为奇了。
我们确实发现 Catalyst 可以有效地使我们能够快速向 Spark SQL 添加功能，并且自其发布以来，我们已经看到外部贡献者也可以轻松添加它们。

> 注：如果一个函数的值可以通过某种纯机械的过程找到，那么这个函数就可以有效地计算出来。
> 这样的函数叫图灵可计算函数。
> 如果一个计算系统可以计算每一个图灵可计算函数，那么这个系统就是图灵完备的。
> 具有图灵完备性的计算机语言，就被称为图灵完备语言。

Spark SQL 于 2014 年 5 月发布，现在是 Spark 中开发最活跃的组件之一。
在撰写本文时，Apache Spark 是最活跃的大数据处理开源项目，过去一年有超过 400 名贡献者。
Spark SQL 已经部署在非常大规模的环境中。
例如，一家大型互联网公司使用 Spark SQL 构建数据管道，并在 8000 节点的集群上运行超过 100 PB 数据的查询。
每个单独的查询通常要计算数十 TB 的内容。
此外，许多用户不仅将 Spark SQL 用于 SQL 查询，还用于将其与过程处理相结合的程序。
例如，托管服务 Databricks Cloud 的客户中有 2/3 运行 Spark，在其他编程语言中使用 Spark SQL。
在性能方面，我们发现 Spark SQL 与 Hadoop 上的 SQL-only 系统在关系查询方面具有竞争力。
在用 SQL 表达的计算中，它比简单的 Spark 代码快 10 倍，内存效率更高。

通常，我们将 Spark SQL 视为核心，它是 Spark API 的重要演变。
虽然 Spark 最初的函数式编程 API 非常通用，但它仅提供了有限的自动优化机会。
Spark SQL 同时使更多用户可以访问 Spark，并优化现有用户的体验。
在 Spark 中，社区现在正在将 Spark SQL 合并到更多 API 中：DataFrames 是用于机器学习的新“ML 管道” API 中的标准数据表示，
我们希望将其扩展到其他组件，例如 GraphX 和 Spark Streaming 。

我们从 Spark 的背景和 Spark SQL 的目标(第 2 章)开始这篇论文。
然后我们会描述 DataFrame API(第 3 章)，Catalyst 优化器(第 4 章)，以及我们在 Catalyst 上构建的高级功能(第 5 章)。
我们在第 6 章中评估 Spark SQL。
我们在第 7 章中描述了关于 Catalyst 的外部研究。
最后，第 8 章涵盖了相关的工作。

### 2 背景和目标

#### 2.1 Spark 概述

Apache Spark 是一个通用的集群计算引擎，具有 Scala、Java 和 Python 中的 API 以及用于流、图形处理和机器学习的库 `[6]`。
据我们所知，它于 2010 年发布，是使用最广泛的系统之一，具有类似于 DryadLINQ `[20]` 的“语言集成” API，也是最活跃的大数据处理开源项目。
Spark 在 2014 年有 400 多个贡献者，并且被多个供应商打包。

Spark 提供了一个类似于其他最新系统 `[20, 11]` 的函数式编程 API，用户可以在其中操作称为弹性分布式数据集(RDD) `[39]` 的分布式集合。
每个 RDD 是跨集群分区的 Java 或 Python 对象的集合。
RDD 可以通过 map、filter 和 reduce 等操作进行操作，这些操作采用编程语言中的函数并将它们传送到集群上的节点。
例如，下面的 Scala 代码计算文本文件中以 “ERROR” 开头的行数：

```text
lines = spark.textFile(" hdfs ://...")
errors = lines.filter(s => s. contains (" ERROR "))
println(errors.count())
```

这段代码通过读取一个 HDFS 文件创建了一个名为 lines 的字符串 RDD，然后使用过滤器选择字符串中包含 `ERROR` 的行并生成另一个 RDD。
然后它对该数据执行计数。

RDD 是容错的，因为系统可以使用 RDD 的 lineage 图恢复丢失的数据(通过重新运行上面的过滤器等操作来重建丢失的分区)。
它们也可以明确地缓存在内存或磁盘上以支持迭代 `[39]`。

