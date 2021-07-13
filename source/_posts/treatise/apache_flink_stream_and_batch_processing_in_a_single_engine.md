---
title: "Apache Flink: Stream and Batch Processing in a Single Engine 中文翻译"
date: 2021-07-12 22:26:13
tags:
- "论文"
- "Flink"
id: apache_flink_stream_and_batch_processing_in_a_single_engine
no_word_count: true
no_toc: false
categories: 大数据
---

## Apache Flink: Stream and Batch Processing in a Single Engine 中文翻译

作者：Paris Carbone, Asterios Katsifodimos, Stephan Ewen, Volker Markl, Seif Haridi, Kostas Tzoumas

[英文原文](http://www.diva-portal.org/smash/get/diva2:1059537/FULLTEXT01.pdf)

### 摘要

Apache Flink 是一个用于处理流数据和批处理数据的开源系统。
Flink 建立在这样的理念之上，即许多类别的数据处理应用程序，包括实时分析、连续的数据管道、历史数据处理(批处理)和迭代算法(机器学习、图分析)
都可以表示为可执行的并且容错的管道数据流。
在本文中，我们展示了 Flink 的架构，并扩展了如何在单个执行模型下统一一组(看似多样化的)用例。

### 1 引言

数据流处理(例如，以复杂事件处理系统为例)和静态(批处理)数据处理(例如，以 MPP 数据库和 Hadoop 为例)传统上被视为两种截然不同的应用程序类型。
它们使用不同的编程模型和 API 进行编程，并由不同的系统执行
(例如专用流系统有 Apache Storm、IBM Infosphere Streams、Microsoft StreamInsight 或 Streambase 与关系数据库或 Hadoop 的执行引擎，
包括 Apache Spark 和 Apache Drill)
传统上，批处理数据分析占用例、数据大小和市场的最大份额，而流数据分析主要服务于专门的应用程序。

然而，越来越明显的是，当今大量的大规模数据处理用例处理的数据实际上是随着时间的推移不断产生的。
例如，这些连续的数据流来自 Web 日志、应用程序日志、传感器，或数据库中应用程序状态的变化(事务日志记录)。
今天大多数的处理方式大多忽略了数据生产的连续性和及时性，针对数据流进行处理。
取而代之的是，数据(通常是人为地)被分批成静态数据集(例如，每小时、每天或每月的数据块)，然后以与时间无关的方式进行处理。
数据收集工具、工作流管理器和调度程序在实际上是连续数据处理管道中协调批次的创建和处理。
诸如“lambda 架构” `[21]` 之类的架构模式结合了批处理和流处理系统来实现多个计算路径:
用于及时近似结果的流式快速路径，以及用于后期精确结果的批处理离线路径。
由于使用了批处理的方式这些方法都存在较大的延时和较高的复杂性(连接和编排多个系统，并两次实现业务逻辑)以及不准确的问题，
因为时间维度没有由应用程序编码进行处理。

Apache Flink 遵循一种范式，即在编程模型和执行引擎中将数据流处理作为实时分析、连续流和批处理的统一模型。
结合允许准任意重放数据流的持久消息队列(如 Apache Kafka 或 Amazon Kinesis)，
流处理程序在实时处理最新事件、在大的时间窗口中定期连续聚合数据或处理 TB 级数据之间没有任何区别。
相反，这些不同类型的计算只是在持久流中的不同点开始处理，并在计算过程中保持不同形式的状态。
通过高度灵活的窗口机制，Flink 程序可以计算早期和近似，以及延迟和准确，结果相同，无需为两个用例组合不同的系统。
Flink 支持不同的时间概念(事件时间、摄取时间、处理时间)，以便让程序员在定义事件应该如何关联方面具有高度的灵活性。

同时，Flink 也认为将需要专门的数据进行批处理(处理静态数据集)。
对静态数据的复杂查询仍然非常适合批处理抽象。
此外，对于流用例的传统实现和分析应用程序，仍然需要批处理，在这些应用程序中，尚不知道对流数据执行此类处理的有效算法。
批处理程序是流程序的特例，其中流是有限的，记录的顺序和时间无关紧要(所有记录都隐含地属于一个全包窗口)。
然而，为了以具有竞争力的易用性和性能支持批处理用例，Flink 有一个专门的 API 来处理静态数据集，
使用专门的数据结构和算法来处理诸如 join 或 grouping 等运算符的批处理版本，并使用专用的调度策略。
结果是 Flink 将自己呈现为一个基于流运行时的成熟高效的批处理器，包括用于图形分析和机器学习的库。
Flink 起源于 Stratosphere 项目 `[4]`，是 Apache 软件基金会的顶级项目，
由一个庞大而活跃的社区(截至撰写本文时由 180 多个开源贡献者组成)开发和支持，并在几家公司的生产中使用。
本文的贡献如下：

- 建设了流和批处理数据处理的统一架构，包括仅与静态数据集相关的特定优化
- 我们展示了流、批处理、迭代和交互式分析如何表示为容错流数据流(第 3 节)
- 我们讨论如何在这些数据流之上构建具有灵活窗口机制(第 4 节)以及成熟的批处理器(第 4.1 节)的成熟的流分析系统，
  通过展示流处理，批处理，迭代处理和交互式分析转换为数据流(streaming dataflows)
  
### 2 系统架构

在本节中，我们将 Flink 的架构布局分为软件堆栈和分布式系统进行展示。
虽然 Flink 的 API 堆栈不断增长，但我们可以区分四个主要层：部署、核心、API 和库。

**Flink 的运行环境和 API**

![图 1：Flink 软件堆栈](https://i.loli.net/2021/07/12/2ZSgTGHPxYDrVUC.png)

图 1 显示了 Flink 的软件堆栈。
Flink 的核心是分布式数据流引擎，它执行数据流程序。
Flink 运行时程序是连接的有状态算子的 DAG 与数据流。
Flink 中有两个核心 API：用于处理有限数据集(通常称为批处理)的 DataSet API，以及用于处理潜在无界数据流(通常称为流处理)的 DataStream API。
Flink 的核心运行时引擎可以看作是一个流式数据流引擎，DataSet 和 DataStream API 都创建了引擎可执行的运行时程序。
因此，它作为通用结构来抽象有界(批处理)和无界(流)处理。
在核心 API 之上，Flink 捆绑了特定领域的库和 API，用于生成 DataSet 和 DataStream API 程序。
目前，FlinkML 用于机器学习，Gelly 用于图形处理和 Table 用于类似 SQL 的操作。

![图 2：Flink 处理模型](https://i.loli.net/2021/07/12/tErYXBFAhqlRsGg.png)

如图 2 所示，一个 Flink 集群包含三种类型的进程：客户端(client)、作业管理器(JobManager)和至少一个任务管理器(TaskManager)。
客户端获取程序代码，将其转换为数据流图，然后将其提交给作业管理器。
此转换阶段还检查运算符之间交换的数据的数据类型(schema)，并创建序列化程序和其他类型/模式特定的代码。
DataSet 程序还经过一个基于成本的查询优化阶段，类似于物理优化，通过关系查询优化器进行(详情参见4.1节)。

作业管理器制定了数据流的分布式执行计划。
它跟踪每个操作和流的状态和进度，安排新的操作，并协调检查点和恢复。
在高可用性设置中，作业管理器将每个检查点的最小元数据集保存到容错存储，以便备用作业管理器可以重建检查点并从那里恢复数据流并重新开始执行。
实际的数据处理发生在任务管理器中。
任务管理器执行一个或多个产生流的操作，并将它们的状态报告给作业管理器。
任务管理器维护了缓冲池以缓冲或物化流，并维护网络连接以在操作之间交换数据流。

### 3 通用结构：数据流

尽管用户可以使用多种 API 编写 Flink 程序，但所有 Flink 程序最终都会编译为一个通用表示：数据流图。
数据流图由 Flink 的运行时引擎执行，这是批处理(DataSet)和流处理(DataStream) API 下的公共层。

#### 3.1 数据流图

![图 3：示例数据流图](https://i.loli.net/2021/07/12/k96gXlHtI7CYSDu.png)

图 3 中描绘的数据流图是一个有向无环图(DAG)，它包括：(i)有状态运算操作(stateful operators) 和 (ii) 经由运算操作生成可被使用的数据流(data streams)。
由于数据流图以数据并行的方式执行，操作被并行化为一个或多个称为子任务的并行实例，并且流被分成一个或多个流分区（每个生产子任务一个分区）。
在特殊情况下有状态运算操作可以是无状态的，它实现了所有的逻辑处理(例如，过滤、哈希连接和流式窗口函数)
许多的运算操作是由众所周知算法的教科书级别的代码实现。
在第 4 节中，我们提供了有关窗口运算符实现的详细信息。
流以各种模式在生产者和消费者之间分配数据，例如点对点、广播、重新分区、扇出和合并。

> 注：扇出指的是将消息发送到所有的主题。

#### 3.2 通过中间数据流进行数据交换

Flink 的中间数据流是操作之间数据交换的核心抽象。
中间数据流表示对由操作产生并且可由一个或多个操作使用的数据的逻辑句柄。
中间流是逻辑的，因为它们指向的数据可能会或可能不会在磁盘上进行物化。
数据流的特定行为由 Flink 中的高层进行参数化(例如，DataSet API 使用的程序优化器)。

**管道和阻塞数据交换**
管道的中间流在并发运行的生产者和消费者之间交换数据，从而执行管道。
因此，管道将背压从消费者传播到生产者，通过中间缓冲池进行缓冲，以补偿短期吞吐量波动。
Flink 对连续的流式程序以及批处理数据流中的许多部分使用管道的方式，以便在可能的情况下避免物化。
另一方面，阻塞流适用于有界数据流。
阻塞流缓冲所有生产操作的数据，然后使其可供消费，从而将生产运算符和消费操作分为不同的执行阶段。
阻塞流自然需要更多内存，经常溢出到二级存储，并且不会传播背压。
它们会在需要的地方将连续的操作彼此隔离，例如需要破坏当前管道的情况(例如排序合并连接)或可能导致分布式死锁的情况下。

![图 4：缓冲区超时对延迟和吞吐量的影响](https://i.loli.net/2021/07/12/upX7fEtWly4jiUZ.png)

**平衡延迟和吞吐量**
Flink 的数据交换机制是围绕缓冲区的交换实现的。
当一个数据记录在生产者端准备好时，它被序列化并分成一个或多个缓冲区(一个缓冲区也可以容纳多个记录)，可以转发给消费者。
缓冲区在 i) 满时或 ii) 达到超时条件时立即发送给使用者。
这使 Flink 能够通过将缓冲区的大小设置为高值(例如，几千字节)来实现高吞吐量，并通过将缓冲区超时设置为低值(例如，几毫秒)来实现低延迟。
图 4 显示了缓冲区超时对在 30 台机器(120 个内核)上的简单流式 grep 作业中传送记录的吞吐量和延迟的影响。
可以看到 Flink 能够在 99% 实现 20ms 的演示。
相应的吞吐量为每秒 150 万个事件。
随着我们增加缓冲区超时，我们看到延迟随着吞吐量的增加而增加，直到达到最大吞吐量(即缓冲区填满的速度快于超时到期)。
在 50ms 的缓冲区超时时，集群达到每秒超过 8000 万个事件的吞吐量，99% 的延迟为 50ms

**控制事件**
除了交换数据，Flink 中的流还传达了不同类型的控制事件。
这些是操作在数据流中注入的特殊事件，并与流分区内的所有其他数据记录和事件一起按顺序交付。
接收操作通过在它们到达时执行某些操作来对这些事件做出反应。
Flink 使用了很多特殊类型的控制事件，包括：

- 检查点屏障通过将流划分为检查点前和检查点后(在第 3.3 节中讨论)来协调检查点
- 表示流分区内事件时间进度的水印(在第 4.1 节中讨论)
- 在循环数据流之上的 Bulk/StaleSynchronous-Parallel 迭代算法(在第 5.3 节中讨论)中，迭代障碍表明流分区已到达超级步的末尾。

如上所述，控制事件假定流分区保留记录的顺序。
为 此，Flink 中使用单个流分区的一元运算符保证记录的 FIFO 顺序。
但是，收到多个流分区的操作符会按到达顺序合并流，以跟上流的速率并避免背压。
因此，Flink 中的流式数据流在任何形式的重新分区或广播后都不提供排序保证，处理乱序记录的责任留给了操作员实现。
我们发现这种安排提供了最有效的设计，因为大多数运算符不需要确定性顺序(例如，散列连接、映射)，并且需要补偿无序到达的运算，
例如时间窗口可以作为运算逻辑的一部分，可以更有效地做到这一点。

#### 3.3 容错性

Flink 通过严格的一次性处理一致性保证提供可靠的执行，并通过检查点和部分重新执行来处理故障。
系统为有效提供这些保证而做出的一般假设是数据源是持久的和可重播的。
此类源的示例是文件和持久消息队列(例如，Apache Kafka)。
在实践中，也可以通过在源操作的状态内保留预写日志来合并非持久性源。

Apache Flink 的检查点机制建立在分布式一致快照的概念之上，以实现恰好一次处理的保证。
数据流可能无限的特性使得在恢复时重新计算变得不切实际，因为长时间运行的作业可能需要重放数月的计算。
为了限制恢复时间，Flink 会定期拍摄算子状态的快照，包括输入流的当前位置。

核心挑战在于在不停止拓扑执行的情况下对所有并行算子进行一致的快照。
本质上，所有算子的快照应该指的是计算中相同的逻辑时间。
Flink 中使用的机制称为 Asynchronous Barrier Snapshotting(ABS `[7]`)。
屏障是从注入到与逻辑时间相对应的输入流中的控制记录，并且在逻辑上将流进行分离，插入之前的数据就会被快照保存。

![图 5：异步屏障快照](https://i.loli.net/2021/07/12/poigwYz8jbStJdK.png)

操作从上游接收屏障并首先执行对齐阶段，确保已经接受到了输入的所有屏障。
然后，操作将其状态(例如，滑动窗口的内容或自定义数据结构)写入持久存储(例如，存储后端可以是外部系统，例如 HDFS)。
一旦状态被备份，操作将向下游转发屏障。
最终，所有操作都将注册其状态的快照，并且全局快照将完成。
例如在图 5 中，我们显示快照 t2 包含所有操作状态，这些状态是在 t2 屏障之前消耗所有记录的结果。
ABS 类似于用于异步分布式快照的 Chandy-Lamport 算法 `[11]`。
但是，由于 Flink 程序的 DAG 结构，ABS 不需要检查点飞行记录，而仅依靠对齐阶段将其所有影响应用于操作状态。
这保证了需要写入可靠存储的数据保持在理论上的最小值(即，仅操作的当前状态)。

从故障中恢复将所有操作状态恢复到从上次成功快照中获取的各自状态，并从有快照的最新屏障开始重新启动输入流。
恢复时所需的最大重新计算量限于两个连续障碍之间的输入记录量。
此外，通过额外重放在直接上游子任务中缓冲的未处理记录，可以部分恢复失败的子任务 `[7]`。

ABS 提供了几个好处：

i) 它保证只更新一次状态而不会暂停计算 
ii) 它与其他形式的控制消息完全分离(例如，通过触发窗口计算的事件，从而不限制窗口化机制到检查点间隔的倍数)
iii) 它与用于可靠存储的机制完全解耦，允许将状态备份到文件系统、数据库等，这取决于使用 Flink 的外部环境。

#### 3.4 迭代数据流

![图 6：Flink 的迭代模型](https://i.loli.net/2021/07/12/DaZ7tCuI1xvrYJ6.png)

增量处理和迭代对于应用程序至关重要，例如图形处理和机器学习。
对数据并行处理平台中迭代的支持通常依赖于为每次迭代提交一个新作业，或者通过向正在运行的 DAG `[6, 25]` 或反馈边 `[23]` 添加额外的节点。
Flink 中的迭代是作为迭代步骤实现的，特殊的操作本身可以包含一个执行图(图 6)。
为了维护基于 DAG 的运行时和调度程序，Flink 允许迭代“头”和“尾”任务，这些任务与反馈边隐式连接。
这些任务的作用是为迭代步骤建立一个活跃的反馈通道，并为在这个反馈通道内处理传输中的数据记录提供协调。
实现任何类型的结构化并行迭代模型(例如批量同步并行 (BSP) 模型)都需要协调，并且使用控制事件来实现。
我们分别在第 4.4 节和第 5.3 节中解释了如何在 DataStream 和 DataSet API 中实现迭代。

### 4 基于数据流的流式分析

Flink 的 DataStream API 在 Flink 的运行时之上实现了一个完整的流分析框架，包括管理时间的机制，例如乱序事件处理、定义窗口以及维护和更新用户定义的状态。
流 API 基于 DataStream 的概念，DataStream 是给定类型元素的(可能是无界的)不可变集合。
由于 Flink 的运行时已经支持流水线数据传输、连续状态操作符和用于一致状态更新的容错机制，因此在其上叠加流处理器本质上归结为实现窗口系统和状态接口。
如前所述，这些对于运行时是不可见的，运行时将窗口视为只是有状态运算符的实现。

#### 4.1 时间的概念

Flink 区分了两种时间概念：
i) 事件时间，它表示事件发生的时间(例如，与传感器(例如移动设备)产生的信号相关联的时间戳)
ii) 处理时间，它是正在处理数据的机器的挂钟时间。

