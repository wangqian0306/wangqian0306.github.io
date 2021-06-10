---
title: Bigtable A Distributed Storage System for Structured Data 中文翻译版
date: 2021-06-10 22:26:13
tags: "论文"
id: bigtable_a_distributed_storage_system_for_structured_data
no_word_count: true
no_toc: false
categories: 大数据
---

## Bigtable: A Distributed Storage System for Structured Data 中文翻译版

### 摘要

Bigtable 是一个分布式的结构化数据存储系统，它被设计用来处理海量数据：通常是分布在数千台普通服务器上的 PB 级的数据。
Google 的很多项目使用 Bigtable 存储数据，包括 Web 索引、Google Earth、Google Finance。
这些应用对 Bigtable 提出的要求差异非常大，无论是在数据量上(从 URL 到网页到卫星图像)还是在响应速度上(从后端的批量处理到实时数据服务)。
尽管应用需求差异很大，但是，针对 Google 的这些产品，Bigtable 还是成功的提供了一个灵活的、高性能的解决方案。
本论文描述了 Bigtable 提供的简单的数据模型，利用这个模型，用户可以动态的控制数据的分布和格式；我们还将描述 Bigtable 的设计和实现。

### 1 引言

在过去的两年半中我们在 Google 设计实现并部署了一个分布式系统来管理结构数据，这个系统被称为 Bigtable。
Bigtable 被设计用来可靠并可扩展的在数千台设备上存储 PB 级别的数据。
Bigtable 完成了一下几项目标：广泛的适用性、可伸缩性、高性能和高可用性。
Bigtable 被 16 项 Google 的产品和项目使用，其中包含 Google Analytics,
Google Finance, Orkut, Personalized Search, Writely, 和 Google Earth。
这些产品将 Bigtable 用于各种苛刻的工作负载，例如面向吞吐量的批处理作业和对延迟敏感的向最终用户提供数据服务。
这些产品使用的 Bigtable 集群的配置范围很广，从少数服务器到数千台服务器，最多可存储几百 TB 的数据。

在许多方面，Bigtable 类似于一个数据库：它与数据库共享许多实现策略。
并行数据库 `[14]` 和内存数据库 `[13]` 已经实现了可伸缩性和高性能，但是 Bigtable 提供了与这类系统不同的接口。
Bigtable 不支持完整的关系数据模型；相反，它为客户机提供了一个简单的数据模型，支持对数据布局和格式的动态控制，
并允许客户机对底层存储中表示的数据的局部性属性进行推理。
数据的索引使用可以是任意的行和列的字符串。
Bigtable 还将数据视为字符串，尽管客户机通常将各种形式的结构化和半结构化数据序列化到这些字符串中。
通过仔细选择数据的模式，客户可以控制数据的位置相关性。
最后，可以通过 BigTable 的模式参数来控制数据是存放在内存中、还是硬盘上。

第 2 节更详细地描述了数据模型，第 3 节概述了客户端 API。
第 4 节简要描述了 Bigtable 所依赖的 Google 基础设施。
第 5 节描述了 Bigtable 实现的基本原理，
第 6 节描述了我们为提高 Bigtable 性能所做的一些改进。
第 7 节提供了 Bigtable 性能的数据。
我们在第 8 节中描述了 Bigtable 在 Google 内部使用的例子，
并在第 9 节中讨论了我们在设计和支持 Bigtable 时学到的一些经验教训。
最后，第 10 节描述了相关工作，第 11 节给出了我们的结论。

### 2 数据模型


