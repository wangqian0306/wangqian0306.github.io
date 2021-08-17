---
title: Kafka CLI
date: 2020-06-09 22:43:13
tags:
- "Kafka"
- "Zookeeper"
id: zookeeper
no_word_count: true
no_toc: false
categories: 大数据
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
|`--alter`|增加主题分区数量|
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

## 强制删除话题

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