在分布式系统中，事件时间和处理时间之间存在任意偏差 `[3]`。
这种偏斜可能意味着基于事件时间语义获得答案的任意延迟。
为了避免任意延迟，这些系统会定期插入称为低水印的特殊事件，用于标记全局进度度量。
例如，在时间进度的情况下，水印包括时间属性 t，指示所有低于 t 的事件都已经进入操作员。
水印有助于执行引擎以正确的事件顺序处理事件并序列化操作，例如通过统一的进度度量进行窗口计算。

水印起源于拓扑的源头，我们可以在其中确定未来元素的固有时间。
水印从源头通过数据流的其他操作符传播。
运营商决定他们如何对水印做出反应。
简单的操作，例如 map 或 filter 只是转发它们接收到的水印，而更复杂的基于水印(例如，事件时间窗口)进行计算的运算符首先计算由水印触发的结果，然后转发它。
如果一项操作有多个输入，系统只会将传入的最小水印转发给操作员，从而确保正确的结果。

基于处理时间的 Flink 程序依赖于本地机器时钟，因此具有不太可靠的时间概念，这可能导致恢复时不一致的重放。
但是，它们表现出较低的延迟。
基于事件时间的程序提供最可靠的语义，但由于事件时间处理时间滞后可能会出现延迟。
Flink 包含第三个时间概念，作为事件时间的一种特殊情况，称为摄取时间，即事件进入 Flink 的时间。
与事件时间相比，这实现了更低的处理延迟，并导致与处理时间相比更准确的结果。

