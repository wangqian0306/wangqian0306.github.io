---
title: Hue 的配置
date: 2020-12-03 22:26:13
tags:
- "CDH"
- "Hue"
id: hue
no_word_count: true
no_toc: false
categories: 大数据
---

## Hue 的配置

### 常见问题

#### Hue 无法访问 HBase

Hue 访问 HBase 异常 `TSocket read 0 bytes `

此问题需要修改 HBase 的配置项

- 进入 HBase 配置页
- 筛选 HBase Thrift Server 服务
- 关闭 `hbase.regionserver.thrift.compact` 和 `hbase.regionserver.thrift.framed`
- 搜索 `xml`
- 新增如下配置项

```xml
<property>
    <name>hbase.table.sanity.checks</name>
    <value>false</value>
</property>
```
- 重新启动服务
