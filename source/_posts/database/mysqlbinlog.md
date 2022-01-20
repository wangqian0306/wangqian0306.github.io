---
title: mysqlbinlog date: 2022-01-20 22:12:59 tags: "MySQL"
id: mysqlbinlog no_word_count: true no_toc: false categories: MySQL
---

## mysqlbinlog

### 简介

MySQL 的二进制日志 binlog 可以说是 MySQL 最重要的日志，它记录了所有的 DDL 和 DML 语句(除了数据查询语句select、show等)
，以事件形式记录，还包含语句所执行的消耗的时间，MySQL的二进制日志是事务安全型的。binlog 的主要目的是复制和恢复。

### 工具

MySQL 官方提供了 mysqlbinlog 命令行工具

```text
show binlog events in mysql-bin.<id> \G
```

```text
mysqlbinlog --no-defaults --database=health_business  --base64-output=decode-rows -v --start-datetime='2021-09-18 14:32:45' --stop-datetime='2021-09-18 14:32:47' mysql-bin.000010
```

```text
mysqlbinlog mysql-bin.<id> | mysql -u <user> -p<pass> -v
```

### 参考资料

[MySQL Binlog 介绍](https://blog.csdn.net/wwwdc1012/article/details/88373440)