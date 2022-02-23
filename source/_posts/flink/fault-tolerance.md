---
title: Flink 容错
date: 2022-02-21 22:26:13
tags:
- "Flink"
id: flink_fault_tolerance
no_word_count: true
no_toc: false
categories: Flink
---

## Flink 容错

### 概念

在 Flink 中的关于容错的专业术语及解释如下：

- Snapshot(快照) 这是一个通用术语，指的是 Flink 作业状态的全局一致性镜像。快照包括指向每个数据源的指针(例如，文件或 Kafka 分区的偏移量)，以及来自每个作业的有状态操作符的状态副本，这些保存的内容中含有之前已经处理的结果和处理条目的指针。
- Checkpoint(检查点) Flink 为能够从故障中恢复而自动拍摄的快照。检查点可以是增量的，并针对快速恢复进行了优化。
- Externalized Checkpoint(外部检查点) 通常检查点不需要用户操作。Flink 在作业运行时仅保留最近的 n 个检查点，并在作业取消时删除它们。但是您可以将它们配置为保留，在这种情况下，您可以手动从它们恢复。
- Savepoint(保存点) 由用户处于某种目的触发的快照。使用场景可能是重新部署/升级/缩放操作。保存点始终是完整的，并且针对灵活性进行了优化。

在 Flink 中当检查点协调器(作业管理器的一部分)指示任务管理器开始检查点时，它会拿到所有的元数据的偏移量(offset) 并将编号后的保存点隔离屏障插入数据流中。
这些屏障(barriers)贯穿整个处理图，通过这一特点可以来判断每段流位相对于检查点的位置。

![数据流示意图](https://nightlies.apache.org/flink/flink-docs-release-1.14/fig/stream_barriers.svg)

如上图所示检查点 N 将包含每个操作的 State，而这些 State 是由屏障 N 之前的每个事件运算生成的，并且在此屏障之后没有任何事件。

当作业图中的每个操作收到这些屏障之一时，它会记录其状态。具有两个输入流(例如 CoProcessFunction)的运算符执行屏障对齐，以便快照将反映从两个输入流中消费事件所产生的状态，直到(但不超过)第二个屏障到来。

![屏障对齐](https://nightlies.apache.org/flink/flink-docs-release-1.14/fig/stream_aligning.svg)

Flink 的状态后端使用写时复制机制来允许流处理继续畅通无阻，同时对旧版本的状态进行异步快照。只有当快照被持久保存时，这些旧版本的 State 才会被垃圾回收机制收集。

### 关键元素介绍

**Checkpoint** Flink 定期对每个算子的所有状态进行持久化快照，并将这些快照复制到更持久的地方(例如分布式文件系统)。如果发生故障，Flink 可以恢复应用程序的完整状态并恢复处理程序，就好像没有出现任何问题一样。快照的存储位置就是通过 Checkpoint 机制进行指定的。

存储位置及优势如下：

- FileSystemCheckpointStorage(分布式文件系统存储)
  - 支持大量的 State 
  - 很高的可靠性
  - 建议在生产环境中使用
- JobManagerCheckpointStorage(JobManager JVM Heap 中存储)
  - 建议少量 State 的情况下在测试和实验环境中使用

**Savepoint** Savepoint 是流作业执行状态的一致镜像，通过 Flink 的检查点机制创建。您可以使用 Savepoint 来停止和恢复、fork 或更新您的 Flink 作业。

保存点由两部分组成：在稳定存储(例如 HDFS、S3 等)上包含(通常较大的)二进制文件的目录和(相对较小的)元数据文件。稳定存储上的文件代表作业执行状态镜像的数据。保存点的元数据文件(主要)包含指向稳定存储上所有文件的指针，这些文件以相对路径的形式作为保存点的一部分。

### 使用

#### Checkpoint

**存储** ：

- 可以在全局配置文件中声明 Checkpoint 的存储位置:

```text
state.checkpoints.dir: hdfs:///checkpoints/
```

- 也可以在代码中配置：

```text
env.getCheckpointConfig().setCheckpointStorage("hdfs:///checkpoints-data/");
```

**恢复** :

直接重启即可

#### Savepoint

**创建** :

- 手动在页面当中创建 Savepoint

- 使用命令行创建运行中程序的 Savepoint

```text
flink savepoint [OPTIONS] <Job ID> [<target directory>]
```

- 使用命令行创建保存点然后停止程序

```text
flink stop --savepointPath [:targetDirectory] :jobId
```

**使用** :

- 从 Savepoint 恢复运行

```text
flink run -s :savepointPath -n [:runArgs]
```

### 参考资料

[容错 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/learn-flink/fault_tolerance/)

[Checkpoint 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/ops/state/checkpoints/)

[Savepoint 官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/ops/state/savepoints/)
