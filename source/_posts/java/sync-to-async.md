---
title: 异步与同步的转化
date: 2022-03-22 21:05:12
tags:
- "JAVA"
id: sync-and-async
no_word_count: true
no_toc: false
categories: JAVA
---

## 异步转同步

### 简介

在实际的项目开发中经常会用到异步与同步的调用方式。这两种调用方式的区别如下：

- 同步调用：调用方在调用过程中，持续等待返回结果。
- 异步调用：调用方在调用过程中，不直接等待返回结果，而是执行其他任务，结果返回形式通常为回调函数。

本文会针对需要转化这两种请求方式的特殊需求进行初步分析。

### 异步转同步

在进行异步转同步调用的时候通常有如下方式

- wait 和 notify
- 条件锁
- Future 包
- CountDownLatch
- CyclicBarrier



