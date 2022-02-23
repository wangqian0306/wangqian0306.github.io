---
title: Flink Broadcast State
date: 2022-02-23 22:26:13
tags:
- "Flink"
id: flink_broadcast_state
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Broadcast State

### 简介

Broadcast State 意为将输入的内容广播至所有 Operator 中。在官方文档当中描述了这样的使用场景，输入流有以下两种：

1. 由颜色和形状组成的 KeyedStream 
2. 由规则组成的普通流

在程序运行时需要将这两种流 JOIN 起来，输出符合特定规则的统计结果。

### 实现



### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/broadcast_state/)