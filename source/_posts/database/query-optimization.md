---
title: 查询优化
date: 2025-05-09 22:12:59
tags: 
- "Database"
id: query-optimization
no_word_count: true
no_toc: false
categories: MySQL
---

## 查询优化

### 简介

刚刚看到 IBM 发了优化查询的逻辑，此处对此进行一些梳理，把之前和 MySQL 处看到的内容进行一些对比。

在优化的时候大概遵循的思路是先去做查询诊断然后针对性的进行优化。

### 诊断

使用 `explain` 查看查询的运行情况，重点关注以下参数：

- 查询条目数和返回条目数的大小，如果查询过大会导致时间过长或效率低下
- 在大量数据返回时警惕使用排序，排序会导致大量数据堆积在内存中
- 全表扫描

在优化时主要的目标是对下面的关键要素进行分解：

- 运行时长
- 消耗的资源量(RAM,CPU)
- 处理数据的条目数

### 处置办法

1. 优化语法
    - 尽早过滤条目数
    - 简化 JOIN
2. 建立索引
3. 创建数据分区
4. 重新构建数据结构
5. 使用并行计算工具

### 参考资料

[Optimize SQL Queries for AI, Performance, & Real-Time Insights](https://www.youtube.com/watch?v=watwW4Hwyyw)