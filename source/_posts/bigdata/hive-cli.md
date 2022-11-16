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

- 查看表分区

```hiveql
SHOW PARTITIONS page_view;
```

- 重命名表

```hiveql
ALTER TABLE old_table_name RENAME TO new_table_name;
```

- 重命名列

```hiveql
ALTER TABLE old_table_name REPLACE COLUMNS (col1 TYPE, ...);
```

- 新增列

```hiveql
ALTER TABLE tab1 ADD COLUMNS (c1 INT COMMENT 'a new int column', c2 STRING DEFAULT 'def val');
```

- 删除分区

```hiveql
ALTER TABLE pv_users DROP PARTITION (ds='2008-08-08')
```

- 从 HDFS 载入数据至 Hive

```hiveql
LOAD DATA INPATH '/tmp/test.txt' INTO TABLE page_view;
```

- 从 HDFS 导入数据至 Hive

```hiveql
IMPORT [[EXTERNAL] TABLE new_or_original_tablename [PARTITION (part_column="value"[, ...])]]
  FROM 'source_path'
  [LOCATION 'import_target_path']
```

- 从 Hive 导出数据至 HDFS

```hiveql
EXPORT TABLE page_view to '/page_view';
```

### 参考资料

[基本命令官方文档](https://cwiki.apache.org/confluence/display/Hive/Tutorial#Tutorial-Creating,Showing,Altering,andDroppingTables)

[导入导出官方文档](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+ImportExport)

[查询语句官方文档](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
