---
title: Flink Checkpoint Savepoint 
date: 2022-02-21 22:26:13
tags:
- "Flink"
id: flink_checkpoint_savepoint
no_word_count: true
no_toc: false
categories: Flink
---

## Flink Checkpoint Savepoint 

### 简介

在 Flink 中的关于存储的专业术语及解释如下：

- Snapshot(快照) 这是一个通用术语，指的是 Flink 作业状态的全局一致性镜像。快照包括指向每个数据源的指针(例如，文件或 Kafka 分区的偏移量)，以及来自每个作业的有状态操作符的状态副本，这些保存的内容中含有之前已经处理的结果和处理条目的指针。
- Checkpoint(检查点) Flink 为能够从故障中恢复而自动拍摄的快照。检查点可以是增量的，并针对快速恢复进行了优化。
- Externalized Checkpoint(外部检查点) 通常检查点不需要用户操作。Flink 在作业运行时仅保留最近的 n 个检查点，并在作业取消时删除它们。但是您可以将它们配置为保留，在这种情况下，您可以手动从它们恢复。
- Savepoint(保存点) 由用户处于某种目的触发的快照。使用场景可能是重新部署/升级/缩放操作。保存点始终是完整的，并且针对灵活性进行了优化。

**Checkpoint** Flink 定期对每个算子的所有状态进行持久化快照，并将这些快照复制到更持久的地方(例如分布式文件系统)。如果发生故障，Flink 可以恢复应用程序的完整状态并恢复处理程序，就好像没有出现任何问题一样。快照的存储位置就是通过 Checkpoint 机制进行指定的。

存储位置及优势如下：

- FileSystemCheckpointStorage(分布式文件系统存储)
  - 支持大量的 State 
  - 很高的可靠性
  - 建议在生产环境中使用
- JobManagerCheckpointStorage(JobManager JVM Heap 中存储)
  - 建议少量 State 的情况下在测试和实验环境中使用

**Savepoint** Savepoint 是流作业执行状态的一致镜像，通过 Flink 的检查点机制创建。您可以使用 Savepoint 来停止和恢复、fork 或更新您的 Flink 作业。

保存点由两部分组成：在稳定存储(例如 HDFS、S3 等)上包含(通常较大的)二进制文件的目录和(相对较小的)元数据文件。稳定存储上的文件代表作业执行状态图像的净数据。保存点的元数据文件(主要)包含指向稳定存储上所有文件的指针，这些文件是保存点的一部分，以相对路径的形式。


