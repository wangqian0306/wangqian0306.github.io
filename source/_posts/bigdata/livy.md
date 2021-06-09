---
title: Livy 的基础使用
date: 2020-06-23 23:25:13
tags:
- "Spark"
- "Livy"
id: livy
no_word_count: true
no_toc: false
categories: 大数据
---

## Livy 基础介绍

Livy 是一个使用 REST API 调度 Spark 任务的组件。

## 安装及配置

对于 HDP 平台来说可以通过新增组件的方式进行安装。CDH 的话需要自行制作或者找到对应的 Parcel 包。

当然也可以通过直接在官网下载 tar 包的形式进行安装。

在安装之前需要配置如下环境变量：

|配置项|说明|
|:---:|:---:|
|SPARK_HOME|SPARK 安装路径|
|HADOOP_CONF_DIR|Hadoop 配置文件所在路径|

> 注：CDH 默认的 HADOOP_CONF_DIR 为 `/etc/alternatives/hadoop-conf`

在配置完环境变量之后需要配置 `livy.conf` 文件，具体配置项如下：

|配置项|说明|样例|
|:---:|:---:|:---:|
|livy.server.host|绑定域名|0.0.0.0|
|livy.server.port|绑定端口|8998|
|livy.spark.master|调度方案|yarn|
|livy.file.local-dir-whitelist|读取本地文件的白名单路径|/|
|livy.server.csrf-protection.enabled|CSRF 保护|false|

在配置完成后运行如下命令即可启动服务

```bash
./bin/livy-server start
```

> 注：服务启动的功能比较少，仅有 start stop status 三项可选。

## 使用方式

Livy 提供了 REST API 和 Java Client 两种方式进行调度：

- [REST](http://livy.incubator.apache.org/docs/latest/rest-api.html)
- [JAVA Client](http://livy.incubator.apache.org/docs/latest/programmatic-api.html)

## 注意事项

### 多文件依赖

对于多个文件的 Python 项目来说需要将代码打包成为 zip 包的方式来进行传输。

### REST API 时效性

Livy 在 REST API 中的运行数据是会被定时清除的，所以需要单独编码来实现日志和任务记录功能。
