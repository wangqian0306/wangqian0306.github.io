---
title: UNIX I/O 模型
date: 2021-07-23 21:57:04
tags: "Linux"
id: unix-io
no_word_count: true
no_toc: false
categories: Linux
---

## UNIX I/O 模型

### 简介

在 Unix 系统的网络部分可以将 I/O 切分为以下 5 种类型：

- Blocking I/O(阻塞式 I/O)
- Non-blocking I/O (非阻塞式 I/O)
- I/O Multiplexing (I/O 多路复用)
- Signal Driven I/O (信号驱动型 I/O)
- Asynchronous I/O (异步 I/O)

输入操作通常有两个不同的阶段：

1. 等待数据到达内核缓冲区
2. 从内核缓冲区拷贝数据到应用程序缓冲区

### 同步和异步

#### 同步

发出一个功能调用时，在没有得到结果之前，该调用就不返回，也就是必须一件一件事做，等前一件做完了才能做下一件事。

#### 异步

当一个异步过程调用发出后，调用者一般不能立刻得到结果，实际处理这个调用的部件在完成后，通过状态、通知和回调来通知调用者

可以使用以下三种方式通知调用者：

- 状态——监听被调用者的状态(轮询)，调用者需要每隔一定时间检查一次，效率会很低；
- 通知——当被调用者执行完成后，发出通知告知调用者，无需消耗太多性能
- 回调——当被调用者执行完成后，会调用调用者提供的回调函数

### 阻塞和非阻塞

#### 阻塞

调用结果返回之前，当前线程会被挂起(线程进入非可执行状态，在这个状态下，OS不会给线程分配时间片，即线程暂停运行)，调用结果返回后线程进入就绪态。

#### 非阻塞

调用结果返回之前，该函数不会阻塞当前线程，而会立刻返回

### Blocking I/O(阻塞式 I/O)

![Blocking I/O](https://i.loli.net/2021/07/23/CR2rwfQo8aIAE7g.gif)

在阻塞式 I/O 模型中，应用程序在从调用 `recvfrom` 开始到它返回有数据报准备好这段时间是阻塞的，`recvfrom` 返回成功后，应用进程开始处理数据报。

**比喻**：一个人在钓鱼，当没鱼上钩时，就坐在岸边一直等。

**优点**：程序简单，在阻塞等待数据期间进程/线程挂起，基本不会占用 CPU 资源。

**缺点**：每个连接需要独立的进程/线程单独处理，当并发请求量大时为了维护程序，内存、线程切换开销较大，这种模型在实际生产中很少使用。

> 注：recvfrom 函数会从 Socket 接收数据。

### Non-blocking I/O (非阻塞式 I/O)

![Non-blocking I/O ](https://i.loli.net/2021/07/23/W9okQYTeRGMcms2.gif)

在非阻塞式 I/O 模型中，应用程序把一个套接口设置为非阻塞，就是告诉内核，当所请求的 I/O 操作无法完成时，不要将进程睡眠。

而是返回一个错误，应用程序基于 I/O 操作函数将不断的轮询数据是否已经准备好，如果没有准备好，继续轮询，直到数据准备好为止。

**比喻**：边钓鱼边玩手机，隔会再看看有没有鱼上钩，有的话就迅速拉杆。

**优点**：不会阻塞在内核的等待数据过程，每次发起的 I/O 请求可以立即返回，不用阻塞等待，实时性较好。

**缺点**：轮询将会不断地询问内核，这将占用大量的 CPU 时间，系统资源利用率较低，所以一般 Web 服务器不使用这种 I/O 模型。

### I/O Multiplexing (I/O 多路复用)

![I/O Multiplexing](https://i.loli.net/2021/07/23/KVbwIXNHDFCB2nU.gif)

在 I/O 多路复用模型中，会用到 select 或 poll 函数或 epoll 函数，这三个函数也会使进程阻塞，但是和阻塞 I/O 有所不同。

这三个函数可以同时阻塞多个 I/O 操作，而且可以同时对多个读操作，多个写操作的 I/O 函数进行检测，直到有数据可读或可写时，才真正调用 I/O 操作函数。

**比喻**：放了一堆鱼竿，在岸边一直守着这堆鱼竿，没鱼上钩就玩手机。

**优点**：可以基于一个阻塞对象，同时在多个描述符上等待就绪，而不是使用多个线程(每个文件描述符一个线程)，这样可以大大节省系统资源。

**缺点**：当连接数较少时效率相比多线程+阻塞 I/O 模型效率较低，可能延迟更大，因为单个连接处理需要 2 次系统调用，占用时间会有增加。

### Signal Driven I/O (信号驱动型 I/O)

![Signal Driven I/O](https://i.loli.net/2021/07/23/HKM6P5zBqCmhT9X.gif)

在信号驱动式 I/O 模型中，应用程序使用套接口进行信号驱动 I/O，并安装一个信号处理函数，进程继续运行并不阻塞。

当数据准备好时，进程会收到一个 SIGIO 信号，可以在信号处理函数中调用 I/O 操作函数处理数据。

**比喻**：鱼竿上系了个铃铛，当铃铛响，就知道鱼上钩，然后可以专心玩手机。

**优点**：线程并没有在等待数据时被阻塞，可以提高资源的利用率。

**缺点**：信号 I/O 在大量 IO 操作时可能会因为信号队列溢出导致没法通知。

信号驱动 I/O 尽管对于处理 UDP 套接字来说有用，即这种信号通知意味着到达一个数据报，或者返回一个异步错误。

但是，对于 TCP 而言，信号驱动的 I/O 方式近乎无用，因为导致这种通知的条件为数众多，每一个来进行判别会消耗很大资源，与前几种方式相比优势尽失。

### Asynchronous I/O (异步 I/O)

![Asynchronous I/O](https://i.loli.net/2021/07/23/3QrpFa9Yeiw4MnX.gif)

由 POSIX 规范定义，应用程序告知内核启动某个操作，并让内核在整个操作（包括将数据从内核拷贝到应用程序的缓冲区）完成后通知应用程序。

这种模型与信号驱动模型的主要区别在于：信号驱动 I/O 是由内核通知应用程序何时启动一个 I/O 操作，而异步 I/O 模型是由内核通知应用程序 I/O 操作何时完成。

**优点**：异步 I/O 能够充分利用 DMA 特性，让 I/O 操作与计算重叠。

**缺点**：要实现真正的异步 I/O，操作系统需要做大量的工作。目前 Windows 下通过 IOCP 实现了真正的异步 I/O。

而在 Linux 系统下，Linux 2.6才引入，目前 AIO 并不完善，因此在 Linux 下实现高并发网络编程时都是以 IO 复用模型模式为主。

### 参考资料

https://www.masterraghu.com/subjects/np/introduction/unix_network_programming_v1.3/ch06lev1sec2.html

https://zhuanlan.zhihu.com/p/121826927

https://zhuanlan.zhihu.com/p/43933717