#### 4.2 有状态流处理

虽然 Flink 的 DataStream API 中的大多数算子看起来像函数式、无副作用的算子，但它们为高效的有状态计算提供支持。
状态对于许多应用程序至关重要，例如机器学习模型构建、图形分析、用户会话处理和窗口聚合。
根据用例，有大量不同类型的状态。
例如，状态可以是简单的计数器或总和或更复杂的东西，例如机器学习应用程序中经常使用的分类树或大型稀疏矩阵。
流窗口是有状态的运算符，它将记录分配给作为运算符状态一部分保存在内存中的不断更新的桶。

在 Flink 中，状态是显式的，并通过提供：
i) 操作员接口或注释来静态注册在操作员范围内的显式局部变量，
ii) 用于声明分区键值状态及其的操作员状态抽象相关操作。

用户还可以使用系统提供的 StateBackend 抽象来配置状态的存储和检查点，从而在流应用程序中实现高度灵活的自定义状态管理。
Flink 的检查点机制(在 3.3 节中讨论)保证任何注册状态都是持久的，并且具有一次性更新语义。

#### 4.3 流窗口

无界流上的增量计算通常在不断发展的逻辑视图(称为窗口)上进行评估。
Apache Flink 将窗口合并到一个有状态操作符中，该操作符通过一个灵活的声明进行配置，该声明由三个核心函数组成：窗口分配器以及可选的触发器和驱逐器。
所有三个函数都可以从一组常见的预定义实现(例如，滑动时间窗口)中选择，或者可以由用户明确定义(即，用户定义的函数)。

