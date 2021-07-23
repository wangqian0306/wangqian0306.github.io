---
title: Redis 多线程
date: 2021-07-23 21:41:32
tags: "Redis"
id: redis-thread-io
no_word_count: true
no_toc: false
categories: Redis
---

## Redis 多线程

### 简介

在 Redis 6.0 中引入了多线程相关功能。

### 官方配置说明

Redis 大多是单线程的，但是，也有一些其他线程，例如 UNLINK、慢速 I/O 访问以及在其他线程上执行的一些操作。

现在还可以在不同的 I/O 线程中处理 Redis 客户端套接字读取和写入。
由于通常是写入速度太慢，Redis 用户一般使用管道来加速每个核心的 Redis 性能，并产生多个实例以进行扩展。
使用 I/O 线程可以轻松地将 Redis 加速两倍，而无需借助管道或实例分片。

默认情况下线程是禁用的，我们建议只在至少有 4 个或更多内核的机器上启用它，至少留下一个备用内核。
使用超过 8 个线程不太可能有太大帮助。
我们还建议您仅在确实存在性能问题时才使用线程 I/O，因为 Redis 实例能够使用相当大比例的 CPU 时间，否则使用此功能没有意义。

因此，例如，如果您有四个 CPU 核心，请尝试使用 2 或 3 个 I/O 线程，如果您有 8 核，请尝试使用 6 线程。
为了启用 I/O 线程，请使用以下配置指令：

```text
io-threads 4
```

将 `io-threads` 设置为 1 将像往常一样使用主线程。
当启用 I/O 线程时，我们只使用线程进行写入，即线程化 write(2) 系统调用并将客户端缓冲区传输到套接字。
但是，也可以使用以下配置指令开启配置项，启用读取线程和协议解析，：

```text
io-threads-do-reads no
```

通常线程读取没有多大帮助。

> 注：
> 
> 1：此配置指令无法在运行时通过 CONFIG SET 更改。在启用 SSL 之后此项配置失效。
> 
> 2：如果您想使用 redis-benchmark 测试 Redis 的性能优化，请确保您也在线程模式下运行基准测试本身，使用 --threads 选项配置 Redis 线程数。

### 实现方式

![流程梳理](https://i.loli.net/2021/07/23/bYoRfeSxadNkp38.png)

流程简述如下：

- 主线程负责接收建立连接请求，获取 Socket 放入全局等待读处理队列。
- 主线程处理完读事件之后，通过 RR（Round Robin）将这些连接分配给这些 IO 线程。
- 主线程阻塞等待 IO 线程读取 Socket 完毕。
- 主线程通过单线程的方式执行请求命令，请求数据读取并解析完成，但并不执行。
- 主线程阻塞等待 IO 线程将数据回写 Socket 完毕。
- 解除绑定，清空等待队列。

![流程图](https://i.loli.net/2021/07/23/URK2DdEQCHy3GVf.png)

该设计有如下特点：

- IO 线程要么同时在读 Socket，要么同时在写，不会同时读或写。
- IO 线程只负责读写 Socket 解析命令，不负责命令处理

### 参考资料

https://www.cnblogs.com/gz666666/p/12901507.html

https://raw.githubusercontent.com/redis/redis/6.0/redis.conf