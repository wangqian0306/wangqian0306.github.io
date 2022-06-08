---
title: SeaTunnel
date: 2022-06-06 22:26:13
tags:
- "SeaTunnel"
id: seatunnel
no_word_count: true
no_toc: false
categories: 大数据
---

## SeaTunnel

### 简介

SeaTunnel 是一个非常好用的超高性能分布式数据集成平台，支持海量数据的实时同步。

> 注：使用方式类似于 DataX 和 Logstash 可以读取多个源并将其进行处理之后存储到目标位置中，只不过其中的执行引擎可以是 Spark 或 Flink。而在数据处理方面目前还是建议使用 SQL

### 安装及配置

#### 安装

- 从官网下载软件包，进行解压。

#### 配置

> 注：SeaTunnel 默认运行需要指定本机中的 SPARK_HOME 或 FLINK_HOME 环境变量。

可以配置 `config/seatunnel-env.sh` 脚本来跳过环境变量。

### 样例

在 `config` 目录中有如下的样例：

- `flink.batch.conf.template`
- `flink.sql.conf.template`
- `flink.streaming.conf.template`
- `spark.batch.conf.template`
- `spark.streaming.conf.template`

> 注：每个插件都有自己的默认值，这些默认值需要到官网进行查询。

在 `bin` 目录中如下脚本：

- `start-seatunnel-flink.sh`
- `start-seatunnel-spark.sh`
- `start-seatunnel-sql.sh`

> 注：目前网站上仅存在 flink 和 spark 的使用说明，而 sql 脚本也是基于 flink 实现的。

运行方式：

- Spark 

```bash
./bin/start-seatunnel-spark.sh \
--master local[4] \
--deploy-mode client \
--config ./config/spark.streaming.conf.template
```

- Flink

```bash
./bin/start-seatunnel-flink.sh \
--config ./config/flink.streaming.conf.template
```

### 配置文件简介

一个基本的配置文件由以下几个部分组成：

```text
env {
    # 设置 Spark 或 Flink 的环境参数
}
source {
    # 声明数据源(此处可声明多个 Source 插件)
}
transform {
    # 数据处理(可以为空，但必须存在)
}
sink {
    # 声明数据输出
}
```

### 插件简介

所有插件都需要去官网查看支持的运行引擎和参数及默认值。除了每个插件自带的参数之外，每种类型的插件还存在共用的参数。

目前的情况是：

- 在 `source` 块中使用 `result_table_name` 标识输出。 
- 在 `transform` 块中使用 `source_table_name` 标识输入，`result_table_name` 标识输出。
- 在 `sink` 块中使用 `source_table_name` 标识输入。

> 注：SQL 无需标识输入参数。

### 参考资料

[官网](http://seatunnel.incubator.apache.org/)

[视频教程](https://www.bilibili.com/video/BV1Gr4y1J7Pw)