更具体地说，分配器负责将每个记录分配给逻辑窗口。
例如，当涉及到事件时间窗口时，此决定可以基于记录的时间戳。
请注意，在滑动窗口的情况下，一个元素可以属于多个逻辑窗口。
一个可选的触发器定义何时执行与窗口定义关联的操作。
最后，一个可选的 evictor 决定在每个窗口中保留哪些记录。
Flink 的窗口分配过程能够覆盖所有已知的窗口类型，例如周期性时间窗口和计数窗口、标点符号、地标、会话和增量窗口。
请注意，Flink 的窗口功能无缝地整合了乱序处理，类似于 Google Cloud Dataflow `[3]`，并且原则上包含这些窗口模型。
例如，下面是一个窗口定义，范围为 6 秒，每 2 秒滑动一次(分配器)。
一旦水印通过窗口的末尾(触发器)，就会计算窗口结果。

```text
stream
    .window(SlidingTimeWindows.of(Time.of(6, SECONDS), Time.of(2, SECONDS))
    .trigger(EventTimeTrigger.create())
```

全局窗口创建单个逻辑组。
下面的示例定义了一个全局窗口(即分配器)，它对每 1000 个事件(即触发器)调用操作，同时保留最后 100 个元素(即驱逐器)。

```text
stream
    .window(GlobalWindow.create())
    .trigger(Count.of(1000))
    .evict(Count.of(100))
```

