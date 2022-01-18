---
title: Flink DataSource
date: 2022-01-18 22:26:13
tags:
- "Flink"
id: flink_data_source
no_word_count: true
no_toc: false
categories: Flink
---

## Flink DataSource

### 简介

DataSource 即 Flink 读取数据的来源。因为 Flink 弃用了 DataSet API 所以本文只针对 DataStream API 进行说明。

在 DataStream API 中可以使用 StreamExecutionEnvironment.addSource(sourceFunction) 将 Data Source 附加到程序中。

StreamExecutionEnvironment 可以访问几个预定义的 DataSource：

- 基于文件：
  - readTextFile(path) 读取文本文件
  - readFile(fileInputFormat, path) 根据指定的文件输入格式读取文件
  - readFile(fileInputFormat, path, watchType, interval, pathFilter, typeInfo) 这是前两个内部调用的方法。它根据给定的 fileInputFormat 读取路径中的文件。根据提供的 watchType，此 DataSource 可以定期监视(每间隔 ms)新数据的路径(FileProcessingMode.PROCESS_CONTINUOUSLY)，或者处理当前路径中的数据并退出(FileProcessingMode.PROCESS_ONCE)。使用 pathFilter，用户可以进一步排除正在处理的文件。

> 注：
> 在底层，Flink 将文件读取过程拆分为两个子任务，即目录监控和数据读取。这些子任务中的每一个都由一个单独的实体实现。监控由单个非并行(并行度 = 1)的任务实现，而读取由并行运行的多个任务执行。后者的并行度等于作业并行度。单个监控任务的作用是扫描目录(定期或只扫描一次，视 watchType 情况而定)，找到要处理的文件，将它们进行分割，并将这些分片分配给下游阅读器。读取端是那些将读取实际数据的人。每个分片仅由一个读取端接收，而读取端可以一个接一个地读取多个分片。 
> 值得注意的是：
> 
> (1) 如果 watchType 设置为 FileProcessingMode.PROCESS_CONTINUOUSLY，则在修改文件时，将完全重新处理其内容。这可能会破坏 “exactly-once” 语义，因为在文件末尾附加数据将导致其所有内容被重新处理。
>
> (2) 如果 watchType 设置为FileProcessingMode.PROCESS_ONCE，则源扫描路径一次并退出，而不等待读者完成文件内容的读取。当然，读者将继续阅读，直到所有文件内容都被读取。关闭源会导致在该点之后不再有检查点。这可能会导致节点故障后恢复速度较慢，因为作业将从最后一个检查点继续读取。

- 基于 Socket：
  - socketTextStream 从 Socket 读取。元素可以用分隔符分隔。
- 基于集合：
  - fromCollection(Collection) 集合中的所有元素必须属于同一类型。
  - fromCollection(Iterator, Class) 从迭代器创建数据流。该类指定迭代器返回的元素的数据类型。
  - fromElements(T ...) 从给定的对象序列创建数据流。所有对象必须属于同一类型。
  - fromParallelCollection(SplittableIterator, Class) 从迭代器并行创建数据流。该类指定迭代器返回的元素的数据类型。
  - generateSequence(from, to) 并行生成给定区间内的数字序列。
- 自定义
  - addSource 附加一个新的 DataSource 函数。(例如各种 connector )

### 官方 connector 列表

|      类型      |                          名称                          | source | sink |
|:------------:|:----------------------------------------------------:|:------:|:----:|
|      捆绑      |                     Apache Kafka                     |   √    |  √   |
|      捆绑      |                   Apache Cassandra                   |        |  √   |
|      捆绑      |                Apache Kinesis Streams                |   √    |  √   |
|      捆绑      |                    Elasticsearch                     |        |  √   |
|      捆绑      |   FileSystem(Hadoop included)-Streaming only sink    |        |  √   |
|      捆绑      | FileSystem(Hadoop included)-Streaming and Batch sink |        |  √   |
|      捆绑      |                       RabbitMQ                       |   √    |  √   |
|      捆绑      |                    Google PubSub                     |   √    |  √   |
|      捆绑      |                    Hibrid Source                     |   √    |      |
|      捆绑      |                     Apache NiFi                      |   √    |  √   |
|      捆绑      |                    Apache Pulsar                     |   √    |      |
|      捆绑      |                Twitter Streaming API                 |   √    |      |
|      捆绑      |                         JDBC                         |        |  √   |
| Apache Bahir |                   Apache ActiveMQ                    |   √    |  √   |
| Apache Bahir |                     Apache Flume                     |        |  √   |
| Apache Bahir |                        Redis                         |        |  √   |
| Apache Bahir |                         Akka                         |        |  √   |
| Apache Bahir |                        Netty                         |   √    |  √   |

### 例程

- 读取文本文件

```text
DataStream<String> stream = env.readTextFile("file:///path/to/file or hdfs://host:port/file");
```

- 读取 Socket

```text
DataStream<String> stream = env.socketTextStream("localhost", 6666);
```

- 读取集合

```text
Collection<String> collection = new ArrayList<>();
collection.add("hello world");
DataStream<String> stream = env.fromCollection(collection);
```

- 读取 Kafka

```text
KafkaSource<String> source = KafkaSource.<String>builder()
                .setBootstrapServers("host:port")
                .setTopics("input-topic")
                .setGroupId("my-group")
                .setStartingOffsets(OffsetsInitializer.earliest())
                .setValueOnlyDeserializer(new SimpleStringSchema())
                .build();
DataStream<String> stream = env.fromSource(source, WatermarkStrategy.noWatermarks(), "Kafka Source");
```

### 参考资料

[官方文档(1.14 版本)](https://nightlies.apache.org/flink/flink-docs-release-1.14/)
