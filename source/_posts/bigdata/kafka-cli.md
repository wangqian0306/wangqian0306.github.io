---
title: Kafka CLI
date: 2020-06-09 22:43:13
tags:
- "Kafka"
- "ZooKeeper"
id: kafka-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka 相关命令梳理

### 容器化试用

#### Confluent 版本

可以使用如下命令安装项目：

```bash
git clone https://github.com/sknop/kafka-docker-composer
cd kafka-docker-composer
pip3 install jinjia2
```

然后使用如下命令创建 `docker-compose` 文件：

- Zookeeper 版

```bash
python3 kafka_docker_composer.py -b 1 -z 1
```

- KRaft 版

```bash
python3 kafka_docker_composer.py --brokers 1 --controllers 1
```

开启容器

```bash
docker-compose up -d
```

#### 官方镜像版

编写 `docker-compose.yaml` 文件，然后输入如下内容

```yaml
services:
  broker:
    image: apache/kafka:latest
    container_name: broker
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://localhost:9092,CONTROLLER://localhost:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@localhost:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_NUM_PARTITIONS: 3
    ports:
      - "9092:9092"
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

### kafka-reassign-partitions.sh

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

### kafka-preferred-replica-election.sh

此工具使每个分区的领导权转移回“首选副本”，它可用于平衡服务器之间的领导权。

|参数名|说明|
|:---:|:---:|
|`--zookeeper <zk_host_1>:<zk_port_1>,<zk_host_2>:<zk_port_2>/<chroot>`| zookeeper 地址|
|`--path-to-json-file`|配置文件地址|

### kafka-consumer-groups.sh

此工具可以列出所有的消费组详情，删除位移(offset)，重置消费组位移。

消费组的重设策略如下：

|纬度|策略|含义| 
|:---:|:---:|:---:|
|位移维度|Earliest|最早|
|位移维度|Latest|当前最新|
|位移维度|Current|最新一次提交|
|位移维度|Specified-Offset|指定位移|
|位移维度|Shift-By-N|当前位移 +N|
|时间维度|DateTime|调整到大于给定时间的最小位移处|
|时间维度|Duration|调整到距离当前时间间隔的位移处|

|参数名|说明|
|:---:|:---:|
|`--all-topics`|管理所有话题|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--by-duration`| Duration 策略，格式为 `PnDTnHnMnS`|
|`--command-config <conf_path>`|配置文件地址|
|`--delete`|删除位移(将目标组以如下形式传递 `--group g1 --group g2`)|
|`--describe`|显示位移信息|
|`--dry-run`|展示运行之后的情况(支持参数 reset-offsets)|
|`--execute`|执行操作(支持参数 reset-offsets)|
|`--export`|导出到csv(支持参数 reset-offsets)|
|`--from-file <conf_path>`|将导入位移|
|`--group`|目标消费组|
|`--list`|列出消费组|
|`--members`|列出组成员|
|`--offsets`|查看位移|
|`--reset-offsets`|重置位移，可以配合试运行，执行操作，导出csv一起使用|
|`--shift-by <Long: N>`|Shift-By-N策略，移动 N 个|
|`--state`|显示状态|
|`--timeout <Long: timeout (ms)>`|超时时间，默认 5000|
|`--to-current`|Current 策略|
|`--to-datetime <String: datetime>`|DateTime 策略|
|`--to-earliest`|Earliest 策略|
|`--to-latest`|Latest 策略|
|`--to-offset <Long: offset>`|Specified-Offset 策略|
|`--topic <String: topic>`|目标主题，在“重置偏移量”时，可以使用以下格式指定分区：`topic1:0,1,2`，其中0,1,2是要包括在进程中的分区。|
|`--verbose`|提供详细信息|

### kafka-log-dirs.sh

查询各个 Broker 上的日志路径磁盘占用情况。

|参数名|说明|
|:---:|:---:|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--broker-list <String: Broker list>`|Broker 列表，样例如下 `0,1,2`|
|`--command-config <conf_path>`|配置文件地址|
|`--describe`|查看详情|
|`--topic-list <String: Topic list>`|话题列表，样例如下 `topic1,topic2,topic3`|

### kafka-consumer-perf-test.sh

消费者性能测试

### kafka-producer-pref-test.sh

生产者性能测试

### kafka-dump-log.sh

此工具有助于解析日志文件并将其内容转储到控制台，这对于调试看似损坏的日志段非常有用。

|参数名|说明|
|:---:|:---:|
|`--files <String: file1,file2,...>`|储存文件列表|
|`--max-message-size <Integer: size>`|最大消息长度|
|`--print-data-log`|同时打印至控制台|
|`--print-data-log`|不输出元数据|

### kafka-delete-records.sh

此工具有助于将给定分区的记录向下删除到指定的偏移量。

|参数名|说明|
|:---:|:---:|
|`--bootstrap-server <kafka_host>:<kafka_port>`|Kafka 地址及端口(必填)|
|`--command-config <conf_path>`|配置文件地址|
|`--offset-json-file <path>`|删除位移文件地址|

删除位移配置文件：

```json
{
  "partitions": [
    {
      "topic": "foo",
      "partition": 1,
      "offset": 1
    }
  ],
  "version": 1
}
```

### 存储消息(日志)片段

```bash
kafka-run-class.sh kafka.tools.DullplogSegllents --files 00000000000052368601.log --print-data-log
```

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
