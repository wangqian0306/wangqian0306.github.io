---
title: Flink Watermark
date: 2022-02-10 22:26:13
tags:
- "Flink"
id: flink_watermark
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Watermark

### 简介

Flink 中有三种不同的时间概念：

- 事件时间(event time)：EventTime 是事件在设备上产生时候携带的。在进入框架之前 EventTime 通常要嵌入到记录中，并且 EventTime 也可以从记录中提取出来。
- 摄取时间(ingestion time)：IngestionTime 是数据进入框架的时间，是在 Source Operator 中设置的。与 ProcessingTime 相比可以提供更可预测的结果，因为 IngestionTime 的时间戳比较稳定(在源处只记录一次)，同一数据在流经不同窗口操作时将使用相同的时间戳，而对于 ProcessingTime 同一数据在流经不同窗口算子会有不同的处理时间戳。
- 处理时间(processing time)：数据流入到具体某个算子时候相应的系统时间。ProcessingTime 有最好的性能和最低的延迟。但在分布式计算环境中 ProcessingTime 具有不确定性，相同数据流多次运行有可能产生不同的计算结果。

比如我们需要统计某天中的某个小时的股票最高价格时就会选择采用事件时间的机制进行聚合操作。
但是我们发现输入系统中的数据不是按序的，某些数据由于某种原因(如：网络原因，外部存储自身原因)产生了一些延迟。
此时 Watermark 机制就可以处理上述问题，Flink 将使用它来跟踪事件时间的进度。

### 实现方式

假设需要对数据进行排序，数据输入方式如下：

```text
4 2 7 11 9 15 12 13 17 14 21 24 22 19 23 ...
```

1. 首先拿到的数据是 4 但是并不能将其作为已排序流的第一个元素释放，因为它可能并不是起点。
2. 等待必须是有限的，加入获取到 2 之后如果持续等待则可能等不到 1。
3. 现在你需要一个策略在给定时间戳之后将数据进行输出，并防止更早的数据损害之前输出的结果。
4. 策略需要是可变的，将时间戳的间隔设短则可以经常拿到结果，设置的长则可以获得更精准的结果。

在 Flink 中 Watermark 实际上也是一种时间戳，并且这个时间戳会被 Source 或者自定义的 Watermark 生成器按照特定的方式编码为系统 Event，与普通的数据流 Event 一起流转至下游，而在下游的算子则会以此不断调整自己管理的 EventTime clock。
Flink 框架保证 Watermark 单调递增，算子接收到一个Watermark时候，框架知道不会再有任何小于该 Watermark 的时间戳的数据元素到来了，所以 Watermark 可以看做是告诉 Flink 框架数据流已经处理到什么位置(时间维度)的方式。

Watermark 的产生和 Flink 内部处理逻辑如下图所示:

![Watermark 的产生和 Flink 内部处理逻辑](https://s2.loli.net/2022/02/10/ASa1cG4vgtPHD6k.png)

### 产生方式

#### 使用 WatermarkStrategy

我们可以在应用程序中选择 Watermark 的生成位置：

1. 在数据源上生成
2. 在非源操作上生成

通常来说第一种方式更好，因为它允许 Source 利用 Watermark 逻辑中的分片/分区/拆分的相应信息。


在流中可以使用如下代码添加 WatermarkStrategy 

```text
DataStream<String> stream = ...
stream.assignTimestampsAndWatermarks(WatermarkStrategy<T> watermarkStrategy)
```

这种方式获取一个流并生成一个带有时间戳元素和水印的新流。如果原始流已经具有时间戳和/或 Watermark，则时间戳分配器会覆盖它们。

但是如果在一段时间内没有新的 Event 就会形成空闲输入或空闲源。在这种情况下 Watermark 会失效。需要采用如下代码：

```text
WatermarkStrategy
        .<Tuple2<Long, String>>forBoundedOutOfOrderness(Duration.ofSeconds(20))
        .withIdleness(Duration.ofMinutes(1));
```

#### 编写 WatermarkGenerators

```text

```

### 参考资料

[Streaming Analytics](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/learn-flink/streaming_analytics/)

[Apache Flink 漫谈系列(03) - Watermark](https://developer.aliyun.com/article/666056)

[Flink 的 Watermark 机制](https://www.cnblogs.com/rossiXYZ/p/12286407.html)

[The Dataflow Model: A Practical Approach to Balancing Correctness, Latency, and Cost in Massive-Scale, Unbounded, Out-of-Order Data Processing](https://research.google.com/pubs/archive/43864.pdf)