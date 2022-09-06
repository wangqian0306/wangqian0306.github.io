---
title: Spark DataSet 和 DataFrame
date: 2022-07-14 22:26:13
tags:
- "Spark"
id: dataframe
no_word_count: true
no_toc: false
categories: Spark
---

## Spark DataSet 和 DataFrame

### 简介

DataSet 是一个分布式数据的集合。

DataFrame 则是按照列名进行整理后的 DataSet，在概念上更贴近于传统关系型数据库中的表或是 R/Python 中的 DataFrame 但在底层进行了更丰富的优化。

### 简单使用

#### DataFrame

##### 读取数据

从 parquet 导入 DataFrame

```scala
val usersDF = spark.read.load("examples/src/main/resources/users.parquet")
```

从 json 导入 DataFrame

```scala
val peopleDF = spark.read.format("json").load("examples/src/main/resources/people.json")
```

从 csv 导入 DataFrame

```scala
val peopleDFCsv = spark.read.format("csv")
  .option("sep", ";")
  .option("inferSchema", "true")
  .option("header", "true")
  .load("examples/src/main/resources/people.csv")
```

从 orc 导入 DataFrame

```scala
val parDF=spark.read.orc("/tmp/orc/data.orc/gender=M")
```

从 rdd 导入 DataFrame

```scala
val rdd = spark.sparkContext.makeRDD(List(1,2,3))
```

从 DataSet 转为 DataFrame

```scala
val df = ds.toDF()
```

从 Hive 读取数据

```scala
val df = spark.read().table("person");
```

从 JDBC 读取数据

```scala
val jdbcDF = spark.read
  .format("jdbc")
  .option("url", "jdbc:postgresql:dbserver")
  .option("dbtable", "schema.tablename")
  .option("user", "username")
  .option("password", "password")
  .load()
```

##### 输出

写入 Parquet 

```scala
peopleDF.write.parquet("people.parquet")
```

写入 ORC 

```scala
usersDF.write.format("orc")
  .option("orc.bloom.filter.columns", "favorite_color")
  .option("orc.dictionary.key.threshold", "1.0")
  .option("orc.column.encoding.direct", "name")
  .save("users_with_options.orc")
```

写入 JSON

```scala
allDF.write.json("src/main/other_resources/all_json_file.json")
```

写入 CSV

```scala
df.write.format("csv").save("/tmp/spark_output/datacsv")
```

写入文本文件

```scala
df.write.text("output")
```

写入 Hive 表

```scala
df.write.mode(SaveMode.Overwrite).saveAsTable("hive_records")
```

写入 JDBC 链接的数据库

```scala
jdbcDF.write
  .format("jdbc")
  .option("url", "jdbc:postgresql:dbserver")
  .option("dbtable", "schema.tablename")
  .option("user", "username")
  .option("password", "password")
  .save()
```

写入 Avro 

```scala
df.write.format("avro").save("namesAndFavColors.avro")
```

#### DataSet

##### 从其他源转换

从集合创建

```scala
case class Person(name: String, age: Long)
val caseClassDS = Seq(Person("Andy", 32)).toDS()
caseClassDS.show()
```

从 DataFrame 创建

```scala
case class Person(name: String, age: Long)
val ds: DataSet[Person] = df.as[User]
```

从 RDD 创建

```scala
case class Person(name: String, age: Long)
val ds: DataSet[Person] = rdd.map => {
  case (name,age) => {
    Person(name,age)
  }
}.toDS()
```

### 参考资料

[官方文档](https://spark.apache.org/docs/latest/sql-programming-guide.html)

[样例教程](https://sparkbyexamples.com/)
