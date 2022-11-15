---
title: Hive CLI
date: 2021-01-13 22:26:13
tags:
- "Hive"
- "CDH"
id: hive-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## Hive CLI

### 简介

Hive 基本命令整理

### Hive 命令行梳理

- 查看数据库清单

```hiveql
show databases;
```

- 使用数据库

```hiveql
use <name>;
```

- 查看数据表清单

```hiveql
show tables;
```

- 创建表

```hiveql
CREATE TABLE page_view
(
    viewTime     INT,
    userid       BIGINT,
    page_url     STRING,
    referrer_url STRING,
    ip           STRING COMMENT 'IP Address of the User'
)
    COMMENT 'This is the page view table'
    PARTITIONED BY (dt STRING, country STRING)
    STORED AS SEQUENCEFILE;
```

- 查看表详情

```hiveql
DESCRIBE [EXTENDED] page_view;
```

- 

```hiveql

```