请注意，如果上面的流在窗口化之前在一个键上分区，上面的窗口操作是本地的，因此不需要工作节点之间的协调。
该机制可用于实现多种窗口功能 `[3]`。

#### 4.4 异步流迭代

流中的循环对于多个应用程序至关重要，例如增量构建和训练机器学习模型、强化学习和图形近似 `[9, 15]`。
在大多数情况下，反馈循环不需要协调。
异步迭代涵盖了流应用程序的通信需求，并且不同于基于有限数据结构化迭代的并行优化问题。
如第 3.4 节和图 6 所示，当未启用迭代控制机制时，Apache Flink 的执行模型已经涵盖了异步迭代。
此外，为了遵守容错保证，反馈流被视为隐式迭代头中的操作状态运算符，并且是全局快照 `[7]` 的一部分。
DataStream API 允许对反馈流进行明确定义，并且可以简单地包含对流 `[23`] 上的结构化循环以及进度跟踪 `[9]` 的支持。

### 5 基于数据流的批量数据分析

有界数据集是无界数据流的特例。
因此，一个将所有输入数据插入窗口的流程序可以形成一个批处理程序，批处理应该完全被 Flink 上面介绍的特性所含盖。
然而，i)可以简化语法(即用于批量计算的 API，例如，不需要定义人工全局窗口)和 ii)处理有界数据集的程序可以进行额外的优化，
更高效的完成记录保持容错性完成分阶段调度。

