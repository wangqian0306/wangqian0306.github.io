---
title: HBase 命令行整理
date: 2021-01-13 22:26:13
tags:
- "HBase"
- "CDH"
id: hbase-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## HBase 命令行整理

### 内部命令

- 查看用户名

```text
whoami
```

- 查看集群信息

```text
status
```

- 列出所有表

```text
list
```

- 建表

```text
create '<table>','<column_family_1>','<column_family_2>',...
```

> 注：
> 使用 SPLITS => ['10', '20', '30', '40'] 指定分片方式。
> 使用 {NUMREGIONS => 15, SPLITALGO => 'HexStringSplit'} 指定分片数量和分片依据。

- 插入或修改数据

```text
put '<table>','<row_key>','<column_family:column>','<value>'
```

- 列出所有数据

```text
scan '<table>','<column_family>'
```

- 读取数据

```text
get '<table>','<row_key>','<column_family>'
```

- 统计表中的数据量

```text
count '<table>'
```

> 注：如果数据量较大建议使用外部命令部分的统计功能

- 禁用并删除表

```text
disable '<table>'
drop '<table>'
```

### 外部命令

- 统计表行数

```bash
hbase org.apache.hadoop.hbase.mapreduce.RowCounter '<table>'
```
### 常见问题

#### Python 链接出现 TSocket read 0 bytes

进入 HBase Thrift Server 配置项当中，关闭如下配置项：

- `hbase.regionserver.thrift.compact`
- `hbase.regionserver.thrift.framed`

然后进入 HBase 配置项中，关闭如下配置项：

- `hbase.regionserver.thrift.http`
- `hbase.thrift.support.proxyuser`

### REGION_SERVER_COMPACTION_QUEUE

错误日志如下：

```text
The health test result for REGION_SERVER_COMPACTION_QUEUE has become disabled:
 Test disabled while the role is stopping:
  Test of whether the RegionServer's compaction queue is too full.
```

根因分析：

HBase 在数据写入时会先将数据写到内存中的 MemStore，然后再将数据刷写到磁盘的中。
每次 MemStore Flush 都会为每个列族创建一个 HFile，频繁的 Flush 就会创建大量的 HFile，并且会使得 HBase 在检索的时候需要读取大量的 HFile，较多的磁盘 IO 操作会降低数据的读性能。
而在此时写入的 StoreFile 数量增加，触发了 Compaction，将任务放入了队列中。所以想要解决此问题就要扩大 Compaction 队列的数量或者增加 MemStore Flush 的文件大小。

相关配置项如下：

```text
hbase.hregion.memstore.flush.size=256M
hbase.hregion.memstore.block.multiplier=8
hbase.hstore.compaction.min=10
hbase.hstore.compaction.max=20
hbase.hstore.blockingStoreFiles=50
```

### 参考资料

[官方文档](https://hbase.apache.org/book.html)

[HBase异常问题分析](https://www.modb.pro/db/42892)

[Hbase Compaction 队列数量较大分析(压缩队列、刷新队列）](https://blog.csdn.net/weixin_43214644/article/details/117601110)