---
title: Flink Sink
date: 2022-02-09 22:26:13
tags:
- "Flink"
id: flink_sink
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Sink

### 简介

Sink 即 Flink 输出数据的方式。因为 Flink 弃用了 DataSet API 所以本文只针对 DataStream API 进行说明。

DataStream 类提供了如下的输出格式:

- 基于 Socket
  - writeToSocket() 将数据流写入 Socket
  - addSink() 调用自定义接收器功能。Flink 与其他系统(例如 Apache Kafka)的连接器捆绑在一起，这些连接器被实现为接收器功能。
  
在生产情况下建议采用 StreamingFileSink 来进行输出。

### StreamingFileSink

StreamingFileSink 支持逐行和批量编码格式，例如 Apache Parquet。这两个变体带有各自的构建器，可以使用以下静态方法创建：

- 行编码：StreamingFileSink.forRowFormat(basePath, rowEncoder)
- 批量编码：StreamingFileSink.forBulkFormat(basePath, bulkWriterFactory)

#### 行编码格式

行编码格式需要指定一个 Encoder 用于将各个行序列化为 OutputStream。

除了存储桶分配器之外，还RowFormatBuilder允许用户指定：

- 自定义 RollingPolicy：滚动策略以覆盖 DefaultRollingPolicy
- bucketCheckInterval (default = 1 min): 检查基于时间的滚动策略的毫秒间隔

样例如下：

```text
/* 指定source */
DataStream<String> stream = ...
/* 自定义滚动策略 */
DefaultRollingPolicy<String, String> rollPolicy = DefaultRollingPolicy.builder()
        .withRolloverInterval(TimeUnit.MINUTES.toMillis(2)) /* 每隔多长时间生成一个文件 */
        .withInactivityInterval(TimeUnit.MINUTES.toMillis(5)) /* 过去 5 分钟(默认是 60 秒)内没有收到新记录就滚动生成新文件 */
        .withMaxPartSize(128 * 1024 * 1024) /* 设置每个文件的最大大小(默认是 128 M) */
        .build();
/*输出文件的前、后缀配置*/
OutputFileConfig config = OutputFileConfig
        .builder()
        .withPartPrefix("prefix")
        .withPartSuffix(".txt")
        .build();

StreamingFileSink<String> streamingFileSink = StreamingFileSink
        /*forRowFormat指定文件的跟目录与文件写入编码方式，这里使用SimpleStringEncoder 以UTF-8字符串编码方式写入文件*/
        .forRowFormat(new Path("hdfs://localhost:8020/cache"), new SimpleStringEncoder<String>("UTF-8"))
        /*这里是采用默认的分桶策略DateTimeBucketAssigner，它基于时间的分配器，每小时产生一个桶，格式如下yyyy-MM-dd--HH*/
        .withBucketAssigner(new DateTimeBucketAssigner<>())
        /*设置上面指定的滚动策略*/
        .withRollingPolicy(rollPolicy)
        /*桶检查间隔，这里设置为1s*/
        .withBucketCheckInterval(1)
        /*指定输出文件的前、后缀*/
        .withOutputFileConfig(config)
        .build();
/*指定sink*/
stream.addSink(streamingFileSink);
```

#### 批量编码格式

批量编码格式指定了一个 BulkWriter.Factory 由BulkWriter 逻辑定义了如何添加和刷新元素，以及如何最终确定一批记录以进行进一步的编码。

Flink 提供了如下 BulkWriter Factory:

- ParquetWriterFactory
- AvroWriterFactory
- SequenceFileWriterFactory
- CompressWriterFactory
- OrcBulkWriterFactory

> 注：Bulk Formats 只能为 `OnCheckpointRollingPolicy` 在每个检查点生成。

样例如下(Hadoop SequenceFile)：

```xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-sequence-file</artifactId>
    <version>1.13.5</version>
</dependency>
```

```text
import org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink;
import org.apache.flink.configuration.GlobalConfiguration;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.SequenceFile;
import org.apache.hadoop.io.Text;
```

```text
DataStream<Tuple2<LongWritable, Text>> input = ...;
Configuration hadoopConf = HadoopUtils.getHadoopConfiguration(GlobalConfiguration.loadConfiguration());
final StreamingFileSink<Tuple2<LongWritable, Text>> sink = StreamingFileSink
  .forBulkFormat(
    outputBasePath,
    new SequenceFileWriterFactory<>(hadoopConf, LongWritable.class, Text.class))
	.build();

input.addSink(sink);
```

#### 写入 Kafka

```xml
<dependency>
    <groupId>org.apache.flink</groupId>
    <artifactId>flink-connector-kafka_2.11</artifactId>
    <version>1.14.3</version>
</dependency>
```

```text
DataStream<String> stream = ...
        
KafkaSink<String> sink = KafkaSink.<String>builder()
        .setBootstrapServers(brokers)
        .setRecordSerializer(KafkaRecordSerializationSchema.builder()
            .setTopic("topic-name")
            .setValueSerializationSchema(new SimpleStringSchema())
            .setDeliveryGuarantee(DeliveryGuarantee.AT_LEAST_ONCE)
            .build()
        )
        .build();
        
stream.sinkTo(sink);
```

### 参考资料

[Sink](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/overview/#anatomy-of-a-flink-program)

[StreamingFileSink](https://nightlies.apache.org/flink/flink-docs-release-1.13/docs/connectors/datastream/streamfile_sink/)

[StreamingFileSink相关特性及代码实战](https://blog.csdn.net/lujisen/article/details/105798504)
