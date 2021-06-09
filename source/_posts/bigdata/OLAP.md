---
title: OLAP 引擎对比
date: 2020-07-21 21:06:58
tags:
- "OLAP"
- "Druid"
- "Kylin"
id: olap
no_word_count: true
no_toc: false
categories: 大数据
---

## 简述

数据处理大致可以分成两大类：

- 联机事务处理OLTP（on-line transaction processing）
- 联机分析处理OLAP（On-Line Analytical Processing)

通常来说

- 以支持业务处理为主要目的是`OLTP`型
- 以支持决策管理分析为主要目的是`OLAP`型

而 OLAP 基于实现方式细分可以分为以下三类：

- 关系OLAP-ROLAP(RelationalOLAP)
- 多维OLAP-MOLAP(MultidimensionalOLAP)
- 混合OLAP-HOLAP(HybridOLAP)

其中：

- ROLAP 依赖操作 DB 数据，通过 SQL 的 WHERE 条件实现传统的切片切块功能
- MOLAP 则是在开始的时候就将数据存在了多位数据集中
- HOLAP 则希望将二者结合起来获取更快的性能

样例产品如下：

ROLAP 有：Presto 和 Impala
MOLAP 有：Kylin 和 Druid

## Kylin

### 简介

Apache Kylin 是一个开源的、分布式的分析型数据仓库，提供Hadoop/Spark 之上的 SQL
查询接口及多维分析（OLAP）能力以支持超大规模数据，最初由 eBay 开发并贡献至开源社区。
它能在亚秒内查询巨大的表。

从存储结构上来说 Kylin 采用 Cube 的方式来存储数据，并将数据按照如下方式构建模型：

- 星型模型(star schema)
- 雪花模型(snowflake schema)

在 Cube 创建之后 Kylin 会将数据按照指定的模型进行聚合并将数据存储至 HBase 中。

### 数据源

Kylin 目前可以使用如下方式接入数据源：

- Hive
- Kafka
- JDBC

然后使用如下的方式来构建 Cube

- Hadoop MapReduce
- Spark
- Flink

### 特点

- 可以便捷的使用 SQL 查询数据
- 与分析工具结合很方便，例如 Tableau 和 Power BI
- 需要进行预计算

## Druid

Apache Druid 是一个开源的分布式数据存储组件。Druid 的核心设计结合了数据仓库，时间序
列数据库和搜索系统的思想，从而创建了一个统一的系统，可对各种用例进行实时分析。Druid
将这三个系统中的每个系统的关键特征合并到其接收层，存储格式，查询层和核心体系结构中。

Druid 采用了列式存储的方式，根据列的类型（字符串，数字等），将应用不同的压缩和编码方法
。Druid 还会根据列类型构建不同类型的索引。与搜索系统类似，Druid为字符串列构建反向索引
，以进行快速搜索和过滤。与时间序列数据库类似，Druid按时间对数据进行智能分区，以实现快  
速的面向时间的查询。

### 数据源

Druid 可以通过以下两种方式完成数据接入

#### 流式数据接入

- Kafka
- Amazon Kinesis

#### 批量数据接入

- 本地批处理
- Hadoop 集群数据接入

### 特点

- 便于查询具有时间成分的数据
- 不适合进行更新
