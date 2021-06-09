---
title: Sqoop 基础使用
date: 2020-06-24 22:13:13
tags: "Sqoop"
id: sqoop-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## Sqoop 版本说明

目前常见的 Sqoop 分成 1(1.4.7)和 2(1.99.7) 两个版本。

Sqoop2与1相比主要新增了 REST 接口，但是在导入数据的时候缺失了导入至 Hive 的重点功能。

> 注：目前主流的方案还是采用 Sqoop 1，所以本文也仅针对于 Sqoop1。

## 安装

在 CDH 和 HDP 集群中都可以通过新增组件的方式安装 Sqoop

## 命令梳理和技巧整理

### 基础命令样例

#### 导入单表

样例命令如下：

```bash
sqoop import --connect jdbc:mysql://localhost:3306/mysql --username mariadb --password mariadb --table user --target-dir /tmp/demo -m 1
```

#### 整库导入

```bash
sqoop import-all-tables --connect jdbc:mysql://localhost:3306/mysql --username mariadb --password mariadb
```

#### 增量导入

```
sqoop import --connect jdbc:mysql://localhost:3306/test --username mariadb --password mariadb --table demo --target-dir /tmp/demo --check-column id --incremental append --last-value 3 -m 1 
```

### 参数说明

参数说明：

|参数|说明|
|:---:|:---:|
|--connect|JDBC 链接字符串|
|--username|数据库用户名|
|--password|数据库链接密码|
|--table|导入表名|
|--target-dir|导入 HDFS 的路径|
|-m|Map 数量(最终生成的文件数)|
|--append|追加模式|
|--columns|导入列名(可以使用`"`包裹列名)|
|--delete-target-dir|如果目标路径存在则删除目标路径|
|--query|使用 SQL 查询获取数据|
|--hive-import|导入至 Hive|
|--hive-overwrite|重写 Hive 数据|
|--hive-database|Hive 数据库名|
|--hive-table|Hive 表名|
|--check-column|关键列,该列的类型不得为 CHAR / NCHAR / VARCHAR / VARNCHAR / LONGVARCHAR / LONGNVARCHAR|
|--incremental|增量导入模式，可选：append(递增追加),lastmodified(最新修改)|
|--last-value|上次导入的值|

### Sqoop 任务

可以使用任务的方式来免去输入 `last-value` 的值。

#### 创建任务

```bash
sqoop job --create demo -- import --connect jdbc:mysql://localhost:3306/mysql --username mariadb --password mariadb --table user --target-dir /tmp/demo -m 1
```

#### 列出任务

```bash
sqoop job --list
```

#### 查看任务配置

```bash
sqoop job --show demo
```

#### 运行任务

```bash
sqoop job --exec myjob -- --username demo --password demo
```

#### 删除任务

```bash
sqoop jon --delete demo
```

## 注意事项

- 在运行导入命令时需要切换至当前用户所属的路径，因为在命令的运行过程中会产生 表名.java 的表结构文件。
- Sqoop 所需的数据库链接 jar 包需要放置在 Hadoop 的 Classpath 下。