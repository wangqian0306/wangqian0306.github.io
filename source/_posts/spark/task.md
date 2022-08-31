---
title: Spark 任务调度
date: 2022-07-13 22:26:13
tags:
- "Spark"
id: spark-task
no_word_count: true
no_toc: false
categories: Spark
---

## Spark 任务调度拆解

### 简介

Spark 的任务调度流程可以概括为下图：

![P8htZL.png](https://s6.jpg.cm/2022/08/30/P8htZL.png)

即在提交作业之后进行如下操作：

1. 通过给定的行动算子来进行任务(Job)划分
2. 通过 Shuffle 操作来划分阶段(Stage)
3. 通过每个阶段中最后一个 RDD 的分区数来确定任务(Task)的数量
4. 根据给定的任务调度器(TaskScheduler)来决定任务的调度方式，对任务进行排序
5. 根据指定的本地化级别将任务分发到 Worker 上

### 流程梳理



### 参考资料

[spark-dagscheduler](https://mallikarjuna_g.gitbooks.io/spark/content/spark-dagscheduler.html)

[Spark job submission breakdown](https://hxquangnhat.com/2015/04/03/arch-spark-job-submission-breakdown/)
