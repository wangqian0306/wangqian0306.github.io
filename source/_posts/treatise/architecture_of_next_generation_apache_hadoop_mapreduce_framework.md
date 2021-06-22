---
title: Architecture of Next Generation Apache Hadoop MapReduce Framework 中文翻译版
date: 2021-06-22 22:26:13
tags:
- "论文"
- "Hadoop"
- "MapReduce"
- "YARN"
id: architecture_of_next_generation_apache_hadoop_mapreduce_framework
no_word_count: true
no_toc: false
categories: 大数据
---

## Architecture of Next Generation Apache Hadoop MapReduce Framework 中文翻译版

作者：

Arun C. Murthy, Chris Douglas, Mahadev Konar, Owen O’Malley, Sanjay Radia, Sharad Agarwal, Vinod K V

### 背景

Apache Hadoop Map-Reduce 框架显然已经过时了。
特别是依据观察到的集群大小和工作负载的相关趋势，Map-Reduce JobTracker 需要彻底改革以解决其内存消耗、优化线程模型，
解决可扩展性/可靠性/性能方面的几个技术缺陷。
虽然我们会定期进行维护。
但是在最近的一年我们发现，这些问题已经变成了基础性的问题并且随着规模的增长变得尤为严重。
即便是在 2007 年，这种架构性的缺陷和纠正措施都很古老而且很容易理解：

https://issues.apache.org/jira/browse/MAPREDUCE-278.

### 需求

当我们考虑改进 Hadoop Map-Reduce 框架的方法时，重要的是不要偏离原先的设计需求。
展望 2011 年及以后，Hadoop 客户对下一代 Map-Reduce 框架的最紧迫要求是：

- 可靠性
- 可用性
- 扩展性(由 10000 个节点和 200,000 个核心组成的集群)
- 向后兼容(确保用户的 Map-Reduce 应用程序可以在框架的下一版本中保持不变地运行。同时也意味着向前兼容。)
- 进化(给用户进行软件栈的全面升级)
- 可预测的延迟(用户的主要关注点)
- 集群利用率

次级的需求是：

- 支持 Map-Reduce 的替代编程范式
- 支持有限的、短期的服务

鉴于上述要求，很明显我们需要重新思考用于系统中的数据处理基础设施。

### 新一代的 MapReduce (MRv2/YARN)

MRv2 的基本思想是将 JobTracker 的两个主要功能(资源管理和作业调度/监控)拆分为单独的守护程序。
这个想法是通过拥有一个全局的 ResourceManager (RM) 和每个应用程序的 ApplicationMaster (AM) 来实现的。
一个应用程序要么是传统意义上的 MapReduce 作业中的单个作业，要么是作业的 DAG。
ResourceManager 和每个从属节点的 NodeManager (NM) 构成了数据计算框架。
ResourceManager 是在系统中的所有应用程序之间仲裁资源的最高机关。
每个应用程序的 ApplicationMaster 实际上是一个特定于框架的库，其任务是协商来自 ResourceManager 的资源并与 NodeManager 一起执行并监视任务。

ResourceManager 有两个主要组件：

- Scheduler (S)
- ApplicationsManager (ASM)

Scheduler 负责将资源分配给各种正在运行的应用程序，这些应用程序受到容量、队列等常见的限制。
Scheduler 只负责调度，它不去监视或跟踪应用程序的状态。
此外，它也不能保证由于应用程序故障或硬件故障而重新启动失败的任务。
Scheduler 根据应用程序的资源需求执行其调度功能；它是基于资源容器的抽象概念来实现的，它包含了内存、cpu、磁盘、网络等元素。

Scheduler 有一个可配置的策略插件，负责在不同的队列、应用程序等之间划分集群资源。
当前的 MapReduce Scheduler (如 CapacityScheduler 和 FairScheduler)就是例子。

ApplicationManager 负责接受作业提交，协商用于执行特定于应用程序的 ApplicationMaster 的第一个容器，
并提供用于在出现故障时重新启动 ApplicationMaster 容器的服务。

NodeManager 是每台机器的框架代理，负责启动应用程序的容器，监视它们的资源使用情况(cpu、内存、磁盘、网络)并向调度器报告。
每个应用程序的 ApplicationMaster 负责与 Scheduler 协商适当的资源容器，跟踪它们的状态并监视进度。

