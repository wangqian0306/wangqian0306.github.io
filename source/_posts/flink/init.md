---
title: Flink 执行环境
date: 2022-01-17 22:26:13
tags:
- "Flink"
id: flink_init
no_word_count: true
no_toc: false
categories: Flink
---

## Flink 执行环境

### 简介

![Flink 软件架构](https://i.loli.net/2021/07/12/2ZSgTGHPxYDrVUC.png)

在 Flink 架构中有两个核心 API：用于处理有限数据集(通常称为批处理)的 DataSet API，以及用于处理潜在无界数据流(通常称为流处理)的 DataStream API。

### DataSet API

在 Flink 源码中是这样描述：

ExecutionEnvironment 是执行程序的上下文。LocalEnvironment 将导致在当前 JVM 中执行，RemoteEnvironment 将导致在远程设置上执行。

该环境提供了控制作业执行(例如设置并行度)和与外界交互(访问数据)的方法。

请注意，执行环境需要强类型信息，用于所有执行的操作的输入和返回类型。这意味着环境需要知道操作的返回值是例如字符串和整数的元组。因为 Java 编译器丢弃了大部分泛型类型信息，所以大多数方法都尝试使用反射重新获取该信息。在某些情况下，可能需要手动将该信息提供给某些方法。

相关类如下：

- LocalEnvironment 本地模式执行
- RemoteEnvironment 提交到远程集群执行
- CollectionEnvironment 集合数据集模式执行
- OptimizerPlanEnvironment 不执行作业，仅创建优化的计划
- PreviewPlanEnvironment 提取预先优化的执行计划

在编写批处理程序时可以使用如下代码创建执行环境：

```text
ExecutionEnvironment.getExecutionEnvironment();
```

### DataStream API

在 Flink 源码中是这样描述：

StreamExecutionEnvironment 是执行流程序的上下文。

LocalStreamEnvironment 将导致在当前 JVM 中执行，RemoteStreamEnvironment 将导致在远程设置上执行。

该环境提供了控制作业执行(例如设置并行度或容错/检查点参数)以及与外部世界交互(数据访问)的方法。

相关类如下：

- LocalStreamEnvironment 本地模式执行
- RemoteStreamEnvironment 提交到远程集群执行
- StreamPlanEnvironment 执行计划

在编写流处理程序时可以使用如下代码创建执行环境：

```text
StreamExecutionEnvironment.getExecutionEnvironment();
```

### Table API

Table API 是构建在 Stream API 和 DataSet API 之上的 API。该 API 的核心概念是 Table 用作查询的输入和输出。

在 Flink 源码中是这样描述：

TabelEnvironment 是用于创建表和 SQL API 程序的基类、入口和核心上下文。

在编写流处理程序时可以使用如下代码创建执行环境：

```text
EnvironmentSettings settings = EnvironmentSettings
    .newInstance()
    .inStreamingMode()
    //.inBatchMode()
    .build();

TableEnvironment tEnv = TableEnvironment.create(settings);
```

或者可以从 StreamExecutionEnvironment 进行创建：

```text
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
StreamTableEnvironment tEnv = StreamTableEnvironment.create(env);
```

### 参考资料

[Flink 源码](https://github.com/apache/flink)

[Flink Environment 概览](https://blog.csdn.net/xiaohulunb/article/details/103030437)
