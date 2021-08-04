---
title: Neo4j 图数据库的基本使用
date: 2020-06-13 22:12:59
tags: "Neo4j"
id: neo4j
no_word_count: true
no_toc: false
categories: Neo4j
---

## 简介

Neo4j 是一款图数据库，相较于其他数据库可以轻松的查询数据之间的具体关系。在遇到复杂关系时使用 Neo4j 可以减少很多的工作量。

> 注：企业版本需要收费。但是目前官网有对初创公司的支持项目。

## 安装

请参照[官方文档](https://neo4j.com/docs/operations-manual/current/installation/linux/rpm/)

或者可以试试 Docker 版

```yaml
version: '3'
services:
  neo4j:
    image: neo4j:latest
    container_name: neo4j
    privileged: true
    restart: always
    ports:
    - "7474:7474"
    - "7687:7687"
```

## 配置文件说明

配置文件的具体位置请参见[配置文件位置表](https://neo4j.com/docs/operations-manual/current/configuration/file-locations/#table-file-locations)

|配置项|说明|
|:---:|:---:|
|dbms.directories.data=< path >|数据地址|
|dbms.directories.plugins=< path >|插件地址|
|dbms.directories.logs=< path >|日志地址|
|dbms.directories.import=< path >|文件导入地址(在实际使用时可以)|
|dbms.security.auth_enabled=< boolean >|鉴权开关|
|dbms.memory.heap.initial_size=< size >|初始内存分配大小|
|dbms.memory.heap.max_size=< size >|最大内存分配大小|
|dbms.connectors.default_listen_address=< ip >|默认监听地址|
|dbms.connector.http.enabled=< boolean >|web界面开关|
|dbms.connector.http.listen_address=< host >:< port >|界面地址和端口|

## 启动服务

在配置完成后可以使用如下命令操作 neo4j

- 启动服务
```bash
neo4j start
```

- 关闭服务
```bash
neo4j stop
```

- 查看服务状态
```bash
neo4j status
```

- 查看数据库版本
```bash
neo4j version
```

> 注: 如果是用 repo 进行安装的话还是可以使用 `systemctl` 命令进行配置的。

## 简单使用

在安装完成后可以访问 `http://<host>:7474` 来访问 Web UI。

在 Web UI 中有使用的具体示例，当然也可以访问 [官方文档](https://neo4j.com/docs/cypher-manual/4.0/clauses/)。

除了基本的查询语句之外还可以使用下面的命令来浏览一些支持性的内容

- 查看最近操作历史记录
```text
:history
```

- 查看索引信息
```text
:schema
```

- 播放引导提示
```text
:play start
```

- 查看系统状态
```text
:sysinfo
```

## CSV 数据导入

Neo4j 提供的导入方式有语句和导入命令两种，语句的使用更为灵活简便，所以此处仅对语句进行说明。

```bash
LOAD CSV FROM 'demo.csv' AS line FIELDTERMINATOR ';'
CREATE (:Artist {name: line[1], year: toInteger(line[2])})
```

> 注：在导入实际文件的时候需要将对应文件放置在 dbms.directories.import 配置项所设置的目录下。或者此处使用远程地址。

## 数据导出和恢复

由于备份功能为企业版专属，所以如果需要使用备份功能只可以关闭 Neo4j 服务，然后使用如下命令将数据导出成 dump 文件。

- 数据导出
```bash
neo4j-admin dump --database=neo4j --to=< filename >.dump
```

- 数据恢复
```bash
neo4j-admin load --from=< filename >.dump --database=neo4j --force
```

> 注：如果是版本是 3.x 的话需要使用的数据库是 graph.db

## 密码恢复

可以使用如下命令来进行密码重置，在登录 Web 界面之后使用默认密码 `neo4j`登录然后设定新密码即可。
```bash
neo4j-admin set-initial-password secret --require-password-change
```

## 与 SpringBoot 集成

坦率的讲 spring-data-neo4j 根本不好用。。。还是推荐使用官方的原生包。
