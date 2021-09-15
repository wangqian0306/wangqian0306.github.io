---
title: Kafka CLI
date: 2020-06-09 22:43:13
tags:
- "Kafka"
- "Zookeeper"
  id: kafka-cli no_word_count: true no_toc: false categories: 大数据
---

## Kafka 相关命令梳理

### 容器化试用

编写 `docker-compose.yaml` 文件，然后输入如下内容

```yaml
version: "2"

services:
  zookeeper:
    image: docker.io/bitnami/zookeeper:3.7
    ports:
      - "2181:2181"
    volumes:
      - "zookeeper_data:/bitnami"
    environment:
      - ALLOW_ANONYMOUS_LOGIN=yes
  kafka:
    image: docker.io/bitnami/kafka:2
    ports:
      - "9092:9092"
    volumes:
      - "kafka_data:/bitnami"
    environment:
      - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
      - ALLOW_PLAINTEXT_LISTENER=yes
    depends_on:
      - zookeeper

volumes:
  zookeeper_data:
    driver: local
  kafka_data:
    driver: local
```

开启容器

```bash
docker-compose up -d
```

### kafka-topics.sh

参数解释:

|参数名|说明|
|:---:|:---:|
|`--alter`|增加主题分区数量(在已经使用的话题中永远不要增加新分区)|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--command-config <path>`|配置文件地址|
|`--config <name>=<value>`|配置项|
|`--create`|创建话题标识|
|`--delete`|删除话题标识|
|`--describe`|展示话题标识|
|`--list`|话题列表的标识|
|`--replication-factor <num>`|副本因子|
|`--partitions <num>`|数据分区|
|`--topic <name>`|话题名|

> 注：如果需要删除话题需要在 `server.properties` 配置文件中编辑 `delete.topic.enable=true` 配置项。在标记删除的话题停止使用后 Kafka 才会真正清除话题。

config 配置项目如下：

|参数名|说明|
|:---:|:---:|
|`cleanup.policy`|数据清理策略|
|`compression.type`|压缩类型|
|`delete.retention.ms`|删除时间周期|
|`file.delete.delay.ms`|文件删除延时|
|`flush.messages`|写入磁盘的消息数量|
|`flush.ms`|写入磁盘的时间间隔|
|`follower.replication.throttled.replicas`|应在从属节点端限制日志复制的副本列表|
|`index.interval.bytes`|索引间隔文件大小|
|`leader.replication.throttled.replicas`|应在领导节点端限制日志复制的副本列表|
|`max.compaction.lag.ms`|消息在日志中不符合压缩条件的最长时间|
|`max.message.bytes`|允许的最大记录批量大小|
|`message.format.version`|消息格式版本呢|
|`message.timestamp.difference.max.ms`|broker 接收消息时的时间戳与消息中指定的时间戳之间允许的最大差异|
|`message.timestamp.type`|消息时间戳的类型|
|`min.cleanable.dirty.ratio`|日志压缩频率|
|`min.compaction.lag.ms`|未压缩日志的保存时间|
|`min.insync.replicas`|最少的同步副本数(ack=-1)|
|`preallocate`|预分配磁盘文件|
|`retention.bytes`|保留文件大小|
|`retention.ms`|保留文件时间长度|
|`segment.bytes`|日志文件分片大小|

具体内容请参见官方手册。

### kafka-console-producer.sh

参数解释:

|参数名|说明|
|:---:|:---:|
|`--batch-size <num>`|发送缓冲区,默认为200|
|`--broker-list <kafka_host>:<kafka_port>,<kafka_host1>:<kafka_port1>`|kafka Broker|
|`--compression-codec`|数据压缩,可选 none,gzip,snappy,lz4,zstd 默认为 gzip|
|`--producer-property <name>=<value>`|配置项|
|`--producer.config <path>`|配置文件地址|
|`--topic <name>`|话题名|

### kafka-console-consumer.sh

参数解释:

|参数名|说明|
|:---:|:---:|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--consumer-property <name>=<value>`|配置项|
|`--consumer.config <path>`|配置文件地址|
|`--from-beginning`|从头开始消费|
|`--group <name>`|消费组|
|`--offset <offset>`|消费偏移量，可填入数字或者 earliest 和 latest，默认为 latest|
|`--partition`|分区|
|`--topic <name>`|话题名|

### kafka-reassign-partitions

参数解释:

|参数名|说明|
|:---:|:---:|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--topics-to-move-json-file <config_file>`|移动配置项|
|`--broker-list <broker_id>,<broker_id>`|目标设备 ID|
|`--generate`|依据配置文件生成分配计划|
|`--execute`|执行重新分配计划|
|`--verify`|检查分区计划是否成功|
|`--throttle`|限速大小(Byte)|

> 注：--execute 和 --verify 参数所采用的配置项是 --generate 参数生成的。

### 自动创建主题

默认情况下，Kafka 会在如下几种情形下自动创建主题：

- 当一个生产者开始往主题中写入消息时；
- 当一个消费者开始从出题读取消息时；
- 当任意一个客户端向主题发送元数据请求时。

### 如何选择分区数量

为主题选定分区数量并不是一件可有可无的事情，在进行数量选择时，需要考虑如下几个因素。

- 主题需要达到多大的吞吐量？例如，是希望每秒钟写入 1OO KB 还是 1GB?
- 从单个分区读取数据的最大吞吐量是多少？每个分区一般都会有一个消费者，如果你知道消费者将数据写入数据库的速度不会超过每秒 50 MB，那么你也该知道，从一个分区读取数据的吞吐量不需要超过每秒 50 MB。
- 可以通过类似的方法估算生产者向单个分区写入数据的吞吐量，不过生产者的速度一般比消费者快得多，所以最好为生产者多估算一些吞吐量。
- 每个 broker 包含的分区个数、可用的磁盘空间和网络带宽。
- 如果消息是按照不同的键采写入分区的，那么为已有的主题新增分区就会很困难。
- 单个 broker 对分区个数是有限制的，因为分区越多，占用的内存越多，完成首领选举需要的时间也越长。

根据经验，把分区的大小限制在 25 GB 以内可以得到比较理想的效果。

### 强制删除话题

在某些话题无法删除完成的时候可以直接操作 zookeeper 实现数据清除。

首先需要定位到数据存储路径，检查 `server.properties` 文件中的 `log.dirs` 配置项，然后记录下来。

然后使用如下命令进入 zookeeper

```bash
zookeeper-shell.sh <zookeeper_host>:<zookeeper_port>
```

然后使用下面的命令删除 zookeeper 数据

```bash
rmr /brokers/topics/<name>
```

如果之前已经设置过了 marked for deletion 则需要运行下面的语句

```bash
rmr /admin/delete_topics/<name>
```

然后在文件夹中删除真实的数据文件即可。

### Kafka Connect

Kafka Connect 是一款接收数据库记录到 Kafka (source)和从 Kafka 将数据写入数据库(sink)的工具。

使用样例如下：

![Kafka Connect](https://help-static-aliyun-doc.aliyuncs.com/assets/img/zh-CN/7219853951/p68623.png)
