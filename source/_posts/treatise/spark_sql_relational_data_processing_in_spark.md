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

关于 API 的最后一个注意事项是 RDD 是惰性求值的。
每个 RDD 代表一个计算数据集的“逻辑计划”，但 Spark 会等到某些输出操作(例如计数)启动计算。
这允许引擎做一些简单的查询优化，例如流水线操作。
例如，在上面的示例中，Spark 将通过应用过滤器并计算运行计数来管道从 HDFS 文件读取行，因此它永远不需要具体化中间行和错误结果。
虽然这种优化非常有用，但它也有局限性，因为引擎不理解 RDD 中数据的结构(任意 Java/Python 对象)或用户函数的语义(包含任意代码)。

#### 2.2 Spark 之前的关系系统

我们在 Spark 上构建关系型接口的第一个努力是 Shark `[38]`，它“魔改“了 Apache Hive 以在 Spark 上运行，
并在 Spark 引擎上实现了传统的 RDBMS 优化，例如列式处理。
虽然 Shark 表现出良好的性能和与 Spark 程序集成度良好，但它面临三个重要挑战。
首先，Shark 只能用于查询存储在 Hive 目录中的外部数据，因此不适用于 Spark 程序内部数据的关系查询(例如，手动创建的错误 RDD 上)。
其次，从 Spark 程序调用 Shark 的唯一方法是将 SQL 字符串放在一起，这在模块化程序中使用起来不方便且容易出错。
最后，Hive 优化器是为 MapReduce 量身定制的，难以扩展，因此很难构建新功能，例如用于机器学习的数据类型或对新数据源的支持。

#### 2.3 Spark SQL 的目标

凭借 Shark 的经验，我们希望扩展关系处理接口以涵盖 Spark 中的原生 RDD 和更广泛的数据源。 
我们为 Spark SQL 设定了以下目标：

1. 不仅是在 Spark 内部的程序(在原生 RDD 中)还有在对程序员友好的外部 API 中在都可以使用的关系处理。
2. 使用成熟的 DBMS 技术提供高性能。
3. 轻松支持新数据源，包括半结构化数据和适合联合查询的外部数据库。
4. 使用高级分析算法(例如图形处理和机器学习)启用扩展。

### 3 编程接口

