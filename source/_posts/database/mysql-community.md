---
title: MySQL
date: 2021-08-04 22:12:59
tags: "MySQL"
id: mysql
no_word_count: true
no_toc: false
categories: MySQL
---

## MySQL

### 单机安装

访问 [Yum Repository](https://dev.mysql.com/downloads/repo/yum/) 下载仓库包，然后进行安装：

```bash
yum localinstall mysql80-community-release-el7-3.noarch.rpm
yum install mysql-community-server
```

或者直接使用 yum 安装 Source distribution 版本 ：

```bash
yum install mysql mysql-server -y
```

启动服务：

```bash
systemctl enable mysqld --now
```

检查临时密码(社区版)

```bash
grep 'temporary password' /var/log/mysqld.log
```

进行登录(社区版)

```bash
mysql -u root -p
```

更新 ROOT 用户密码

```bash
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
```

创建用户并赋予用户指定库的访问权限：

```bash
CREATE USER 'rbfish'@'%' IDENTIFIED BY 'Rbfish123..';
GRANT ALL PRIVILEGES ON *.* TO 'rbfish'@'%';
FLUSH PRIVILEGES;
```

开放用户远程访问：

```sql
USE mysql;
UPDATE USER SET host = '%' WHERE user = '<user>';
FLUSH PRIVILEGES;
```

创建数据库：

```sql
CREATE DATABASE `<name>` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

> 注：本文以 RockyLinux 7 为例，详情参照 [官方文档](https://dev.mysql.com/doc/mysql-linuxunix-excerpt/8.4/en/linux-installation.html)，记得进入页面后切换至当前版本。

### 容器化安装

```bash
services:
  db:
    image: mysql:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: test
    volumes:
      - "<data-dir>:/var/lib/mysql"
      - "<initsql-dir>:/docker-entrypoint-initdb.d"
    ports:
      - "3306:3306"
```

> 注：详细配置信息请参照 [DockerHub 文档](https://registry.hub.docker.com/_/mysql)或官方文档。

### 存储引擎

#### InnoDB

在 InnoDB 中的数据结构分为以下两个部分：

- 内存
- 磁盘

![InnoDB 架构](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-architecture-8-0.png)

##### 内存架构

在内存中的数据类型有以下四种：

- `Buffer Pool` ：缓冲池是主内存中的一个区域，用于 InnoDB 在访问数据时缓存表和索引数据。缓冲池允许直接从内存访问常用数据，从而加快处理速度。

![Buffer Pool](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-buffer-pool-list.png)

> 注：在 Buffer Pool 中采用 LRU 算法来逐出最近最少使用的页。

- `Change Buffer` ：更改缓冲区是一种特殊的数据结构，二级索引不在缓冲池中时，它会缓存对这些页所做的更改，并在稍后通过其他读取操作将页加载到缓冲池中时进行合并。

![Change Buffer](https://dev.mysql.com/doc/refman/8.0/en/images/innodb-change-buffer.png)

- `Adaptive Hash Index` ：自适应哈希索引是基于经常访问的索引页中键的前缀构建的，用于加速用户的查询操作。

- `Log Buffer` ：日志缓冲区是保存要写入磁盘上日志文件的数据的内存区域。日志缓冲区的内容会定期刷写到磁盘。大型日志缓冲区可以使大型事务能够运行，而无需在事务提交之前将重做日志数据写入磁盘。

##### 磁盘架构

在磁盘中的数据类型有以下六种：

- `Tables`
  - idb 文件：表结构，索引，数据等
  - cfg 文件：元数据文件，例如锁和加密信息
  - cfp 文件：密钥文件
- `Indexes`
  - 聚簇索引：每个表都有一个 InnoDB 称为聚簇索引的特殊索引，用于存储行数据。通常，聚簇索引与主键同义。
  - 二级索引：聚集索引以外的索引称为二级索引。在 InnoDB 中，二级索引中的每条记录都包含行的主键列，以及为二级索引指定的列。
- `Tablespaces`
  - `The Systsem Tablespace` ：系统表空间是更改缓冲区的存储区域。如果表是在系统表空间中创建的，而不是在每个表的文件或常规表空间中创建的，则它还可能包含表和索引数据。
  - `File-Per-Table Tablespaces` ：独占表空间包含单个表的数据和索引，并存储在文件系统上的单个 InnoDB 数据文件中。
  - `General Tablespaces` ：通用表空间是使用 CREATE TABLESPACE 语法创建的共享 InnoDB 表空间。由于共享所以消耗的空间会稍小。
  - `Undo Tablespaces` ：撤消表空间包含撤消日志，撤消日志是记录的集合，其中包含有关如何撤消事务对聚集索引记录的最新更改的信息。
  - `Temporary Tablespaces`
    - `Session Temporary Tablespaces` ：会话临时表空间存储用户创建的临时表和优化程序在配置为磁盘上内部临时表的存储引擎时 InnoDB 创建的内部临时表。
    - `Global Temporary Tablespace` ：全局临时表空间存储对用户创建的临时表所做的更改的回滚段。
- `Doublewrite Buffer` ：双重写入缓冲区是一个存储区域，用于在将页面写入 InnoDB 数据文件中的适当位置之前， InnoDB 从缓冲池中刷新的页面。如果在页面写入过程中出现操作系统、存储子系统或意外的 mysqld 进程退出， InnoDB 则可以在崩溃恢复期间从双重写入缓冲区中找到页面的良好副本。
- `Redo Log` ：重做日志是一种基于磁盘的数据结构，用于在崩溃恢复期间更正不完整事务写入的数据。
- `Undo Logs` ：撤消日志是与单个读写事务关联的撤消日志记录的集合。撤消日志记录包含有关如何撤消事务对聚集索引记录的最新更改的信息。如果另一个事务需要查看原始数据作为一致读取操作的一部分，则会从撤消日志记录中检索未修改的数据。撤消日志存在于撤消日志段中，这些日志段包含在回滚段中。回滚段驻留在撤消表空间和全局临时表空间中。

### 常见问题

#### Too many connestions

可以使用如下 SQL 查看当前的连接数：

```sql
SHOW VARIABLES LIKE 'max_connections';
```

使用如下 SQL 可以临时设置连接数：

```sql
SET GLOBAL max_connections = 200;
```

> 注：SQL 方式只可以配置单次，重启之后会失效。

最好还是修改配置文件：

```text
[mysqld]
max_connections=xxx
```

此外还需要注意 Linux 中的 ulimit 大小：

获取当前 ulimit :

```bash
ulimit -n 
```

设置 ulimit ：

```bash
sudo ulimit -n <number>
```

相关配置参见 [MySQL 官方文档](https://dev.mysql.com/doc/refman/8.3/en/server-system-variables.html#sysvar_open_files_limit)

#### 字符集与排序方式

为了解决中文和表情符号等特殊内容的存储建议采用 `utf8mb4` 字符集，而对于排序方式来说 MySQL 5 和 8 的默认排序方式则是不同的：

- MySQL 5 采用了 `utf8mb4_general_ci`
- MySQL 8 采用了 `utf8mb4_0900_ai_ci`(MySQL 5 并不支持)

如果需要兼容的情况可以选择采用 `utf8mb4_general_ci` 排序方式，具体详细内容请参阅 [官方文档](https://dev.mysql.com/doc/refman/8.0/en/charset.html)。

在排序方式中有很多的缩写，这些缩写有如下含义：

- `ci` 表示不区分大小写
- `ai` 指的是口音不敏感，也就是说不区分 `e`，`è`，`é`，`ê` 和 `ë`

### 参考资料

[MySQL 官方文档](https://dev.mysql.com/doc/refman/8.0/en/)
