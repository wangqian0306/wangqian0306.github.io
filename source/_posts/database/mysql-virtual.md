---
title: MySQL 虚拟列
date: 2022-09-28 22:12:59
tags: "MySQL"
id: mysql-virtual
no_word_count: true
no_toc: false
categories: MySQL
---

## MySQL 虚拟列

### 简介

在创建表的时候 MySQL 还支持虚拟列。虚拟列的值是根据列定义中包含的表达式计算得出的。

### 使用方式

按照如下方式建表和查询即可：

```sql
CREATE TABLE triangle (
  sidea DOUBLE,
  sideb DOUBLE,
  sidec DOUBLE AS (SQRT(sidea * sidea + sideb * sideb))
);
INSERT INTO triangle (sidea, sideb) VALUES(1,1),(3,4),(6,8);
```

```sql
SELECT * FROM triangle;
```

```text
+-------+-------+--------------------+
| sidea | sideb | sidec              |
+-------+-------+--------------------+
|     1 |     1 | 1.4142135623730951 |
|     3 |     4 |                  5 |
|     6 |     8 |                 10 |
+-------+-------+--------------------+
```

虚拟列有以下语法：

```text
col_name data_type [GENERATED ALWAYS] AS (expr)
  [VIRTUAL | STORED] [NOT NULL | NULL]
  [UNIQUE [KEY]] [[PRIMARY] KEY]
  [COMMENT 'string']
```

其中的关键在于 `[VIRTUAL | STORED]` 选项：

- `VIRTUAL`：列值不存储，但在读取时，最终值在任何BEFORE 触发器之后计算。虚拟列不占用存储空间。InnoDB支持虚拟列的二级索引

- `STORED`：插入或更新行时，将计算和存储列值。存储的列需要存储空间，可以进行索引。

> 注：如果不进行声明默认会采用 `VIRTUAL` 方式。

虚拟列的表达式必须遵守以下规则：

- 必须使用使用文字、确定性内置函数和运算符。如果给定表中的相同数据，多次调用产生相同的结果，而不依赖于连接的用户，则函数是确定的。不确定且未通过此定义的函数示例：`CONNECTION_ID()`、`CURRENT_USER()`、`NOW()`。
- 不允许使用存储函数和可加载函数。
- 不允许使用存储过程和函数参数。
- 不允许使用变量（系统变量、用户定义变量和存储的程序局部变量）。
- 不允许子查询。
- 生成的列定义可以引用其他生成的列，但只能引用表定义中前面出现的列。生成的列定义可以引用表中的任何基（非生成的）列，无论其定义出现在前面还是后面。
- `AUTO_INCREMENT` 属性不能在生成的列定义中使用。
- `AUTO_INCREMENT` 列不能用作生成的列定义中的基列。
- 如果表达式求值导致错误或向函数提供不正确的输入，`CREATE TABLE` 语句将终止并返回错误，DDL 操作将被拒绝。

### 参考资料

[官方文档](https://dev.mysql.com/doc/refman/8.0/en/create-table-generated-columns.html)
