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

### 参考资料

[官网](http://seatunnel.incubator.apache.org/)

[视频教程](https://www.bilibili.com/video/BV1Gr4y1J7Pw)