![图 1：Spark SQL 的程序接口和 Spark 的交互](https://i.loli.net/2021/06/30/TAFWDgdiZIptrbs.png)

Spark SQL 作为一个基于 Spark 的库运行，如图 1 所示。
它公开了 SQL 接口，可以通过 JDBC/ODBC 或命令行控制台访问这些 SQL 接口，以及集成到 Spark 支持的编程语言中的 DataFrame API。
我们首先介绍 DataFrame API，它允许用户将程序和关系代码进行融合。
但是，高级函数也可以通过 UDF 在 SQL 中对外提供服务，例如，通过商业智能工具。
我们在 3.7 节讨论 UDF。

#### 3.1 DataFrame API

Spark SQL 的 API 中的主要抽象是一个 DataFrame，一个具有相同结构的分布式行集合。
DataFrame 相当于关系数据库中的表，也可以以类似于 Spark(RDD) 中“原生”分布式集合的方式进行操作。
与 RDD 不同，DataFrame 会跟踪其架构并支持各种关系操作，从而对执行流程进行优化。

DataFrames 可以从系统目录中的表(基于外部数据源)或从本机 Java/Python 对象现有的 RDD 进行构建(参见第 3.5 节)。
构建后，它们可以使用各种关系运算符进行操作，例如 where 和 groupBy，它们采用域特定语言(DSL)中的表达式，类似于 R 和 Python 中的 DataFrame `[32, 30]`。
每个 DataFrame 也可以看成是一个 Row 对象的 RDD，允许用户调用 map 等程序化的 Spark API。

> 注：这些 Row 对象是动态构建的，不一定代表数据的内部存储格式，通常将数据按列存储。

最后，与传统的 DataFrame API 不同，Spark DataFrames 是惰性的，因为每个 DataFrame 对象代表一个计算数据集的逻辑计划，
但在用户调用特殊的“输出操作”(例如保存)之前不会执行。
这可以对用于构建 DataFrame 的操作进行丰富优化。

为了说明这一点，下面的 Scala 代码从 Hive 中的表定义了一个 DataFrame，基于它进行了操作然后打印结果：

```text
ctx = new HiveContext()
users = ctx.table("users")
young = users.where(users("age") < 21)
println(young.count())
```

在这段代码中，users 和 young 是DataFrames。
代码段 `users("age") < 21` 是 DataFrame DSL 中的一个表达式，它被捕获为抽象语法树，而不是像传统 Spark API 那样表示的 Scala 函数。
最后，每个 DataFrame 只代表一个逻辑计划(即，读取用户表并筛选年龄 < 21 岁的记录)。
当用户调用 count 时(这是一个输出操作)，Spark SQL 会构建一个物理计划来计算最终结果。
物理计划可能包含优化，例如仅扫描数据的“age”列(如果其存储格式为列式)，或者甚至使用数据源中的索引来计算匹配的行。

接下来我们将介绍 DataFrame API 的详细信息。

#### 3.2 数据模型

Spark SQL 使用基于 Hive `[19]` 的嵌套数据模型来处理表和 DataFrame。
它支持所有主要的 SQL 数据类型，包括 boolean, integer, double, decimal, string, date,timestamp 以及复杂(即非原子)数据类型：
structs, arrays, maps, unions.
复杂数据类型也可以嵌套在一起以创建更强大的类型。
与许多传统 DBMS 不同，Spark SQL 在查询语言和 API 中为复杂数据类型提供一流的支持。
此外，Spark SQL 还支持用户自定义类型，如 4.4.2 节所述。
使用这种类型系统，我们能够准确地对来自各种来源和格式的数据进行建模，包括 Hive、关系数据库、JSON 和 Java/Scala/Python 中的本地对象。

#### 3.3 DataFrame 的操作

用户可以使用类似于 R DataFrame `[32]` 和 Python Pandas `[30]` 的特定领域语言(DSL) 对 DataFrame 执行关系操作。
DataFrames 支持所有常见的关系运算符，包括投影(select)、过滤器(where)、连接(join)和聚合(groupBy)。
这些操作符都在一个有限的 DSL 中获取表达式对象，让 Spark 捕获表达式的结构。
例如，以下代码计算每个部门的女性员工人数。

```text
employees
  .join(dept, employees("deptId") === dept("id"))
  .where(employees("gender") === "female")
  .groupBy(dept("id"), dept("name"))
  .agg(count("name"))
```

这里，employees 是一个 DataFrame，employees("deptId") 是一个表示 deptId 列的表达式。
表达式对象有许多返回新表达式的运算符，包括常用的比较运算符(例如，=== 用于相等性测试，> 用于大于)和算术运算符(+、- 等)。
它们还支持聚合，例如 count("name")。
所有这些运算符都构建了表达式的抽象语法树(AST)，然后将其传递给 Catalyst 进行优化。
这与原生 Spark API 不同，后者采用包含任意 Scala/Java/Python 代码的函数，然后这些代码对运行时引擎是不透明的。
有关 API 的详细列表，我们建议读者参阅 Spark 的官方文档 `[6]`。

除了关系型 DSL，DataFrame 还可以为系统中的的内容建立临时表并使用 SQL 进行查询。
下面的代码显示了一个示例：

```text
users.where(users("age") < 21)
     .registerTempTable("young")
ctx.sql("SELECT count (*), avg(age) FROM young")
```

SQL 有时便于简洁地计算多个聚合，并且还允许程序通过 JDBC/ODBC 将数据集对外输出。
在系统中注册的 DataFrame 仍然是尚未被具体化的视图，因此还可以跨越 SQL 和原始的 DataFrame 表达式对其进行优化。
然而，DataFrames 也可以具体化，正如我们在 3.6 节中讨论的那样。

#### 3.4 DataFrames 与关系查询语言

虽然从表面上看，DataFrames 提供与 SQL 和 Pig `[29]` 等关系查询语言相同的操作，但我们发现，由于它们与完整的编程语言集成，用户可以更轻松地使用它们。
例如，用户可以将他们的代码分解成 Scala、Java 或 Python 函数，在它们之间传递 DataFrame 以构建逻辑计划，并且在运行输出操作时仍将受益于整个计划的优化。
同样，开发人员可以使用 if 语句和循环等控制结构来构建他们的工作。
一位用户说 DataFrame API “像 SQL 一样简洁和声明性，但我可以命名中间结果”，指的是如何更容易地构建计算和调试中间步骤。

为了简化 DataFrames 中的编程，我们还使 API 热切地分析逻辑计划(即识别表达式中使用的列名是否存在于底层表中，以及它们的数据类型是否合适)，
即使查询结果是惰性计算的。
因此，只要用户输入无效的代码行，Spark SQL 就会报告错误，而不是等待执行。
这再次比大型 SQL 语句更容易使用。

#### 3.5 查询原生数据集

现实世界的数据管道通常从异构源中提取数据，并运行来自不同编程库的各种算法。
为了与过程 Spark 代码互操作，Spark SQL 允许用户直接针对编程语言本机对象的 RDD 构造 DataFrames。
Spark SQL 可以使用反射自动推断这些对象的模式。
在 Scala 和 Java 中，类型信息是从语言的类型系统(来自 JavaBeans 和 Scala case 类)中提取的。
在 Python 中，由于动态类型系统，Spark SQL 对数据集进行采样以执行模式推断。

例如，下面的 Scala 代码从用户对象的 RDD 中定义了一个 DataFrame。
Spark SQL 会自动检测列的名称(“name”和“age”)和数据类型(string 和 int)。

```text
case class User(name:String, age:Int)

// Create an RDD of User objects
usersRDD = spark. parallelize (
  List(User("Alice", 22), User("Bob", 19)))

// View the RDD as a DataFrame
usersDF = usersRDD.toDF
```

在内部，Spark SQL 创建一个指向 RDD 的逻辑数据扫描操作符。
这被编译成访问本机对象字段的物理运算符。
需要注意的是，这与传统的对象关系映射(ORM)非常不同。
ORM 通常会导致将整个对象转换为不同格式的昂贵转换。

在内部，Spark SQL 创建一个指向 RDD 的逻辑数据扫描操作符。
这被编译成访问本机对象字段的物理运算符。
需要注意的是，这与传统的对象关系映射(ORM) 非常不同。
ORM 通常会导致将整个对象转换为不同格式性能消耗严重。
相比之下，Spark SQL 就地访问本机对象，仅提取每个查询中使用的字段。

查询本机数据集的能力让用户可以在现有 Spark 程序中运行优化的关系操作。
此外，它还可以轻松地将 RDD 与外部结构化数据相结合。
例如，我们可以将用户 RDD 与 Hive 中的一个表连接起来：

```text
views = ctx.table("pageviews")
usersDF.join(views ,usersDF("name") === views("user")
```

#### 3.6 缓存在内存中

与之前的 Shark 一样，Spark SQL 可以使用列式存储在内存中物化(通常称为“缓存”)热数据。
与 Spark 的原生缓存将数据简单地存储为 JVM 对象相比，列式缓存可以将内存占用减少一个数量级，因为它应用了列式压缩方案，例如字典编码和运行长度编码。
缓存对于交互式查询和机器学习中常见的迭代算法特别有用。
它可以通过在 DataFrame 上调用 `cache()` 方法来调用。

#### 3.7 用户定义的函数(UDF)

用户定义函数(UDF) 已成为数据库系统的重要扩展点。
例如，MySQL 依靠 UDF 为 JSON 数据提供基本支持。
一个更高级的例子是 MADLib 使用 UDF 为 Postgres 和其他数据库系统实现机器学习算法 `[12]`。
但是，数据库系统通常需要在与主要查询接口不同的单独编程环境中定义 UDF。
Spark SQL 的 DataFrame API 支持 UDF 的内联定义，没有其他数据库系统复杂的打包和注册过程。
事实证明，此功能对于 API 的采用至关重要。

在 Spark SQL 中，UDF 可以通过传递 Scala、Java 或 Python 函数来内联注册，这些函数可能在内部使用完整的 Spark API。
例如，给定机器学习模型的模型对象，我们可以将其预测函数注册为 UDF：

```text
val model: LogisticRegressionModel = ...

ctx.udf. register (" predict",
    (x: Float , y: Float) => model.predict(Vector(x, y)))

ctx.sql ("SELECT predict(age , weight) FROM users ")
```

注册后，商业智能工具还可以通过 JDBC/ODBC 接口使用 UDF。
除了像这里这样对标量值进行操作的 UDF 之外，还可以通过取其名称来定义对整个表进行操作的 UDF，
如 MADLib `[12]`，就在其中使用分布式 Spark API，从而公开高级分析功能给 SQL 用户。
最后，由于 UDF 定义和查询执行使用相同的通用语言(例如 Scala 或 Python)表示，因此用户可以使用标准工具调试或分析整个程序。

> 注：在 Spark 权威指南中是这样描述 Python UDF 的
> 启动此 Python 进程代价很高，但主要代价是将数据序列化为 Python 可理解格式的过程。
> 造成代价高的原因有两个: 一个是计算昂贵，另一个是数据进入 Python 后 Spark 无法管理 worker 的内存。
> 这意味着，如果某个 worker 因资源受限而失败 (因为 JVM 和 Python 都在同一台计算机上争夺内存)，则可能会导致该worker出现故障。
> 所以建议使用 Scala 或 Java编写UDF，不仅编写程序的时间少，还能提高性能。
> 当然仍然可以使用 Python 编写函数。

### 4 Catalyst 优化器

为了实现 Spark SQL，我们设计了一个新的可扩展优化器 Catalyst，它基于 Scala 中的函数式编程结构。
Catalyst 的可扩展设计有两个目的。
首先，我们希望能够轻松地向 Spark SQL 添加新的优化技术和功能，尤其是解决我们在“大数据”(例如，半结构化数据和高级分析)方面遇到的各种问题。
其次，我们希望让外部开发人员能够扩展优化器——例如，添加特定于数据源的规则，这些规则可以将过滤或聚合推送到外部存储系统中，或者支持新的数据类型。
Catalyst 支持基于规则和基于成本的优化。

> 注：基于成本的优化是通过使用规则生成多个计划，然后计算它们的成本来执行的。

虽然过去已经提出了可扩展优化器，但它们通常需要一种复杂的领域特定语言来指定规则，并需要一个“优化器编译器”来将规则转换为可执行代码 `[17, 16]`。
这会导致显着的学习曲线和维护负担。
相比之下，Catalyst 使用 Scala 编程语言的标准特性，例如模式匹配 `[14]`，让开发人员使用完整的编程语言，同时仍然使规则易于指定。
函数式语言的部分设计目的是构建编译器，因此我们发现 Scala 非常适合这项任务。
尽管如此，据我们所知，Catalyst 是第一个基于这种语言构建的生产级别质量的查询优化器。

其核心中，Catalyst 包含一个通用库，用于表示树并应用规则来操作它们。
在此框架之上，我们构建了特定于关系查询处理(例如表达式、逻辑查询计划)的库，以及处理查询执行不同阶段的几组规则：
分析、逻辑优化、物理规划和生成代码以将部分查询编译为 Java 字节码。
对于后者，我们使用另一个 Scala 特性，quasiquotes `[34]`，它可以很容易地在运行时从可组合表达式生成代码。
最后，Catalyst 提供了几个公共扩展点，包括外部数据源和用户定义的类型。

#### 4.1 树

Catalyst 中的主要数据类型是由节点对象组成的树。
每个节点都有一个节点类型和零个或多个子节点。
新的节点类型在 Scala 中定义为 TreeNode 类的子类。
这些对象是不可变的，可以使用函数转换来操作，如下一小节中所述。

作为一个简单的例子，假设对于一个非常简单的表达式语言，我们有以下三个节点类：

- Literal(value: Int): 一个常数值
- Attribute(name: String): 来自输入行的属性，例如“x”
- Add(left: TreeNode, right: TreeNode): 获取两个表达式的合。

> 注：我们在这里对类使用 Scala 语法，其中每个类的字段都在括号中定义，它们的类型使用冒号标识。

这些类可用于构建树；例如，表达式 x+(1+2) 的树，如图 2 所示，将在 Scala 代码中表示如下：

![image.png](https://i.loli.net/2021/06/30/POp4JZigAdhLwVG.png)

```text
Add(Attribute (x), Add(Literal(1), Literal(2)))
```
