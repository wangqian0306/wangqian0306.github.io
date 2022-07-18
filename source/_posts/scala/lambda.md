---
title: lambda
date: 2022-07-18 22:43:13
tags:
- "Scala"
id: lambda
no_word_count: true
no_toc: false
categories: Scala
---

## Lambda 表达式

### 简介

在 Scala 中 Lambda 表达式还有一些特殊的用法。

### 样例

可以使用 `_` 代替唯一参数：

```scala
val ints = List(1, 2, 3)
val doubledIntsFull = ints.map(i => i * 2)
val doubledInts = ints.map(_ * 2)
```

可以直接传入函数：

```scala
val ints = List(1, 2, 3)
ints.foreach((i: Int) => println(i))
ints.foreach(println)
```

可以快速访问元组中的某个元素：

```scala
val tuplesList = List(("wq",1),("nice",2))
tuplesList.map(tuple => tuple._1).foreach(println)
tuplesList.map(_._1).foreach(println)
```

### 参考资料

[匿名函数](https://docs.scala-lang.org/scala3/book/fun-anonymous-functions.html#)