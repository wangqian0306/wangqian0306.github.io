---
title: mysqlbinlog 
date: 2022-01-20 22:12:59 
tags: "MySQL"
id: mysqlbinlog 
no_word_count: true 
no_toc: false 
categories: MySQL
---

## mysqlbinlog

### 简介

MySQL 的二进制日志 binlog 可以说是 MySQL 最重要的日志，它记录了所有的 DDL 和 DML 语句(除了数据查询语句select、show等)，以事件形式记录，还包含语句所执行的消耗的时间，MySQL的二进制日志是事务安全型的。binlog 的主要目的是复制和恢复。

每次 MySQL 启动都会默认生成一个新的 binlog 文件，所以如果在数据库启动过程中出现了问题可以使用原始的 binlog 文件进行数据恢复。

### 使用

#### 开启 binlog

在 my.cnf 配置文件中填写如下信息：

```text
server_id=1
log-bin= mysql-bin
```

之后重启集群即可。

#### 查询 binlog

可以在 MySQL 在交互式 mysql 命令行工具 和 mysqlbinlog 命令行工具中进行查询

##### mysql 命令

|                                       命令                                       |           说明            |
|:------------------------------------------------------------------------------:|:-----------------------:|
|                              `SHOW MASTER LOGS;`                               |        查看日志文件列表         |
|                             `SHOW MASTER STATUS;`                              | 查看 master 状态，即最新的日志文件信息 |
|                                 `FLUSH LOGS;`                                  |    刷新日志，并生成新编号的日志文件     |
|                                `RESET MASTER;`                                 |          清空日志           |
| `SHOW BINLOG EVENTS [IN 'log_name'] [FROM pos] [LIMIT [offset,] row_count] \G` |         查看日志细节          |

##### mysqlbinlog 命令

mysqlbinlog 工具的官方描述是：转储 MySQL 二进制日志，其格式可用于查看或传送到 MySQL 命令行客户端。

|                    常见参数                    |       作用       |
|:------------------------------------------:|:--------------:|
|             `--database=<db>`              |  显示指定数据库的相关操作  |
|            `--offset=<offset>`             |     跳过条目数      |
|                    `-s`                    |     使用简单格式     |
| `--start-datetime=<'yyyy-MM-dd HH:mm:ss'>` |     指定起始时间     |
| `--stop-datetime=<'yyyy-MM-dd HH:mm:ss'>`  |     指定结束时间     |
|             `--server-id=<id>`             | 显示指定服务器 ID 的数据 |

> 注：此工具需要读取 my.cnf 配置，如果跨设备使用需要关注服务器配置。

使用样例如下：

```text
mysqlbinlog --start-datetime='2021-09-18 14:34:34' mysql-bin.000010
```

### 使用 binlog 恢复数据

```text
mysqlbinlog <bin_path> | mysql -u <user> -p -v
```

### 参考资料

[MySQL 官方文档](https://dev.mysql.com/doc/refman/8.0/en/)

[MySQL Binlog 介绍](https://blog.csdn.net/wwwdc1012/article/details/88373440)
