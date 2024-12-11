---
title: MySQL 优化
date: 2024-12-09 22:12:59
tags: "MySQL"
id: mysql-optimization
no_word_count: true
no_toc: false
categories: MySQL
---

## MySQL 优化

### 简介

数据库性能取决于数据库中的几个因素 级别，例如 tables、queries 和 configuration settings。这些软件结构导致硬件级别产生不同的 CPU 指令和 I/O 操作，为了优化性能需要将操作数进可能缩减。在提高数据库性能时，首先需要试用设计上的基础规则和软件的指导手册，并采用时间所为评判工具来进行优化。想成为专家，可以更多地了解软件内部发生的事情， 并开始测量 CPU 周期和 I/O 操作等内容。

典型用户的目标是从其现有的软件和硬件配置中获得最佳数据库性能。高级用户寻找机会改进 MySQL 软件本身，或开发自己的存储引擎和硬件设备来扩展 MySQL 生态系统。在官方文档中针对优化方式进行了如下分类：

- 在数据库级别进行优化
- 在硬件级别进行优化
- 平衡可移植性和性能(略)

### 在数据库级别进行优化

从基础设计上进行优化是最主要的提升方向，具体项目如下：

- 表结构(tables structure)
- 索引(indexes)
- 存储引擎(storage engine)
- 行格式(row format)
- 锁策略(locking strategy)
- 缓存大小(memory areas used for caching)

在上述优化执行前可以先考虑通过优化 SQL 的角度来提升检索速度。

#### 优化 SQL 语句

在优化 SQL 时主要遵循的思路是：

- 利用索引
- 隔离并优化查询的任何部分
- 减少全表扫描
- 让优化器读取到最新的表结构
- 了解存储引擎的优化技术、索引技术和配置参数
- 调整 MySQL 缓存中关于内存区域的大小和配置
- 减少缓存的大小
- 处理锁的问题

> 注：由于此处内容过多且杂乱，此时暂不整理。如有需求请参照 [Optimizing SQL Statements](https://dev.mysql.com/doc/refman/8.0/en/statement-optimization.html)

#### 优化索引

大多数 MySQL 索引(PRIMARY KEY ,UNIQUE ,INDEX, FULLTEXT)存储在 B 树(B-Trees,统称，一般应该是 B+ 树)。例外： SPECIAL 类型的索引使用 R 树; MEMORY table 还支持哈希索引; InnoDB 对 FULLTEXT 索引使用倒排索引。

在索引使用上遵循如下规则：

- 如果有多列索引，检索时要从左往右进行索引拼接。
- 如果需要跨表，最好让链接列具有相同的数据类型和大小且如果是字符串需要相同的字符集。
- 如果是SPATIAL 索引需要指定 SRID(Spatial Reference System Identifier, 例如：EPSG:4326)。
- 在遇到非二进制数据时需要确保字段编码后长度小于 767 字节。

在检索时可以使用 Explain 语句查看检索方式，进行优化。

### 在硬件级别进行优化

任何数据库应用程序最终都会达到硬件限制，因为 数据库变得越来越繁忙。DBA 必须评估 可以调整应用程序或重新配置服务器 要避免这些 瓶颈，或者是否需要更多硬件资源。系统瓶颈通常来自以下来源：

- 磁盘查找(Disk seeks)
- 磁盘读取和写入(Disk reading and writing)
- CPU 周期(CPU cycles)
- 内存带宽(Memory bandwidth)

### 参考资料

[官方文档](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
