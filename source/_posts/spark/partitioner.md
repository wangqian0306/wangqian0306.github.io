---
title: Spark Partitioner
date: 2022-07-19 22:26:13
tags:
- "Spark"
id: partitioner 
no_word_count: true
no_toc: false
categories: Spark
---

## Spark Partitioner

### 简介

Spark 中的数据可以被分区器(Partitioner)重新分配分区，解决数据倾斜等问题。

### 分区函数

Spark 内置了 HashPartitioner 和 RangePartitioner 两种分区器，并且用户可以编写一个 `Partitioner` 的子类完成自定义分区器。

#### HashPartitioner

HashPartitioner 为默认分区器

分区方式：

哈希取模，具体源码如下

```text
class HashPartitioner(partitions: Int) extends Partitioner {
  def numPartitions: Int = partitions

  def getPartition(key: Any): Int = key match {
    case null => 0
    case _ => Utils.nonNegativeMod(key.hashCode, numPartitions)
  }

  override def equals(other: Any): Boolean = other match {
    case h: HashPartitioner =>
      h.numPartitions == numPartitions
    case _ =>
      false
  }

  override def hashCode: Int = numPartitions
}
```

> 注：此方式可能导致数据偏移。

#### RangePartitioner

分区方式：

1. 根据父 RDD 的数据特征，确定子 RDD 分区的边界
2. 给定一个键值对数据，能够快速根据键值定位其所应该被分配的分区编号

> 注：通过水塘抽样算法确定边界数组，再根据 key 来获取所在的分区索引。具体实现细节参见源码。

### 自定义分区器

```text
class TestPartitioner(Partitions:Int) extends Partitioner {
    override def numPartitions: Int = Partitions
    override def getPartition(key: Any):Int = {
      val a = if (<xxx>) {
        1
      }else if (<xxx>){
        2
      }else{
        0
      }
      a
}
```

### 参考资料

[官方文档](https://spark.apache.org/docs/3.1.1/api/scala/org/apache/spark/Partitioner.html)

[Apache Spark 源码阅读](https://ihainan.gitbooks.io/spark-source-code/content/section1/partitioner.html)

[源码](https://github.com/apache/spark/blob/master/core/src/main/scala/org/apache/spark/Partitioner.scala)
