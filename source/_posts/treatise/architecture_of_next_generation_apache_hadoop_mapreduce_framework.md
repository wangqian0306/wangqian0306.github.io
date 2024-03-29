---
title: Architecture of Next Generation Apache Hadoop MapReduce Framework 中文翻译版
date: 2021-06-22 22:26:13
tags:
- "论文"
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

##### Scheduler 

Scheduler 聚合来自所有正在运行的应用程序的资源请求，以构建分配资源的全局计划。
然后，调度器基于特定于应用程序的约束(如适当的机器)和全局约束(如应用程序、队列、用户等的配额)来分配资源。

Scheduler 使用熟悉的容量和容量保证概念作为在竞争应用程序之间分配资源的策略。
调度算法是很简单的：

- 选择系统中最空闲的队列
- 选择队列中最高优先级的任务
- 给这个任务它需要的资源

##### Scheduler API

YARN 调度程序和 ApplicationMaster 之间只有一个 API：

```text
Response allocate (List<ResourceRequest> ask, List<Container> release)
```

AM 通过 ResourceRequests 列表(ask)请求特定的资源，并释放 Scheduler 分配的不必要的容器。

该响应包含新分配的容器的列表、自 AM 和 RM 之间的上一次交互以来完成的特定于应用程序的容器的状态，以及向应用程序指示可用的集群资源。
AM 可以使用容器状态来收集有关已完成容器的信息，并对失败等做出反应。
AM 可以使用空余资源来调整其未来的请求，例如，在 MapReduce 中 AM 可以使用此信息来安排 Map 和 Reduce，以避免死锁，
例如将其所有空间用于 Reduce 等。

##### 资源监控

Scheduler 从 NodeManagers 接收有关已分配资源的资源使用情况的定期信息。
Scheduler 还向 ApplicationMaster 提供已完成容器的状态。

##### 程序提交

应用程序遵循下面的提交流程：

- 用户(通常来自网关)向 ApplicationsManager 提交作业。
  - 客户端首先得到一个新的 Application ID
  - 打包应用相关内容，上传至 HDFS 中的 `${user}/.staging/${application_id}`
  - 提交程序至 ApplicationsManager
- ApplicationsManager 接受用户发出的程序申请
- ApplicationsManager 与 Scheduler 协商，申请所需的 slot 并启动 ApplicationMaster
- ApplicationsManager 还负责向客户端提供正在运行的 ApplicationMaster 的详细信息，用于监控应用程序进度等。

##### ApplicationMaster 的生命周期

ApplicationsManager 负责管理系统中所有应用程序的 ApplicationMaster 的生命周期。

如应用程序提交部分所述，ApplicationsManager 负责启动 ApplicationMaster。

之后 ApplicationsManager 会监控 ApplicationMaster 发送周期性的心跳，并负责确保其运行状态，在失败时重新启动 ApplicationMaster 等。

##### ApplicationsManager 的组件

如前几节所述，ApplicationsManager 的主要职责是管理 ApplicationMaster 的生命周期。

为了实现这一需求，ApplicationsManager 具有以下组件：

- SchedulerNegotiator ——负责与 Scheduler 协调用于 AM 的容器
- AMContainerManager ——通过 NodeManager 启动和停止 AM 的容器
- AMMonitor ——负责管理 AM 的运行状态并负责在必要时重新启动 AM 

##### 可用性

ResourceManager 将其状态存储在 ZooKeeper 中以确保其高可用。
依靠 ZooKeeper 中保存的状态可以快速重启。
有关更多详细信息，请参阅 YARN 可用性部分。

#### NodeManager

一旦 Scheduler 将容器分配给应用程序，每台机器的 NodeManager 负责启动应用程序的容器。
NodeManager 还负责确保分配的容器不超额使用其在机器上分配的资源。

NodeManager 还负责为任务设置容器的环境。
这包括二进制文件、jar 文件等。

NodeManager 还提供了一个简单的服务来管理节点上的本地存储。
即使应用程序在节点上没有分配到活动，也可以使用本地存储。
例如 MapReduce 应用程序使用此服务来存储临时的 Map 任务输出并将它们 shuffle 到 Reduce 任务。

#### ApplicationMaster

ApplicationMaster 是每个应用程序的 master，负责协商来自 Scheduler 的资源，与 NodeManager 一起在适当的容器中运行字任务并监控任务。
它通过向 Scheduler 请求备用资源来对容器故障作出反应。