![YARN 架构](https://i.loli.net/2021/06/22/Ay2E3uTeqwlIhsL.png)

### YARN v1.0

在这一节中我们会描述第一版 YARN 的设计目标。

#### 需求

- 可靠性
- 可用性
- 扩展性(由 10000 个节点和 200,000 个核心组成的集群)
- 向后兼容(确保用户的 Map-Reduce 应用程序可以在框架的下一版本中保持不变地运行。同时也意味着向前兼容。)
- 进化(给用户进行软件栈的全面升级)
- 集群利用率

#### ResourceManager

ResourceManager 是在系统中的所有应用程序之间仲裁资源的最高机关。

##### 资源模型

YARN 1.0版中的 Scheduler 只对内存建模。
系统中的每个节点都被认为是由多个最小内存大小(比如 512 MB 或 1 GB)的容器组成的。
ApplicationMaster可 以请求任何容器作为最小内存大小的倍数。

最后，我们希望转向更通用的资源模型，但是，对于Yarn v1，我们提出了一个相当简单的模型：

资源模型完全基于内存(RAM)，每个节点都由离散的内存块组成。

与 Hadoop MapReduce 不同，集群没有切分到 Map slot 和 Reduce slot 。
每一块内存都是可替换的，这对集群的利用有着巨大的好处。
目前 Hadoop MapReduce 的一个众所周知的问题是，Reduce slot 受到限制，缺少可替换资源是一个严重的限制因素。

在应用程序中(通过 ApplicationMaster)可以请求跨越任意数量内存块的容器，也可以请求不同数量不同类型的容器。
ApplicationMaster 通常要求特定的主机/机架具有特定的容器功能。

##### 资源定位

ApplicationMaster 可以请求具有适当资源需求的容器，包括特定的机器。
它们还可以在每台机器上请求多个容器。
所有资源请求都受到应用程序、其队列等的容量限制。

ApplicationMaster 负责计算应用程序的资源需求，例如拆分 MapReduce 应用程序的输入，并将其转换为 Scheduler 可以理解的协议。
调度器理解的协议将是: <priority, (host, rack, *), memory, #containers>。

> 注释：<优先级，(主机，机架，*)，内存，#容器>

在 MapReduce 中，ApplicationMaster 接受拆分后的输入，
并向 ResourceManager 的 Scheduler 呈现一个在主机上设置了键的反转表，并限制其生命周期中所需的容器总数，但这一限制可能会发生更改。

下面是一个典型的 ApplicationMaster 中单个应用程序的资源获取请求：

|优先级|主机名|获取资源(内存/GB)|容器数量|
|:---:|:---:|:---:|:---:|
|1|h1001.company.com|1 GB|5|
|1|h1010.company.com|1 GB|3|
|1|h2031.company.com|1 GB|6|
|1|rack11|1 GB|8|
|1|rack45|1 GB|6|
|1|*|1 GB|14|
|2|*|2 GB|3|

Scheduler 将尝试为应用程序匹配适当的机器；如果特定机器不可用，它还可以在同一机架或不同机架上提供资源。
有时，由于集群的异常繁忙，ApplicationMaster 可能会收到不太合适的资源；然后，它可以通过将它们返回给 Scheduler 来拒绝它们，而不必占用资源。

与 Hadoop MapReduce 相比，一个非常重要的改进是不再将集群资源拆分为 Map slot 和 Reduce slot。
这对集群利用率有着巨大的影响，因为应用程序在这两种类型的 slot 上都不再是瓶颈。

> 注：异常的 ApplicationMaster 可能去请求超出需要的容器，Scheduler 使用应用程序限额、用户限额、队列限额等来保护集群不被滥用。

##### 利弊

该模型的主要优点是，对于每个应用程序来说，
在 ResourceManager 上进行调度所需的状态以及 ApplicationMaster 和 ResourceManager 之间传递的信息量来说，都是非常紧凑的。
这对于扩展 ResourceManager 至关重要。
在这个模型中，每个应用程序的信息量总是 O(集群大小)，在当前的 Hadoop MapReduce JobTracker 中，它是O(任务数)，而任务数可以是成百上千个。

计划资源模型的主要问题是，如上所述，在从拆分到主机/机架的转换过程中会丢失信息。
这种转换是单向的、不可撤销的，ResourceManager 对资源请求之间的关系没有概念，例如，如果将 h43 和 h32 分配给应用程序，则不需要 h46。

为了克服上述缺点并证明 Scheduler 未来的兼容性，我们提出了一个简单的扩展——
其思想是向 ApplicationMaster 添加一个互补的调度器组件，该组件在 ApplicationMaster 没有帮助/知识的情况下执行翻译，
ApplicationMaster 在没有翻译的情况下继续按照任务/拆分进行思考。
ApplicationMaster 中的这个调度程序组件与 Scheduler 协同工作，可以想象的是在未来移除这个组件，而不影响 ApplicationMaster 的任何实现。

#### 任务调度

Scheduler 聚合来自所有正在运行的应用程序的资源请求，以构建分配资源的全局计划。
然后，调度器基于特定于应用程序的约束(如适当的机器)和全局约束(如应用程序、队列、用户等的配额)来分配资源。

Scheduler 使用熟悉的容量和容量保证概念作为在竞争应用程序之间分配资源的策略。
调度算法是很简单的：

- 选择系统中最空闲的队列
- 选择队列中最高优先级的任务
- 给这个任务它需要的资源

#### Scheduler API

YARN 调度程序和 ApplicationMaster 之间只有一个 API：

```text
Response allocate (List<ResourceRequest> ask, List<Container> release)
```

AM 通过 ResourceRequests 列表(ask)请求特定的资源，并释放 Scheduler 分配的不必要的容器。

该响应包含新分配的容器的列表、自 AM 和 RM 之间的上一次交互以来完成的特定于应用程序的容器的状态，以及向应用程序指示可用的集群资源。
AM 可以使用容器状态来收集有关已完成容器的信息，并对失败等做出反应。
AM 可以使用空余资源来调整其未来的请求，例如，在 MapReduce 中 AM 可以使用此信息来安排 Map 和 Reduce，以避免死锁，
例如将其所有空间用于 Reduce 等。

#### 资源监控