Flink 批处理的方式如下：

- 批处理计算由与流计算相同的运行时执行。运行时可执行文件可以使用阻塞的数据流进行参数化，以将大型计算分解为连续调度的孤立阶段。
- 定期快照在其开销很高时会被关闭。相反，可以通过从最新的物化中间流(可能是源)重放丢失的流分区来实现故障恢复。
- 阻塞运算(例如，排序)只是运算的实现，直到它们消费了全部输入才结束阻塞状态。运行时不知道操作是否阻塞。
  这些操作使用 Flink 提供的托管内存(无论是在 JVM 堆上还是在 JVM 堆外)，如果他们的输入超出其内存界限，则可能溢写到磁盘。
- 专用的数据集 API 为批量计算提供了熟悉的抽象，即有界容错数据集数据结构和数据集上的转换(例如，连接、聚合、迭代)。
- 查询优化层将 DataSet 程序转换为高效的可执行文件。

下面我们更详细地描述这些方面。

#### 5.1 查询优化

Flink 的优化器建立在并行数据库系统的技术之上，例如计划等效(plan equivalence)、成本建模(cost modeling)和兴趣属性传播(interesting property propagation)。
然而，构成 Flink 数据流程序的任意 UDF-heavy DAG 不允许传统优化器使用开箱即用的数据库技术 `[17]`，因为操作符对优化器隐藏了它们的语义。
出于同样的原因，基数和成本估计方法同样难以使用。
Flink 的运行时支持各种执行策略，包括重新分区和广播数据传输，以及基于排序的分组和基于排序和哈希的方式实现连接。
Flink 的优化器基于有趣的属性传播概念枚举不同的物理计划 `[26]`，使用基于成本的方法在多个物理计划中进行选择。
成本包括网络和磁盘 I/O 以及 CPU 成本。
为了克服 UDF 存在时的基数估计问题，Flink 的优化器可以使用程序员提供的提示。

#### 5.2 内存管理

基于数据库技术，Flink 将数据序列化到内存段中，而不是在 JVM 堆中分配对象来表示缓冲的动态数据记录。
排序和连接等操作尽可能直接对二进制数据进行操作，将序列化和反序列化开销保持在最低限度，并在需要时将部分数据溢出到磁盘。
为了处理任意对象，Flink 使用类型推断和自定义序列化机制。
通过将数据处理保持在二进制表示和堆外，Flink 设法减少了垃圾收集的开销，并使用缓存高效且健壮的算法在内存压力下优雅地扩展。

#### 5.3 批量迭代

迭代图分析、并行梯度下降和优化技术过去已经在批量同步并行(BSP)和陈旧同步并行(SSP)模型等基础上实现。
Flink 的执行模型允许通过使用迭代控制事件在顶部实现任何类型的结构化迭代逻辑。
例如，在 BSP 执行的情况下，迭代控制事件标记了迭代计算中超步的开始和结束。
最后，Flink 引入了更多新颖的优化技术，例如 delta 迭代的概念 `[14]`，它可以利用稀疏的计算依赖关系 Delta 迭代已经被 Flink 的 Graph API Gelly 所利用。

### 6 相关工作

今天，有大量用于分布式批处理和流分析处理的引擎。我们将主要系统分类如下。 

