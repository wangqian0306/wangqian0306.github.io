---
title: ksqlDB
date: 2022-12-09 22:43:13
tags:
- "Kafka"
- "ksqlDB"
id: ksqldb
no_word_count: true
no_toc: false
categories: 大数据
---

## ksqlDB

### 简介

ksqlDB 是专门为流处理应用程序构建的数据库。使用它的好处在于依赖项较少，仅仅需要 Kafka 且构建应用较为方便。

可以大致这样理解其关键元素：

- Stream：结构化的 kafka topic
- Table：物化视图(方便查询或存储中间结果)
- Source：数据源(Kafka Connect)
- Sink：数据输出(Kafka Connect)

> 注：Kafka Connect 可以嵌入 ksqlDB 与其一同部署，也可以独立部署。

### 部署和安装

#### Docker 方式

编写 `docker-compose.yaml`：

```yaml
# Docker compose from bringing up a local ksqlDB cluster and dependencies.
#
# By default, the cluster has two ksqlDB servers. You can scale the number of ksqlDB nodes in the
# cluster by using the docker `--scale` command line arg.
#
# e.g. for a 4 node cluster run:
# > docker-compose up --scale additional-ksqldb-server=3
#
# or a 1 node cluster run:
# > docker-compose up --scale additional-ksqldb-server=0
#
# The default is one `primary-ksqldb-server` and one `additional-ksqdb-server`. The only
# difference is that the primary node has a well-known port exposed so clients can connect, where
# as the additional nodes use auto-port assignment so that ports don't clash.
#
# If you wish to run with locally built ksqlDB docker images then:
#
# 1. Follow the steps in https://github.com/confluentinc/ksql/blob/master/ksqldb-docker/README.md
# to build a ksqlDB docker image with local changes.
#
# 2. Update .env file to use your local images by setting KSQL_IMAGE_BASE=placeholder/ and KSQL_VERSION=local.build.

---
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 32181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-enterprise-kafka:latest
    ports:
      - "29092:29092"
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:32181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 100

  schema-registry:
    image: confluentinc/cp-schema-registry:latest
    depends_on:
      - zookeeper
      - kafka
    environment:
      SCHEMA_REGISTRY_HOST_NAME: schema-registry
      SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS: PLAINTEXT://kafka:9092


  primary-ksqldb-server:
    image: confluentinc/ksqldb-server:latest
    hostname: primary-ksqldb-server
    container_name: primary-ksqldb-server
    depends_on:
      - kafka
      - schema-registry
    ports:
      - "8088:8088"
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8088
      KSQL_BOOTSTRAP_SERVERS: kafka:9092
      KSQL_KSQL_SCHEMA_REGISTRY_URL: http://schema-registry:8081
      KSQL_KSQL_LOGGING_PROCESSING_STREAM_AUTO_CREATE: "true"
      KSQL_KSQL_LOGGING_PROCESSING_TOPIC_AUTO_CREATE: "true"

  additional-ksqldb-server:
    image: confluentinc/ksqldb-server:latest
    hostname: additional-ksqldb-server
    depends_on:
      - primary-ksqldb-server
    ports:
      - "8090"
    environment:
      KSQL_LISTENERS: http://0.0.0.0:8090
      KSQL_BOOTSTRAP_SERVERS: kafka:9092
      KSQL_KSQL_SCHEMA_REGISTRY_URL: http://schema-registry:8081

  # Access the cli by running:
  # > docker-compose exec ksqldb-cli  ksql http://primary-ksqldb-server:8088
  ksqldb-cli:
    image: confluentinc/ksqldb-cli:latest
    container_name: ksqldb-cli
    depends_on:
      - primary-ksqldb-server
    entrypoint: /bin/sh
    tty: true
```

然后使用如下命令运行服务：

```bash
docker-compose up -d --scale additional-ksqldb-server=<num>
```

> 注：num 可以设置为 0。

使用如下命令可以进入交互式命令行：

```bash
docker-compose exec ksqldb-cli ksql http://primary-ksqldb-server:8088
```

### 基本命令

Topic 列表

```text
SHOW TOPICS;
```

Stream 列表：

```text
SHOW STREAMS;
```

Table 列表：

```text
SHOW TABLES;
```

显示详情：

```text
DESCRIBE <name>;
-- Describe <name> in detail:
DESCRIBE EXTENDED <name>;
```

查看 Topic 内容：

```text
PRINT '<topic_name>' FROM BEGINNING;
```

插入数据：

```text
INSERT INTO s1 (x, y, z) VALUES (0, 1, 2);
```

检索数据：

```text
SELECT SUBSTRING(str, 1, 10) FROM s1 EMIT CHANGES;
```

查看 Connector：

```text
SHOW CONNECTORS;
```

查看 Connector 详情：

```text
DESCRIBE CONNECTOR conn1;
```

创建 Source：

```text
CREATE SOURCE CONNECTOR jdbc_source WITH (
  'connector.class'          = 'io.confluent.connect.jdbc.JdbcSourceConnector',
  'connection.url'           = 'jdbc:postgresql://localhost:5432/postgres',
  'connection.user'          = 'user',
  'topic.prefix'             = 'jdbc_',
  'table.whitelist'          = 'include_this_table',
  'mode'                     = 'incrementing',
  'numeric.mapping'          = 'best_fit',
  'incrementing.column.name' = 'id',
  'key'                      = 'id');
```

创建 Sink：

```text
CREATE SINK CONNECTOR elasticsearch_sink WITH (
  'connector.class' = 'io.confluent.connect.elasticsearch.ElasticsearchSinkConnector',
  'key.converter'   = 'org.apache.kafka.connect.storage.StringConverter',
  'topics'          = 'send_these_topics_to_elasticsearch',
  'key.ignore'      = 'true',
  'schema.ignore'   = 'true',
  'type.name'       = '',
  'connection.url'  = 'http://localhost:9200');
```

终止持久查询：

```text
TERMINATE q1;
```

删除 Stream：

```text
DROP STREAM s1;
```

删除 Table:

```text
DROP TABLE t1;
```

### 参考资料

[官方文档](https://docs.ksqldb.io/en/latest)
