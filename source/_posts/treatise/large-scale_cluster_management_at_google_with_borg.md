---
title: "Large-scale cluster management at Google with Borg 中文翻译版"
date: 2021-12-28 22:26:13
tags:
- "论文"
- "Borg"
id: large-scale_cluster_management_at_google_with_borg
no_word_count: true
no_toc: false
categories: 大数据
---

## Large-scale cluster management at Google with Borg 中文翻译版

作者：

Abhishek Verma, Luis Pedrosa, Madhukar Korupolu, David Oppenheimer, Eric Tune, John Wilkes

### 原版的版权说明

```text
Permission to make digital or hard copies of part or all of this work for personal or classroom use is granted without 
fee provided that copies are not made or distributed for profit or commercial advantage and that copies bear this notice 
and the full citation the first page. Copyrights for third-party components of this work must be honored.For all other uses,
 contact the owner/author(s).EuroSys’15, April 21–24, 2015, Bordeaux, France.Copyright is held by the owner/author(s).
 ACM 978-1-4503-3238-5/15/04.http://dx.doi.org/10.1145/2741948.2741964
```

### 摘要

Google 的 Borg 系统是一个集群管理器，它在多个集群中运行数十万个作业，来自数千个不同的应用程序，每个集群都有多达数万台机器。

它通过将准入控制、高效任务打包、过度承诺(over-commit)和机器共享与进程级性能隔离相结合来实现高效利用资源。
它支持具有运行时功能的高可用性应用程序，这些功能可以最大限度地缩短故障恢复时间，以及减少相关故障概率的调度策略。
Borg 通过提供声明性的工作规范语言、名称服务集成、实时工作监控以及分析和模拟系统行为的工具来简化其用户的生活。

我们总结了 Borg 系统架构和特征、重要的设计决策、对其某些政策决策的定量分析，以及对从十年的操作经验中吸取的经验教训的定性检验。

### 1 引言

我们内部称为 Borg 的集群管理系统负责接纳、调度、启动、重启和监控 Google 运行的所有应用程序。这篇论文描述了它的工作方式。

Borg 提供了三个主要好处：(1) 隐藏了资源管理和故障处理的细节，因此它的用户可以专注于应用程序开发；(2) 以非常高的可靠性和可用性运行，并支持具有相同功能的应用程序；(3) 让我们有效地在数万台机器上运行工作负载。
Borg 不是第一个解决这些问题的系统，但它是为数不多的以这种规模运作的系统之一，具有这种程度的弹性和完整性。
本文围绕这些主题展开，最后总结了我们在生产环境中运行 Borg 十多年来所做的一系列定性观察。

### 2 用户视角

Borg 的用户是运行 Google 应用程序和服务的 Google 开发人员和系统管理员(站点可靠性工程师或 SRE)。
用户以作业的形式向 Borg 提交他们的工作，每个作业由一个或多个运行相同(二进制)程序的任务组成。
每个作业都在一个 Borg 单元中运行，这是一组作为一个单元进行管理的机器。
本节的其余部分描述了 Borg 用户视图中公开的主要功能。

#### 2.1 工作负载

Borg 单元运行具有两个主要部分的异构工作负载。
第一个是长期运行的服务，它们应该“永远”不停机，并处理短期的延迟敏感请求(几微秒到几百毫秒)。
此类服务用于面向最终用户的产品，例如 Gmail、Google Docs 和网络搜索，以及内部基础设施服务(例如 BigTable)。
第二种是需要几秒钟到几天才能完成的批处理作业；这些对短期业务波动的敏感性要低得多。
工作负载组合因单元而异，这些单元根据主要租户运行不同的应用程序组合(例如，某些单元是批量密集型的)，并且还会随时间变化：
批处理作业大量运行之后我们发现许多面向最终用户的服务中出现了日间使用的模式。
Borg 需要同样好地处理所有这些情况。

可以在 2011 年 5 月的公开可用的长达一个月的跟踪中找到具有代表性的 Borg 工作负载 `[80]`，该跟踪已被广泛分析(例如，`[68]` 和 `[1, 26, 27, 57]`)

在过去几年中，许多应用程序框架都建立在 Borg 之上，包括我们内部的 MapReduce 系统 `[23]`、FlumeJava `[18]`、Millwheel `[3]` 和 Pregel `[59]`。
其中大多数都有一个控制器，用于提交一个主作业和一个或多个工作作业； 前两个扮演与 YARN 的应用程序管理器类似的角色 `[76]`。 
我们的分布式存储系统，例如 GFS `[34]` 及其后继 CFS、Bigtable `[19]` 和 Megastore `[8]`，都在 Borg 上运行。

对于本文，我们将优先级较高的 Borg 工作归类为“生产”(prod)工作，其余归为 “非生产”(non-prod)工作。
大多数长时间运行的服务器作业都是生产工作；大多数批处理作业是非生产的。
在一个有代表性的运行单元中，生产作业分配了大约 70% 的总 CPU 资源和大约 60% 的总 CPU 使用率；它们被分配了大约 55% 的总内存并代表了大约 85% 的总内存使用量。
分配和使用之间的差异将在第 5.5 节中证明他们的重要性。

#### 2.2 集群和运行单元

运行单元中的机器属于单个集群，由连接它们的高性能数据中心规模的网络结构定义。
集群运行在一个数据中心大楼中，一组这样的基础设施构成了一个站点<sup>1</sup>。
一个集群通常承载一个大型单元，可能有一些较小规模的测试或专用单元。
我们努力避免任何单点故障。

> 注 1：每种关系都有一些例外。

排除测试用的运行单元后，我们的通常的运行单元大小约为 10k 台机器；有些要大得多。
运行单元中的机器在许多方面都是异构的：大小(CPU、RAM、磁盘、网络)、处理器类型、性能和功能，例如外部 IP 地址或闪存。
Borg 通过确定在单元中运行任务的位置、分配他们的资源、安装他们的程序和其他依赖项、监控他们的健康状况以及在失败时重新启动他们，将用户与大多数这些差异隔离开来。

#### 2.3 工作和任务

Borg 作业的属性包括它的名称、所有者和它拥有的任务数量。
作业可以有约束来强制其任务在具有特定属性的机器上运行，例如处理器架构、操作系统版本或外部 IP 地址。
约束可以是硬的，也可以是软的； 后者表现为偏好而不是要求。
一项工作的开始的方式可以是到前一项工作完成。一项作业仅在一个运行单元中运行。

每个任务都映射到在机器上的容器中运行的一组 Linux 进程 `[62]`。
绝大多数 Borg 工作负载不在虚拟机(VM)内运行，因为我们不想支付虚拟化成本。
此外，该系统是在我们对处理器进行大量投资的时候设计的，而硬件没有虚拟化支持。

任务也有属性，例如它的资源需求和任务在作业中的索引。
大多数任务属性在作业中的所有任务中都是相同的，但可以被覆盖——例如，提供特定于任务的命令行标志。
每个资源维度(CPU 内核、RAM、磁盘空间、磁盘访问速率、TCP 端口等)都是以细粒度独立指定的； 我们不强加固定大小的桶或槽(参见第 5.4 节)。
Borg 程序是静态链接的，以减少对其运行时环境的依赖，并将其结构化为二进制文件和数据文件的包，其安装由 Borg 编排。

用户通过向 Borg 发出远程过程调用(RPC)来操作作业，最常见的是来自命令行工具、其他 Borg 作业或我们的监控系统(参见第 2.6 节)。
大多数工作描述都是用声明性配置语言 BCL 编写的。
这是 GCL `[12]` 的变体，它生成 protobuf 文件 `[67]`，并扩展了一些 Borg 特定的关键字。
GCL 提供了 lambda 函数来允许计算，应用程序使用这些函数来调整它们的配置以适应它们的环境；成千上万的 BCL 文件都超过 1k 行，我们已经积累了数千万行的 BCL。
Borg 作业配置与 Aurora 配置文件有相似之处 `[6]`。