**批处理**
Apache Hadoop 是最流行的大规模数据分析开源系统之一，它基于 MapReduce 范式 `[12]`。
Dryad `[18]` 引入了嵌入式用户定义函数一般基于 DAG 的数据流，并由 SCOPE `[26]` 丰富，它是一种语言和基于它的 SQL 优化器。
Apache Tez `[24]` 可以看作是 Dryad 提出的想法的开源实现。
MPP 数据库 `[13]` 以及最近的开源实现(如 Apache Drill 和 Impala `[19]`)将其 API 限制为 SQL 变体。
与 Flink 类似，Apache Spark `[25]` 是一个数据处理框架，它实现了基于 DAG 的执行引擎，提供了 SQL 优化器，执行基于驱动程序的迭代，并将无界计算视为微批次。
相比之下，Flink 是唯一一个包含 i) 分布式数据流运行时的系统，该运行时利用流水线流式执行来处理批处理和流工作负载，
ii) 通过轻量级检查点实现一次状态一致性，iii) 本地迭代处理，iv) 复杂的窗口语义，支持乱序处理。

**流处理**
在学术和商业流处理系统(例如 SEEP、Naiad、Microsoft StreamInsight 和 IBM Streams)方面有大量的先前工作。
其中许多系统都基于数据库社区的研究 `[1, 5, 8, 10, 16, 22, 23]`。
上述大多数系统要么是 i) 学术原型，ii) 闭源商业产品，或 iii) 不在商品服务器集群上水平扩展计算。
最新的数据流方法支持水平可扩展性和组合数据流运算符，并具有较弱的状态一致性保证(例如，Apache Storm 和 Samza 中的至少一次处理)。
值得注意的是，诸如“乱序处理”(OOP) `[20]` 之类的概念获得了极大的吸引力，并被 MillWheel `[2]` 所采用，
它是后来提供的 Apache Beam/Google Dataflow `[3]` 商业执行器的 Google 内部版本。
Millwheel 充当了一次性低延迟流处理和 OOP 的概念证明，因此对 Flink 的演变非常有影响。
据我们所知，Flink 是唯一一个开源项目：i) 支持事件时间和无序事件处理 ii) 提供一致的托管状态，并保证只执行一次 iii) 实现高吞吐量和低延迟，提供批处理和流处理服务。

### 7 致谢

```text
The development of the Apache Flink project is overseen by a self-selected team of active contributors to the project.
A Project Management Committee (PMC) guides the project’s ongoing operations, including community development and product releases.
At the current time of writing this, the list of Flink committers are : Marton Balassi, Paris Carbone, Ufuk Celebi, Stephan Ewen, Gyula F ´ ora, Alan Gates, Greg Hogan, ´Fabian Hueske, Vasia Kalavri, Aljoscha Krettek, ChengXiang Li, Andra Lungu, Robert Metzger, Maximilian Michels, Chiwan Park, Till Rohrmann, Henry Saputra, Matthias J. Sax, Sebastian Schelter, Kostas Tzoumas, Timo Walther and Daniel Warneke.
In addition to these individuals, we want to acknowledge the broader Flink community of more than 180 contributors.
```

### 8 结论

在本文中，我们介绍了 Apache Flink，这是一个实现通用数据流引擎的平台，旨在执行流分析和批处理分析。
Flink 的数据流引擎将操作符状态和逻辑中间结果视为一等公民，并由具有不同参数的批处理和数据流 API 进行处理。
构建在 Flink 流数据流引擎之上的流 API 提供了保持可恢复状态以及分区、转换和聚合数据流窗口的方法。
虽然理论上批处理计算是流式计算的一个特例，但 Flink 对它们进行了特殊处理，通过使用查询优化器优化它们的执行并实现在没有内存的情况下优雅地溢出到磁盘的阻塞运算。

### 参考资料

[1] D. J. Abadi, Y. Ahmad, M. Balazinska, U. Cetintemel, M. Cherniack, J.-H. Hwang, W. Lindner, A. Maskey, A. Rasin,
E. Ryvkina, et al. The design of the Borealis stream processing engine. CIDR, 2005.

[2] T. Akidau, A. Balikov, K. Bekiroglu, S. Chernyak, J. Haberman, R. Lax, S. McVeety, D. Mills, P. Nordstrom, and
˘S. Whittle. Millwheel: fault-tolerant stream processing at Internet scale. PVLDB, 2013.

[3] T. Akidau, R. Bradshaw, C. Chambers, S. Chernyak, R. J. Fernandez-Moctezuma, R. Lax, S. McVeety, D. Mills,
´F. Perry, E. Schmidt, et al. The dataflow model: a practical approach to balancing correctness, latency, and cost in
massive-scale, unbounded, out-of-order data processing. PVLDB, 2015.

