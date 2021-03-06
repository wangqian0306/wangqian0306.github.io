---
title: MapReduce Simplified Data Processing on Large Clusters 中文翻译版
date: 2021-06-02 22:26:13
tags:
- "论文"
- "MapReduce"
id: mapreduce_simplified_data_processing_on_large_clusters
no_word_count: true
no_toc: false
categories: 大数据
---

## MapReduce: Simplified Data Processing on Large Clusters 中文翻译版

作者：

Jeffrey Dean and Sanjay Ghemawat

### 摘要

MapReduce 是一种编程模型同时也是一个处理和生成超大数据集的算法模型的相关实现。
用户首先需要创建一个用于处理键值对的 Map 函数，来生成中间结果数据，然后编写一个 Reduce 函数来把所有的带有相同键的中间结果进行合并和关联，生成最终结果。
如同本文所表述的一样，许多现实生活中的许多事务也能通过这种模型进行处理。

使用本文所示的编码方式可以让程序在多台普通的设备当中并行的执行。
运行时系统负责对输入数据进行分区、在一组机器上调度程序的执行、处理机器故障以及管理所需的机器间通信等细节。
这使得没有任何并行和分布式系统经验的程序员能够轻松地利用大型分布式系统的资源。

我们的 MapReduce 运行在一个大型的通用设备集群上，并且具有高度的可伸缩性：一个 MapReduce 程序可以在数千台机器上处理许多 TB 的数据。
程序员发现这个系统很容易使用：已经实现了数百个 MapReduce 程序，每天在 Googl e的集群上执行了超过 1000 个 MapReduce 作业。

### 1 引言

在过去的5年里，包括本文作者在内的Google的很多程序员，为了处理海量的原始数据，已经实现了数以百计的、专用的计算方法。
这些计算方法用来处理大量的原始数据，比如，文档抓取（类似网络爬虫的程序）、Web请求日志等等；
也为了计算处理各种类型的衍生数据，比如：倒排索引，网页的图形结构的不同表现形式，每台主机上的数据爬取记录汇总，特定日期最常查询的问题等等。
大多数这样的计算在概念上都很简单。
然而，由于输入数据通常很大，为了在合理的时间内完成计算，所以必须将计算分布在成百上千台机器上。
如何处理并行计算、如何分发数据、如何处理错误？所有这些问题综合在一起，需要大量的代码处理，因此也使得原本简单的运算变得难以处理。

为了解决上述复杂的问题，我们设计一个新的抽象模型，使用这个抽象模型，我们只要表述我们想要执行的简单运算即可，
而不必关心并行计算、容错、数据分布、负载均衡等复杂的细节，这些问题都被封装在了一个库里面。
设计这个抽象模型的灵感来自 Lisp 和许多其他函数式语言的 Map 和 Reduce 原语。
我们意识到我们大多数的运算都包含这样的操作：在输入数据的 “逻辑” 记录上应用 Map 操作得出一个键值对集合类型的中间结果，
然后在所有具有相同键的数据上应用 Reduce 操作，从而达到合并中间的数据，得到目标结果。
我们使用带有用户指定的 Map 和 Reduce 操作的函数模型，使我们能够轻松地以并行化的方式运行大量的计算，并将重新执行作为容错的主要机制。

这项工作的主要贡献是提供了一个简单而强大的接口，可以实现大规模的分布并行计算。
实现此接口，我们就可在大型通用设备集群上获得高性能。

第2节描述了基本的编程模型并给出了几个例子。
第3节描述了针对我们基于集群的计算环境定制的 MapReduce 接口的实现。
第4节描述了我们发现有用的编程模型的一些改进。
第5节给出了我们实现各种任务的性能度量。
第6节探讨了在 Google 中使用 MapReduce，包括我们在使用 MapReduce 作为重写我们的产品索引系统的基础上的经验。
第7节讨论了相关的和未来的工作。

### 2 编程模型

在计算过程中的输入和输出都采用了键值对的形式。
MapReduce 库的用户将计算表示为两个函数：Map 和 Reduce。

由用户编写的 Map 函数接受输入对并生成一组中间键/值对。
MapReduce 库回将所有的中间结果进行组合和关联，并将它们传递给 Reduce 函数。

Reduce 函数也由用户编写，它接受一个中间键和该键的一组值。
它将这些值合并在一起，形成一组可能更小的值。
通常每个 Reduce 调用只生成零或一个输出值。
中间值通过迭代器提供给用户的 Reduce 函数。
这允许我们处理太大而无法放入内存的数据。

#### 2.1 样例

在此样例中我们需要计算大量文档中每个单词出现的次数。
用户将会编写的代码类似于以下伪代码：

```text
map(String key, String value):
    // key: document name
    // value: document contents
    for each word w in value:
        EmitIntermediate(w, "1");

reduce(String key, Iterator values):
    // key: a word
    // values: a list of counts
    int result = 0;
    for each v in values:
        result += ParseInt(v);
    Emit(AsString(result));
```

Map 函数会将每个单词加上相关的出现次数 (在这个简单的例子中只有 “1”)。
Reduce 函数将为特定单词发出的所有计数相加。

另外，用户编写代码，使用输入和输出文件的名字、可选的调节参数来完成一个符合 MapReduce 模型规范的对象，
然后调用 MapReduce 函数，并把这个规范对象传递给它。
用户的代码和 MapReduce 库链接在一起(用C++实现)。
附录 A 包含了这个实例的全部程序代码。

#### 2.2 类型

尽管前面的伪代码是根据字符串输入和输出编写的，但从概念上讲，用户提供的 Map 和 Reduce 函数只要有对应的关联就可以：

```text
map       (k1,v1)        -> list (k2,v2)\
reduce    (k2,list(v2))  -> list (v2)
```

比如，输入的键和值与输出的键和值属于不同的域。
此外，中间的键和值与输出的键和值属于同一域。

我们的C++中使用字符串类型作为用户自定义函数的输入输出，用户在自己的代码中对字符串进行适当的类型转换。

#### 2.3 更多示例

下面是一些有趣程序的简单示例，这些程序可以很容易地表示为 MapReduce 计算。

