---
title: Spark 知识整理
date: 2022-07-06 22:26:13
tags:
- "Spark"
id: spark_init
no_word_count: true
no_toc: false
categories: Spark
---

## Spark 知识整理

### 简介

Apache Spark 是用于大规模数据处理的统一分析引擎。
它提供 Java、Scala、Python 和 R 中的高级 API，以及支持通用执行图(DAG)的优化引擎。

Spark 还支持一组丰富的高级工具，包括:

- 用于 SQL 和结构化数据处理的 Spark SQL 
- 用于 Pandas 工作负载的 Pandas API on Spark 
- 用于机器学习的 MLlib、用于图形处理的 GraphX
- 以及用于增量计算和流处理的结构化流(Spark Streaming)

而在部署模式上则分为：

- 独立部署
- Apache Mesos(已弃用)
- Hadoop Yarn
- Kubernetes

### 使用

#### 交互式

Spark 提供了 Scala 和 Python 两种语言的交互式命令行，可以使用如下命令开启交互式命令行：

- Scala

```bash
./bin/spark-shell
```

> 注：使用 `:help` 可以查看帮助，`:quit` 退出交互式命令行

- Python

```bash
./bin/pyspark
```

> 注：使用 `help()` 可以查看帮助，`exit()` 退出交互式命令行

在启动后会自动初始化 spark-session 对象，可以使用 `spark` 变量进行访问

#### 独立应用程序



### 参考资料

[官方文档](https://spark.apache.org/docs/latest/)
