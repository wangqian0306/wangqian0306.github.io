---
title: Spark DataSet 和 DataFrame
date: 2022-07-14 22:26:13
tags:
- "Spark"
id: dataframe
no_word_count: true
no_toc: false
categories: Spark
---

## Spark DataSet 和 DataFrame

### 简介

DataSet 是一个分布式数据的集合。

DataFrame 则是按照列名进行整理后的 DataSet，在概念上更贴近于传统关系型数据库中的表或是 R/Python 中的 DataFrame 但在底层进行了更丰富的优化。

### 简单使用

#### 读取数据

从 parquet 导入 DataFrame

```scala
val usersDF = spark.read.load("examples/src/main/resources/users.parquet")
```

从 json 导入 DataFrame

```scala
val peopleDF = spark.read.format("json").load("examples/src/main/resources/people.json")
```

从 csv 导入 DataFrame

```scala
val peopleDFCsv = spark.read.format("csv")
  .option("sep", ";")
  .option("inferSchema", "true")
  .option("header", "true")
  .load("examples/src/main/resources/people.csv")
```

从 orc 导入 DataFrame

```scala
val parDF=spark.read.orc("/tmp/orc/data.orc/gender=M")
```

### 参考资料

[官方文档](https://spark.apache.org/docs/latest/sql-programming-guide.html)