**分布式检索**：Map 函数输出匹配某个模式的一行，Reduce 函数是一个恒等函数，即把中间数据复制到输出。

**URL 访问频率统计**：Map 函数处理日志中 web 页面请求的记录，然后输出 `(URL,1)`。
Reduce 函数把相同 URL 的值都累加起来，产生 `(URL,记录总数)`结果。

**倒转网络链接图**：Map 函数在源页面(source)中检索出所有的链接目标(target)并输出为`(target,source)`。
Reduce 函数把给定链接目标的链接组合成一个列表，输出`(target,list(source))`。

**每个主机的词向量统计**：检索词向量用一个`(词,频率)`列表来概述出现在文档或文档集中的最重要的一些词。
Map 函数为每一个输入文档解析为`(主机名,检索词向量)`，其中主机名来自文档的URL。
Reduce 函数接收给定主机的所有文档的检索词向量，并把这些检索词向量加在一起，丢弃掉低频的检索词，输出一个最终的 `(主机名,检索词向量)`。

**倒排索引**：Map 函数将每个文档解析成 `(词,文档号)` 组成的列表，
Reduce 函数接收所有词并依照文档号进行排序，最终输出 `(词,list(文档号))`键值对。
这样输出的所有内容就形成了一个简单的倒排索引。
这样我们就可以简单的去获取词的出处。

**分布式排序**：Map 函数会从每条记录当中提取 key 并输出 `(key,record)` 键值对。
Reduce 函数会直接输出所有的值。
此计算取决于第 4.1 节中描述的分区特性和第 4.2 节中描述的排序属性。

### 3 实现方式

MapReduce 有很多种不同的实现方式。
需要在具体环境中才能得出最优实现。
例如：一种实现可能适用于小型共享内存的设备，另一种适用于大型 NUMA 多处理器的设备，还有一种适用于更大的网络设备集合。

本章节描述一个适用于 Google 内部广泛使用的运算环境的实现：
用以太网交换机连接、由普通 PC 机组成的大型集群。
在我们的环境里包括：

1. x86架构、运行Linux操作系统、双处理器、2-4GB内存的机器。
2. 普通的网络硬件设备，每个机器的带宽为百兆或者千兆，但是远小于网络的平均带宽的一半。
3. 集群中包含成百上千的设备，因此，设备故障是常态。
4. 存储为廉价的内置IDE硬盘。我们用一个内部分布式文件系统`[8]`来管理存储在这些磁盘上的数据。
   文件系统通过数据复制来在不可靠的硬件上保证数据的可靠性和有效性。
5. 用户提交工作（job）给调度系统。每个工作(job) 都包含一系列的任务(task)，调度系统将这些任务调度到集群中多台可用的机器上。

#### 3.1 执行概览

调度器会把数据分片(partition)成 M 份，然后 Map 操作也会被分发至这些设备上。
不同的分片就可以被不同的设备并行处理。
用户可以指定的 Reduce 函数的分区数量和分区方式。
分区函数(例如，`hash(key) mod R`) 会将 Map 函数生成的中间结果进行重新分区, Reduce 函数也会被分发到多台设备上执行。

