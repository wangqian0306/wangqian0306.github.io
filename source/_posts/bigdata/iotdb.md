---
title: IoTDB 的初步搭建及基本使用
date: 2021-02-07 22:26:13
tags:
- "IoTDB"
id: iotdb
no_word_count: true
no_toc: false
categories: 大数据
---

## IoTDB 的初步搭建及基本使用

### 简介

Apache IoTDB（物联网数据库）是一体化收集、存储、管理与分析物联网时序数据的软件系统。

[官网地址](https://iotdb.apache.org/zh/)

### 安装

#### Docker 版

- 新建 `docker-compose.yaml` 文件，填入如下内容即可

```yaml
version: "3"
services:
  iotdb:
    image: "apache/iotdb:latest"
    volumes:
      - ./logs:/iotdb/logs
      - ./data:/iotdb/data
    ports:
      - 6667:6667
      - 31999:31999
      - 8181:8181
```

### 基础使用

使用如下命令可以进入交互式命令行：

```bash
start-cli.bat -h <host> -p <port> -u <user> -pw <password>
```

IoTDB 采用了类似于 SQL 的语句，常见内容如下：

|命令|作用|
|:---:|:---:|
|`SHOW STORAGE GROUP`|展示存储组|
|`SET STORAGE GROUP TO <user>.<group>`|切换或者创建组|
|`CREATE TIMESERIES <user>.<group>.<table> WITH DATATYPE=INT32,ENCODING=RLE;`|创建时间序列|
|`SHOW DEVICES`|显示所有用户的组？？|
|`SHOW TIMESERIES <user>.<group>`|查看用户组中所有的时间序列|
|`insert into root.demo(timestamp,s0) values(1,1);`|插入数据点|
|`SELECT * FROM root.demo`|检索数据|

### 代码编译

> 注： IoTDB 向 Hadoop 存储数据的软件包需要重新编译。

- 在官网下载源码包并解压
- 使用如下命令进行构建

```bash
mvn clean package -pl server,hadoop -am
```

- 构建完成后将 IoTData 的 Hadoop 模块中的 `hadoop-tsfile-0.10.0-jar-with-dependencies.jar` 拷贝至 `server/target/iotdb-server-<version>/lib` 下

#### 编译常见问题

##### maven 无法拉取依赖包

[ISSUE](https://issues.apache.org/jira/browse/IOTDB-1151)

解决方式：

- 从可执行软件包中获取 jar 包，然后手动将其拷贝至 `maven` 本地目录中

##### maven 无法拉取 thrift exe 库文件

- 进入源码中的 `thrift/target/tools` 目录，手动下载库文件

```bash
wget https://github.com/jt2594838/mvn-thrift-compiler/raw/master/thrift_0.12.0_0.13.0_linux.exe
```

- 重新编译

```bash
mvn package -pl server,hadoop -am
```
