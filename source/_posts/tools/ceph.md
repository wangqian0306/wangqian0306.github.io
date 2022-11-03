---
title: Ceph
date: 2022-10-28 23:09:32
tags:
- "Ceph"
id: ceph
no_word_count: true
no_toc: false
categories: "工具"
---

## Ceph

### 简介

Ceph 是一个开源的分布式存储系统。

从安装方式上来讲可以才用 Cephadmin 来安装在容器和 `systemd` 中，也可以使用 [Rook](https://rook.io/) 安装在 Kubernetes 上。

### 关键概念

Ceph 集群有如下组件：

[Ceph 组件图](https://docs.ceph.com/en/latest/_images/ditaa-a05e8639fc0d9031e9903a52a15a18e182d673ff.png)

Ceph 将数据作为对象存储在逻辑存储池中。使用 CRUSH 算法，Ceph 计算应计算应选择哪个归置组(placement group,PG)包含此对象，以及哪个 OSD 应存储归置组。这 CRUSH 算法使 Ceph 存储集群能够方便扩展、重新平衡以及动态恢复。

#### Monitors

Ceph Monitor(监视器，`ceph-mon`) 维护着集群状态的 Map，此 Map 包括了Monitors Map，Manager Map，OSD Map，MDS Map 和 CRUSH Map。这些 Map 是集群用于协调 Ceph 守护进程之间关键集群状态。监视器还负责管理客户端与守护进程之间的授权。通常需要至少三个 Ceph Monitor 实现冗余和高可用性。

#### Manager

Ceph Manager 守护进程(管理器，`ceph-mgr`) 负责跟踪运行时指标和当前 Ceph 集群的状态，包括存储利用率、当前性能指标和系统负载。Ceph Manager 守护进程还托管了一些基于 Python 的模块包括 Ceph Dashboard 和 REST API。为了高可用最少需要引入两个 Ceph Manager。

#### Ceph OSDs

Ceph OSD(`ceph-osd`,Object Storage Daemon) 是对象存储的守护进程，负责存储数据，处理数据副本，数据恢复，数据重平衡，并且通过查询其余 Ceph OSD 心跳数据从而向 Ceph Monitors 和 Ceph Manager 提供监控数据。为了高可用最少需要引入三个 Ceph Manager。

#### MDSs

Ceph Metadata Server(元数据服务器,`ceph-mds`)负责代表 Ceph File System(Ceph 文件系统)存储元数据(例如 Ceph Block Devices 和 Ceph Object Storage 是不使用 MDS 的)。Ceph Metadata Server 允许符合 `POSIX` 规范的文件系统用户执行基本的命令(例如 `ls`,`find` 等)而不会给 Ceph 存储集群带来巨大负担。

### Ceph File System

Ceph File System(Ceph FS)，是一个符合 `POSIX` 规范的文件系统，构建在 Ceph 的分布式对象存储 RADOS 上。CephFS 的目标是构建一款最先进的，多用途，高可用，为大量应用程序提供高性能存储，其中用例包括像目录分享，HPC 暂存空间和分布式工作流所需的共享存储。

CephFS 通过使用一些新颖的架构实现这些目标。尤其重要的是，文件元数据与实际数据分离存储在一个 RADOS 池中并通过一个可靠的元数据服务器集群(MDS)提供服务，其还可以通过缩放的方式来应对更好的工作负载。文件系统的客户端可以直接访问 RADOS 以读取和写入文件数据块。因此，工作负载可能会随着底层RADOS 对象存储的大小而线性扩展；也就是说，没有网关或 broker 代理客户端的数据 I/O。

对数据的访问通过 MDS 集群进行协调，MDS 集群作为客户端和 MDS 协作维护的分布式元数据缓存状态的权威机构。元数据的变更由每个 MDS 聚合成一系列写入 RADOS 上的日志；MDS 本地不存储元数据状态。该模型允许在 POSIX 文件系统的上下文中客户机之间进行一致和快速的协作。

[CephFS 架构图](https://docs.ceph.com/en/quincy/_images/cephfs-architecture.svg)

CephFS 是 Ceph 中最旧的存储接口，曾经是 RADOS 的主要用例。但现在，它由另外两个存储接口连接起来，形成了一个现代的统一存储系统：RBD(Ceph Block Device)和 RGW(Ceph Object Storage Gateway)。

### Ceph Block Device

Block 是一系列的字节(通常是 512)。基于 Block 的存储接口是在包括 HDD、SSD、CD、软盘甚至磁带在内的介质上存储数据的一种成熟而常见的方式。Block Device 接口的普遍性非常适合与包括 Ceph 在内的海量数据存储交互。

Ceph Block Device 的特点是简单的配置，可调整存储大小，将数据切分存储在多个 OSD 上。Ceph Block Device 利用了 RADOS 包括快照、复制和强一致性的功能。Ceph Block 存储客户端可以通过 内核模组或者 `librbd` 库读取 Ceph 集群。

### 使用方式

在安装完成 Ceph 存储集群之后就可以使用 Ceph FS 作为文件系统进行挂载使用。

如需在 Kubernetes 中使用则可以创建 Ceph PV，又或者使用 [RBD](https://docs.ceph.com/en/latest/rbd/rbd-kubernetes/)

### 参考资料

[官方文档](https://docs.ceph.com/en/quincy/start/intro/)