![图1 执行概览](https://i.loli.net/2021/06/03/57P2Zh4DRxcJOmp.png)

图1 展示了我们实现的 MapReduce 操作执行流程。
当用户的程序调用 MapReduce 函数时，将发生以下操作 (图1中的编号标签对应于下面列表中的编号)：

1. 在用户代码中的 MapReduce 库会把输入文件切分成 M 份，每份通常有 16-64 MB(用户可以进行配置)。
2. 程序的副本当中的 master 是特殊的。
   由 master 分发任务给其他的 worker。
   总共会有 M 个 Map 任务，R 个 Reduce 任务。
   master 会挑选空闲的 worker 并给他们指派一个 Map 或 Reduce 任务。
3. 当 worker 接收到 Map 任务后会去读取对应的输入分片。
   Map 函数会依照用户的函数将输入数据处理成键值对格式的中间结果，并将其缓存在内容中。
4. 缓存中的数据会被分区函数将其分割为 R 个区域并定期的写入磁盘中然后回报给 master。
   由 master 将存储地址发送给分配了 Reduce worker。
5. 在 Reduce worker 接收到中间结果的存储位置时，它会使用 RPC(remote procedure call) 的方式读取在 Map worker 上的数据。
   当 Reduce worker 读取到所有的中间数据后会按照键进行排序，以便于实现分组聚合。
   排序操作是必要的因为通常需要把许多不同的键映射到一个 Reduce 任务。
   如果中间结果的数据量太大，在内存中已经无法容纳就会使用外部排序的方式。
6. Reduce worker 会对排序后的中间数据进行迭代，对于遇到的每个唯一的中间键，它将键和相应的中间值集传递给用户的 Reduce 函数。
   Reduce 函数的输出会被追加到这个 Reduce 分区最终的输出文件中。
7. 当所有的 Map 和 Reduce 任务执行完成后，master 会唤醒用户的程序。
   在此时 MapReduce 会将处理结果输出至用户代码中。

在执行成功之后，MapReduce 的输出结果会在 R 个分片(一个 Reduce 任务对应一个分片，文件名由用户指定)。
通常来说，用户不需要将文件合并成一个文件。
他们经常把这些文件作为另外一个 MapReduce 的输入，或者在另外一个可以处理多个分割文件的分布式应用中使用。

#### 3.2 Master 的数据结构

Master 保存了一些数据结构。
它存储了每一个 Map 和 Reduce 任务的状态(空闲 idle、工作中 in-process 或 完成 completed)，
以及 worker (非空闲任务) 的标识。

Master 就像一个数据管道，中间结果存储区域的位置信息通过这个管道从 Map 传递到 Reduce。
因此，对于每个完成的 Map 任务，master 存储了 Map 任务生成的 R 中间结果的位置和大小。
在 Map 任务执行完成后 master 会更新中间结果的位置和大小等信息。
这些信息将以增量方式推送到正在执行的 Reduce 任务。

#### 3.3 容错性

因为 MapReduce 库的设计初衷是使用由成百上千的机器组成的集群来处理超大规模的数据，所以，这个库必须要能很好的处理机器故障。

##### worker 故障

Master 会周期性的ping worker。
如果在一定周期内没有接受到相应请求则 Master 会将该 worker 标记为失败。
在这个 worker 上运行的所有 Map 任务会被重新标记成空闲状态，因此这些任务可以被分配到其他 worker 上。
类似的，在发生故障的 worker 上正在运行的 Map 或者 Reduce 任务也将被重新标记为空闲状态，等待重新调度。

已经运行完成的 Map 任务会被重新执行，因为它们的输出存储在发生故障的设备中的硬盘上，所以这些结果无法被访问。
而完成的 Reduce 任务无需重新执行，因为它们的数据存储在全局文件系统中。

当一个 Map 任务先被 worker A 执行然后被 worker B 执行(由于节点故障)，所有运行 Reduce 任务的 worker 都会收到执行通知。
任何 Reduce 任务若没有获取到 worker A 的数据就会去 worker B 中读取。

MapReduce 可以处理大规模 worker 失效的情况。
例如，在一次 MapReduce 操作期间，运行集群上的网络维护导致有80台计算机、在几分钟内无法访问。
MapReduce 的 master 只是重新执行无法访问的工作机器所做的工作，并继续运行，最终完成了 MapReduce 操作。

##### master 故障

一个简单的解决办法是让 master 周期性的将上面描述的数据结构的写入磁盘，即检查点(checkpoint)。
如果 master 任务异常关闭，一个新的副本可以从最新的检查点重新启动。
然而，考虑到只有一个主控器，它不太可能失败；因此，如果主程序失败，我们当前的实现将中止 MapReduce 计算。
客户端可以检查此情况，并根据需要重试 MapReduce 操作。

##### 在失效方面的处理机制

当用户提供的 Map 和 Reduce 操作符是其输入是确定函数时，我们的分布式实现在任何情况下的输出都和所有程序没有出现任何错误、顺序的执行产生的输出是一样的。

我们依赖对 Map 和 Reduce 任务的输出的提交是原子性的来完成这个特性。
每个在运行的任务都会把他们的输出写在私有的临时文件中。
一个 Reduce 任务产生一个这样的文件，而一个 Map 任务会产生 R 个这样的文件(R 取决于 Reduce 任务个数)。
当 Map 任务执行完成后 worker 会向 master 发送消息，在此条消息中会说明 R 个临时文件的名称。
如果主机接受到一个已经标记为完成的 Map 任务则会忽略这条消息。
否则将会把 R 个文件的文件名记录在 master 的数据结构中。

当 Reduce 任务完成时，Reduce worker 会自动将其临时文件重命名为最终输出文件。
如果在多台机器上执行相同的 Reduce 任务，则将对同一最终输出文件执行多个 Rename 调用。
我们依靠底层文件系统提供的原子重命名操作来保证最终文件系统状态只包含 Reduce 任务的一次执行所产生的数据。

我们的 Map 和 Reduce 操作符绝大多数都是确定性的，而且在这种情况下，我们的语义约等于顺序执行，这使得程序员很容易对程序的行为进行推理。
当 Map 和/或 Reduce 操作符是不确定的时，我们提供了较弱但仍然合理的语义。
在存在非确定性运算符的情况下，特定 Reduce 任务 R1 的输出等效于由非确定性程序的顺序执行产生的 R1 的输出。
然而，不同 Reduce 任务 R2 的输出可以对应于由不确定程序的不同顺序执行产生的 R2 的输出。

考虑 Map 任务 M 和 Reduce 任务 R1、R2 的情况。
我们假设 e(Ri) 是 Ri 的执行结果(只有一个这样的结果)。
当 e(R1) 读取了由 M 一次执行产生的输出，而 e(R2) 读取了由 M 的另一次执行产生的输出，导致了较弱的失效处理。

#### 3.4 存储位置

网络带宽在我们的环境当中是一种稀缺资源。
我们通过利用输入数据(由 GFS `[8]` 管理)存储在组成集群的机器的本地磁盘上这一事实来节省网络带宽。
GFS 将每个文件分为 64MB 块，并在不同的机器上存储每个块的多个副本(通常为3个副本)。
MapReduce master 会考虑输入文件的位置信息，并尝试在包含相应输入数据副本的计算机上调度 Map 任务。
否则，它将尝试在该任务输入数据的副本附近(例如，在与包含数据的计算机位于同一网络交换机上的工作计算机上) 调度映射任务。
在集群中大部分的 worker 在运行大型 MapReduce 操作时，大多数输入数据都是本地读取的，不消耗网络带宽。

#### 3.5 任务粒度

和上面描述的内容一致，我们将 Map 阶段分成 M 份 Reduce 阶段分成 R 份。
理想情况下，M 和 R 应该远远大于 worker 的数量。
让每个 worker 执行许多不同的任务可以优化动态负载平衡，还可以在一个 worker 失败时加快恢复速度：它完成的许多 Map 任务可以分布在所有其他worker机器上。

但是实际上，在我们的具体实现中对 M 和 R 的取值都有一定的客观限制，因为 master 必须执行 O(M+R) 次调度，并且在内存中保存 O(M*R) 个状态。
(在实际情况中内存的影响因素较小，O( M * R) 个持久化的信息当中每个 Map/Reduce 任务只需要 1 byte。)

此外，R 的数量则常常受到用户的约束，因为每个 Reduce 任务的结果最终都输出都在一个单独的文件中。
在实践中，我们倾向于选择 M 的大小，这样每个任务的输入数据大约为 16 MB 到 64 MB (此种局部优化是最有效的)，
并且我们会将 R 的数量设为我们期望使用的 worker 数量的一个小倍数。
我们经常使用 2000 台设备执行 M=200000 和 R=5000 的 MapReduce 计算。

#### 3.6 备份任务

MapReduce 任务执行时间过长的常见原因之一是 “落伍者”: 在运算的过程中，某台设备消耗了过长的事件去处理最后几个 Map 或者 Reduce 任务。
“落伍者” 的出现原因有很多。
例如：一台设备的磁盘出现了问题，在读取时需要经常进行纠错操作，导致其读取性能从 30 MB/s 降低到 1 MB/s。
集群中的调度系统可能已经调度了机器上的其他任务，由于 CPU、内存、本地磁盘或网络带宽的竞争，导致它执行 MapReduce 代码的速度较慢。
我们最近遇到的一个问题是机器初始化代码中的一个 bug，它导致处理器缓存被禁用：受影响机器上的计算速度降低了 100 倍以上。

我们有一个通用的机制来缓解落伍者问题。
当 MapReduce 操作接近完成时，master 会安排其余正在进行的任务备份执行。
无论是主任务还是备份任务执行完成，都会将任务标记为已完成
我们已经对这个机制进行了调整，使得它通常会将操作使用的计算资源增加不超过百分之几。
我们发现，这大大缩短了完成大型 MapReduce 操作的时间。
例如，当备份任务机制被禁用时，第 5.3 节中描述的排序程序需要额外花费 44% 的时间才能完成。

### 4 优化方式

尽管简单地编写 Map 和 Reduce 函数所提供的基本功能足以满足大多数需求，但我们发现有一些扩展是有用的。
本节对这些问题进行了描述。

#### 4.1 分区函数

用户需要制定 MapReduce 计算中 Reduce 任务或是输出文件的数量 R。
分区函数会将数据按照分片键进行切分。
默认的分区函数是哈希函数(例如："hash(key) mod R")。
这样一来我们的分区就是非常平衡的。
但是在某些情况下，使用其他函数对数据进行分区则是非常有用的。
例如：有时我们需要输出的内容包含 URL，我们想让单个主机的所有数据在同一个文件上输出。
为了支持这种情况，用户可以提供一个特殊的分区函数。
例如：使用 "hash(Hostname(urlkey)) mod R" 作为分区函数，就可以让来自同一主机的所有 URL 最终输出到同一文件中。

#### 4.2 保证排序

我们保证在给定的分区内，键值对会对按递增键的顺序进行处理。
这样的顺序保证对每个分成生成一个有序的输出文件，这对于需要对输出文件按键值随机存取的应用非常有意义，对在排序输出的数据集中也很有帮助。

#### 4.3 Combiner 函数

在某些情况下，每个 Map 任务生成的键都有明显的重复，用户指定的 Reduce 函数是可以对这些键进行交换的和关联的。
这方面的一个很好的例子是第 2.1 节中的单词计数示例。
由于词频倾向于遵循 Zipf 分布，因此每个 Map 任务将产生数百或数千条 <the，1> 形式的记录。
所有这些计数都将通过网络发送到一个 Reduce 任务，然后通过 Reduce 函数相加生成一个数字。
我们允许用户指定一个可选的 Combiner 函数，在数据通过网络发送之前对其进行部分合并。

Combiner 函数会在每台运行 Map 任务的设备上执行。
通常使用相同的代码来实现 Combiner 和 Reduce 函数。
Reduce 函数和 Combiner 函数之间的唯一区别是 MapReduce 库如何处理函数的输出。
Reduce 函数的输出被写入最终的输出文件。
Combiner 函数的输出会被写入一个中间文件，该文件将被发送到 Reduce 任务。

合并部分数据可以大大加快了特定的 MapReduce 操作。
附录 A 包含了一个使用 Combiner 的示例。

#### 4.4 输入和输出类型

MapReduce 库支持多种不同格式的输入类型。
例如，“text” 模式输入将每一行视为键/值对：键是文件中的偏移量，值是行的内容。
另一种常见的支持格式存储按键排序的键/值对序列。
种输入类型的实现都必须能够把输入数据分割成数据片段，该数据片段能够由单独的 Map 任务来进行后续处理
(例如，文本模式的范围分割必须确保仅仅在每行的边界进行范围分割)。
用户可以通过提供一个简单读取器接口的实现来添加对新输入类型的支持，尽管大多数用户只使用少数预定义输入类型中的一种。

读取器不一定需要提供从文件读取的数据。
例如：从数据库或者从内存映射的数据结构中读取数据也是很容易的。

以类似的方式，我们支持一组输出类型来生成不同格式的数据，用户代码很容易添加对新输出类型的支持。

#### 4.5 副作用

在某些情况下，MapReduce 的用户发现从 Map 与 Reduce 操作生成辅助文件作为附加输出非常方便。
我们依靠程序writer把这种“副作用”变成原子的和幂等的。
通常，应用程序会写入临时文件，并在完全生成该文件后自动重命名该文件。

如果一个任务产生了多个输出文件，我们没有提供类似两阶段提交的原子操作支持这种情况。
因此，生成具有跨文件一致性要求的多个输出文件的任务应该是确定的。
这种限制在实践中从来都不是问题。

#### 4.6 跳过错误数据

有时，用户代码中存在一些 bug，这些 bug 会导致 Map 或 Reduce 函数在某些记录上崩溃。
这样的 bug 会阻止 MapReduce 操作完成。
通常的做法是修复错误，但有时这是不可行的；也许这个 bug 在第三方库中，而这个库的源代码是不可修改的。
此外，有时忽略一些记录是用户可以接受的，例如在对一个大数据集进行统计分析时。
我们提供了一种可选的执行模式，其中 MapReduce 库会检测哪些记录会导致崩溃，并跳过这些记录以继续运行。

每个 worker 进程都会安装一个信号处理程序这个程序会捕捉内存段异常 (segmentation violation) 和总线错误 (bus error)。
在调用自定义的 Map 或 Reduce 操作之前，MapReduce 库会将参数的序列号存储在全局变量中。
如果用户程序触发了一个系统信号，消息处理函数将用 “最后一口气” 通过 UDP 包向 master 发送处理的最后一条记录的序号。
当 master 在某个特定记录上看到多次失败时，它指示在下一次重新执行相应的 Map 或 Reduce 任务时应跳过该记录。

#### 4.7 本地执行

在 Map 或 Reduce 函数中的调试问题可能很棘手，因为实际的计算发生在一个分布式系统中，通常在几千台机器上，而工作分配决策是由 master 动态做出的。
为了方便调试、评测和小规模测试，我们开发了 MapReduce 库的替代实现，它在本地机器上顺序执行 MapReduce 操作的所有工作。
用户可以控制 MapReduce 操作的执行，可以把操作限制到特定的 Map 任务上。
用户通过设定特别的标志来在本地执行他们的程序，之后就可以很容易的使用本地调试和测试工具(比如gdb)。

#### 4.8 状态信息

Master 运行了一个内部的 HTTP 服务器并导出一组状态页供用户使用。
状态页显示计算的进度，如已完成的任务数、正在进行的任务数、输入字节数、中间数据字节数、输出字节数、处理速率等。
这些页面还包含指向每个任务生成的标准错误和标准输出文件的链接。
用户可以使用这些数据来预测计算需要多长时间，以及是否应该向计算中添加更多的资源。
这些页面还可以用来计算什么时候计算速度比预期慢得多。

此外，顶级状态页还会显示哪些 worker 存在失败，以及失败时映射和减少他们正在处理的任务。
在尝试诊断用户代码中的错误时，此信息非常有用。

#### 4.9 计数器

MapReduce 库提供了一个计数器工具来统计各种事件的发生次数。
例如，用户代码可能要计算处理的单词总数或索引的德语文档数等。

为了使用这个工具，需要在用户代码中新增一个命名为 Counter 的对象，然后在 Map 与 Reduce 函数中适当的增加计数器，例如：

```text
Counter* uppercase;
uppercase = GetCounter("uppercase");

map(String name, String contents):
    for each word w in contents:
        if (IsCapitalized(w)):
            uppercase->Increment();
        EmitIntermediate(w, "1");
```

这些计数器的值周期性的从各个单独的 worker 机器上传递给 master (附加在 ping 的应答包中传递)。
Master 会聚合来自成功的 Map 和 Reduce 任务的计数器值，并在 MapReduce 操作完成时将它们返回给用户代码。
当前的计数器值也显示在主状态页上，以便用户可以查看实时计算的进度。
聚合计数器值时，master 消除了重复执行同一 Map 或 Reduce 任务的影响，以避免重复计数。
(重复执行可能是由于使用备份任务和由于失败而重新执行任务造成的。)

MapReduce 库会自动维护一些计数器值，例如处理的输入键值对数量和生成的输出键值对数量。

计数器机制对于 MapReduce 操作的完整性检查非常有用。
例如，在某些 MapReduce 操作中，用户代码可能希望确保生成的输出键值对的数目正好等于处理的输入键值对的数目，
或者确保处理的德语文档的分数在处理的文档总数中的某个可容许分数内。

### 5 性能

在本节中，我们将测量在大型计算机集群上运行的两个 MapReduce 计算的性能。
一种计算方法是在大约 1 TB 的数据中搜索特定的模式。
另一种计算对大约 1 TB 的数据进行排序。

这两个程序代表了由 MapReduce 用户编写的真实程序的一个大子集–
一类程序将数据从一个表示形式转移到另一个表示形式，另一类从一个大数据集中提取少量有趣的数据。

#### 5.1 集群配置

所有的程序都是在一个由大约 1800 台机器组成的集群上执行的。
每台机器有两个 2GHz 的 Intel Xeon 处理器，支持超线程，4 GB 内存，两个 160 GB 磁盘和一个千兆以太网链路。
这些机器被安排在一个两级树形交换网络中，根节点的总带宽约为 100 - 200 gbps。
所有的机器都在同一个托管设施中，因此任何一对机器之间的往返时间都不到一毫秒。

在 4 GB 内存中，群集上运行的其他任务保留了大约 1-1.5GB 的内存。
这些程序是在周末下午执行的，当时 CPU、磁盘和网络大部分处于空闲状态。

#### 5.2 检索程序

检索程序会查询 10^10 个 100 byte 的记录，在其中检索相对罕见的三字符模式(共有 92337 处)。
输入被切分成大约 64 MB 的大小(M=15000)，整个输出被存放在一个文件中（R=1）。

![图2 数据传输速率与时间的关系图](https://i.loli.net/2021/06/04/H8fNeSIkcGLv1wi.png)

图2 展示了计算进度与时间的关系。
Y 轴显示了输入数据的速率。
随着越来越多的机器被分配到这个 MapReduce 计算中，这个速率逐渐加快，当分配了 1764 个 worker 时，这个速率达到了超过 30 Gb/s 的峰值。
当 Map 任务完成时，速率开始下降，并在大约 80 秒的计算时间内达到零。
整个计算从开始大约需要 150 秒结束。
这包括大约一分钟的启动开销。
启动开销是由于需要将程序发送至所有 worker 以及等待 GFS 文件系统打开 1000 个输入文件集合的时间、获取相关的文件本地位置优化信息的时间。

#### 5.3 排序程序

排序程序会处理 10^10 个 100 byte 的记录(大约 1 TB 的数据)。 这个程序是以 TeraSort 基准测试为模型的`[10]`。

排序程序由少于 50 行的代码构成。 三行映射函数从文本行中提取一个 10 字节的排序键，并将该键和原始文本行作为键值对输出。 我们使用了一个内置的身份函数作为 Reduce 操作符。 此函数将中间的键值对作为输出键值对原封不动地传输。
最终排序的输出被写入一组双向复制的 GFS 文件(也就是说，2 TB的输出)。

和以前一样，输入数据被分割成 64 MB 的片段 ( M=15000 )
我们将排序后的输出划分为 4000 个文件 (R=4000)。 分区函数使用 key 的原始字节来把数据分区到 R 个片段中。

在这个基准测试中，我们使用的分区函数知道 key 的分区情况。 在一般的排序程序中，我们将添加一个预传递的 MapReduce 操作，该操作将收集 key 的样本，并使用样本 key 的分布来计算最终排序过程的分割情况。

![图3 在不同情况下排序算法中数据传输速率与时间的对比情况](https://i.loli.net/2021/06/06/hntq6dSr5VCPyAi.png)

图 3 (a) 中显示了正常执行排序程序的进度。
左上角的图表显示了读取输入的速率。
由于所有 Map 任务都在 200 秒之内完成，因此速率峰值约为 13 GB/s，并很快的执行完成。
值得注意的是，输入的速率小于处理的速率。
这是因为排序映射任务将花费大约一半的时间和I/O带宽将中间输出写入本地磁盘。
grep 的相应中间输出的大小可以忽略不计。

左侧中间的图表显示了 Map 任务通过网络输送给 Reduce 任务的速率。
当第一个 Map 任务完成时，洗牌 (shuffle) 流程就开始了。
图中的第一个峰值是第一批大约 1700 个 Reduce 任务(整个 MapReduce 被分配了 1700 台机器，每台机器一次只能执行一个 Reduce 任务)。
在大约 300 秒的计算过程中，第一批 Reduce 任务中的一些任务完成了，我们开始为剩余的 Reduce 任务对数据进行洗牌。
所有的洗牌操作是在大约 600 秒的计算时间内完成的。

左下角的图表显示了 Reduce 任务将排序后的数据写入最终输出文件的速率。
在第一个洗牌周期结束和写入周期开始之间有一个延迟，因为设备在对中间数据进行排序。
写入将以大约 2-4 GB/s 的速率持续一段时间。
在整个计算过程中所有写操作都在大约 850 秒内完成。
包括启动开销，整个计算需要 891 秒。
这是目前执行效率最高的排序，TeraSort 基准测试结果为 1057 秒`[18]`。

需要注意的是：由于我们的局部优化，输入速率高于洗牌速率和输出速率—大多数数据都是从本地磁盘读取的，并且绕过了相对带宽受限的网络。
我们会将写入操作执行两次来生成副本，因为这是底层文件系统提供的可靠性和可用性机制。
如果底层文件系统使用擦除编码而不是复制，则写入数据的网络带宽需求将减少`[14]`。

#### 5.4 备份任务的影响

在图 3 (b) 中，我们展示了在禁用备份任务的情况下执行排序程序。
执行流与图 3 (a) 中所示的类似，只是有一个很长的尾部此时几乎没有任何写活动发生。
960 秒后，除 5 个 Reduce 任务外的所有任务都完成。
然而，最后几个掉队者要到 300 秒后才能完成。
整个计算耗时 1283 秒，耗用时间增加了 44%。

#### 5.5 设备故障

在图 3 (c) 中，我们展示了排序程序的执行过程，在计算的几分钟内，我们故意杀死了 1746 个 worker 中的 200 个。
底层集群调度器立即在这些机器上重新启动新的工作进程(因为只有进程被终止，所以机器仍然正常工作)。

图三（c）显示出了一个“负”的输入数据读取速度，这是因为一些已经完成的 Map 任务丢失了
(由于相应的执行 Map 任务的 worker 进程被杀死了)，需要重新执行这些任务。
相关 Map 任务很快就被重新执行了。
整个运算在 933 秒内完成，包括了初始启动时间 (只比正常执行多消耗了5%的时间)。

### 6 经验

我们在 2003 年 1 月完成了第一个版本的 MapReduce 库，在 2003 年 8 月的版本有了显著的增强，这包括了输入数据本地优化、worker 机器之间的动态负载均衡等等。
从那以后，我们惊喜的发现，MapReduce 库能广泛应用于我们日常工作中遇到的各类问题。
它现在在 Google 内部各个领域得到广泛应用，包括：

- 大规模机器学习
- 为 Google News 和 Froogle products 处理问题
- 从公众查询产品 (比如 Google Zeitgeist) 的报告中抽取数据。
- 从大量的新应用和新产品的网页中提取有用信息 (比如，从大量的位置搜索网页中抽取地理位置信息)。
- 大规模的图形计算。

![图4 MapReduce 实例数与时间的关系图](https://i.loli.net/2021/06/07/Lb1zO2ACJYjNagI.png)

图4 显示了在我们的源代码管理系统中，随着时间推移，独立的 MapReduce 程序数量的显著增加。
从 2003 年早些时候的 0 个增长到 2004 年 9 月份的差不多 900 个不同的程序。
MapReduce 的成功取决于采用 MapReduce 库能够在不到半个小时时间内写出一个简单的程序，
这个简单的程序能够在上千台机器的组成的集群上做大规模并发处理，这极大的加快了开发和原形设计的周期。
另外，采用 MapReduce 库，可以让完全没有分布式与并行系统开发经验的程序员很容易的利用大量的资源，开发出分布式并行处理的应用。

|项目|数量|
|:---:|:---:|
|任务数量|29423|
|平均任务执行时长|634 s|
|每日使用设备数|79186|
|输入数据量|3288 TB|
|中间数据产生量| 758 TB|
|输出数据量|193 TB|
|每个任务平均的 worker 数量|157|
|平均每个任务运行失败的 worker 数量|1.2|
|平均每个任务 Map 任务的数量|3351|
|平均每个 Reduce 任务的数量|55|
|独立的 Map 实现|395|
|独立的 Reduce 实现|269|
|独立的 Map/Reduce 组合|426|

> 表1 在 2004 年运行的 MapReduce 任务

在每个任务结束的时候，MapReduce 库统计计算资源的使用状况。
在表1，我们列出了 2004 年 8 月份 MapReduce 运行的任务所占用的相关资源。

#### 6.1 大规模索引

到目前为止，MapReduce 最成功的应用就是重写了 Google 网络搜索服务所使用到的索引系统。
索引系统的输入数据是网络爬虫抓取回来的海量的文档，这些文档数据都保存在 GFS 文件系统里。
这些文档原始内容的大小超过了 20 TB。
索引程序是通过一系列的 MapReduce 操作 (大约 5 到 10 次)来建立索引。
使用MapReduce (而不是索引系统的早期版本中的 ad-hoc 分布式处理方式) 提供了以下几个好处：

- 索引代码更简单、更小、更易于理解，因为处理容错、分布和并行化的代码隐藏在 MapReduce 库中。
  例如，当使用 MapReduce 方式时，计算的一个阶段的代码从大约 3800 行的 C++ 代码下降到大约 700 行。
- MapReduce 库的性能足够好，以至于我们可以将概念上无关的计算分开，而不是将它们混合在一起，以避免对数据进行额外的传递。
  这使得更改索引过程变得很容易。
  例如，在我们的旧索引系统中花了几个月才做的一个更改在新系统中只花了几天就实现了。
- 索引过程变得更易于维护，因为大多数由机器故障、机器速度慢和网络故障引起的问题都由 MapReduce 库自动处理，无需操作员干预。
  此外，通过向索引集群添加新机器，可以很容易地提高索引过程的性能。

### 7 相关工作

许多系统提供了限制性编程模型，并利用这些限制进行自动并行化计算。
例如，一个聚合函数可以通过并行使用 N 个处理器，在 log N 的时间内处理 N 个元素的数组来计算所有的内容 `[6，9，13]`。
MapReduce 可以被认为是其中一些模型的简化和升华，这些模型是基于我们对大型现实世界计算的经验。
更重要的是，我们提供了可扩展到数千个处理器的容错实现。
相比之下，大多数并行处理系统只在较小的规模上实现，并将处理机器故障的细节留给程序员。

批量同步编程 `[17]` 和一些 MPI 原语 `[11]` 提供了更高级别的抽象，使程序员更容易编写并行程序。
这些系统与 MapReduce 之间的一个关键区别是 MapReduce 利用受限编程模型自动并行化用户程序并提供透明的容错。

我们数据本地优化策略的灵感来源于active disks `[12,15]` 等技术，在 active disks 中，计算任务是尽量推送到数据存储的节点处理，这样就减少了网络和 IO 子系统的吞吐量。
我们通过使用商品化的处理器挂载硬盘的方式而不是在磁盘控制器上，但是一般的做法是相似的。

我们的备用任务机制和 Charlotte System `[3]` 提出的 eager 调度机制比较类似。
Eager调度机制的一个缺点是如果一个任务反复失效，那么整个计算就不能完成。
我们通过忽略引起故障的记录的方式在某种程度上解决了这个问题。

MapReduce 的实现依赖于一个内部的集群管理系统，这个集群管理系统负责在一个超大的、共享机器的集群上分布和运行用户任务。
虽然这个不是本论文的重点，但是有必要提一下，这个集群管理系统在理念上和其它系统，如 Condor `[16]` 是一样的。

MapReduce 库的排序机制和 NOW-Sort `[1]` 的操作上很类似。
读取输入源的机器(Map workers)把待排序的数据进行分区后，发送到 R 个 Reduce worker中的一个进行处理。
每个 Reduce worker 在本地对数据进行排序 (尽可能在内存中排序)。
当然，NOW-Sort 没有给用户自定义的 Map 和 Reduce 函数的机会，因此不具备 MapReduce 库广泛的实用性。

River `[2]` 提供了一个编程模型，其中进程通过在分布式队列上发送数据来相互通信。
与 MapReduce 一样，River 系统试图提供良好的平衡性能，即使存在由异构硬件或系统扰动引入的不一致性。
River 通过仔细安排磁盘和网络传输来实现这一点，从而实现平衡的完成时间。
MapReduce 使用不同的方式实现。
通过限制编程模型，MapReduce 框架能够将问题划分为大量细粒度任务。
这些任务在可用的 worker 上进行动态调度，以便更快的 worker 处理更多的任务。
受限编程模型还允许我们在接近作业结束时安排任务的冗余执行，这大大减少了在存在不一致(例如缓慢或卡住的 worker)的情况下的完成时间。

BAD-FS `[5]` 的编程模型与 MapReduce 非常不同，它的目标是跨广域网执行作业。
然而，有两个基本的相似之处。
1. 两个系统都使用冗余执行来从故障导致的数据丢失中恢复。
2. 两者都使用位置感知调度来减少通过拥塞的网络链路发送的数据量。

TACC `[7]` 是一个旨在简化高可用网络服务构建的系统。
与 MapReduce 一样，它依赖于重新执行作为实现容错的机制。

### 8 结论

MapReduce 编程模型在 Google 内部成功应用于多个领域。
我们把这种成功归结为几个方面：首先，由于 MapReduce 封装了并行处理、容错处理、数据本地化优化、负载均衡等等技术难点的细节，这使得 MapReduce 库易于使用。
即便对于完全没有并行或者分布式系统开发经验的程序员而言；其次，大量不同类型的问题都可以通过 MapReduce 简单的解决。
比如，MapReduce 用于生成 Google 的网络搜索服务所需要的数据、用来排序、用来数据挖掘、用于机器学习，以及很多其它的系统；
第三，我们实现了一个在数千台计算机组成的大型集群上灵活部署运行的 MapReduce。
这个实现使得有效利用这些丰富的计算资源变得非常简单，因此也适合用来解决 Google 遇到的其他很多需要大量计算的问题。

我们也从 MapReduce 开发过程中学到了不少东西。
首先，约束编程模式使得并行和分布式计算非常容易，也易于构造容错的计算环境；其次，网络带宽是稀有资源。
大量的系统优化是针对减少网络传输量为目的的：本地优化策略使大量的数据从本地磁盘读取，中间文件写入本地磁盘、并且只写一份中间文件也节约了网络带宽；
第三，多次执行相同的任务可以减少性能缓慢的机器带来的负面影响，同时解决了由于机器失效导致的数据丢失问题。

### 9 致谢

Josh Levenberg has been instrumental in revising and extending the user-level MapReduce API with
a number of new features based on his experience with using MapReduce and other people’s suggestions
for enhancements. MapReduce reads its input from and writes its output to the Google File System `[8]`.
We would like to thank Mohit Aron, Howard Gobioff, Markus Gutschke, David Kramer, Shun-Tak Leung,
and Josh Redstone for their work in developing GFS. We would also like to thank Percy Liang and Olcan Sercinoglu
for their work in developing the cluster management system used by MapReduce. Mike Burrows, Wilson Hsieh,
Josh Levenberg, Sharon Perl, Rob Pike, and Debby Wallach provided helpful comments on earlier drafts of this paper.
The anonymous OSDI reviewers, and our shepherd, Eric Brewer, provided many useful suggestions of areas where the paper
could be improved. Finally, we thank all the users of MapReduce within Google’s engineering organization for providing
helpful feedback, suggestions, and bug reports.

### 参考资料

`[1]` Andrea C. Arpaci-Dusseau, Remzi H. Arpaci-Dusseau, David E. Culler, Joseph M. Hellerstein, and David A. Patterson.
High-performance sorting on networks of workstations.
In Proceedings of the 1997 ACM SIGMOD International Conference on Management of Data, Tucson, Arizona, May 1997.

`[2]` Remzi H. Arpaci-Dusseau, Eric Anderson, Noah Treuhaft, David E. Culler, Joseph M. Hellerstein,
David Patterson, and Kathy Yelick.Cluster I/O with River:
Making the fast case common. In Proceedings of the Sixth Workshop on Input/Output in Parallel and Distributed Systems 
(IOPADS ’99), pages 10–22, Atlanta, Georgia, May 1999.

`[3]` Arash Baratloo, Mehmet Karaul, Zvi Kedem, and Peter Wyckoff.
Charlotte: Metacomputing on the web.
In Proceedings of the 9th International Conference on Parallel and Distributed Computing Systems, 1996.

`[4]` Luiz A. Barroso, Jeffrey Dean, and Urs H¨olzle. 
Web search for a planet: The Google cluster architecture. IEEE Micro, 23(2):22–28, April 2003.

`[5]` John Bent, Douglas Thain, Andrea C.Arpaci-Dusseau, Remzi H. Arpaci-Dusseau, and Miron Livny.
Explicit control in a batch-aware distributed file system.
In Proceedings of the 1st USENIX Symposium on Networked Systems Design and Implementation NSDI, March 2004.

`[6]` Guy E. Blelloch. Scans as primitive parallel operations. 
IEEE Transactions on Computers, C-38(11), November 1989.

`[7]` Armando Fox, Steven D. Gribble, Yatin Chawathe, Eric A. Brewer, and Paul Gauthier. 
Cluster-based scalable network services. In Proceedings of the 16th ACM Symposium on Operating System Principles,
pages 78–91, Saint-Malo, France, 1997.

`[8]` Sanjay Ghemawat, Howard Gobioff, and Shun-Tak Leung.
The Google file system. In 19th Symposium on Operating Systems Principles,
pages 29–43, Lake George, New York, 2003.

`[9]` S. Gorlatch. Systematic efficient parallelization of scan and other list homomorphisms.
In L. Bouge, P. Fraigniaud, A. Mignotte, and Y. Robert, editors, Euro-Par’96.
Parallel Processing, Lecture Notes in Computer Science 1124, pages 401–408. Springer-Verlag, 1996.

`[10]` Jim Gray. Sort benchmark home page.
http://research.microsoft.com/barc/SortBenchmark/.

`[11]` William Gropp, Ewing Lusk, and Anthony Skjellum.
Using MPI: Portable Parallel Programming with the Message-Passing Interface.
MIT Press, Cambridge, MA, 1999.

`[12]` L. Huston, R. Sukthankar, R. Wickremesinghe, M. Satyanarayanan, G. R. Ganger, E. Riedel, and A. Ailamaki. 
Diamond: A storage architecture for early discard in interactive search.
In Proceedings of the 2004 USENIX File and Storage Technologies FAST Conference, April 2004.

`[13]` Richard E. Ladner and Michael J. Fischer.
Parallel prefix computation. Journal of the ACM, 27(4):831–838, 1980.

`[14]` Michael O. Rabin.
Efficient dispersal of information for security, load balancing and fault tolerance.
Journal of the ACM, 36(2):335–348, 1989.

`[15]` Erik Riedel, Christos Faloutsos, Garth A. Gibson, and David Nagle.
Active disks for large-scale data processing. IEEE Computer, pages 68–74, June 2001.

`[16]` Douglas Thain, Todd Tannenbaum, and Miron Livny.
Distributed computing in practice: The Condor experience.
Concurrency and Computation: Practice and Experience, 2004.

`[17]` L. G. Valiant. A bridging model for parallel computation.
Communications of the ACM, 33(8):103–111, 1997.

`[18]` Jim Wyllie.
Spsort: How to sort a terabyte quickly.
http://alme1.almaden.ibm.com/cs/spsort.pdf.

### 附录 A 词频统计

本节包含了一个完整的程序，用于统计在一组命令行指定的输入文件中，每一个不同的单词出现频率。

```text
#include "mapreduce/mapreduce.h"
// User’s map function
class WordCounter : public Mapper {
   public:
      virtual void Map(const MapInput& input) {
         const string& text = input.value();
         const int n = text.size();
         for (int i = 0; i < n; ) {
            // Skip past leading whitespace
            while ((i < n) && isspace(text[i]))
               i++;
            // Find word end
            int start = i;
            while ((i < n) && !isspace(text[i]))
            i++;
            if (start < i)
               Emit(text.substr(start,i-start),"1");
         }
      }
};
REGISTER_MAPPER(WordCounter);

// User’s reduce function
class Adder : public Reducer {
   virtual void Reduce(ReduceInput* input) {
      // Iterate over all entries with the
      // same key and add the values
      int64 value = 0;
      while (!input->done()) {
         value += StringToInt(input->value());
         input->NextValue();
      }
      
      // Emit sum for input->key()
      Emit(IntToString(value));
   }
};
REGISTER_REDUCER(Adder);

int main(int argc, char** argv) {
   ParseCommandLineFlags(argc, argv);
   
   MapReduceSpecification spec;
   // Store list of input files into "spec"
   for (int i = 1; i < argc; i++) {
      MapReduceInput* input = spec.add_input();
      input->set_format("text");
      input->set_filepattern(argv[i]);
      input->set_mapper_class("WordCounter");
   }

// Specify the output files:
// /gfs/test/freq-00000-of-00100
// /gfs/test/freq-00001-of-00100
// ...
MapReduceOutput* out = spec.output();
out->set_filebase("/gfs/test/freq");
out->set_num_tasks(100);
out->set_format("text");
out->set_reducer_class("Adder");
// Optional: do partial sums within map
// tasks to save network bandwidth
out->set_combiner_class("Adder");

// Tuning parameters: use at most 2000
// machines and 100 MB of memory per task
spec.set_machines(2000);
spec.set_map_megabytes(100);
spec.set_reduce_megabytes(100);

// Now run it
MapReduceResult result;
if (!MapReduce(spec, &result)) abort();

// Done: ’result’ structure contains info
// about counters, time taken, number of
// machines used, etc.

return 0;
}
```
