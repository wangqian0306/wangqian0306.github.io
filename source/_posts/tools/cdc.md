---
title: CDC 工具对比
date: 2021-11-01 23:09:32
tags:
- "CDC"
id: cdc
no_word_count: true
no_toc: false
categories: "工具"
---

## CDC 工具对比

### 简介

Change Data Capture (缩写为 CDC)—— 大概可以机翻为 “变动数据捕获”—— 你可以将它视为和数据库有关的架构设计模式的一种。它的核心思想是，监测并捕获数据库的变动（包括数据或数据表的插入，更新，删除等），将这些变更按发生的顺序完整记录下来，写入到消息中间件中以供其他服务进行订阅及消费。

目前市面上常见的处理方式大致分为如下三种：

1. 基于日志的解析模式；
2. 基于增量条件查询模式；
3. 数据源主动 Push 模式。

### 开源项目对比

|项目名|支持数据库|工作方式|
|:---:|:---:|:---:|
|Sqoop|JDBC 链接均可|增量条件查询|
|Kafka Connector JDBC|JDBC 链接均可|增量条件查询|
|Maxwell|MySQL|日志解析|
|Canal|MySQL|日志解析|
|DataBus|Oracle,MySQL|日志解析|
|Debezium|MySQL, MongoDB, Postgre SQL, Oracle, SQL Server, Cassandra, Vitess|日志解析|

### 参考资料

[Sqoop](https://sqoop.apache.org/)

[Kafka Connector JDBC](https://docs.confluent.io/kafka-connect-jdbc/current/index.html)

[Maxwell](https://maxwells-daemon.io/)

[Canal](https://github.com/alibaba/canal)

[DataBus](https://github.com/linkedin/databus)

[Debezium](https://debezium.io/)