[4] A. Alexandrov, R. Bergmann, S. Ewen, J.-C. Freytag, F. Hueske, A. Heise, O. Kao, M. Leich, U. Leser, V. Markl,
F. Naumann, M. Peters, A. Rheinlaender, M. J. Sax, S. Schelter, M. Hoeger, K. Tzoumas, and D. Warneke. The
stratosphere platform for big data analytics. VLDB Journal, 2014.

[5] A. Arasu, B. Babcock, S. Babu, J. Cieslewicz, M. Datar, K. Ito, R. Motwani, U. Srivastava, and J. Widom. Stream:
The stanford data stream management system. Technical Report, 2004.

[6] Y. Bu, B. Howe, M. Balazinska, and M. D. Ernst. HaLoop: Efficient Iterative Data Processing on Large Clusters.
PVLDB, 2010.

[7] P. Carbone, G. Fora, S. Ewen, S. Haridi, and K. Tzoumas. Lightweight asynchronous snapshots for distributed ´
dataflows. arXiv:1506.08603, 2015.

[8] B. Chandramouli, J. Goldstein, M. Barnett, R. DeLine, D. Fisher, J. C. Platt, J. F. Terwilliger, and J. Wernsing. Trill:
a high-performance incremental query processor for diverse analytics. PVLDB, 2014.

[9] B. Chandramouli, J. Goldstein, and D. Maier. On-the-fly progress detection in iterative stream queries. PVLDB, 2009.

[10] S. Chandrasekaran and M. J. Franklin. Psoup: a system for streaming queries over streaming data. VLDB Journal, 2003.

[11] K. M. Chandy and L. Lamport. Distributed snapshots: determining global states of distributed systems. ACM TOCS, 1985.

[12] J. Dean et al. MapReduce: simplified data processing on large clusters. Communications of the ACM, 2008.

[13] D. J. DeWitt, S. Ghandeharizadeh, D. Schneider, A. Bricker, H.-I. Hsiao, R. Rasmussen, et al.
The gamma database machine project. IEEE TKDE, 1990.

[14] S. Ewen, K. Tzoumas, M. Kaufmann, and V. Markl. Spinning Fast Iterative Data Flows. PVLDB, 2012.

[15] J. Feigenbaum, S. Kannan, A. McGregor, S. Suri, and J. Zhang. On graph problems in a semi-streaming model.
Theoretical Computer Science, 2005.

[16] B. Gedik, H. Andrade, K.-L. Wu, P. S. Yu, and M. Doo. Spade: the system s declarative stream processing engine.
ACM SIGMOD, 2008.

[17] F. Hueske, M. Peters, M. J. Sax, A. Rheinlander, R. Bergmann, A. Krettek, and K. Tzoumas. 
Opening the Black Boxes in Data Flow Optimization. PVLDB, 2012.

[18] M. Isard, M. Budiu, Y. Yu, A. Birrell, and D. Fetterly.
Dryad: distributed data-parallel programs from sequential building blocks. ACM SIGOPS, 2007.

[19] M. Kornacker, A. Behm, V. Bittorf, T. Bobrovytsky, C. Ching, A. Choi, J. Erickson, M. Grund, D. Hecht, M. Jacobs,
et al. Impala: A modern, open-source sql engine for hadoop. CIDR, 2015.

[20] J. Li, K. Tufte, V. Shkapenyuk, V. Papadimos, T. Johnson, and D. Maier.
Out-of-order processing: a new architecture for high-performance stream systems. PVLDB, 2008.

[21] N. Marz and J. Warren. Big Data: Principles and best practices of scalable realtime data systems.
Manning Publications Co., 2015.

[22] M. Migliavacca, D. Eyers, J. Bacon, Y. Papagiannis, B. Shand, and P. Pietzuch. 
Seep: scalable and elastic event processing. ACM Middleware’10 Posters and Demos Track, 2010.

[23] D. G. Murray, F. McSherry, R. Isaacs, M. Isard, P. Barham, and M. Abadi. Naiad: a timely dataflow system.
ACM SOSP, 2013.

[24] B. Saha, H. Shah, S. Seth, G. Vijayaraghavan, A. Murthy, and C. Curino.
Apache tez: A unifying framework for modeling and building data processing applications. ACM SIGMOD, 2015.

[25] M. Zaharia, M. Chowdhury, M. J. Franklin, S. Shenker, and I. Stoica.
Spark: Cluster Computing with Working Sets. USENIX HotCloud, 2010.

[26] J. Zhou, P.-A. Larson, and R. Chaiken. Incorporating partitioning and parallel plans into the scope optimizer. IEEE
ICDE, 2010.

