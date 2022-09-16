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
- 由日志记录单元的数据流被称为 `ledger`
- 每个存储 `ledger` 的服务器被称为 `bookie`

BookKeeper 被设计为可靠且具有弹性以应对各种故障。Bookies 可能会崩溃、损坏数据或丢弃数据，但只要在 ensemble 中有足够多的 bookie 行为正确，整个服务就会正确运行。

每个 `entry` 包含了写入 `ledger` 的字节序列。每个条目都有以下字段：

|          列名           | Java 类型 |           描述            |
|:---------------------:|:-------:|:-----------------------:|
|    `Ledger number`    |  Long   | `entry` 写入的 `ledger` ID |
|    `Entry number`     |  Long   |       `entry` ID        |
| `Last confirmed (LC)` |  Long   |    最后一个 `entry` 的 ID    |
|        `Data`         | Byte[]  |           数据            |
| `Authentication code` | Byte[]  |         消息认证编号          |

每个 `ledger` 会按顺序存储 `entry` ,并且遵循以下规则：

- 序列化写入
- 至多写入一次

这代表了 `ledger` 的语义为只做追加。`entry` 写入之后就无法被修改。正当的写入顺序需要客户端负责。

每个 `bookie` 服务器存储 `ledgers` 的一些片段，它们是 BookKeeper 存储服务器的组成元素。
为了性能考虑对于给定 L `ledger` 来说都有一组 `bookie` 服务器负责存储。
当一些 `entrie` 写入 `ledger` 时，这些 `entrie` 会被分散存储到 `bookie` 组中(写入一个子组肯定比写入所有的服务器更好)。

### 数据存储

> 注：BookKeeper 收到了 HDFS NameNode 的启发。

目前 BookKeeper 使用 Zookeeper 存储元数据，例如：`ledger` 元数据，目前可用的 `bookie` 服务器，等等。

实际数据则按照日志结构进行存储，分为如下三种：

- `journals` 
- `entry logs`
- `index files`

#### Journals

一个 `journal file` 存储了 BookKeeper 的事务日志。在 `ledger` 更新发生之前，`bookie` 会确保此更新事务的相关描述会被写入一个暂未合规的存储中。一个新的 `journal file` 会在 `bookie` 启动或者旧的 `journal file` 文件大小达到设定阈值的时候创建。

#### Entry logs

`entry log file` 管理了 BookKeeper 客户端发送回来已经完成写入的 `entry`。来自不同 `ledger` 的 `entry` 会经过聚合然后顺序写入，而它们的 `offset` 会作为指针缓存在 `ledger`
 中来支持快速检索。

一个新的 `entry log file` 会在 `bookie` 启动或者旧的 `entry log file` 文件大小达到设定阈值的时候创建。
旧的 `entry log file` 一旦与 `ledger` 断开关联就会被垃圾回收线程收集。

#### Index files

`index file` 是为了每个 `ledger` 创建的，其中包含了文件头和一些固定长度的索引页，其中记录了 `entry log file` 中存储数据的 `offset`。

由于更新 `index file` 会引入随机磁盘I/O，因此 `index file` 由后台运行的同步线程进行延迟更新。这确保了更新的快速性能。在索引页被持久化到磁盘之前，它们被收集在 `ledger` 缓存中进行查找。

> 注：`ledger` 缓存页存储在内存池中，这可以让磁盘头调度更有效。

#### 写入顺序

当客户端指示 `bookie` 写入 `ledger` 一项 `entry` 时，会遵循如下步骤持久写入磁盘：

1. 写入 `entry log`
2. 将 `entry` 索引写入 `ledger` 缓存
3. 对应于此 `entry` 的写入事件会追加写入 `journal`
4. 返回响应至客户端

> 注: 出于性能原因，`entry log` 会缓存一些到本地内存中，然后批量的写入磁盘。当 `ledger` 缓存到足够的索引页就会将它们刷写至磁盘。

`ledger` 缓存页会在如下两种情况下写入 `index files`：

- `ledger` 缓存的内存达到阈值。没有空间存储新的缓存页了。旧的缓存页会被驱逐出缓存然后持久化到磁盘中。
- 一个后台同步线程会在周期性的运行负责将 `ledger` 缓存页刷写到 `index files`。

除了刷新 `ledger` 缓存页之外，此同步线程还负责滚动 `journal file` 并通过此方式防止 `journal file` 使用太多的磁盘空间。在同步线程中的数据刷写流程如下：

- 将 `LastLogMark` 记录在内存中。`LastLogMark` 表示了此 `entriy` 在持久化之前(存储到 `index file` 和 `entry log file`)的如下两种信息：
  1. `txnLogId`(`journal file` ID)
  2. `txnLogPos`(`journal` 的 `offset`)
- 旧的缓存页会从 `ledger` 缓存页刷写到 `index files` 并且 `entry log file` 也会被刷写，来确保所有缓存在 `entry log file` 的 `entry` 都被持久化在磁盘上。

> 注：理想情况下 `bookie` 只需要刷写索引页和 `entry log file` 其中先于 `LastLogMark` 的 `entry`。但是在 `ledger` 和 `entry log` 映射到 `journal files` 中的内容并没有这样的信息。因此，线程会在此处完全刷写 `ledger` 缓存和 `entry log`，并且可能会刷写 `LastLogMark` 之后的数据。不过，刷写更多数据没什么大问题，只是有些多余。

- 将 `LastLogMark` 持久化到磁盘，这可以让在 `LastLogMark` 之前的 `entry` 数据和索引页写入磁盘。这样可以让 ` journal file` 更安全的移除早于 `txnLogId` 的数据。

如果 `bookie` 在持久化 `LastLogMark` 之前故障了，它还是会有 `journal file` 其中存储了 索引页中可能没有持久化的 `entry`。因此，当 `bookie` 重启的时候，它会检查 `journal file` 并且重新存储这些 `entry`，数据不会丢失。

使用上述数据刷写机制，当 `bookie` 关闭时，同步线程跳过数据刷写是安全的。然而在 `entry logger` 中会使用缓存的频道(channel)批量写入数据，在关闭时它可能还缓冲了数据。 `bookie` 还需要确保在关闭期间 `entry log` 每次的刷写都是完成的。否则，`entry log file` 会因部分 `entry` 而损坏。

#### 数据压缩



### 参考资料

[官方文档](https://bookkeeper.apache.org)
