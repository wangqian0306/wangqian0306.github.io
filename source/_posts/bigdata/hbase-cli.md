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