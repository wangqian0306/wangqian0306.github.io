---
title: Spark shuffle
date: 2021-06-02 22:13:13
tags: "Spark"
id: spark-shuffle
no_word_count: true
no_toc: false
categories: 大数据
---

## Spark shuffle

### 简介

Spark 的核心数据结构在计算过程中是保持不变的，这意味着它们在创建之后无法更改。
在实际的使用过程中我们需要将操作相关内容发送给 Spark 而这个过程被称为转换。
转换又分为两类：

- 窄依赖
- 宽依赖

区别宽窄依赖的方式是明确操作是否会对多个输出分区造成影响。
窄依赖仅仅会决定一个输出分区的转换，而宽依赖转换则相反。
通常宽依赖关系的转换经常被称为洗牌 (shuffle) 操作，它会在整个集群中执行互相交换分区数据的功能。

### 触发洗牌

#### 手动重新分区

在程序执行中可以手动将数据进行分区，这一操作同时也会触发洗牌。常用的方式如下：

- 获取分区信息

```text
// in Scala
df.rdd.getNumPartitions // 1
# in Python
df.rdd.getNumPartitions() # 1
```

- 手动重新分区

```text
// in Scala
df.repartition(5)
# in Python
df.repartition(5)
// in Scala
df.repartition(col("DEST_COUNTRY_NAME"))
# in Python
df.repartition(col("DEST_COUNTRY_NAME"))
// in Scala
df.repartition(5, col("DEST_COUNTRY_NAME"))
# in Python
df.repartition(5, col("DEST_COUNTRY_NAME"))
```

- 合并分区操作（不会全面洗牌，但是尝试合并分区）

```text
// in Scala
df.repartition(5, col("DEST_COUNTRY_NAME")).coalesce(2)
# in Python
df.repartition(5, col("DEST_COUNTRY_NAME")).coalesce(2)
```

#### 数据操作

- ByKey 操作(除了 counting)
- groupBy
- reduceByKey
- cogroup
- join

### 执行流程及逻辑

> 注：目前版本的 Spark 只使用 SortShuffleManager。

#### 官方说明

在基于排序的 shuffle 中，传入的记录根据其目标分区 ID 进行排序，然后写入单个输出文件。
Reducers 获取该文件的连续区域，以便读取它们需要的 Map 输出。
在 Map 输出数据太多而无法放入内存的情况下，输出的排序子集可以溢写到磁盘，
通过合并文件以生成最终输出文件。

基于排序的 shuffle 有两种不同的写入路径来生成其地图输出文件：

- 序列化排序：当以下三个条件都成立时使用：
  - shuffle 的依赖项指定没有 map-side combine。
  - shuffle 序列化器支持序列化值的重定位 (目前 KryoSerializer 和 Spark SQL 的自定义序列化器支持此功能)。
  - shuffle 产生少于或等于 16777216 个输出分区。
- 反序列化排序 (bypass)：用于处理所有其他情况。

##### 序列化排序方式

在序列化排序模式下，传入的记录一旦传递到 shuffle writer 就会马上被序列化并在排序的过程中进入缓冲。
这种方式有以下几项优化:

- 它的排序对序列化的二进制数据而不是 Java 对象进行操作，从而减少了内存消耗和 GC 开销。
  此优化要求记录序列化器具有某些属性，以允许对序列化的记录进行重新排序，而无需反序列化。
  有关更多详细信息，请参阅 [SPARK-4550](https://issues.apache.org/jira/browse/SPARK-4550)，该优化是首次提出并实施的。
- 它使用专门的缓存高效排序器 (`ShuffleExternalSorter`) 对压缩记录指针和分区 ID 的数组进行排序。
  通过在排序数组中每条记录仅使用 8 个字节的空间，这可以将更多的数组放入缓存中。
- 溢出合并过程对属于同一分区的序列化记录块进行操作，并且在合并期间不需要反序列化记录。
- 当溢写压缩编解码器支持压缩数据的连接时，溢写合并操作会简单的连接序列化和压缩的溢出分区以产生最终输出分区。

有关这些优化的更多详细信息，请参阅 [SPARK-7081](https://issues.apache.org/jira/browse/SPARK-7081)。

### 参考资料

[Spark Shuffle 概念及 shuffle 机制](https://zhuanlan.zhihu.com/p/70331869)

[Spark 中的 Spark Shuffle 详解](https://www.cnblogs.com/itboys/p/9226479.html)

[Spark Shuffle 管理器SortShuffleManager内核原理深入剖析](https://blog.csdn.net/shenshouniu/article/details/83870220)

[Spark The Definitive Guide](https://analyticsdata24.files.wordpress.com/2020/02/spark-the-definitive-guide40www.bigdatabugs.com_.pdf)