![图 2：作业和任务的状态图。用户可以触发提交、终止和更新操作。](https://s2.loli.net/2021/12/29/Gn6J9qwK3hLmUst.png)

图 2 说明了作业和任务在其生命周期中经历的状态。

用户可以通过将新的作业配置推送到 Borg，然后指示 Borg 将任务更新配置来更改正在运行的作业中部分或全部任务的属性。
这是一个轻量级的非原子事务，在直到它关闭(提交)前都可以很容易地撤消。
更新通常以滚动方式完成，并且可以对更新导致的任务中断(重新安排或抢占)的数量施加限制；任何会导致更多中断的更改都会被跳过。

某些任务更新(例如，推送新的二进制文件)将始终需要重新启动任务；一些(例如，增加资源需求或改变约束)可能会使任务不再适合机器，并导致它被停止和重新安排；有些(例如，更改优先级)总是可以在不重新启动或移动任务的情况下完成。

任务可以在被 SIGKILL 抢占之前通过 Unix SIGTERM 信号请求通知，因此它们有时间清理、保存状态、完成任何当前正在执行的请求，并拒绝新的请求。
如果抢占者设置了延迟界限，则实际通知可能会更少。实际上，大约 80% 的时间都会发送通知。

#### 2.4 分配(alloc)

Borg alloc(分配的缩写)是机器上的一组保留资源，可以在其中运行一个或多个任务；无论是否使用，资源都保持分配状态。
Allocs 可用于为未来的任务留出资源，在停止任务和重新启动任务之间保留资源，以及将来自不同作业的任务收集到同一台机器上——例如，一个 web 服务器实例和一个复制保存其 URL 日志从到本地磁盘到分布式文件系统的任务。
alloc 的资源的处理方式与机器的资源类似；在一个内部运行的多个任务共享其资源。如果必须将 alloc 重新定位到另一台机器，则其任务将与它一起重新安排。

一个 alloc 集合就像一个作业：它是一组在多台机器上保留资源的 alloc。
创建 alloc 集合后，可以提交一个或多个作业以在其中运行。为简洁起见，我们通常使用“task”来指代一个 alloc 或顶层任务(一个在 alloc 之外的任务)，使用 “job” 来指代一个作业或 alloc 集合。

#### 2.5 优先级、配额和准入控制

当出现的工作量超过可容纳的量时会发生什么？我们对此的解决方案是优先级和配额。

每个工作都有一个优先级，一个小的正整数。高优先级任务可以以牺牲低优先级任务为代价获得资源，即使这涉及抢占(杀死)后者。
Borg 为不同的用途定义了不重叠的优先级带，包括(按优先级递减的顺序)：监控、生产、批处理和最佳努力(也称为测试或免费)。
对于本文，生产作业是监控和生产环境中的作业。

虽然被抢占的任务通常会被重新安排在运行单元的其他地方，但如果一个高优先级的任务与一个稍低优先级的任务相撞，又与另一个稍低优先级的任务相撞，依此类推，就会发生抢占级联。
为了消除大部分这种情况，我们不允许生产优先级范围内的任务相互抢占。
细粒度的优先级在其他情况下仍然有用——例如，MapReduce 主任务的运行优先级略高于他们控制的工作节点，以提高其可靠性。

优先级表示单元格中正在运行或等待运行的作业的相对重要性。配额用于决定允许调度哪些作业。
配额表示为一段时间(通常为几个月)内给定优先级的资源数量(CPU、RAM、磁盘等)向量。
这些数量指定了用户的作业请求一次可以请求的最大资源量(例如，“从现在到 7 月底，运行单元 xx 中的生产优先级为 20 TiB 的 RAM”)。
配额检查是准入控制的一部分，而不是调度：配额不足的作业在提交后会立即被拒绝。

高优先级配额的成本高于低优先级配额。生产优先配额仅限于单元中可用的实际资源，因此提交符合其配额的生产优先作业的用户可以期望它运行，模碎片和约束。
尽管我们鼓励用户购买的配额不要超过他们需要的数量，但许多用户还是会过度购买，因为当他们的应用程序的用户群增长时，这可以使他们免受未来短缺的影响。
我们通过在较低优先级的超额销售配额来对此做出回应：每个用户在优先级为零的情况下都有一个无限的配额，尽管这通常很难行使，因为资源被超额订阅。
低优先级的作业可能会被接纳但由于资源不足而保持挂起(未安排)。

配额分配在 Borg 之外处理，与我们的物理容量规划密切相关，其结果反映在不同数据中心的配额价格和可用性上。用户作业仅在具有所需优先级的足够配额时才被允许。
配额的使用减少了对显性资源公平(DRF)等政策的需求 `[29, 35, 36, 66]`。

Borg 有一个能力系统，赋予一些用户特殊的权限；例如，允许管理员删除或修改运行单元中的任何作业，或允许用户访问受限内核功能或 Borg 行为，例如禁用其作业的资源估计(参见第 5.5 节)。

#### 2.6 名称服务和监控

创建和放置任务是不够的：服务的客户端和其他系统需要能够找到它们，即使它们被重新定位到新机器上。
为了实现这一点，Borg 为每个包含单元名称、作业名称和任务编号的任务创建了一个稳定的“Borg 名称服务”(BNS)名称。
Borg 使用此名称将任务的主机名和端口写入 Chubby `[14]` 中一致的、高度可用的文件中，我们的 RPC 系统使用它来查找任务端点。
BNS 名称也构成了任务 DNS 名称的基础，因此运行单元 `cc` 中用户 `ubar` 所拥有的作业 `jfoo` 中的第 50 个任务将可以通过 `50.jfoo.ubar.cc.borg.google.com` 访问。
Borg 还会在发生变化时将作业大小和任务健康信息写入 Chubby，因此负载均衡器可以看到将请求路由到哪里。

几乎在 Borg 下运行的每个任务都包含一个内置的 HTTP 服务器，该服务器发布有关任务健康状况和数千个性能指标(例如，RPC 延迟)的信息。
Borg 监控健康检查 URL 并重新启动没有及时响应或返回 HTTP 错误代码的任务。其他数据由仪表板和服务级别目标 (SLO) 违规警报的监控工具跟踪。

名为 Sigma 的服务提供基于 Web 的用户界面 (UI)，用户可以通过该界面检查所有作业、特定运行单元的状态，或深入查看单个作业和任务以检查其资源行为、详细日志、执行历史记录，以及最终的状态。
我们的应用程序会生成大量日志；这些应用会自动轮换以避免磁盘空间不足，并在任务退出后保留一段时间以协助调试。
如果应用程序没有在运行，Borg 提供了一个”为什么等待”的注解，与如何修改作业的资源请求以更好地适应运行单元的指南。
我们发布了可能容易调度的“符合”资源形状的指南。

Borg 在 Infrastore 中记录了所有作业提交和任务事件，以及详细的每个任务资源使用信息，Infrastore 是一个可扩展的只读数据存储，通过 Dremel `[61]` 提供类似 SQL 的交互式界面。
此数据用于基于使用情况的计费、调试作业和系统故障以及长期容量规划。它还提供了 Google 集群工作负载跟踪的数据 `[80]`。

所有这些功能都可以帮助用户了解和调试 Borg 及其作业的行为，并帮助我们的 SRE 管理每人数万台机器。

### 3 Borg 的架构设计

![图 1：Borg 的高层架构。仅显示了数千个工作节点中的一小部分。](https://s2.loli.net/2021/12/28/i3jJ1DE2woGRkm7.png)

Borg 单元由一组机器、一个称为 Borgmaster 的逻辑集中控制器和一个称为 Borglet 的代理进程组成，该代理进程在单元中的每台机器上运行(参见图 1)。Borg 的所有组件都是用 C++ 编写的。

#### 3.1 Borgmaster

每个运行单元的 Borgmaster 由两个进程组成：主 Borgmaster 进程和一个单独的调度程序(参见第 3.2 节)。
主 Borgmaster 进程处理客户端 RPC，这些 RPC 要么改变状态(例如，创建作业)，要么提供对数据的只读访问(例如，查找作业)。
它还管理系统中所有对象(机器、任务、alloc 等)的状态机，与 Borglet 通信，并提供 Web UI 作为 Sigma 的备份。

Borgmaster 在逻辑上是一个单一的进程，但实际上被复制了五次。
每个副本都维护了大部分单元状态的内存副本，并且该状态也记录在副本本地磁盘上的高可用、分布式、基于 Paxos `[55]` 的存储中。
每个运行单元选出的单个 master 既充当 Paxos 的领导节点又充当状态修改器，处理所有改变运行单元状态的操作，例如提交作业或终止机器上的任务。
当运行单元被启动时以及当被选举的 master 失效时，一个 master 会被选举(使用 Paxos)；它会获取一个 Chubby 锁，以便其他系统可以找到它。
选举一个 master 并故障转移到新的 master 通常需要大约 10 秒，但在大的运行单元中可能需要长达一分钟的时间，因为必须重建一些内存中的状态。
当一个副本从中断中恢复时，它会从其他最新的 Paxos 副本动态地重新同步它的状态。

Borgmaster 在某个时间点的状态称为检查点，它采用定期快照和保存在 Paxos 存储中的更改日志的形式。
检查点有很多用途，包括将 Borgmaster 的状态恢复到过去的任意点(例如，就在接受触发 Borg 中软件缺陷的请求之前，以便对其进行调试)；在极端情况下手动修复；
为未来的查询建立一个持久的事件日志；和模拟离线情况。

一个名为 Fauxmaster 的高保真 Borgmaster 模拟器可用于读取检查点文件，并包含生产 Borgmaster 代码的完整副本，以及 Borglet 的存根接口。
它接受 RPC 以进行状态机更改并执行操作，例如“调度所有挂起的任务”，我们使用它来调试故障，方法是与它进行交互，就好像它是一个实时的 Borgmaster，模拟 Borglet 重放来自检查点文件的真实交互。
用户可以单步执行并观察过去实际发生的系统状态的变化。
Fauxmaster 还可用于容量规划(“这种类型的新工作有多少适合？”)，以及在对单元配置进行更改之前的健全性检查(“此更改会驱逐任何重要工作吗？”)

#### 3.2 定时任务

当一个作业被提交时，Borgmaster 将它持久地记录在 Paxos 存储中，并将作业的任务添加到待处理队列中。
调度程序会异步扫描它们，如果有足够的可用资源满足作业的约束，调度程序就会将任务分配给机器。(调度程序主要对任务(task)进行操作，而不是作业(job)。)
扫描从高优先级到低优先级进行，由优先级内的循环方案调制，以确保用户之间的公平性并避免大型作业背后的队头阻塞。
调度算法有两部分：可行性检查，寻找可以运行任务的机器，以及评分，选择一台可行的机器。

在可行性检查中，调度程序会找到一组满足任务约束条件并具有足够“可用”资源的机器——包括分配给可以被驱逐的低优先级任务的资源。
在评分时，调度器确定每个可行机器的“优点”。
该分数考虑了用户指定的偏好，但主要由内置标准驱动，例如最小化被抢占任务的数量和优先级、挑选已经拥有任务包副本的机器、跨电源域和故障域传播任务，以及打包质量(将高优先级和低优先级任务混合到一台机器上，以允许高优先级任务在负载高峰时扩展)。

Borg 最初使用 E-PVM `[4]` 的变体进行评分，它在异构资源中生成单一成本值，并在放置任务时最小化成本的变化。 在实践中，E-PVM 最终将负载分散到所有机器上，为负载峰值留出空间——但以增加碎片为代价，特别是对于需要大部分机器的大型任务；我们有时称其为“最糟糕的选择”。

频谱的另一端是“最佳拟合”，它试图尽可能紧密地填充机器。
这使得一些机器没有用户作业(它们仍然运行存储服务器)，因此放置大型任务很简单，但紧密包装会惩罚用户或 Borg 对资源需求的任何错误估计。
这会损害具有突发负载的应用程序，对于指定低 CPU 需求的批处理作业尤其不利，因此它们可以轻松调度并尝试在未使用的资源中机会性地运行：20% 的非生产任务请求少于 0.1 个 CPU 内核。

我们当前的评分模型是一种混合模型，它试图减少闲置资源的数量——因为机器上的另一个资源已完全分配而无法使用。
与最适合我们的工作负载相比，它提供了大约 3-5% 的打包效率(在 `[78]` 中定义)。

如果评分阶段选择的机器没有足够的可用资源来适应新任务，Borg 会抢占(杀死)较低优先级的任务，从最低到最高优先级，直到它完成。
我们将被抢占的任务添加到调度程序的支出队列中，而不是迁移或休眠它们。

任务启动延迟(从作业提交到任务运行的时间)是一个已经受到并将继续受到显着关注的区域。它是高度可变的，中位数通常约为 25 秒。
软件包安装约占总数的 80%：已知瓶颈之一是对写入软件包的本地磁盘的争用。
为了减少任务启动时间，调度程序更喜欢将任务分配给已经安装了必要包(程序和数据)的机器：大多数包是不可变的，因此可以共享和缓存。
(这是 Borg 调度器支持的唯一数据本地形式。)
此外，Borg 使用类似树和 torrent 的协议将包并行分发到机器。

此外，调度程序使用多种技术让它扩展到拥有数万台机器的单元(第 3.4 节)。

#### 3.4 Borglet

Borglet 是一个本地 Borg 代理，存在于运行单元中的每台机器上。
它负责启动和停止任务；如果发生故障，则重新启动它们；通过对操作系统内核的设置来管理本地资源；滚动调试日志；并将机器状态报告给 Borgmaster 和其他监控系统。

Borgmaster 每隔几秒钟轮询每个 Borglet 以检索机器的当前状态并向其发送任何未完成的请求。
这使 Borgmaster 可以控制通信速率，避免需要明确的流量控制机制，并防止恢复风暴 `[9]`。

选定的主节点负责准备要发送给 Borglet 的消息，并用它们的响应更新运行单元的状态。
为了性能的可扩展性，每个 Borgmaster 副本运行一个无状态链接分片来处理与一些 Borglet 的通信；每当 Borgmaster 选举发生时，就会重新计算分区。
为了弹性，Borglet 始终报告其完整状态，但链接分片通过仅向状态机报告差异来聚合和压缩此信息，以减少所选主节点的更新负载。

如果 Borglet 没有响应多个轮询消息，它的机器将被标记为停机，并且它正在运行的任何任务都将重新安排在其他机器上。
如果通信恢复，Borgmaster 会告诉 Borglet 终止那些已重新安排的任务，以避免重复。
即使 Borglet 与 Borgmaster 失去联系，它也会继续正常运行，因此即使所有 Borgmaster 副本都失败，当前正在运行的任务和服务也会保持正常运行。

#### 3.4 可伸缩性

我们不确定 Borg 中心化架构的最终可伸缩性的限制从何而来；到目前为止，每次我们接近极限时，我们都设法消除了它。
一个 Borgmaster 可以在一个运行单元中管理数千台机器，并且几个单元的到达率超过每分钟 10000 个任务。
繁忙的 Borgmaster 使用 10-14 个 CPU 内核和高达 50 GiB 的 RAM。我们使用了几种技术来达到这个规模。

Borgmaster 的早期版本有一个简单的同步循环，用于接受请求、计划任务并与 Borglet 通信。
为了处理更大的单元，我们将调度程序拆分为一个单独的进程，以便它可以与其他 Borgmaster 功能并行运行，这些功能被复制以实现容错。
调度程序副本对运行单元状态的缓存副本进行操作。
它会重复以下事件：从选定的主节点中检索状态更改(包括已分配的和未决的工作)；更新其本地副本；进行调度传递以分配任务；并将这些作业通知选定的主人。
Borgmaster 将接受并应用这些分配，除非它们不合适(例如，基于过时的状态)，这将导致它们在调度程序的下一次通过时被重新考虑。
这在本质上与 Omega `[69]` 中使用的乐观并发控制非常相似，实际上我们最近为 Borg 添加了针对不同工作负载类型使用不同调度程序的能力。

为了缩短响应时间，我们添加了单独的线程来与 Borglet 对话并响应只读 RPC。
为了获得更高的性能，我们将这些功能分片(分区)到 5 个 Borgmaster 副本(参见第 3.3 节)。
以上因素将 UI 的 99%ile (正态分布中的平均值的 99%) 响应时间保持在 1 以下，并将 Borglet 轮询间隔的 95%ile (正态分布中的平均值的 95%) 保持在 10 秒以下。

有几件事使 Borg 调度器更具可扩展性:

**分数缓存**：评估可行性并对机器进行评分是昂贵的，因此 Borg 会缓存分数，直到机器的属性或任务发生变化——例如，机器上的任务终止、属性改变或任务的要求发生变化。忽略资源数量的微小变化会减少缓存失效。

**等价类**：Borg 作业中的任务通常具有相同的要求和约束，因此与其为每台机器上的每个待处理任务确定可行性，并对所有可行机器进行评分，Borg 只对每个等价类的一个任务进行可行性和评分-一组具有相同要求的任务。

**宽松的随机化**：为一个运行单元中的所有机器计算可行性和分数是一种浪费，因此调度程序以随机顺序检查机器，直到找到“足够”的可行机器来评分，然后在该集合中选择最好的。
这减少了任务进入和离开系统时所需的评分和缓存失效量，并加快了将任务分配给机器的速度。
宽松随机化有点类似于 Sparrow `[65]` 的批量抽样，同时也处理优先级、抢占、异质性和包安装成本。

在我们的实验中(第 5 节)，从头开始调度一个单元的整个工作负载通常需要几百秒，但当上述技术被禁用时，超过 3 天后仍未完成。
但是，通常情况下，挂起队列上的在线调度会在不到半秒的时间内完成。

### 4 能力

![图 3：生产和非生产工作负载的任务驱逐率和原因。2013 年 8 月 1 日的数据](https://s2.loli.net/2021/12/29/WInUgwmZjkNBGJz.png)

故障是大规模系统中的常态 `[10, 11, 22]`。图 3 提供了 15 个样本单元中任务驱逐原因的细分。
运行在 Borg 上的应用程序应该使用诸如复制、在分布式文件系统中存储持久状态和(如果合适)偶尔保存检查点等技术来处理此类事件。
即便如此，我们仍会努力减轻这些事件的影响。例如，Borg 的处理方式如下：

- 如有必要，在新机器上自动重新安排被驱逐的任务
- 通过跨故障域(例如机器、机架和电源域)分散作业的任务来减少相关故障；
- 限制允许的任务中断率以及在维护活动(例如操作系统或机器升级)期间可以同时关闭的作业中的任务数量；
- 使用声明性的期望状态表示和幂等的变异操作，以便失败的客户端可以无害地重新提交任何被遗忘的请求；
- 限制提交速率，将无法传输到设备的任务寻找新的位置。因为它因为它无法区分大规模机器故障和网络分区；
- 避免重复 task::machine 配对导致任务或机器崩溃
- 通过反复重新运行日志保护程序任务(第 2.4 节)来恢复写入本地磁盘的关键中间数据，即使它所附加的 alloc 已终止或移动到另一台机器。用户可以设置系统重试时间(通常是几天)。

Borg 的一个关键设计特性是，即使 Borgmaster 或任务的 Borglet 出现故障，已经运行的任务也会继续运行。
但是保持 master 运行仍然很重要，因为当它宕机时，无法提交新作业或更新现有作业，并且无法重新安排来自故障机器的任务。

Borgmaster 使用了多种技术组合，使其能够在实践中实现 99.99% 的可用性：机器故障复制；准入控制以避免过载；并使用简单的低级工具部署实例以最大限度地减少外部依赖性。
每个运行单元都独立于其他运行单元，以最大限度地减少相关操作员错误和故障传播的机会。这些目标，而不是可扩展性限制，是反对更大运行单元的主要论据。

### 5 利用率

Borg 的主要目标之一是有效利用 Google 的机器群，这是一项重大的财务投资：将利用率提高几个百分点可以节省数百万美元。本节讨论和评估 Borg 用于这样做的一些策略和技术。

#### 5.1 评估方法

我们的作业有放置约束，需要处理罕见的工作负载峰值，我们的机器是异构的，我们在从服务作业回收的资源中运行批处理作业。
因此，为了评估我们的政策选择，我们需要一个比“平均利用率”更复杂的指标。
经过大量实验，我们选择了运行单元压缩的方式：给定一个工作负载，我们通过移除机器直到工作负载不再适合它来发现它可以安装到多小的运行单元中，从头开始反复重新打包工作负载，以确保我们不会被一个不走运的配置所困扰。
这提供了干净的终止条件，并促进了自动比较，而不存在合成额外产生工作负载和建模的陷阱 `[31]`。
评估技术的定量比较可以在 `[78]` 中找到：细节出奇地微妙。

不可能在实时生产运行单元上进行实验，但我们使用 Fauxmaster 获得高保真模拟结果，使用来自真实生产单元和工作负载的数据，包括它们的所有约束、实际限制、预留和使用数据(参见第 5.5 节)。
该数据来自于名美国太平洋夏令时间 2014-10-01 14:00 星期三拍摄的 Borg 检查点。
我们选择了 15 个 Borg 运行单元进行报告，首先消除了特殊用途的、测试的和小型(< 5000 台机器)运行单元，然后对剩余的群体进行采样，以在大小范围内实现大致均匀的分布。

为了保持压缩单元中的机器异质性，我们随机选择要移除的机器。
为了保持工作负载的异构性，我们保留了所有内容，除了与特定机器(例如 Borglet)相关的服务器和存储任务。
对于大于原始单元大小一半的作业，我们将硬约束更改为软约束，并允许多达 0.2% 的任务挂起，如果它们非常“挑剔”并且只能放置在少数机器上；大量实验表明，这产生了具有低方差的可重复结果。
如果我们需要一个比原始运行单元更大的运行单元，我们会在压缩前克隆原始运行单元几次；如果我们需要更多运行单元，我们就克隆原始运行单元。

对于具有不同随机数种子的每个运行单元，每个实验重复 11 次。
在图中，我们使用误差条来显示所需机器数量的最小值和最大值，并选择 90% 的值作为“结果”——平均值或中位数不会反映系统管理员会做什么如果他们想合理地确定工作量是否合适。
我们相信单元压缩提供了一种公平、一致的方式来比较调度策略，它直接转化为成本/收益结果：更好的策略需要更少的机器来运行相同的工作负载。

我们的实验侧重于从某个时间点调度(打包)工作负载，而不是重放长期工作负载跟踪。
这部分是为了避免处理开放和封闭队列模型的困难 `[71, 79]`，部分是因为传统的完成时间指标不适用于我们的长期运行服务的环境，部分是为了提供清晰的信号进行比较，部分是因为我们不相信结果会有显着不同，部分是因为实际问题：我们发现自己曾在某个时间点消耗 200 000 个 Borg CPU 内核用于我们的实验——即使在 Google 的规模下，这也是非常重要的投资。

在生产中，我们故意为工作负载增长、偶尔的“黑天鹅”事件、负载尖峰、机器故障、硬件升级和大规模局部故障(例如，电源总线故障)留出很大的空间。
图 4 显示了如果我们对它们应用运行单元压缩，我们的现实世界的运行单元会小多少。下图中的基线使用这些压缩尺寸。

![图 4：压缩的效果。压缩后获得的原始运行单元大小百分比的 CDF，跨越 15 个运行单元](https://s2.loli.net/2021/12/29/nPRjEWNYlkhiX16.png)

#### 5.2 运行单元共享

我们几乎所有的机器都同时运行生产和非生产任务：98% 的机器在共享的 Borg 单元中，83% 的机器在 Borg 管理的整个机器集中。(我们有一些特殊用途的专用运行单元。)

![图 5：将生产和非生产工作隔离到不同的运行单元中需要更多的机器。](https://s2.loli.net/2021/12/29/WisuOEfKYg9McwS.png)

> 注：两个图表都显示了如果生产和非生产工作负载被发送到不同的单元需要多少额外的机器，表示为在单个运行单元中运行工作负载所需的最少机器数量的百分比。在这个和随后的 CDF 图中，每个运行单元显示的值来自我们的实验试验产生的不同运行单元大小的 90%；误差条显示了试验值的完整范围。

由于许多其他组织在不同的集群中运行面向用户的批处理作业，因此我们研究了如果我们这样做会发生什么。
图 5 显示隔离生产和非生产工作需要在中间单元中多 20-30% 的机器来运行我们的工作负载。
这是因为生产作业通常会预留资源来处理罕见的工作负载高峰，但大多数时候不会使用这些资源。
Borg 回收未使用的资源(参见第 5.5 节)来运行大部分非生产工作，因此我们总体上需要更少的机器。

![图 6：隔离用户需要更多的机器。如果用户需求大于的阈值，如图所示我们为 5 个不同的运行单元分配了自己的专用单元，这样依赖也就需要新的运行单元和额外的机器。](https://s2.loli.net/2021/12/31/nSkuYVlEAmrOiFt.png)

大多数 Borg 运行单元由数千个用户共享。图 6 显示了原因。
对于此测试，如果用户消耗至少 10 TiB 的内存(或 100 TiB)，我们会将用户的工作负载拆分到一个新单元中。
我们现有的策略看起来不错：即使使用更大的阈值，我们也需要 2-16 倍的单元，以及 20-150% 的额外机器。再一次证明了，集中资源显着降低了成本。

但也许将不相关的用户和作业类型打包到同一台机器上会导致 CPU 干扰，因此我们需要更多的机器来补偿？
为了评估这一点，我们研究了 CPI (每条指令的周期数)如何在不同环境中以相同的时钟速度运行在相同机器类型上的任务中发生变化。
在这些条件下，CPI 值是可比较的，并且可以用作性能干扰的代理，因为 CPI 加倍会使 CPU 密集型程序的运行时间加倍。
数据是从一周内随机选择的 12000 个生产任务中收集的，使用 `[83]` 中描述的硬件分析基础设施在 5 分钟的时间间隔内计算周期和指令，并对样本进行加权，以便 CPU 时间的每一秒都被相等地计数。结果并不明确。

(1) 我们发现 CPI 与同一时间间隔内的两个测量值呈正相关：机器上的总体 CPU 使用率和(很大程度上独立的)机器上的任务数量；向机器添加任务会使其他任务的 CPI 增加 0.3%(使用拟合数据的线性模型）向机器添加任务会使其他任务的 CPI 增加 0.3%（使用拟合数据的线性模型)；将机器 CPU 使用率提高 10% 会使 CPI 增加不到 2%。
但即使相关性在统计上显着，它们也只能解释我们在 CPI 测量中看到的方差的 5%； 其他因素占主导地位，例如应用和特定干扰模式的固有差异 `[24, 83]`。

(2) 将我们从共享单元中采样的 CPI 与应用程序不太多样化的几个专用单元中的 CPI 进行比较，我们看到共享单元中的平均 CPI 为 1.58 (σ = 0.35)，而专用单元中的平均值为 1.53 (σ = 0.32) – 即 , CPU 性能在共享单元中大约差 3%。

(3) 为了解决不同单元中的应用程序可能具有不同的工作负载，甚至遭受选择偏差(可能对干扰更敏感的程序已移至专用单元)的担忧，我们查看了 Borglet 的 CPI，它们运行在所有设备中两种不同类型的运行单元上。

这些实验证实了仓库规模的性能比较是棘手的，又一次证明了 `[51]` 中的观察结果，并且还表明共享不会显着增加运行程序的成本。

但即使假设我们的结果最不利，共享仍然是一个胜利：CPU 速度下降被几种不同分区方案所需的机器减少所抵消，并且共享优势适用于包括内存和磁盘在内的所有资源，而不仅仅是 CPU。

#### 5.3 大型运行单元

![图 7：将运行单元细分为更小的运行单元需要更多的机器。如果我们将这些特定的运行单元分成不同数量的较小的运行单元，将需要额外的机器(在单个运行单元的情况下作为其中的补充)。](https://s2.loli.net/2021/12/31/E3Wux6NbLPd8yBo.png)

Google 构建大型单元，既可以运行大型计算，又可以减少资源碎片。
我们通过将一个单元的工作负载划分到多个较小的单元来测试后者的效果——首先随机排列作业，然后在分区之间以循环方式分配它们。
图 7 证实，使用更小的单元将需要更多的机器。

#### 5.4 细粒度的资源请求

![图 8：没有一个单一的桶尺寸可以适合大多数任务。我们的示例单元中请求的 CPU 和内存请求的 CDF 显示。尽管一些整数 CPU 内核尺寸更受欢迎，但没有一个值脱颖而出。](https://s2.loli.net/2021/12/31/aI1pkS9D2VlHzjE.png)

Borg 用户以毫核(milli-core)为单位请求 CPU，以字节为单位请求内存和磁盘空间。
(核心是处理器超线程，针对跨机器类型的性能进行了标准化。)
图 8 显示他们利用了这种粒度：在请求的内存或 CPU 内核量中几乎没有明显的“最佳点”，并且这些资源之间几乎没有明显的相关性。
这些分布与 `[68]` 中呈现的分布非常相似，除了我们在 90% 和以上看到稍大的内存请求。

![图 9：资源“分桶”需要更多的机器。将 CPU 和内存请求四舍五入到 15 个单元中的下一个最近的 2 次幂所导致的额外开销的 CDF。下限和上限跨越实际值(见正文)。](https://s2.loli.net/2021/12/31/aI1pkS9D2VlHzjE.png)

提供一组固定大小的容器或虚拟机，虽然在 IaaS (基础设施即服务)提供商 `[7, 33]` 中很常见，但并不能很好地满足我们的需求。
为了证明这一点，我们通过将每个资源维度中的下一个最接近的 2 次幂四舍五入来“分桶”生产作业和分配(第 2.4 节)的 CPU 内核和内存资源限制，从 0.5 个 CPU 内核和 1 GiB RAM 开始。
图 9 显示，在中等情况下，这样做需要多 30-50% 的资源。
上限来自将整台机器分配给大型任务，这些任务在压缩开始之前将原始运行单元翻了四倍；允许这些任务挂起的下限。
(这低于 `[37]` 中报告的大约 100% 的开销，因为我们支持 4 个以上的存储桶并允许 CPU 和 RAM 容量独立扩展。)

#### 5.5 资源回收

一个作业可以指定一个资源限制——每个任务应该被授予的资源的上限。
Borg 使用该限制来确定用户是否有足够的配额来接受作业，以及确定特定机器是否有足够的空闲资源来安排任务。
就像有些用户购买的配额比他们需要的多一样，有些用户请求的资源比他们的任务使用的资源多，因为 Borg 通常会杀死一个尝试使用比请求更多的 RAM 或磁盘空间的任务，或者节流 CPU 以它要求什么。
此外，某些任务偶尔需要使用其所有资源(例如，在一天的高峰时间或在应对拒绝服务攻击时)，但大多数时间不需要。

我们不会浪费当前未消耗的已分配资源，而是估计任务将使用多少资源，并将剩余的资源用于可以容忍较低质量资源的工作，例如批处理作业。这整个过程称为资源回收。
该估计值称为任务预留，由 Borgmaster 每隔几秒计算一次，使用 Borglet 捕获的细粒度使用(资源消耗)信息。
初始预留设置为等于资源请求(限制)；300 秒后，为了允许启动瞬变，它会缓慢衰减到实际使用情况加上安全裕度。如果使用量超过它，则预订会迅速增加。

Borg 调度器使用限制来计算生产任务的可行性（第 3.2 节），4 因此它们从不依赖回收资源，也不会暴露于资源超额订阅；对于非生产任务，它使用现有任务的预留，以便可以将新任务安排到回收资源中。

如果预留(预测)错误，机器可能会在运行时耗尽资源——即使所有任务使用的资源都少于其限制。如果发生这种情况，我们会终止或限制非生产任务，而不是生产任务。

![图 10：资源回收相当有效。如果我们为 15 个代表性单元禁用它，则需要的额外机器的 CDF。](https://s2.loli.net/2021/12/31/bBcxqvWaEwQ8NtG.png)

图 10 显示，如果不进行资源回收，将需要更多的机器。大约 20% 的工作负载（第 6.2 节）在中间单元中的回收资源中运行。

![图 11：资源预估在识别未使用的资源方面是成功的。](https://s2.loli.net/2021/12/31/v4sXlELt5GSezFI.png)

> 注：资源估计在识别未使用的资源方面是成功的。虚线显示了 CPU 和内存使用率与 15 个单元中任务的请求（限制）比率的 CDF。大多数任务使用的 CPU 比其限制少得多，但也有少数任务使用的 CPU 比请求的多。
> 实线表示 CPU 和内存预留与限制的比率的 CDF； 这些都接近 100%。直线是资源估算过程的产物。

我们可以在图 11 中看到更多详细信息，其中显示了预留和使用与限制的比率。
如果需要资源，超过其内存限制的任务将首先被抢占，无论其优先级如何，因此任务很少会超过其内存限制。
另一方面，CPU 很容易受到限制，因此短期峰值可以相当无害地将使用率推高至预留值之上。

![图 12：更积极的资源估计可以回收更多资源，而对内存不足事件 (OOM) 的影响很小。](https://s2.loli.net/2021/12/31/pwhCkcGLbVOa7Is.png)

> 注：一个时间线（从 2013 年 11 月 11 日开始）用于一个生产单元的使用、预留和限制平均超过 5 分钟的窗口和累积的内存不足事件；后者的斜率是 OOM 的总比率。竖线将具有不同资源估计设置的周分开。

图 11 表明资源回收可能过于保守：预留线和使用线之间有很大的区域。
为了测试这一点，我们选择了一个实时生产单元，并通过降低安全裕度，将其资源估算算法的参数调整为一周内的激进设置，然后调整为下周介于基线和激进设置之间的中等设置，然后恢复到基线。
图 12 显示了发生的情况。
预订量显然更接近第二周的使用量，而在第三周的情况略少，最大的差距出现在基准周(第 1 周和第 4 周)。
正如预期的那样，内存不足 (OOM) 事件的发生率在第 2 周和第 3.5 周略有增加在审查这些结果后，我们决定净收益超过不利因素，并将中等资源回收参数部署到其他单元。

### 6 隔离策略

我们 50% 的机器运行 9 个或更多任务；一台 90%ile 的机器有大约 25 个任务，将运行大约 4500 个线程 `[83]`。
尽管在应用程序之间共享机器提高了利用率，但它也需要良好的机制来防止任务相互干扰。这适用于安全性和性能。

#### 6.1 安全隔离

我们使用 Linux chroot jail 作为同一台机器上多个任务之间的主要安全隔离机制。
为了允许远程调试，我们曾经自动分发(和撤销)ssh 密钥，以便用户仅在机器为用户运行任务时才能访问它。
对于大多数用户来说，这已被 borgssh 命令所取代，该命令与 Borglet 合作构建到与任务在相同 chroot 和 cgroup 中运行的 shell 的 ssh 连接，从而更紧密地锁定访问。

谷歌的 AppEngine (GAE) `[38]` 和谷歌计算引擎 (GCE) 使用虚拟机和安全沙箱技术来运行外部软件。
我们在作为 Borg 任务运行的 KVM 进程 `[54]` 中运行每个托管 VM。

#### 6.2 性能隔离

Borglet 的早期版本具有相对原始的资源隔离强制：对内存、磁盘空间和 CPU 周期进行事后使用检查，同时终止使用过多内存或磁盘的任务，并积极应用 Linux 的 CPU 优先级来控制使用过多 CPU 的任务。
但是流氓任务仍然太容易影响机器上其他任务的性能，因此一些用户夸大了他们的资源请求，以减少 Borg 可以与他们共同调度的任务数量，从而降低利用率。
由于涉及安全边际，资源回收可以收回部分盈余，但不是全部。在最极端的情况下，用户请求使用专用机器或单元。

现在，所有 Borg 任务都在基于 Linux cgroup 的资源容器内运行 `[17, 58, 62]` 并且 Borglet 操作容器设置，由于操作系统内核处于循环中，因此提供了大大改进的控制。
即便如此，偶尔的低级资源干扰(例如，内存带宽或 L3 缓存污染)仍然会发生，如 `[60, 83]`。

为了帮助处理过载和过度使用，Borg 任务有一个应用程序类或应用程序类。
最重要的区别在于延迟敏感 (LS) 应用程序类和其他应用程序类之间的区别，我们在本文中将其称为批处理。
LS 任务用于需要快速响应请求的面向用户的应用程序和共享基础设施服务。
高优先级的 LS 任务得到最好的处理，并且能够一次使批处理任务暂时饥饿(缺少资源)几秒钟。

第二次分裂是在基于速率的可压缩资源(例如，CPU 周期、磁盘 I/O 带宽)之间进行划分，并且可以通过降低服务质量而不杀死它来从任务中回收；和不可压缩的资源(例如，内存、磁盘空间)，这些资源通常无法在不终止任务的情况下回收。
如果机器用完不可压缩的资源，Borglet 会立即终止任务，从最低到最高优先级，直到可以满足剩余的预留。
如果机器用完可压缩资源，Borglet 会限制使用(支持 LS 任务)，以便可以在不终止任何任务的情况下处理短暂的负载峰值。
如果情况没有改善，Borgmaster 将从机器中删除一项或多项任务。

Borglet 中的用户空间控制循环根据预测的未来使用情况(对于生产任务)或内存压力(对于非生产任务)为容器分配内存；处理来自内核的内存不足(OOM)事件；并在任务尝试分配超出其内存限制时，或者当过度使用的机器实际耗尽内存时终止任务。
由于需要准确的内存计算，Linux 的急切文件缓存使实现变得非常复杂。

为了提高性能隔离，LS 任务可以保留整个物理 CPU 内核，从而阻止其他 LS 任务使用它们。
批处理任务可以在任何内核上运行，但相对于 LS 任务，它们的调度程序份额很小。
Borglet 动态调整贪婪 LS 任务的资源上限，以确保它们不会让批处理任务饿死多分钟，在需要时选择性地应用 CFS 带宽控制 `[75]`；份额不足，因为我们有多个优先级。

与 Leverich `[56]` 一样，我们发现标准 Linux CPU 调度程序 (CFS) 需要大量调整以支持低延迟和高利用率。
为了减少调度延迟，我们的 CFS 版本使用扩展的每个 cgroup 加载历史记录 `[16]`，允许 LS 任务抢占批处理任务，并在多个 LS 任务可在 CPU 上运行时减少调度时间。
幸运的是，我们的许多应用程序都使用线程每请求模型，这减轻了持续负载不平衡的影响。我们谨慎地使用 cpuset 将 CPU 内核分配给具有特别严格的延迟要求的应用程序。
这些努力的一些结果如图 13 所示。该领域的工作仍在继续，添加线程放置和 CPU 管理，即 NUMA、超线程和功耗感知(例如，`[81]`)，并提高 Borglet 的控制保真度。

允许任务消耗资源达到其限制。他们中的大多数被允许超越 CPU 等可压缩资源的限制，以利用未使用的(松弛)资源。
只有 5% 的 LS 任务禁用此功能，大概是为了获得更好的可预测性；不到 1% 的批处理任务会这样做。
默认情况下禁用使用 slack 内存，因为它增加了任务被杀死的机会，但即便如此，10% 的 LS 任务会覆盖这一点，而 79% 的批处理任务会这样做，因为这是 MapReduce 框架的默认设置。
这补充了回收资源的结果(第 5.5 节)。
批处理任务愿意机会性地利用未使用和回收的内存：大多数情况下这是有效的，尽管当 LS 任务急需资源时，偶尔会牺牲批处理任务。

### 7 相关工作

资源调度已被研究了数十年，其环境多种多样，如广域 HPC 超级计算网格、工作站网络和大型服务器集群。
我们在这里只关注大规模服务器集群环境中最相关的工作。

最近的几项研究分析了来自 Yahoo!、Google 和 Facebook `[20, 52, 63, 68, 70, 80, 82]` 的集群痕迹，并说明了这些现代数据中心和工作负载中固有的规模和异构性挑战。 `[69]` 包含集群管理器架构的分类。

Apache Mesos `[45]` 使用基于报价的机制在中央资源管理器(有点像 Borgmaster 减去其调度程序)和多个“框架”(例如 Hadoop `[41]` 和 Spark `[73]`)之间拆分资源管理和放置功能。
Borg 主要使用可扩展的基于请求的机制来集中这些功能。DRF `[29, 35, 36, 66]` 最初是为 Mesos 开发的； Borg 使用优先级和准入配额。
Mesos 开发人员已宣布将扩展 Mesos 以包括推测性资源分配和回收，并解决 `[69]` 中确定的一些问题。

YARN `[76]` 是一个以 Hadoop 为中心的集群管理器。
每个应用程序都有一个管理器，它与一个中央资源管理器协商它需要的资源； 这与 Google MapReduce 作业从 2008 年左右以来从 Borg 获取资源所使用的方案大致相同。
YARN 的资源管理器最近才变得容错。
一个相关的开源工作是 Hadoop 容量调度器 `[42]`，它通过容量保证、分层队列、弹性共享和公平性提供多租户支持。
YARN 最近已经扩展到支持多种资源类型、优先级、抢占和高级准入控制 `[21]`。
俄罗斯方块研究原型 `[40]` 支持制作跨度感知的作业打包。

Facebook 的 Tupperware `[64]`，是一个类似于 Borg 的系统，用于在集群上调度 cgroup 容器；虽然它似乎提供了一种资源回收的形式，但只披露了一些细节。
Twitter 开源了 Aurora `[5]`，这是一个类似于 Borg 的调度程序，用于在 Mesos 之上运行的长时间运行的服务，具有类似于 Borg 的配置语言和状态机。

Microsoft `[48]` 的 Autopilot 系统提供了“自动化软件供应和部署；系统监控；并针对 Microsoft 群集执行修复操作以处理错误的软件和硬件”。
Borg 生态系统提供了类似的功能，但篇幅限制了这里的讨论； Isaard `[48]` 概述了我们也遵循的许多最佳实践。

Quincy `[49]` 使用网络流模型为数百个节点的集群上的数据处理 DAG 提供公平性和数据位置感知调度。
Borg 使用配额和优先级在用户之间共享资源并扩展到数万台机器。Quincy 直接处理执行图，而它是在 Borg 之上单独构建的。

Cosmos `[44]` 专注于批处理，强调确保其用户能够公平地访问他们捐赠给集群的资源。它使用 per-job manager 来获取资源；但很少公开实现细节。

微软的 Apollo 系统 `[13]` 使用 per-job 调度程序进行短期批处理作业，以在似乎与 Borg 单元相当大小的集群上实现高吞吐量。
Apollo 使用机会执行较低优先级的后台工作，以(有时)多天排队延迟为代价将利用率提高到高水平。
Apollo 节点提供任务开始时间的预测矩阵，作为两个资源维度大小的函数，调度程序将其与启动成本和远程数据访问的估计相结合，以做出放置决策，并通过随机延迟进行调制以减少冲突。
Borg 使用中央调度器根据先前分配的状态进行放置决策，可以处理更多资源维度，并专注于高可用性、长时间运行的应用程序的需求；Apollo 可能可以处理更高的任务到达率。

阿里巴巴的 Fuxi `[84]` 支持数据分析工作负载；它从 2009 年开始运行。与 Borgmaster 一样，中央 FuxiMaster(为了容错而复制)从节点收集资源可用性信息，接受来自应用程序的请求，并相互匹配。
Fuxi 增量调度策略与 Borg 的等价类相反：Fuxi 将新可用资源与待处理工作的积压相匹配，而不是将每个任务与一组合适的机器匹配。
与 Mesos 一样，Fuxi 允许定义“虚拟资源”类型。只有合成工作负载的结果是公开的。

Omega `[69]` 支持多个并行的、专门的“vertical"，它大致相当于一个 Borgmaster 减去它的持久存储和链接分片。
Omega 调度器使用乐观并发控制来操纵存储在中央持久存储中的所需和观察到的单元状态的共享表示，该状态通过单独的链接组件与 Borglets 同步。
Omega 架构旨在支持多个不同的工作负载，这些工作负载具有自己的特定于应用程序的 RPC 接口、状态机和调度策略(例如，长时间运行的服务器、来自各种框架的批处理作业、集群存储系统等基础设施服务、来自谷歌云平台)。
另一方面，Borg 提供了“一刀切”的 RPC 接口、状态机语义和调度程序策略，由于需要支持许多不同的工作负载，它们的大小和复杂性随着时间的推移而增长，而可扩展性尚未是一个问题(第 3.4 节)。

Google 的开源 Kubernetes 系统 `[53]` 将 Docker 容器 `[28]` 中的应用程序放置在多个主机节点上。
它既可以在裸机(如 Borg)上运行，也可以在各种云托管服务提供商(如 Google Compute Engine)上运行。
许多建造 Borg 的工程师正在积极开发它。Google 提供了一个托管版本，称为 Google Container Engine `[39]`。
我们将在下一节讨论如何将 Borg 的经验教训应用于 Kubernetes。

高性能计算社区在该领域有着悠久的工作传统(例如 Maui、Moab、Platform LSF `[2, 47, 50]`)；然而，规模、工作负载和容错的要求与谷歌的单元不同。
通常，此类系统通过大量待办工作的积压(队列)来实现高利用率。

VMware `[77]` 等虚拟化提供商和 HP 和 IBM `[46]` 等数据中心解决方案提供商提供的集群管理解决方案通常可扩展到 O(1000) 台机器。
此外，几个研究小组已经设计出以某些方式提高调度决策质量的系统原型(例如，`[25、40、72、74]`)。

最后，正如我们所指出的，管理大规模集群的另一个重要部分是自动化和“运营商横向扩展”。
`[43]` 描述了如何规划故障、多租户、健康检查、准入控制和可重启性，以实现每个操作者管理大量机器。
Borg 的设计理念是相似的，它使我们能够支持每个操作员(SRE)管理数以万计的机器。

### 8 经验教训和未来的工作

在本节中，我们将回顾我们从十多年来在生产中运行 Borg 中学到的一些定性经验教训，并描述如何利用这些观察结果来设计 Kubernetes `[53]`。

#### 8.1 经验教训：坏的方面

我们从 Borg 的一些作为警示故事的功能开始，并为 Kubernetes 中的替代设计提供了参考。

**作业作为任务的唯一分组机制是有局限性的。**
Borg 没有一流的方法来将整个多作业服务作为单个实体进行管理，或者引用服务的相关实例(例如，金丝雀(Canary)和生产轨道)。
作为一个黑客，用户在作业名称中编码他们的服务拓扑，并构建更高级别的管理工具来解析这些名称。
另一方面，不可能引用作业的任意子集，这会导致诸如滚动更新和作业调整大小不灵活的语义等问题。

为了避免这种困难，Kubernetes 拒绝了作业概念，而是使用标签来组织其调度单元(pod)——用户可以附加到系统中任何对象的任意键/值对。
可以通过将 job:jobname 标签附加到一组 pod 来实现 Borg 作业的等价物，但也可以表示任何其他有用的分组，例如服务、层或发布类型(例如，生产、暂存、测试)。
Kubernetes 中的操作通过标签查询来识别它们的目标，该标签查询选择操作应该应用到的对象。
这种方法比单一的固定作业分组具有更大的灵活性。

**每台机器一个 IP 地址会使事情复杂化。** 在 Borg 中，机器上的所有任务都使用其主机的单个 IP 地址，因此共享主机的端口空间。
这导致了许多困难：Borg 必须将端口作为资源进行调度； 任务必须预先声明它们需要多少端口，并愿意在启动时被告知使用哪些端口；Borglet 必须强制执行端口隔离；命名和 RPC 系统必须处理端口和 IP 地址。
由于 Linux 命名空间、VM、IPv6 和软件定义网络的出现，Kubernetes 可以采用更加用户友好的方法来消除这些复杂性：每个 pod 和服务都有自己的 IP 地址，允许开发人员选择端口而不是要求他们的软件适应基础设施选择的软件，并消除了管理端口的基础设施复杂性。

**以牺牲临时用户为代价为高级用户进行优化。**
Borg 提供了大量针对“高级用户”的功能，因此他们可以微调其程序的运行方式(BCL 规范列出了大约 230 个参数)：最初的重点是支持 Google 最大的资源消费者，为他们提高效率 收益是最重要的。
不幸的是，这个 API 的丰富性使“临时”用户的工作变得更加困难，并限制了它的发展。
我们的解决方案是构建在 Borg 之上运行的自动化工具和服务，并通过实验确定适当的设置。
这些受益于容错应用程序提供的试验自由：如果自动化出错，那只是麻烦，而不是灾难。

#### 8.2 经验教训：好的方面

另一方面，Borg 的许多设计特点非常有益，并且经受住了时间的考验。

**Alloc 很有用。** Borg alloc 抽象产生了广泛使用的日志保存模式(第 2.4 节)和另一种流行的模式，其中一个简单的数据加载器任务定期更新 Web 服务器使用的数据。
Alloc 和包允许由不同的团队开发此类帮助服务。Kubernetes 相当于 alloc 是 pod，它是一个或多个容器的资源信封，这些容器总是被调度到同一台机器上并且可以共享资源。
Kubernetes 在同一个 pod 中使用辅助容器，而不是在 alloc 中使用任务，但想法是一样的。

**集群管理不仅仅是任务管理。** 尽管 Borg 的主要角色是管理任务和机器的生命周期，但在 Borg 上运行的应用程序受益于许多其他集群服务，包括命名和负载平衡。
Kubernetes 使用服务抽象支持命名和负载平衡：服务具有名称和由标签选择器定义的动态 pod 集。集群中的任何容器都可以使用服务名称连接到服务。
在幕后，Kubernetes 会自动在与标签选择器匹配的 pod 之间平衡与服务的连接，并在 pod 因故障而重新调度时跟踪它们的运行位置。

**内省至关重要。** 尽管 Borg 几乎总是“正常工作”，但当出现问题时，找到根本原因可能具有挑战性。
Borg 的一个重要设计决策是向所有用户显示调试信息而不是隐藏它：Borg 有成千上万的用户，因此“自助”必须是调试的第一步。
尽管这让我们更难弃用功能并更改用户所依赖的内部策略，但这仍然是一个胜利，我们没有找到现实的替代方案。
为了处理海量数据，我们提供了多个级别的 UI 和调试工具，因此用户可以快速识别与其作业相关的异常事件，然后从其应用程序和基础架构本身深入了解详细的事件和错误日志。

Kubernetes 旨在复制 Borg 的许多内省技术。例如，它附带了用于资源监控的 cAdvisor `[15]` 等工具，以及基于 Elasticsearch/Kibana `[30]` 和 Fluentd `[32]` 的日志聚合。
可以查询 master 以获取其对象状态的快照。Kubernetes 有一个统一的机制，所有组件都可以使用该机制来记录可供客户端使用的事件(例如，一个 pod 被调度，一个容器失败)。

**Master是分布式系统的内核。** Borgmaster 最初被设计为一个整体系统，但随着时间的推移，它更像是一个内核，位于合作管理用户作业的服务生态系统的核心。
例如，我们将调度程序和主 UI(Sigma)拆分为单独的进程，并添加了用于准入控制、垂直和水平自动缩放、重新打包任务、定期作业提交(corn)、工作流管理和归档系统操作的服务用于离线查询。
总之，这些使我们能够在不牺牲性能或可维护性的情况下扩展工作负载和功能集。

Kubernetes 架构更进一步：它的核心有一个 API 服务器，它只负责处理请求和操作底层状态对象。
群集管理逻辑构建为小型、可组合的微服务，这些服务是此 API 服务器的客户端，例如 replication controller (在出现故障时维护 pod 的所需副本数量)和 node controller(管理机器生命周期)。

#### 8.3 结论

在过去十年中，几乎所有 Google 的集群工作负载都转而使用 Borg。我们将继续改进它，并将从中学到的经验应用到 Kubernetes 中。

### 致谢

```text
The authors of this paper performed the evaluations and
wrote the paper, but the dozens of engineers who designed, implemented, and maintained Borg’s components
and ecosystem are the key to its success. We list here just
those who participated most directly in the design, implementation, and operation of the Borgmaster and Borglets.
Our apologies if we missed anybody.

The initial Borgmaster was primarily designed and implemented by Jeremy Dion and Mark Vandevoorde, with
Ben Smith, Ken Ashcraft, Maricia Scott, Ming-Yee Iu, and
Monika Henzinger. The initial Borglet was primarily designed and implemented by Paul Menage.

Subsequent contributors include Abhishek Rai, Abhishek
Verma, Andy Zheng, Ashwin Kumar, Beng-Hong Lim,
Bin Zhang, Bolu Szewczyk, Brian Budge, Brian Grant,
Brian Wickman, Chengdu Huang, Cynthia Wong, Daniel
Smith, Dave Bort, David Oppenheimer, David Wall, Dawn
Chen, Eric Haugen, Eric Tune, Ethan Solomita, Gaurav Dhiman, Geeta Chaudhry, Greg Roelofs, Grzegorz Czajkowski,
James Eady, Jarek Kusmierek, Jaroslaw Przybylowicz, Jason Hickey, Javier Kohen, Jeremy Lau, Jerzy Szczepkowski,
John Wilkes, Jonathan Wilson, Joso Eterovic, Jutta Degener, Kai Backman, Kamil Yurtsever, Kenji Kaneda, Kevan Miller, Kurt Steinkraus, Leo Landa, Liza Fireman,
Madhukar Korupolu, Mark Logan, Markus Gutschke, Matt
Sparks, Maya Haridasan, Michael Abd-El-Malek, Michael
Kenniston, Mukesh Kumar, Nate Calvin, Onufry Wojtaszczyk,
Patrick Johnson, Pedro Valenzuela, Piotr Witusowski, Praveen
Kallakuri, Rafal Sokolowski, Richard Gooch, Rishi Gosalia, Rob Radez, Robert Hagmann, Robert Jardine, Robert
Kennedy, Rohit Jnagal, Roy Bryant, Rune Dahl, Scott Garriss, Scott Johnson, Sean Howarth, Sheena Madan, Smeeta
Jalan, Stan Chesnutt, Temo Arobelidze, Tim Hockin, Todd
Wang, Tomasz Blaszczyk, Tomasz Wozniak, Tomek Zielonka,
Victor Marmol, Vish Kannan, Vrigo Gokhale, Walfredo
Cirne, Walt Drummond, Weiran Liu, Xiaopan Zhang, Xiao
Zhang, Ye Zhao, and Zohaib Maya.

The Borg SRE team has also been crucial, and has included Adam Rogoyski, Alex Milivojevic, Anil Das, Cody
Smith, Cooper Bethea, Folke Behrens, Matt Liggett, James
Sanford, John Millikin, Matt Brown, Miki Habryn, Peter Dahl, Robert van Gent, Seppi Wilhelmi, Seth Hettich,
Torsten Marek, and Viraj Alankar. The Borg configuration
language (BCL) and borgcfg tool were originally developed
by Marcel van Lohuizen and Robert Griesemer.

We thank our reviewers (especially Eric Brewer, Malte
Schwarzkopf and Tom Rodeheffer), and our shepherd, Christos Kozyrakis, for their feedback on this paper.
```

### 参考资料

[1] O. A. Abdul-Rahman and K. Aida.
Towards understanding the usage behavior of Google cloud users: the mice and elephants phenomenon.
In Proc. IEEE Int’l Conf. on Cloud Computing Technology and Science (CloudCom), pages 272–277, Singapore, Dec. 2014.

[2] Adaptive Computing Enterprises Inc., Provo, UT. Maui Scheduler Administrator’s Guide, 3.2 edition, 2011.

[3] T. Akidau, A. Balikov, K. Bekiroglu, S. Chernyak, J. Haberman, R. Lax, S. McVeety, D. Mills, P. Nordstrom, and S. Whittle.
MillWheel: fault-tolerant stream processing at internet scale.
In Proc. Int’l Conf. on Very Large Data Bases (VLDB), pages 734–746, Riva del Garda, Italy, Aug.2013


[4] Y. Amir, B. Awerbuch, A. Barak, R. S. Borgstrom, and A. Keren.
An opportunity cost approach for job assignment in a scalable computing cluster.
IEEE Trans. Parallel Distrib. Syst., 11(7):760–768, July 2000.

[5] Apache Aurora. http://aurora.incubator.apache.org/, 2014.

[6] Aurora Configuration Tutorial. https://aurora.incubator.apache.org/documentation/latest/configuration-tutorial/, 2014

[7] AWS. Amazon Web Services VM Instances.http://aws.amazon.com/ec2/instance-types/, 2014.

[8] J. Baker, C. Bond, J. Corbett, J. Furman, A. Khorlin, J. Larson, J.-M. Leon, Y. Li, A. Lloyd, and V. Yushprakh.
Megastore: Providing scalable, highly available storage for interactive services.
In Proc. Conference on Innovative Data Systems Research (CIDR), pages 223–234, Asilomar, CA, USA, Jan. 2011.

[9] M. Baker and J. Ousterhout.
Availability in the Sprite distributed file system.
Operating Systems Review, 25(2):95–98, Apr. 1991.

[10] L. A. Barroso, J. Clidaras, and U. Holzle.
The datacenter as a computer: an introduction to the design of warehouse-scale machines.
Morgan Claypool Publishers, 2nd edition, 2013.

[11] L. A. Barroso, J. Dean, and U. Holzle.
Web search for a planet: the Google cluster architecture.
In IEEE Micro, pages 22–28, 2003.

[12] I. Bokharouss.
GCL Viewer: a study in improving the understanding of GCL programs.
Technical report, Eindhoven Univ. of Technology, 2008. MS thesis.

[13] E. Boutin, J. Ekanayake, W. Lin, B. Shi, J. Zhou, Z. Qian, M. Wu, and L. Zhou.
Apollo: scalable and coordinated scheduling for cloud-scale computing.
In Proc. USENIX Symp. on Operating Systems Design and Implementation(OSDI), Oct. 2014.

[14] M. Burrows.
The Chubby lock service for loosely-coupled distributed systems.
In Proc. USENIX Symp. on Operating Systems Design and Implementation (OSDI), pages 335–350, Seattle, WA, USA, 2006.

[15] cAdvisor. https://github.com/google/cadvisor,2014.

[16] CFS per-entity load patches. http://lwn.net/Articles/531853, 2013.

[17] cgroups. http://en.wikipedia.org/wiki/Cgroups,2014.

[18] C. Chambers, A. Raniwala, F. Perry, S. Adams, R. R. Henry, R. Bradshaw, and N. Weizenbaum. 
FlumeJava: easy, efficient data-parallel pipelines.
In Proc. ACM SIGPLAN Conf. on Programming Language Design and Implementation (PLDI), pages 363–375, Toronto, Ontario, Canada, 2010.

[19] F. Chang, J. Dean, S. Ghemawat, W. C. Hsieh, D. A. Wallach, M. Burrows, T. Chandra, A. Fikes, and R. E. Gruber.
Bigtable: a distributed storage system for structured data.
ACM Trans. on Computer Systems, 26(2):4:1–4:26, June 2008.

[20] Y. Chen, S. Alspaugh, and R. H. Katz.
Design insights for MapReduce from diverse production workloads.
Technical Report UCB/EECS–2012–17, UC Berkeley, Jan. 2012.

[21] C. Curino, D. E. Difallah, C. Douglas, S. Krishnan, R. Ramakrishnan, and S. Rao.
Reservation-based scheduling: if you’re late don’t blame us! 
In Proc. ACM Symp. on Cloud Computing (SoCC), pages 2:1–2:14, Seattle, WA, USA,2014.

[22] J. Dean and L. A. Barroso.
The tail at scale.
Communications of the ACM, 56(2):74–80, Feb. 2012.

[23] J. Dean and S. Ghemawat.
MapReduce: simplified data processing on large clusters.
Communications of the ACM, 51(1):107–113, 2008.

[24] C. Delimitrou and C. Kozyrakis.
Paragon: QoS-aware scheduling for heterogeneous datacenters.
In Proc. Int’l Conf. on Architectural Support for Programming Languages and Operating Systems (ASPLOS), Mar. 201.

[25] C. Delimitrou and C. Kozyrakis. Quasar: resource-efficient and QoS-aware cluster management.
In Proc. Int’l Conf. on Architectural Support for Programming Languages and Operating Systems (ASPLOS), pages 127–144, Salt Lake City, UT, USA, 2014.

[26] S. Di, D. Kondo, and W. Cirne. Characterization and comparison of cloud versus Grid workloads.
In International Conference on Cluster Computing (IEEE CLUSTER), pages 230–238, Beijing, China, Sept. 2012.

[27] S. Di, D. Kondo, and C. Franck. Characterizing cloud applications on a Google data center.
In Proc. Int’l Conf. on Parallel Processing (ICPP), Lyon, France, Oct. 2013.

[28] Docker Project. https://www.docker.io/, 2014.

[29] D. Dolev, D. G. Feitelson, J. Y. Halpern, R. Kupferman, and N. Linial.
No justified complaints: on fair sharing of multiple resources.
In Proc. Innovations in Theoretical Computer Science (ITCS), pages 68–75, Cambridge, MA, USA, 2012.

[30] ElasticSearch. http://www.elasticsearch.org, 2014.

[31] D. G. Feitelson.
Workload Modeling for Computer Systems Performance Evaluation.
Cambridge University Press, 2014.

[32] Fluentd. http://www.fluentd.org/, 2014.

[33] GCE. Google Compute Engine. http://cloud.google.com/products/compute-engine/

[34] S. Ghemawat, H. Gobioff, and S.-T. Leung.
The Google File System.
In Proc. ACM Symp. on Operating Systems Principles (SOSP), pages 29–43, Bolton Landing, NY, USA, 2003. ACM.


[35] A. Ghodsi, M. Zaharia, B. Hindman, A. Konwinski, S. Shenker, and I. Stoica.
Dominant Resource Fairness: fair allocation of multiple resource types.
In Proc. USENIX Symp. on Networked Systems Design and Implementation (NSDI), pages 323–326, 2011.

[36] A. Ghodsi, M. Zaharia, S. Shenker, and I. Stoica. 
Choosy:max-min fair sharing for datacenter jobs with constraints.
In Proc. European Conf. on Computer Systems (EuroSys), pages 365–378, Prague, Czech Republic, 2013.

[37] D. Gmach, J. Rolia, and L. Cherkasova.
Selling T-shirts and time shares in the cloud.
In Proc. IEEE/ACM Int’l Symp. on Cluster, Cloud and Grid Computing (CCGrid), pages 539–546, Ottawa, Canada, 2012.

[38] Google App Engine.http://cloud.google.com/AppEngine, 2014.

[39] Google Container Engine (GKE). https://cloud.google.com/container-engine/,2015.

[40] R. Grandl, G. Ananthanarayanan, S. Kandula, S. Rao, and A. Akella.
Multi-resource packing for cluster schedulers.
In Proc. ACM SIGCOMM, Aug. 2014.

[41] Apache Hadoop Project. http://hadoop.apache.org/,2009.

[42] Hadoop MapReduce Next Generation – Capacity Scheduler.
http://hadoop.apache.org/docs/r2.2.0/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html, 2013.

[43] J. Hamilton.
On designing and deploying internet-scale services.
In Proc. Large Installation System Administration Conf. (LISA), pages 231–242, Dallas, TX, USA, Nov. 2007.

[44] P. Helland. Cosmos: big data and big challenges.
http://research.microsoft.com/en-us/events/fs2011/helland\_cosmos\_big\_data\_and\_big\_challenges.pdf, 2011.

[45] B. Hindman, A. Konwinski, M. Zaharia, A. Ghodsi, A. Joseph, R. Katz, S. Shenker, and I. Stoica.
Mesos: a platform for fine-grained resource sharing in the data center.
In Proc. USENIX Symp. on Networked Systems Design and Implementation (NSDI), 2011.

[46] IBM Platform Computing. http://www-03.ibm.com/systems/technicalcomputing/platformcomputing/ products/clustermanager/index.html.

[47] S. Iqbal, R. Gupta, and Y.-C. Fang.
Planning considerations for job scheduling in HPC clusters.
Dell Power Solutions, Feb. 2005.

[48] M. Isaard. Autopilot: Automatic data center management. 
ACM SIGOPS Operating Systems Review, 41(2), 2007.

[49] M. Isard, V. Prabhakaran, J. Currey, U. Wieder, K. Talwar, and A. Goldberg.
Quincy: fair scheduling for distributed
computing clusters. In Proc. ACM Symp. on Operating Systems Principles (SOSP), 2009.

[50] D. B. Jackson, Q. Snell, and M. J. Clement.
Core algorithms of the Maui scheduler.
In Proc. Int’l Workshop on Job Scheduling Strategies for Parallel Processing, pages 87–102. Springer-Verlag, 2001.

[51] M. Kambadur, T. Moseley, R. Hank, and M. A. Kim.
Measuring interference between live datacenter applications.
In Proc. Int’l Conf. for High Performance Computing, Networking, Storage and Analysis (SC), Salt Lake City, UT, Nov. 2012.

[52] S. Kavulya, J. Tan, R. Gandhi, and P. Narasimhan. 
An analysis of traces from a production MapReduce cluster.
In Proc. IEEE/ACM Int’l Symp. on Cluster, Cloud and Grid Computing (CCGrid), pages 94–103, 2010.

[53] Kubernetes. http://kubernetes.io, Aug. 2014.

[54] Kernel Based Virtual Machine. http://www.linux-kvm.org.

[55] L. Lamport. The part-time parliament.
ACM Trans. on Computer Systems, 16(2):133–169, May 1998.

[56] J. Leverich and C. Kozyrakis.
Reconciling high server utilization and sub-millisecond quality-of-service.
In Proc. European Conf. on Computer Systems (EuroSys), page 4, 2014.

[57] Z. Liu and S. Cho.
Characterizing machines and workloads on a Google cluster.
In Proc. Int’l Workshop on Scheduling and Resource Management for Parallel and Distributed Systems (SRMPDS), Pittsburgh, PA, USA, Sept. 2012.

[58] Google LMCTFY project (let me contain that for you).
http://github.com/google/lmctfy, 2014.

[59] G. Malewicz, M. H. Austern, A. J. Bik, J. C. Dehnert, I. Horn, N. Leiser, and G. Czajkowski. 
Pregel: a system for large-scale graph processing.
In Proc. ACM SIGMOD Conference, pages 135–146, Indianapolis, IA, USA, 2010.

[60] J. Mars, L. Tang, R. Hundt, K. Skadron, and M. L. Soffa.
Bubble-Up: increasing utilization in modern warehouse scale computers via sensible co-locations.
In Proc. Int’l Symp. on Microarchitecture (Micro), Porto Alegre, Brazil, 2011.

[61] S. Melnik, A. Gubarev, J. J. Long, G. Romer, S. Shivakumar, M. Tolton, and T. Vassilakis.
Dremel: interactive analysis of web-scale datasets.
In Proc. Int’l Conf. on Very Large Data Bases (VLDB), pages 330–339, Singapore, Sept. 2010.

[62] P. Menage. Linux control groups.
http://www.kernel.org/doc/Documentation/cgroups/cgroups.txt, 2007–2014.

[63] A. K. Mishra, J. L. Hellerstein, W. Cirne, and C. R. Das.
Towards characterizing cloud backend workloads: insights from Google compute clusters.
ACM SIGMETRICS Performance Evaluation Review, 37:34–41, Mar. 2010.

[64] A. Narayanan.
Tupperware: containerized deployment at Facebook.
http://www.slideshare.net/dotCloud/tupperware-containerized-deployment-at-facebook, June 2014.

[65] K. Ousterhout, P. Wendell, M. Zaharia, and I. Stoica.
Sparrow: distributed, low latency scheduling.
In Proc. ACM Symp. on Operating Systems Principles (SOSP), pages 69–84, Farminton, PA, USA, 2013.

[66] D. C. Parkes, A. D. Procaccia, and N. Shah.
Beyond Dominant Resource Fairness: extensions, limitations, and indivisibilities.
In Proc. Electronic Commerce, pages 808–825, Valencia, Spain, 2012.

[67] Protocol buffers. 
https://developers.google.com/protocol-buffers/, and https://github.com/google/protobuf/., 2014.

[68] C. Reiss, A. Tumanov, G. Ganger, R. Katz, and M. Kozuch.
Heterogeneity and dynamicity of clouds at scale: Google trace analysis.
In Proc. ACM Symp. on Cloud Computing(SoCC), San Jose, CA, USA, Oct. 2012.

[69] M. Schwarzkopf, A. Konwinski, M. Abd-El-Malek, and J. Wilkes.
Omega: flexible, scalable schedulers for large compute clusters.
In Proc. European Conf. on Computer Systems (EuroSys), Prague, Czech Republic, 2013.

[70] B. Sharma, V. Chudnovsky, J. L. Hellerstein, R. Rifaat, and C. R. Das.
Modeling and synthesizing task placement constraints in Google compute clusters.
In Proc. ACM Symp. on Cloud Computing (SoCC), pages 3:1–3:14, Cascais, Portugal, Oct. 2011.

[71] E. Shmueli and D. G. Feitelson.
On simulation and design of parallel-systems schedulers: are we doing the right thing?
IEEE Trans. on Parallel and Distributed Systems, 20(7):983–996, July 2009.

[72] A. Singh, M. Korupolu, and D. Mohapatra. Server-storage
virtualization: integration and load balancing in data centers.
In Proc. Int’l Conf. for High Performance Computing, Networking, Storage and Analysis (SC), pages 53:1–53:12, Austin, TX, USA, 2008.

[73] Apache Spark Project.
http://spark.apache.org/, 2014.

[74] A. Tumanov, J. Cipar, M. A. Kozuch, and G. R. Ganger.
Alsched: algebraic scheduling of mixed workloads in heterogeneous clouds.
In Proc. ACM Symp. on Cloud Computing (SoCC), San Jose, CA, USA, Oct. 2012.

[75] P. Turner, B. Rao, and N. Rao.
CPU bandwidth control for CFS.
In Proc. Linux Symposium, pages 245–254, July 2010.

[76] V. K. Vavilapalli, A. C. Murthy, C. Douglas, S. Agarwal, M. Konar, R. Evans, T. Graves, J. Lowe, H. Shah, S. Seth, B. Saha, C. Curino, O. O’Malley, S. Radia, B. Reed, and E. Baldeschwieler.
Apache Hadoop YARN: Yet Another Resource Negotiator.
In Proc. ACM Symp. on Cloud Computing (SoCC), Santa Clara, CA, USA, 2013.

[77] VMware VCloud Suite.
http://www.vmware.com/products/vcloud-suite/.

[78] A. Verma, M. Korupolu, and J. Wilkes.
Evaluating job packing in warehouse-scale computing.
In IEEE Cluster, pages 48–56, Madrid, Spain, Sept. 2014.

[79] W. Whitt.
Open and closed models for networks of queues. 
AT&T Bell Labs Technical Journal, 63(9), Nov. 1984.

[80] J. Wilkes.
More Google cluster data.
http://googleresearch.blogspot.com/2011/11/more-google-cluster-data.html, Nov. 2011.

[81] Y. Zhai, X. Zhang, S. Eranian, L. Tang, and J. Mars.
HaPPy: Hyperthread-aware power profiling dynamically.
In Proc. USENIX Annual Technical Conf. (USENIX ATC), pages 211–217, Philadelphia, PA, USA, June 2014. USENIX Association.

[82] Q. Zhang, J. Hellerstein, and R. Boutaba. 
Characterizing task usage shapes in Google’s compute clusters.
In Proc. Int’l Workshop on Large-Scale Distributed Systems and Middleware (LADIS), 2011.

[83] X. Zhang, E. Tune, R. Hagmann, R. Jnagal, V. Gokhale, and J. Wilkes.
CPI2: CPU performance isolation for shared compute clusters.
In Proc. European Conf. on Computer Systems (EuroSys), Prague, Czech Republic, 2013.

[84] Z. Zhang, C. Li, Y. Tao, R. Yang, H. Tang, and J. Xu.
Fuxi: a fault-tolerant resource management and job scheduling system at internet scale. 
In Proc. Int’l Conf. on Very Large Data Bases (VLDB), pages 1393–1404. VLDB Endowment Inc., Sept. 2014.