ApplicationMaster 负责计算应用程序的资源需求，例如拆分 MapReduce 应用程序的输入，并将其转换为 Scheduler 可以理解的协议。
ApplicationsManager 仅在失败时重新启动 AM；AM 负责从保存的持久状态中恢复应用程序。
当然，AM 也可以从一开始就运行应用程序。

#### 在 YARN 上运行 MapReduce 任务

本节介绍用于通过 YARN 运行 Hadoop MapReduce 作业的各种组件。

##### MapReduce ApplicationMaster

Map-Reduce ApplicationMaster 是 MapReduce 特定类型的 ApplicationMaster，负责管理 MR 作业。

MR AM 的主要职责是从 ResourceManager 获取适当的资源，在分配的容器上调度任务，监控正在运行的任务并管理 MR 作业的生命周期直至完成。
MR AM 的另一个职责是将作业的状态保存到持久存储中，以便在 AM 本身发生故障时可以恢复 MR 作业。

该提议是在 MR AM 中使用基于事件的有限状态机(FSM)来管理 MR 任务和作业的生命周期和恢复。
这允许将 MR 作业的状态自然表达为 FSM，并允许可维护性和可观察性。

下图显示了 MR 作业、任务和任务尝试的 FSM：

![YARN Job State Machine, 20110328](https://i.loli.net/2021/06/23/J3cHeo6TkuKrbZ7.png)

![State Transition Dragram fro MR Job](https://i.loli.net/2021/06/23/Y6UyndWfzrVegx5.png)

> 注：此处原文截图本来就不清晰。。。基本没法看

在 YARN 中运行的 MapReduce 作业的生命周期应当是这样的：

- Hadoop MR JobClient 将作业提交给 YARN ResourceManager (ApplicationsManager) 而不是 Hadoop MapReduce JobTracker。
- YARN ASM 与 Scheduler 协商 MR AM 的容器，然后为作业启动 MR AM。
- MR AM 启动并注册到 ASM。
- Hadoop MapReduce JobClient 轮询 ASM 以获取有关 MR AM 的信息，然后直接与 AM 通信获取状态、计数器等。
- MR AM 将输入数据进行拆分并将所有映射构建成 YARN Scheduler 的资源请求。
- MR AM 为作业运行 Hadoop MR OutputCommitter 的必要作业设置 API。
- MR AM 将 Map/Reduce 任务的资源请求提交给 YARN Scheduler，从 RM 中获取容器，并通过与每个容器的 NodeManager 协同工作，
  在对应容器上调度适当的任务。
- MR AM 监控单个任务的完成情况，如果任何任务失败或停止响应，则请求备用资源。
- MR AM 还会使用应用程序清理 Hadoop MR OutputCommitter 已完成的任务。
- 一旦整个一次 Map 和 Reduce 任务完成，MR AM 就会提交相应任务或者终止相应任务的 Hadoop MR OutputCommitter 的API
- 作业完成只有 MR AM 也会终止。

MapReduce ApplicationMaster 具有以下组件：

- Event Dispatcher ——作为协调器的中央组件，为下面的其他组件生成事件。
- ContainerAllocator ——该组件负责将任务的资源需求转换为 YARN Scheduler 可以理解的资源请求，并与 RM 协商资源。
- ClientService ——负责使用作业状态、计数器、进度等响应 Hadoop MapReduce JobClient 的组件。
- TaskListener ——从 Map/Reduce 任务接收心跳。
- TaskUmbilical ——负责接收心跳和更新 Map Reduce 任务的组件
- ContainerLauncher ——负责通过适当的 NodeManager 来启动容器的组件。
- JobHistoryEventHandler ——将作业历史事件写入 HDFS。
- Job ——负责维护作业和组件任务状态的组件。

![ApplicationMaster：组件时间流程图](https://i.loli.net/2021/06/23/FdYTHLvtN7qmkVP.png)

##### 可用性

ApplicationMaster 通常将其状态存储在 HDFS 中，以确保其高可用。

有关更多的详细信息，请参阅 YARN 可用性部分。

### YARN 可用性

本节描述了 YARN 高用性相关的设计。

#### 运行失败的场景

本节列举了 YARN 中实体(如 ResourceManager、ApplicationMasters、Containers 等)的各种异常和失败场景，并重点介绍了负责处理这些情况的实体。

场景和处理实体：

- 容器(任务)活着，但被卡住了 ——AM 容器运行超时并杀死了它。
- 容器(任务)死了 ——NM 发现容器已经退出，并通知了 RM(Scheduler)；AM 在下一次与 YARN 调度器交互期间获取容器的状态(参见 Scheduler API 部分)
- NM 活着，但被卡住了 ——RM 发现 NM 已经超时了，在下一次交互时通知所有在该节点上有容器的 AM。
- NM 死了 ——RM 发现 NM 已经超时了，在下一次交互时通知所有在该节点上有容器的 AM。
- AM 活着，但被卡住了 ——ApplicationsManager 使 AM 超时，释放 RM 的容器并通过协商另一个容器重新启动 AM。
- AM 死了 ——ApplicationsManager 使 AM 超时，释放 RM 的容器并通过协商另一个容器重新启动 AM。
- RM 死了 ——参见 RM 重启的部分

#### MapReduce 应用程序和 ApplicationMaster 的可用性

本节介绍 MR ApplicationMaster 的故障转移以及如何恢复 MR 作业。

如 YARN ResourceManager 中的 ApplicationsManager(ASM) 部分所述，
ASM 负责监控 MR ApplicationMaster 或任何与此相关的 ApplicationMaster 并为其提供高可用性。

MR ApplicationMaster 自己负责恢复具体的 MR 作业，ASM 只重启 MR AM。

当 MR AM 重新启动时，我们有多种选择来恢复 MR 作业：

- 从头开始重新启动作业。
- 仅重启未完整的 Map 和 Reduce 任务。
- 为 Map 和 Reduce 任务标识正在运行的 MR AM 来完成它们。

仅针对单个容器(即运行 AM 的容器)失败，而从头开始重新启动 MR 作业的成本太高因此是不可行的选择。

仅重新启动不完整的 Map 和 Reduce 任务的方式很吸引我们，因为它确保我们不会运行已完成的任务，但是它仍然会伤害 Reduce，
因为它们可能(几乎)完成了 shuffle 并会因重新启动它们而受到影响。

从工作本身的角度来看，为 Map 和 Reduce 任务标识正在运行的 MR AM 是最有吸引力的选择，但从技术上讲，这是一项更具挑战性的任务。

鉴于上述权衡，我们建议对 YARN-v1.0 使用选项 2。
是一个更简单的实现，但有显著的好处。
我们很可能会在未来的版本中实现选项 3。

实现选项 2 的建议是让 MR AM 将事务日志写出到 HDFS，以跟踪所有已完成的任务。
在重新启动时，我们可以从事务日志中重放任务完成事件，并使用 MR AM 中的状态来跟踪已完成的任务。
因此，让 MR AM 运行剩余的任务是相当简单的。

####  YARN ResourceManager 的可用性

这里的主要目标是能够在遇到灾难性故障时快速重启 ResourceManager 和所有正在运行/挂起的应用程序。

因此 YARN 的可用性有两个方面：

- ResourceManager 的可用性
- 单个应用程序及其 ApplicationMaster 的可用性。

YARN 的高可用性设计在概念上非常简单 ——ResourceManager 负责恢复它自己的状态，例如运行 AM、分配 NM 和资源。
AM 本身负责恢复它自己的应用程序的状态。
有关恢复 MR 作业的详细讨论，请参阅 MR ApplicationMaster 可用性部分。

本节介绍了确保 YARN ResourceManager 高可用的设计。

为了提供高可用性，YARN ResourceManager 具有以下需要的特性：

- Queue definitions ——这些定义已经存在于持久存储中，例如文件系统或 LDAP。
- 正在运行和待处理的应用程序的定义
- 各种应用程序和队列的资源分配。
- 已经运行并分配给应用程序的容器。
- 单个 NodeManager 上的资源分配。

该提议是使用 ZooKeeper 来存储 YARN ResourceManager 的状态，该状态尚未存在于持久存储中，即 AM 的状态和单个应用程序的资源分配。

通过扫描对应用程序的分配，可以快速重建对各种 NM 和队列的资源分配。

ZooKeeper 允许通过主选举快速恢复 RM 和故障转移。

一个简单的方案是为每个 NodeManager 创建 ZooKeeper 临时节点，并为每个分配的容器创建一个节点，并使用以下最少信息：

- 应用 ID
- 容器资源

样例如下：

```text
|
+ app_1
| + <container_for_AM>
| |
| + <container_1, host_0, 2G>
| |
| + <container_11, host_10, 1G>
| |
| + <container_34, host_9, 2G>
|
+ app2
| + <container_for_AM>
| |
| + <container_5, host_87, 1G>
| |
| + <container_67, host_14, 4G>
| |
| + <container_87, host_9, 2G>
| |
```

有了这些信息，ResourceManager 在重启时可以通过 ZooKeeper 快速重建状态。
ZooKeeper 是所有分配的真实来源。

这是容器分配的流程。 

- ResourceManager 获取了 ApplicationMaster 容器的请求
- ResourceManager 在 /app$i 下的 ZooKeeper 中创建一个 znode，其中包含 containerid、node id 和资源能力信息。
- ResourceManager 响应 ApplicationMaster 获取对应资源的请求。

在释放容器时，遵循以下步骤：

- ApplicationMaster 向 NodeManager 发送 `stopContainer()` 请求以停止容器，如果遇到失败它会自动重试。
- ApplicationMaster 然后使用 `deallocateContainer(containerid)` 向 ResourceManager 发送请求。
- ResourceManager 然后从 ZooKeeper 中删除容器的 znode。

为了能够在 ApplicationMaster、ResourceManager 和 NodeManager 之间保持所有容器分配同步，我们需要一些 API：

ApplicationMaster 使用 `getAllocatedContainers(appid)` 在分配给 ApplicationMaster 的容器集合上与 ResourceManager 保持同步。

NodeManager 保持自己与 ResourceManager 的心跳同步，ResourceManager 则使用 NodeManager 应当清理和删除的容器作为响应。

重新启动时，ResourceManager 会遍历 HDFS/ZK 中的所有应用程序定义，即 /systemdir 并假设所有 RUNNING 状态的 ApplicationMaster 都处于活动状态。
ApplicationsManager 负责重新启动任何不更新 ApplicationsManager 的失败 AM，如前所述。

启动时的 ResourceManager 在 `${yarn-root}/yarn/rm` 下的 ZooKeeper 上发布其主机和端口。

```text
|
+ yarn
| |
| + <rm>
```

这个 ZooKeeper 节点是一个临时节点，如果 ResourceManager 死亡，它会自动删除。
在这种情况下，备份 ResourceManager 可以通过来自 ZooKeeper 的通知来接管。
由于 ResourceManager 状态在 ZooKeeper 中，因此备份 ResourceManager 可以启动。

所有的 NodeManager 都会监视 `${yarn-root}/yarn/rm` 以便在 znode 被删除或更新时得到通知。

ApplicationMaster 也会监视 `${yarn-root}/yarn/rm` 上的通知。

删除 znode 时，NodeManagers 和 ApplicationMasters 会收到更改通知。
ResourceManager 中的这种变化可以通过 ZooKeeper 通知 YARN 组件。

### YARN 的安全性

本节介绍 YARN 安全方面的内容。

一个硬性要求是 YARN 至少与当前的 Hadoop MapReduce 框架一样安全。

这意味着几个方面，例如：

- 全面基于 Kerberos 的强身份验证。
- YARN 守护程序（例如 RM 和 NM）应该以安全的非 root Unix 用户身份运行。
- 单个应用程序作为提交应用程序的实际用户运行，并且他们可以安全地访问 HDFS 等上的数据。
- 支持 Oozie 等框架的超级用户。
- 队列、管理工具等的类似授权。

该提议是使用 Hadoop 现有的安全机制和组件来实现 YARN 的安全性。

YARN 的唯一额外要求是，NodeManager 可以通过确保 ResourceManager 实际分配容器来安全地验证传入请求以分配和启动容器。

该提议是在 RM 和 NM 之间使用共享密钥。
RM 使用密钥来签署授权的 ContainerToken，其中包括 ContainerID、ApplicationID 和分配的资源能力。
NM 可以使用共享密钥来解码 ContainerToken 并验证请求。

#### ZooKeeper 的安全性

ZooKeeper 具有可配置的安全插件，可以使用 YCA 或共享秘密身份验证。它具有用于授权的 ACL。

ZooKeeper 中用于发现 RM 的 RM 节点和 YARN RM 可用性一节中提到的应用程序容器分配可由 ResourceManager 写入，并且只能由其他人读取。
YCA 用于认证系统。

请注意，由于 ZooKeeper 尚不支持 Kerberos，因此不允许单个 ApplicationMaster 和任务写入 ZooKeeper，所有写入均由 RM 自己完成。
