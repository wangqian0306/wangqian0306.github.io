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
这允许引擎做一些简单的查询优化，例如管道操作。
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
usersRDD = spark. parallelize(
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

ctx.udf.register (" predict",
    (x: Float , y: Float) => model.predict(Vector(x, y)))

ctx.sql("SELECT predict(age , weight) FROM users ")
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
分析、逻辑优化、物理规划和代码生成以将部分查询编译为 Java 字节码。
对于后者，我们使用另一个 Scala 特性，quasiquotes `[34]`，它可以很容易地在运行时从可组合表达式代码生成。
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

![图 2：通过 Catalyst 树表达 x+(1+2)](https://i.loli.net/2021/06/30/POp4JZigAdhLwVG.png)

```text
Add(Attribute (x), Add(Literal(1), Literal(2)))
```

#### 4.2 规则

可以使用规则来操作树，规则是将一棵树转化为另一棵树的函数。
模式匹配是许多函数式语言的一个特性，它允许从代数数据类型的潜在嵌套结构中提取值。
在 Catalyst 中，树提供了一种转换方法，该方法在树的所有节点上递归地应用模式匹配函数，将与每个模式匹配的节点转换为结果。
例如，我们可以实现一个规则，在常量之间折叠 Add 操作，如下所示：

```text
tree. transform {
  case Add(Literal(c1), Literal(c2)) => Literal(c1+c2)
}
```

将此应用于图 2 中 x+(1+2) 的树将产生新树 x+3。
此处的 case 关键字是 Scala 的标准模式匹配语法 `[14]`，可用于匹配对象的类型以及为提取的值命名(此处为 c1 和 c2)。

传递给 transform 的模式匹配表达式是一个偏函数，这意味着它只需要匹配所有可能的输入树的一个子集。
Catalyst 将测试给定规则适用于树的哪些部分，自动跳过并下降到不匹配的子树。
这种能力意味着规则只需要推理应用给定优化的树，而不是那些不匹配的树。
因此，当新类型的运算符添加到系统中时，不需要修改规则。

规则(以及一般的 Scala 模式匹配)可以在同一个转换调用中匹配多个模式，使得一次实现多个转换变得非常简洁：

```text
tree. transform {
  case Add(Literal(c1), Literal(c2)) => Literal(c1+c2)
  case Add(left , Literal(0)) => left
  case Add(Literal(0), right) => right
}
```

在实践中，规则可能需要多次执行才能完全转换一棵树。
Catalyst 将规则分组，并执行每个批次，直到达到固定点，即直到应用其规则后树停止更改为止。
将规则运行到定点意味着每个规则都可以是简单的和自包含的，但最终仍会对树产生更大的全局影响。
在上面的例子中，重复应用会不断折叠更大的树，例如 (x+0)+(3+3)。
作为另一个示例，第一批可能会分析表达式以将类型分配给所有属性，而第二批可能会使用这些类型进行常量折叠。
在每批之后，开发人员还可以对新树运行健全性检查(例如，查看所有属性都分配了类型)，这些检查通常也通过递归匹配编写。

最后，规则条件及其主体可以包含任意 Scala 代码。
这使 Catalyst 比面向特定领域对应语言的优化器更强大，同时保持简单规则的简洁。

根据我们的经验，不可变树上的函数转换使整个优化器非常容易推理和调试。
它们还在优化器中启用并行化，尽管我们还没有进一步开发它。

#### 4.3 在 Spark SQL 中使用 Catalyst

![图 3：Spark SQL 中的查询计划阶段，圆角矩形代表 Catalyst 树](https://i.loli.net/2021/07/01/RNUldhDQOJuZS21.png)

我们在四个阶段使用 Catalyst 的通用树转换框架，如图 3 所示：

1. 分析逻辑计划以解析引用
2. 逻辑计划优化
3. 指定物理计划
4. 生成并编译代码来查询部分 Java 字节码。

在物理规划阶段，Catalyst 可能会生成多个计划并根据成本进行比较。
所有其他阶段完全基于规则。
每个阶段使用不同类型的树节点；Catalyst 包括用于表达式、数据类型以及逻辑和物理运算符的节点库。
我们现在对这些内容进行描述。

##### 4.3.1 分析

Spark SQL 从一个要计算的关系开始，可能是来自于 SQL 解析器返回的抽象语法树(AST)，也可能是来自 API 构造的 DataFrame 对象。
在这两种情况下，关系可能包含未解析的属性引用或关系：例如，在 SQL 查询 SELECT col FROM sales 中，col 的类型，甚至它是否是有效的列名，
直到我们查找 sales 表时才知道。
如果我们不知道其类型或未将其与输入表(或别名)匹配，则该属性被称为未解析。
Spark SQL 使用 Catalyst 规则和一个 Catalog 对象来跟踪所有数据源中的表来解析这些属性。
它首先构建具有未绑定属性和数据类型的“未解析逻辑计划”树，然后应用执行以下操作的规则。

- 从 Catalog 中按照名称查找关系。
- 将命名之后的属性(例如 col)作为输入映射到给定运算符的子项
- 确定哪些属性引用相同的值，并为它们提供唯一的 ID(稍后允许优化表达式，例如 col = col)。
- 表达式的传递和强制类型转换：例如，我们无法知道 1+col 的类型，直到我们解析 col 并可能将其子表达式转换为兼容类型。

总的来说，分析器的规则大约是 1000 行代码。

##### 4.3.2 逻辑优化

在逻辑优化阶段会将标准的基于规则的优化方案应用于逻辑计划。
其中包括常量折叠(constant folding)、谓词下推(predicate pushdown)、投影修剪(projection pruning)、空值传导(null propagation)、
布尔表达式简化和其他规则。
总的来说，我们发现为各种情况添加规则非常简单。

> 注：
> 常量折叠——将常量渲染至代码中
> 谓词下推——将过滤表达式尽可能移动至靠近数据源的位置，以使真正执行时能直接跳过无关的数据。
> 投影修剪——? 推测是通过切分数据进行优化
> 空值传导——? 空值验证

例如，当我们将固定精度的 DECIMAL 类型添加到 Spark SQL 时，我们想优化小精度 DECIMAL 上的总和与平均值等聚合；
用 12 行代码编写了一个规则，在 SUM 和 AVG 表达式中找到这样的小数，并将它们转换为未缩放的 64 位 LONG，在其上进行聚合，然后将结果转换回。
仅优化 SUM 表达式的此规则的简化版本复制如下：

```text
object DecimalAggregates extends Rule[LogicalPlan] {
  /** Maximum number of decimal digits in a Long */
  val MAX_LONG_DIGITS = 18
  def apply(plan: LogicalPlan): LogicalPlan = {
    plan transformAllExpressions {
      case Sum(e @ DecimalType.Expression(prec , scale ))
              if prec + 10 <= MAX_LONG_DIGITS =>
        MakeDecimal(Sum(LongValue(e)), prec+10, scale)
    }
}
```

再举一个例子，一个 12 行的规则使用简单的正则表达式将 LIKE 表达式优化为 String.startsWith 或 String.contains 方法。
在规则中自由使用任意 Scala 代码使得这些类型的优化变得容易表达，这些优化超越了子树结构的模式匹配。
逻辑优化规则总共有 800 行代码。

##### 4.3.3 物理计划

在物理规划阶段，Spark SQL 使用与 Spark 执行引擎匹配的物理运算符，获取一个逻辑计划并生成一个或多个物理计划。
然后使用成本模型选择计划。
目前，基于成本的优化仅用于 select 和 join 算法：对于已知较小的关系，Spark SQL 会使用 Spark 中可用的点对点广播工具进行广播连接。
然而，该框架支持更广泛地使用基于成本的优化，因为可以使用规则递归地估计整个树的成本。
因此，我们打算在未来实施更丰富的基于成本的优化。

> 注：估计表大小的方式为：判断表是否缓存在内存中或来自外部文件，或者它是具有 LIMIT 的子查询的结果。

物理规划器还执行基于规则的物理优化，例如将投影或过滤器流水线化为一个 Spark 映射操作。
此外，它还可以将逻辑计划中的操作推送到支持谓词或投影下推的数据源中。
我们将在第 4.4.1 节中描述这些数据源的 API。
总的来说，物理规划规则大约有 500 行代码。

##### 4.3.4 代码生成

查询优化的最后阶段涉及生成 Java 字节码以在每台机器上运行。
由于 Spark SQL 经常在内存数据集上运行，其中处理受 CPU 限制，我们希望支持代码生成以加快执行速度。
尽管如此，代码生成引擎的构建通常很复杂，本质上相当于一个编译器。
Catalyst 依靠 Scala 语言的一个特殊功能 quasiquotes `[34]` 来简化代码生成。
Quasiquotes 允许在 Scala 语言中以编程方式构建抽象语法树 (AST)，然后可以在运行时将其提供给 Scala 编译器以生成字节码。
我们使用 Catalyst 将表示 SQL 中表达式的树转换为 AST 以供 Scala 代码评估该表达式，然后编译并运行生成的代码。

作为一个简单的例子，参考第 4.2 节中介绍的 Add、Attribute 和 Literal 树节点，它们允许我们编写诸如 (x+y)+1 之类的表达式。
如果没有代码生成，则必须通过沿着 Add、Attribute 和 Literal 节点的树为每一行数据解释此类表达式。
这会引入大量分支和虚函数调用，从而减慢执行速度。
通过代码生成，我们可以编写一个函数来将特定的表达式树转换为 Scala AST，如下所示：

```text
def compile(node: Node): AST = node match {
  case Literal(value) => q"$value"
  case Attribute(name) => q"row.get($name)"
  case Add(left, right) =>
    q"${compile(left)} + ${compile(right)}"
}
```

以 q 开头的字符串是 quasiquotes，这意味着虽然它们看起来像字符串，但它们在编译时被 Scala 编译器解析并代表其中代码的 AST。
Quasiquotes 可以将变量或其他 AST 拼接到其中，使用 $ 符号表示。
例如，Literal(1) 将成为 1 的 Scala AST，而 Attribute("x") 将成为 row.get("x")。
最后，像 Add(Literal(1), Attribute("x")) 这样的树变成了像 1+row.get("x") 这样的 Scala 表达式的 AST。

Quasiquotes 在编译时进行类型检查，以确保只替换适当的 AST 或文字，使它们比字符串连接更有用，
并且它们直接生成 Scala AST，而不是在运行时依靠 Scala 解析器。
此外，它们是高度可组合的，因为每个节点的代码生成规则不需要知道其子节点返回的树是如何构建的。
最后，如果存在 Catalyst 遗漏的表达式级优化，Scala 编译器会进一步优化生成的代码。
图 4 显示 quasiquotes 让我们生成性能类似于手动调整程序的代码。

![图 4：评估表达式 x+x+x 的性能比较，其中 x 是整数，10 亿次](https://i.loli.net/2021/07/01/Nnf6kvHAZeJ8MOq.png)

我们发现 quasiquotes 用于代码生成非常简单，并且我们观察到即使是 Spark SQL 的新贡献者也可以快速为新类型的表达式添加规则。
Quasiquotes 也适用于我们在原生 Java 对象上运行的目标：从这些对象访问字段时，我们可以通过代码生成对所需字段的直接访问，
而不必将对象复制到 Spark SQL Row 中并使用 Row 的访问方法。
最后，将代码生成的评估与我们尚未为其生成代码的表达式的解释评估结合起来很简单，因为我们编译的 Scala 代码可以直接调用我们的表达式解释器。

Catalyst 的代码生成器总共大约有 700 行代码。

#### 4.4 执行点

Catalyst 围绕可组合规则的设计使用户和第三方库可以轻松扩展。
开发人员可以在运行时向查询优化的每个阶段添加批量规则，只要他们遵守每个阶段的约定(例如，确保分析解决所有属性)。
但是，为了在不了解 Catalyst 规则的情况下更简单地添加某些类型的扩展，我们还定义了两个更窄的公共扩展点：数据源和用户定义类型。
这些仍然依赖于核心引擎中的设施与优化器的其余部分进行交互。

##### 4.4.1 数据源

开发人员可以使用多个 API 为 Spark SQL 定义新的数据源，这些 API 公开了不同程度的可能优化。
所有数据源都必须实现一个 createRelation 函数，该函数接受一组键值参数并返回该关系的 BaseRelation 对象(如果可以成功加载)。
每个 BaseRelation 都包含一个模式和一个可选的估计大小(以字节为单位)。
例如，代表 MySQL 的数据源可以将表名作为参数，并要求 MySQL 估计表大小。

> 注：非结构化数据源也可以将所需的模式作为参数； 例如，有一个 CSV 文件数据源可让用户指定列名称和类型。

为了让 Spark SQL 读取数据，BaseRelation 可以实现几个接口之一，让它们暴露不同程度的复杂性。
最简单的 TableScan 需要关系返回表中所有数据的 Row 对象的 RDD。
更高级的 PrunedScan 需要读取一组列名，并且应该返回仅包含这些列的行。
第三个接口 PrunedFilteredScan 接受所需的列名和 Filter 对象数组，它们是 Catalyst 表达式语法的子集，允许谓词下推。
过滤器是建议性的，即数据源应尝试仅返回通过每个过滤器的行，但在无法评估的过滤器的情况下允许返回误报。
最后，为 CatalystScan 接口提供了一个完整的 Catalyst 表达式树序列，用于谓词下推，尽管它们再次是建议性的。

> 注：目前，过滤器包括相等、与常量的比较、和 IN 子句，每个子句都在一个属性上。

这些接口允许数据源实现不同程度的优化，同时仍然使开发人员可以轻松添加几乎任何类型的简单数据源。
我们和其他人已经使用该接口实现了以下数据源：

- CSV 文件，它只是扫描整个文件，但允许用户指定结构。
- Avro `[4]`，一种用于嵌套数据的自描述二进制格式。
- Parquet `[5]`，一种柱状文件格式，我们支持列修剪和过滤器。
- JDBC 数据源，它并行扫描来自 RDBMS 的表的范围并将过滤器推送到 RDBMS 以达到最小化通信。

为了使用这些数据源，程序员在 SQL 语句中指定他们的包名，为配置选项传递键值对。
例如，Avro 数据源采用文件的路径：

```text
CREATE TEMPORARY TABLE messages
USING com. databricks .spark.avro
OPTIONS (path "messages.avro ")
```

所有数据源也可以公开网络位置信息，即数据的每个分区从哪个机器读取最有效。
这是通过它们返回的 RDD 对象公开的，因为 RDD 具有用于数据局部性的内置 API [39]。

最后，可以使用将数据写入现有表或新表的类似接口。
这些更简单，因为 Spark SQL 只提供要写入的 Row 对象的 RDD。

##### 4.4.2 用户定义的类型(UDTs)

我们希望在 Spark SQL 中允许高级分析的一项功能是支持用户定义的类型。
例如，机器学习应用程序可能需要向量类型，而图算法可能需要用于表示图的类型，这在关系表上是可能的 `[15]`。
然而，添加新类型可能具有挑战性，因为数据类型遍及执行引擎的所有方面。
例如，在 Spark SQL 中，内置数据类型以列式压缩格式存储，用于内存缓存(第 3.6 节)，而在上一节的数据源 API 中，我们需要公开所有可能的数据类型给数据源作者。

在 Catalyst 中，我们通过将用户定义的类型映射到由 Catalyst 的内置类型组成的结构来解决这个问题，如第 3.2 节所述。
要将 Scala 类型注册为 UDT，用户需要提供从其类的对象到内置类型的 Catalyst 行的映射，以及反向映射。
在用户代码中，他们现在可以在使用 Spark SQL 查询的对象中使用 Scala 类型，并且它会在幕后转换为内置类型。
同样，它们可以注册直接对其类型进行操作的 UDF(参见第 3.7 节)。

作为一个简短的例子，假设我们想要将二维点(x, y) 注册为 UDT。
我们可以将这些向量表示为两个 DOUBLE 值。
要注册 UDT，我们需要编写以下内容:

```text
class PointUDT extends UserDefinedType [Point] {
  def dataType = StructType (Seq( // Our native structure
    StructField("x", DoubleType),
    StructField("y", DoubleType)
  ))
  def serialize (p: Point) = Row(p.x, p.y)
  def deserialize (r: Row) =
    Point(r.getDouble (0), r.getDouble (1))
}
```

注册此类型后，Spark SQL 转换为 DataFrames 时 Point 会在本机对象中识别，并将传递给 UDF。
此外，Spark SQL 将在缓存数据时以列格式存储 Points(将 x 和 y 压缩为单独的列)，
并且 Points 将可写入 Spark SQL 的所有数据源，这些数据源会将它们视为 DOUBLE 键值对。
我们在 Spark 的机器学习库中使用此功能，如第 5.2 节所述。

### 5 高级分析功能

在本节中，我们将描述我们添加到 Spark SQL 的三个特性，专门用于处理“大数据”环境中的挑战。
首先，在这些环境中，数据通常是非结构化或半结构化的。
虽然按程序解析此类数据是可能的，但它会导致冗长的样板代码。
为了让用户立即查询数据，Spark SQL 包含了一种用于 JSON 和其他半结构化数据的模式推理算法。
其次，大规模处理通常需要机器学习超过聚合和链接。
我们描述了 Spark SQL 如何被整合到 Spark 机器学习库的新高级 API 中 `[26]`。
最后，数据管道通常结合来自不同存储系统的数据。
基于第 4.4.1 节中的数据源 API，Spark SQL 支持查询联邦，允许单个程序高效地查询不同的数据源。
这些功能都建立在 Catalyst 框架之上。

#### 5.1 半结构化数据的结构推断

```text
{
  "text": "This is a tweet about #Spark",
  "tags": ["#Spark"],
  "loc": {"lat": 45.1 , "long": 90}
}

{
  "text": "This is another tweet",
  "tags": [],
  "loc": {"lat": 39, "long": 88.5}
}

{
  "text": "A #tweet without #location",
  "tags": ["#tweet", "#location"]
}
```

> 图 5：一组示例 JSON 记录，表示推文。

```text
text STRING NOT NULL,
tags ARRAY <STRING NOT NULL > NOT NULL,
loc STRUCT <lat FLOAT NOT NULL, long FLOAT NOT NULL>
```

> 图 6：为图 5 中的推文推断的结构。

半结构化数据在大规模环境中很常见，因为随着时间的推移，它易于生成和添加字段。
在 Spark 用户中，我们看到 JSON 用于输入数据的使用率非常高。
不幸的是，在 Spark 或 MapReduce 等程序环境中使用 JSON 很麻烦：
大多数用户求助于类似 ORM 的库(例如，Jackson `[21]`)将 JSON 结构映射到 Java 对象，或者一些尝试直接使用低级库。

在 Spark SQL 中，我们添加了一个 JSON 数据源，它可以从一组记录中自动推断出结构。
例如，图 5 中的 JSON 对象，经过库推断得出了图 6 中所示的结构。
用户可以简单地将 JSON 文件注册为表，并使用按路径访问字段的语法进行查询，例如：

```text
SELECT loc.lat ,loc.long FROM tweets
WHERE text LIKE ’%Spark%’ AND tags IS NOT NULL
```

我们的结构推断算法会一次性的处理数据，但也可以在数据样本上运行。
它与之前关于 XML 和对象数据库 `[9, 18, 27]` 结构推断的工作有关，但更简单，因为它只推断静态树结构，不允许在任意深度递归嵌套元素。

具体来说，该算法尝试推断 STRUCT 类型的树，每个类型可能包含原子、数组或其他 STRUCT。
Foreach 字段由根 JSON 对象(例如，tweet.loc.latitude)的不同路径定义，该算法找到与该字段的观察实例匹配的最具体的 Spark SQL 数据类型。
例如，如果该字段的所有出现都是适合 32 位的整数，它将推断为 INT；如果它们更大，它将使用 LONG(64 位)或 DECIMAL(任意精度) 如果还有小数值，它将使用 FLOAT。

具体来说，该算法尝试推断 STRUCT 类型的树，每个类型可能包含原子、数组或其他 STRUCT。
对于由 JSON 对象根(例如，tweet.loc.latitude)的不同路径定义的每个字段，该算法会找到与该字段的观察到的实例匹配的 Spark SQL 数据类型。
例如，如果该字段的所有出现都是适合 32 位的整数，它将推断为 INT；如果它们更大，它将使用 LONG(64 位)或 DECIMAL(任意精度)；
如果还有小数值，它将使用 FLOAT。
对于显示多种类型的字段，Spark SQL 使用 STRING 作为最通用的类型，保留原始 JSON 格式。
对于包含数组的字段，它使用相同的“最具体的超类型”逻辑从所有观察到的元素中确定元素类型。
我们使用对数据的单个归约操作来实现该算法，该操作从每个单独记录的模式(即类型树)开始，并使用关联的“最具体的超类型”函数合并它们，该函数概括了每个字段的类型。
这使得该算法既是单次传递又是高效通信，因为在每个节点上都发生了高度的减少。

作为一个简短的例子，请注意在图 5 和图 6 中，该算法如何概括 loc.lat 和 loc.long 的类型。
每个字段在一个记录中显示为整数，在另一个记录中显示为浮点数，因此算法返回 FLOAT。
另请注意，对于 tags 字段，算法如何推断出一个不能为 null 的字符串数组。

在实践中，我们发现该算法可以很好地处理实际的 JSON 数据集。
例如，它正确地为 Twitter 的 firehouse 中的 JSON tweets 标识了一个可用的模式，其中包含大约 100 个不同的字段和高度嵌套。
多个 Databricks 客户也成功地将其应用于其内部 JSON 格式。

在 Spark SQL 中，我们也使用相同的算法来推断 Python 对象的 RDD 模式(参见第 3 节)，因为 Python 不是静态类型的，因此 RDD 可以包含多种对象类型。
未来，我们计划为 CSV 文件和 XML 添加类似的推理。
开发人员发现能够将这些类型的数据集视为表格，并立即查询它们或将它们与其他对提高生产力非常有价值的数据结合起来。

#### 5.2 与 Spark 机器学习库进行集成

> 注：此处机器学习相关专业名词可能有翻译错误。

作为 Spark SQL 在其他 Spark 模块中的实用程序的示例，Spark 的机器学习库 MLlib 引入了使用 DataFrames `[26]` 的新高级 API。
这个新 API 基于机器学习管道的概念，这是其他高级 ML 库(如 SciKit-Learn `[33]` )中的抽象。
管道是数据转换的图，例如特征提取、归一化、降维和模型训练，每一个都交换数据集。
管道是一种有用的抽象，因为 ML 工作流有很多步骤；将这些步骤表示为可组合元素，可以轻松更改管道的各个部分或在整个工作流程级别搜索调整参数。

![图 7：一个简短的 MLlib 管道和运行它的 Python 代码。](https://i.loli.net/2021/07/05/V4WJSn7zp65sZdy.png)

> 注：我们从 (text, label) 组成的 DataFrame 开始，将文本标记为单词，运行词频特征化器(HashingTF)以获取特征向量，然后训练逻辑回归。

为了在管道阶段之间交换数据，MLlib 的开发人员需要一种紧凑(因为数据集可能很大)但又灵活的格式，允许为每条记录存储多种类型的字段。
例如，用户可能从包含文本字段和数字字段的记录开始，然后在文本上运行特征化算法(例如 TF-IDF)将其转换为向量，
对其他字段之一进行归一化，对文本执行降维整套功能等。
为了表示数据集，新 API 使用 DataFrames，其中每一列代表数据的一个特征。
可以在管道中调用的所有算法都为输入列和输出列命名，因此可以在字段的任何子集上调用并生成新的集合。
这使开发人员可以轻松构建复杂的管道，同时保留每条记录的原始数据。
为了说明 API，图 7 显示了一个简短的管道和创建的 DataFrame 的架构。

MLlib 使用 Spark SQL 必须做的主要工作是为向量创建用户定义的类型。
这个向量 UDT 可以存储稀疏向量和密集向量，并将它们表示为四个原始字段：类型(密集或解析)的布尔值、向量的大小、
索引数组(用于稀疏坐标)和数组 double 值(稀疏向量的非零坐标或其他所有坐标)。
除了 DataFrames 用于跟踪和操作列的实用程序之外，我们还发现它们还有另一个用处：它们使在 Spark 支持的所有编程语言中公开 MLlib 的新 API 变得更加容易。
以前，MLlib 中的每个算法都采用特定领域概念的对象(例如，用于分类的标记点或用于推荐的(用户、产品)评级)，
并且这些类中的每一个都必须以各种语言实现(例如，从 Scala 复制到 Python)。
在任何地方使用 DataFrames 使得以所有语言公开所有算法变得更加简单，因为它们已经存在所以我们只需要在 Spark SQL 中进行数据转换就可以了。
这一点尤其重要，因为 Spark 为新的编程语言添加了绑定的特性。

最后，在 MLlib 中使用 DataFrames 存储也可以很容易地在 SQL 中公开其所有算法。
我们可以简单地定义一个 MADlib 风格的 UDF，如 3.7 节所述，它将在内部调用表上的算法。
我们还在探索 API 来将管道构建相关内容在 SQL 中开放出来。

#### 5.3 查询联合到外部数据库

数据管道通常结合来自异构源的数据。
例如，推荐管道可能会将流量日志与用户配置文件数据库和用户的社交媒体流结合起来。
由于这些数据源通常位于不同的机器或地理位置，因此单纯地查询它们可能会非常昂贵。
Spark SQL 数据源利用 Catalyst 尽可能将谓词下推到数据源中。

例如，下面使用 JDBC 数据源和 JSON 数据源将两个表连接在一起，以查找最近注册用户的流量日志。
方便的是，两个数据源都可以自动推断模式，而无需用户定义它。
JDBC 数据源还将过滤谓词下推到 MySQL 中以减少传输的数据量。

```text
CREATE TEMPORARY TABLE users USING jdbc
OPTIONS(driver "mysql" url "jdbc:mysql :// userDB/users")

CREATE TEMPORARY TABLE logs
USING json OPTIONS (path "logs.json")

SELECT users.id , users.name, logs.message
FROM users JOIN logs WHERE users.id = logs.userId
AND users.registrationDate > "2015-01-01"
```

在后台，JDBC 数据源使用第 4.4.1 节中的 PrunedFilteredScan 接口，该接口为其提供了请求列的名称和这些列上的简单谓词(相等、比较和 IN 子句)。
在这种情况下，JDBC 数据源将在 MySQL 上运行以下查询：

```text
SELECT users.id ,users.name FROM users
WHERE users.registrationDate > "2015-01-01"
```

> 注：JDBC 数据源还支持按特定列“分片”源表并并行读取它的不同范围。

在未来的 Spark SQL 版本中，我们还希望为 HBase 和 Cassandra 等键值存储添加谓词下推，它们支持某些形式的过滤。

### 6 评估

我们从两个维度评估 Spark SQL 的性能：SQL 查询处理性能和 Spark 程序性能。
特别是，我们证明了 Spark SQL 的可扩展架构不仅支持更丰富的功能集，而且比以前基于 Spark 的 SQL 引擎带来了显着的性能改进。
此外，对于 Spark 应用程序开发人员而言，DataFrame API 可以比原生 Spark API 带来显着的加速，同时使 Spark 程序更加简洁和易于理解。
最后，与将 SQL 和过程代码作为单独的并行作业运行相比，将关系查询和过程查询相结合的应用程序在集成的 Spark SQL 引擎上运行得更快。

#### 6.1 SQL 性能

我们使用 AMPLab 大数据基准测试 `[3]` 将 Spark SQL 与 Shark 和 Impala `[23]` 的性能进行了比较，
该基准测试使用 Pavlo 等人开发的 Web 分析工作负载。`[31]`
基准包含四种类型的查询，具有不同的参数，执行扫描、聚合、连接和基于 UDF 的 MapReduce 工作。
我们使用了六台 EC2 i2.xlarge 机器(一台主机，五台工作器)的集群，每台机器有 4 个内核、30 GB 内存和 800 GB SSD，
运行 HDFS 2.4、Spark 1.3、Shark 0.9.1 和 Impala 2.1.1。
使用柱状 Parquet 格式 `[5]` 压缩后的数据集是 110 GB 的数据。

![图 8：Shark、Impala 和 Spark SQL 在大数据基准查询上的性能](https://i.loli.net/2021/07/05/fs97XU24aACRGqH.png)

> 注：参见 `[31]`

图 8 显示了每个查询的结果，按查询类型分组。
查询 1-3 具有不同的参数来改变它们的选择性，其中 1a、2a 等是最具选择性的，而 1c、2c 等是最不具有选择性并处理更多数据的。
查询 4 使用基于 Python 的 Hive UDF，它在 Impala 中不直接支持，但很大程度上受 UDF 的 CPU 性能限制。

我们看到，在所有查询中，Spark SQL 比 Shark 快得多，并且通常与 Impala 竞争。
与 Shark 不同的主要原因是 Catalyst 中的代码生成(第 4.3.4 节)，它减少了 CPU 开销。
此功能使 Spark SQL 在许多此类查询中与基于 C++ 和 LLVM 的 Impala 引擎竞争。
与 Impala 最大的差距是在查询 3a 中，Impala 选择了更好的连接计划，因为查询的选择性使得其中一个表非常小。

#### 6.2 DataFrames 和原生 Spark 代码的对比

除了运行 SQL 查询之外，Spark SQL 还可以通过 DataFrame API 帮助非 SQL 开发人员编写更简单、更高效的 Spark 代码。
Catalyst 可以对手写代码难以完成的 DataFrame 操作执行优化，例如谓词下推、管道和自动连接选择。
即使没有这些优化，DataFrame API 也可以通过代码生成实现更高效的执行。
对于 Python 应用程序尤其如此，因为 Python 通常比 JVM 慢。

对于本次评估，我们比较了执行分布式聚合的 Spark 程序的两种实现。
数据集由 10 亿个整数对 (a, b) 组成，具有 100,000 个不同的 a 值，位于与上一节相同的五个 i2.xlarge 集群上。
我们测量为每个 a 值计算 b 的平均值所花费的时间。
首先，我们看一个使用 Python API for Spark 中的 map 和 reduce 函数计算平均值的版本：

```text
sum_and_count = \
  data.map(lambda x: (x.a, (x.b, 1))) \
      .reduceByKey(lambda x, y: (x[0]+y[0], x[1]+y[1])) \
      .collect()
[(x[0], x[1][0] / x[1][1]) for x in sum_and_count ]
```

相比之下，相同的程序可以使用 DataFrame API 编写为一个简单的操作：

```text
df.groupBy("a").avg("b")
```

![图 9：使用本机 Spark Python 和 Scala API 与 DataFrame API 编写的聚合的性能](https://i.loli.net/2021/07/05/iengLS7KUXPTRwd.png)

图 9 显示代码的 DataFrame 版本比手写 Python 版本高 12 倍，而且更加简洁。
这是因为在 DataFrame API 中，Python 只构建了逻辑计划，所有物理执行都被编译成原生 Spark 代码作为 JVM 字节码，从而提高执行效率。
事实上，DataFrame 版本的性能也比上述 Spark 代码的 Scala 版本高 2 倍。
这主要是由于代码生成：DataFrame 版本中的代码避免了在手写 Scala 代码中发生的键值对的昂贵分配。

#### 6.3 管道性能

DataFrame API 还可以让开发人员在单个程序中跨越关系和逻辑代码来编写业务逻辑并优化性能。
作为一个简单的例子，我们考虑一个两阶段管道，它从语料库中选择文本消息的子集并计算最常用的词。
虽然非常简单，但这可以模拟一些现实世界的管道，例如，计算特定人群在推文中使用的最流行的词。

在这个实验中，我们在 HDFS 中生成了一个包含 100 亿条消息的合成数据集。
每条消息平均包含 10 个从英语词典中提取的单词。
管道的第一阶段使用关系过滤器来选择大约 90% 的消息。
第二阶段计算字数。

![图 10：作为单独的 Spark SQL 查询和 Spark 作业(上方)以及集成的 DataFrame 作业(下方)编写的两阶段管道的性能](https://i.loli.net/2021/07/05/UagFWYSjm5Nrz7K.png)

首先，我们使用单独的 SQL 查询和基于 Scala 的 Spark 作业来实现管道，这可能发生在运行单独的关系和过程引擎(例如，Hive 和 Spark)的环境中。
然后我们使用 DataFrame API 实现了一个组合管道，即使用 DataFrame 的关系运算符执行过滤器，并使用 RDD API 对结果执行字数统计。
与第一个管道相比，第二个管道避免了在将 SQL 查询的整个结果传递到 Spark 作业之前将其保存到 HDFS 文件作为中间数据集的成本，
因为 SparkSQL 使用关系运算符进行过滤并管道化了统计单词数的 map 。
图 10 比较了两种方法的运行时性能。
除了更容易理解和操作，基于 DataFrame 的管道还将性能提升了 2 倍。

### 7 研究应用

除了 Spark SQL 的即时实际生产用例之外，我们还看到了从事更多实验项目的研究人员的浓厚兴趣。
我们概述了两个利用 Catalyst 可扩展性的研究项目：一个是近似查询处理，一个是基因组学。

#### 7.1 广义在线聚合

曾和他的团队，已经在工作中使用了 Catalyst，以提高在线聚合的通用性 `[40]`。
这项工作概括了在线聚合的执行，以支持任意嵌套的聚合查询。
它允许用户通过查看在总数据的一小部分上计算的结果来查看执行查询的进度。
这些部分结果还包括准确性度量，让用户在达到足够的准确性时停止查询。

为了在 Spark SQL 内部实现这个系统，作者添加了一个新的操作符来表示一个被分解为采样批次的关系。
在查询规划期间，调用转换用于将原始完整查询替换为多个查询，每个查询对数据的连续样本进行操作。

然而，简单地用样本替换完整数据集不足以让在线方式计算出准确的答案。
标准聚合等操作必须替换为同时考虑当前样本和先前批次结果的有状态对应项。
此外，可能会根据近似答案过滤掉元组的操作必须替换为可以考虑当前估计错误的版本。

这些转换中的每一个都可以表示为 Catalyst 规则，这些规则修改算子树，直到它产生正确的在线答案。
不基于采样数据的树片段会被这些规则忽略，并且可以使用标准代码路径执行。
通过使用 Spark SQL 作为基础，作者能够用大约 2000 行代码实现一个相当完整的原型。

#### 7.2 计算基因组学

计算基因组学中的一个常见操作涉及基于数值偏移检查重叠区域。
这个问题可以表示为不等式谓词的连接。
考虑两个数据集 a 和 b，其结构为 (start LONG, end LONG)。
范围连接操作可以用如下 SQL 表示：

```text
SELECT * FROM a JOIN b
WHERE a.start < a.end
  AND b.start < b.end
  AND a.start < b.start
  AND b.start < a.end
```

如果没有特殊优化，前面的查询将被许多系统使用低效算法(例如嵌套循环连接)执行。
相比之下，专门的系统可以使用区间树计算这个连接的答案。
ADAM 项目 `[28]` 中的研究人员能够在 Spark SQL 版本中构建一个特殊的规划规则，以有效地执行此类计算，
从而使他们能够利用标准数据操作能力以及专门的处理代码。
所需的更改大约是 100 行代码。

### 8 相关工作

**编程模型** 
一些系统试图将关系处理与最初用于大型集群的程序处理引擎相结合。
其中，Shark `[38]` 最接近 Spark SQL，运行在相同的引擎上并提供相同的关系查询和高级分析组合。
Spark SQL 通过更丰富且对程序员更友好的 API DataFrames 改进了 Shark，其中可以使用宿主编程语言中的构造以模块化方式组合查询(参见第 3.4 节)。
它还允许直接在本机 RDD 上运行关系查询，并支持 Hive 之外的广泛数据源。

启发 Spark SQL 设计的一个系统是 DryadLINQ `[20]`，它将 C# 中的语言集成查询编译为分布式 DAG 执行引擎。
LINQ 查询也是关系查询，但可以直接对 C# 对象进行操作。
Spark SQL 超越了 DryadLINQ，还提供类似于常见数据科学库 `[32, 30]` 的 DataFrame 接口、数据源和类型的 API，以及通过在 Spark 上执行来支持迭代算法。

其他系统仅在内部使用关系数据模型，并将过程代码委托给 UDF。
例如，Hive 和 Pig `[36, 29]` 提供关系查询语言，但已广泛使用 UDF 接口。
ASTERIX `[8]` 内部有一个半结构化数据模型。
Stratosphere `[2]` 也有一个半结构化模型，但提供了 Scala 和 Java 的 API，让用户可以轻松调用 UDF。
PIQL `[7]` 同样提供了 Scala DSL。
与这些系统相比，Spark SQL 通过能够直接查询用户定义类(原生 Java/Python 对象)，并让开发人员可以在同一语言中混合使用过程 API 和关系 API。
此外，通过 Catalyst 优化器，Spark SQL 实现了大多数大型计算框架中不存在的优化(例如，代码生成)和其他功能(例如，JSON 和机器学习数据类型的模式推断)。
我们相信，这些功能对于为大数据提供集成的、易于使用的环境至关重要。

最后 DataFrame API 已经适用于单机 `[32,30]` 和集群 `[13,10]`
与以前的 API 不同，Spark SQL 优化器使用关系优化器进行 DataFrame 计算。

**高级分析**
Spark SQL 以最近的工作为基础，在大型集群上运行高级分析算法，包括迭代算法平台 `[39]` 和图分析 `[15, 24]`。
MADlib `[12]` 也希望公开分析功能，尽管方法不同，因为 MADlib 必须使用 Postgres UDF 的有限接口，而 Spark SQL 的 UDF 可以是成熟的 Spark 程序。
最后，包括 Sinew 和 Invisible Loading `[35, 1]` 在内的技术试图提供和优化对 JSON 等半结构化数据的查询。
我们希望在我们的 JSON 数据源中应用其中一些技术。

### 9 结论

我们展示了 Spark SQL，这是 Apache Spark 中的一个新模块，提供与关系处理的丰富集成。
Spark SQL 使用声明性 DataFrame API 扩展了 Spark，以允许进行关系处理，提供自动优化等优势，并让用户编写混合关系分析和复杂分析的复杂管道。
它支持为大规模数据分析量身定制的各种功能，包括半结构化数据、联邦查询和用于机器学习的数据类型。
为了启用这些功能，Spark SQL 基于名为 Catalyst 的可扩展优化器，通过嵌入 Scala 编程语言，可以轻松添加优化规则、数据源和数据类型。
用户反馈和基准测试表明，Spark SQL 使编写混合关系和过程处理的数据管道变得更加简单和高效，同时与以前的 SQL-on-Spark 引擎相比提供了显着的加速。

Spark SQL 在如下地址开源: [http://spark.apache.org](http://spark.apache.org)

### 10 致谢

We would like to thank Cheng Hao, Tayuka Ueshin, Tor Myklebust,
Daoyuan Wang, and the rest of the Spark SQL contributors so far.
We would also like to thank John Cieslewicz and the other members
of the F1 team at Google for early discussions on the Catalyst
optimizer. The work of authors Franklin and Kaftan was supported
in part by: NSF CISE Expeditions Award CCF-1139158, LBNL
Award 7076018, and DARPA XData Award FA8750-12-2-0331,
and gifts from Amazon Web Services, Google, SAP, The Thomas
and Stacey Siebel Foundation, Adatao, Adobe, Apple, Inc., Blue
Goji, Bosch, C3Energy, Cisco, Cray, Cloudera, EMC2, Ericsson,
Facebook, Guavus, Huawei, Informatica, Intel, Microsoft, NetApp,
Pivotal, Samsung, Schlumberger, Splunk, Virdata and VMware.

### 11 参考资料

`[1]` A. Abouzied, D. J. Abadi, and A. Silberschatz.
Invisible loading: Access-driven data transfer from raw files into database systems.
In EDBT, 2013.

`[2]` A. Alexandrov et al.
The Stratosphere platform for big data analytics.
The VLDB Journal, 23(6):939–964, Dec. 2014.

`[3]` AMPLab big data benchmark.
https://amplab.cs.berkeley.edu/benchmark.

`[4]` Apache Avro project.
http://avro.apache.org.

`[5]` Apache Parquet project.
http://parquet.incubator.apache.org.

`[6]` Apache Spark project.
http://spark.apache.org.

`[7]` M. Armbrust, N. Lanham, S. Tu, A. Fox, M. J. Franklin, and D. A. Patterson.
The case for PIQL: a performance insightful query language.
In SOCC, 2010.

`[8]` A. Behm et al.
Asterix: towards a scalable, semistructured data platform for evolving-world models.
Distributed and Parallel Databases, 29(3):185–216, 2011.

`[9]` G. J. Bex, F. Neven, and S. Vansummeren.
Inferring XML schema definitions from XML data.
In VLDB, 2007.

`[10]` BigDF project.
https://github.com/AyasdiOpenSource/bigdf.

`[11]` C. Chambers, A. Raniwala, F. Perry, S. Adams, R. R. Henry, R. Bradshaw, and N. Weizenbaum.
FlumeJava: Easy, efficient data-parallel pipelines.
In PLDI, 2010.

`[12]` J. Cohen, B. Dolan, M. Dunlap, J. Hellerstein, and C. Welton.
MAD skills: new analysis practices for big data.
VLDB, 2009.

`[13]` DDF project.
http://ddf.io.

`[14]` B. Emir, M. Odersky, and J. Williams.
Matching objects with patterns.
In ECOOP 2007 – Object-Oriented Programming, volume 4609 of LNCS, pages 273–298. Springer, 2007.

`[15]` J. E. Gonzalez, R. S. Xin, A. Dave, D. Crankshaw, M. J. Franklin, and I. Stoica.
GraphX: Graph processing in a distributed dataflow framework.
In OSDI, 2014.

`[16]` G. Graefe.
The Cascades framework for query optimization.
IEEE Data Engineering Bulletin, 18(3), 1995.

`[17]` G. Graefe and D. DeWitt.
The EXODUS optimizer generator.
In SIGMOD, 1987.

`[18]` J. Hegewald, F. Naumann, and M. Weis.
XStruct: efficient schema extraction from multiple and large XML documents.
In ICDE Workshops, 2006.

`[19]` Hive data definition language.
https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL.

`[20]` M. Isard and Y. Yu.
Distributed data-parallel computing using a high-level programming language.
In SIGMOD, 2009.

`[21]` Jackson JSON processor.
http://jackson.codehaus.org.

`[22]` Y. Klonatos, C. Koch, T. Rompf, and H. Chafi.
Building efficient query engines in a high-level language.
PVLDB, 7(10):853–864, 2014.

`[23]` M. Kornacker et al.
Impala: A modern, open-source SQL engine for Hadoop.
In CIDR, 2015.

`[24]` Y. Low et al.
Distributed GraphLab: a framework for machine learning and data mining in the cloud.
VLDB, 2012.

`[25]` S. Melnik et al.
Dremel: interactive analysis of web-scale datasets.
Proc. VLDB Endow., 3:330–339, Sept 2010.

`[26]` X. Meng, J. Bradley, E. Sparks, and S. Venkataraman.
ML pipelines: a new high-level API for MLlib.
https://databricks.com/blog/2015/01/07/ml-pipelines-a-newhigh-level-api-for-mllib.html.

`[27]` S. Nestorov, S. Abiteboul, and R. Motwani.
Extracting schema from semistructured data. In ICDM, 1998.

`[28]` F. A. Nothaft, M. Massie, T. Danford, Z. Zhang, U. Laserson, C. Yeksigian, J. Kottalam, A. Ahuja, J. Hammerbacher,
M. Linderman, M. J. Franklin, A. D. Joseph, and D. A. Patterson.
Rethinking data-intensive science using scalable analytics systems.
In SIGMOD, 2015.

`[29]` C. Olston, B. Reed, U. Srivastava, R. Kumar, and A. Tomkins.
Pig Latin: a not-so-foreign language for data processing.
In SIGMOD, 2008.

`[30]` pandas Python data analysis library.
http://pandas.pydata.org.

`[31]` A. Pavlo et al.
A comparison of approaches to large-scale data analysis.
In SIGMOD, 2009.

`[32]` R project for statistical computing.
http://www.r-project.org.

`[33]` scikit-learn: machine learning in Python.
http://scikit-learn.org.

`[34]` D. Shabalin, E. Burmako, and M. Odersky.
Quasiquotes for Scala, a technical report.
Technical Report 185242, École Polytechnique Fédérale de Lausanne, 2013.

`[35]` D. Tahara, T. Diamond, and D. J. Abadi. 
Sinew: A SQL system for multi-structured data.
In SIGMOD, 2014.

`[36]` A. Thusoo et al. Hive–a petabyte scale data warehouse using
Hadoop. In ICDE, 2010.

`[37]` P. Wadler.
Monads for functional programming.
In Advanced Functional Programming, pages 24–52. Springer, 1995.

`[38]` R. S. Xin, J. Rosen, M. Zaharia, M. J. Franklin, S. Shenker, and I. Stoica.
Shark: SQL and rich analytics at scale.
In SIGMOD, 2013.

`[39]` M. Zaharia et al. 
Resilient distributed datasets: a fault-tolerant abstraction for in-memory cluster computing.
In NSDI, 2012.

`[40]` K. Zeng et al.
G-OLA: Generalized online aggregation for interactive analysis on big data.
In SIGMOD, 2015.