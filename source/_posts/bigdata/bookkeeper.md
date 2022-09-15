---
title: Apache BookKeeper
date: 2022-09-15 22:26:13
tags:
- "Pulsar"
- "BookKeeper"
id: bookkeeper
no_word_count: true
no_toc: false
categories: 大数据
---

## Apache BookKeeper

### 简介

BookKeeper 是一种服务，它提供日志条目流(记录)的持久存储在名为 `ledgers` 的序列中。BookKeeper 会将数据分布式的复制到多台设备中存储。

### 基本元素

在 BookKeeper 中：

- 每个日志记录单元被称为 `entry` 又名 `record`
- 由日志记录单元的数据流被称为 `ledgers`
- 每个存储 `ledgers` 的服务器被称为 `bookies`

BookKeeper 被设计为可靠且具有弹性以应对各种故障。Bookies 可能会崩溃、损坏数据或丢弃数据，但只要在 ensemble 中有足够多的 bookie 行为正确，整个服务就会正确运行。

每个 `entry` 包含了写入 `ledgers` 的字节序列。每个条目都有以下字段：

|          列名           | Java 类型 |           描述            |
|:---------------------:|:-------:|:-----------------------:|
|    `Ledger number`    |  Long   | `entry` 写入的 `ledger` ID |
|    `Entry number`     |  Long   |       `entry` ID        |
| `Last confirmed (LC)` |  Long   |    最后一个 `entry` 的 ID    |
|        `Data`         | Byte[]  |           数据            |
| `Authentication code` | Byte[]  |         消息认证编号          |

每个 `ledgers` 会按顺序存储 `entry` ,并且遵循以下规则：

- 序列化写入
- 至多写入一次

这代表了 `ledgers` 的语义为只做追加。`entry` 写入之后就无法被修改。正当的写入顺序需要客户端负责。

### 参考资料

[官方文档](https://bookkeeper.apache.org)
