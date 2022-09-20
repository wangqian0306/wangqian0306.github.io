---
title: Flink Table API
date: 2022-09-20 22:26:13
tags:
- "Flink"
id: flink_table
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Table API

### 简介

Apache Flink 提供了两种处理关系型内容的 API，分别是 `Table API` 和 `SQL`。

### 样例

```scala
// for batch programs use ExecutionEnvironment instead of StreamExecutionEnvironment
val env = StreamExecutionEnvironment.getExecutionEnvironment

// create a TableEnvironment
val tableEnv = TableEnvironment.getTableEnvironment(env)

// register a Table
tableEnv.registerTable("table1", ...) // or
tableEnv.registerTableSource("table2", ...) // or
tableEnv.registerExternalCatalog("extCat", ...)

// register an output Table
tableEnv.registerTableSink("outputTable", ...);
// create a Table from a Table API query
val tapiResult = tableEnv.scan("table1").select(...)
// Create a Table from a SQL query
val sqlResult = tableEnv.sqlQuery("SELECT ... FROM table2 ...")

// emit a Table API result Table to a TableSink, same for SQL result
tapiResult.insertInto("outputTable")

// execute
env.execute()
```

### 参考资料

[Table API & SQL](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/dev/table/overview/)
