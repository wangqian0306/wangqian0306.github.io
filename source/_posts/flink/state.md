---
title: Flink State
date: 2022-02-17 22:26:13
tags:
- "Flink"
id: flink_state
no_word_count: true
no_toc: false
categories: Flink
---

## Flink State

### 简介

State 是指流计算过程中计算节点的中间计算结果或元数据属性，比如在 aggregation 过程中要在 state 中记录中间聚合结果，比如 Apache Kafka 作为数据源时候，我们也要记录已经读取记录的 offset，这些 State 数据在计算过程中会进行持久化(插入或更新)。所以Apache Flink中的State就是与时间相关的，Apache Flink任务的内部数据(计算数据和元数据属性)的快照。

Flink 内部按照算子和数据分组角度将 State 划分为如下两类：

- KeyedState 这里面的 key 是我们在 SQL 语句中对应的 GroupBy/PartitionBy 里面的字段，key 的值就是 GroupBy/PartitionBy 字段组成的 Row 的字节数组，每一个 key 都有一个属于自己的 State，key 与 key 之间的 State 是不可见的；
- OperatorState Flink 内部的 Source Connector 的实现中就会用 OperatorState 来记录 source 数据读取的 offset。

自带数据存储后端有如下两种：

- HashMapStateBackend
- EmbeddedRocksDBStateBackend

如果没有其他配置，系统将使用 HashMapStateBackend。

通常情况下应该采用 HashMapStateBackend 仅在处理大量 State，超大窗口及大量键值对 State 时应当选择 HashMapStateBackend。

### 配置

使用 HashMapStateBackend 可以进行如下配置

```text
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.setStateBackend(new HashMapStateBackend());
```

如果使用 EmbeddedRocksDBStateBackend 则需要额外引入如下包：

```xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-statebackend-rocksdb_2.11</artifactId>
    <version>1.14.3</version>
    <scope>provided</scope>
</dependency>
```

```text
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.setStateBackend(new EmbeddedRocksDBStateBackend());
```

### 参考资料


[state 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/state/)

[state_backends 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/ops/state/state_backends/)

[Apache Flink 漫谈系列(04) - State](https://developer.aliyun.com/article/667562?spm=a2c6h.13262185.0.0.60da7e18Eon9c4)