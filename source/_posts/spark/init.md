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

在启动后会自动初始化 spark-session 对象，可以使用 `spark` 变量进行访问。

#### 独立应用程序

对于 Java 和 Scala 这样的应用程序来说可以使用 maven 或 sbt 这样的包管理工具来制作可执行 jar 包，然后使用 `spark-submit` 命令提交即可。

Python 程序则需要打包成 zip 文件才能提交，详情请参照 [官方文档](https://spark.apache.org/docs/latest/api/python/user_guide/python_packaging.html) 。

### 关键对象说明

在 Spark 2.0 之前，SparkContext 是任何 Spark 应用程序的入口点，用于访问所有 Spark 功能，并且需要具有所有集群配置和参数的 SparkConf 来创建 SparkContext 对象，并在为其他交互创建特定的 SparkContext。
而现在有了 SparkSession 对象，它是这些不同 Context 对象的组合，在任何情况下都可以使用 SparkSession 对象访问 Spark 资源。

### 参考资料

[官方文档](https://spark.apache.org/docs/latest/)
