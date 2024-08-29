---
title: 操作系统
date: 2024-08-13 22:26:13
tags:
- "OS"
id: os
no_word_count: true
no_toc: false
---

## 操作系统

### 简介

在 B 站刷视频的时候发现自己大学的知识像没学一样，回头捡捡操作系统。

### xv6 教学操作系统的安装

首先可以通过如下命令安装相关依赖并拉取项目进行编译

```bash
sudo apt update
sudo apt upgrade -y 
sudo apt install build-essential qemu-system -y
git clone https://github.com/mit-pdos/xv6-public.git
cd xv6-public
make
```

在编译完成后即可使用如下命令进入系统：

```bash
make qemu-nox
```

> 注：退出系统时则需要同时按住 `Ctrl` + `A` 然后松开，接着按下 `X` 即可退出虚拟机。

如果需要清除之前编译的内容则可以使用如下命令：

```bash
make clean
```

### 进程

一个 xv6 进程由两部分组成，一部分是用户内存空间（指令，数据，栈），另一部分是仅对内核可见的进程状态。

而在 Linux 中也类似，进程内存空间分成以下两个不同区域：

- **内核空间** (Kernel Space)：这是操作系统（内核）的核心所在的内存受保护区域。内核负责管理硬件、调度任务以及为应用程序提供基本服务。内核空间是共享的，并且对于所有进程都是相同的。
- **用户空间** (User Space)：这是您的应用程序及其数据所在的位置。出于安全原因，应用程序无法直接访问内核空间。每个进程都有其自己的隔离用户空间，确保一个进程不会干扰另一个进程的内存。

对与每个进程来说，它的用户空间其实是一个内存沙箱(sandbox)。虚拟地址会通过页表映射到物理内存。具体结构如下：

![线程内存结构图](https://lh3.googleusercontent.com/blogger_img_proxy/AEn0k_uxAF8seBbcHjy8T7ad5LwIrXqTJ99neYe1aIlbOU7JeXF-X9sUjqAtj51clYsR_csGZwVVt0bpdYXFdF-wV-XmHLN8sy_yzB0dWm6x_V9e3RaXITrNbuCCFA_HH3vd8MliqqtmfPzmh7Xd_qpqCQ=s0-d)

> 注：样例图片是基于 32 位系统进行表述的，64 位系统暂时没找到说明。

### 虚拟内存和页表(Page tables)

在 xv6 中为了保证系统安全所以需要对进程的空间进行隔离。对于每个应用程序来说获取到的内容都是地址空间。通过地址管理单元（Memory Management Unit）或者其他的技术，可以将每个进程的虚拟地址空间映射到物理内存地址。

页表是一种在一个物理内存上，创建不同的地址空间的常见方法。其是在硬件中通过处理器和内存管理单元（Memory Management Unit）实现的。

对于任何一条带有地址的指令，其中的地址应该认为是虚拟内存地址而不是物理地址。假设寄存器 a0 中是地址 0x1000，那么这是一个虚拟内存地址。虚拟内存地址会被转到内存管理单元（MMU，Memory Management Unit）内存管理单元会将虚拟地址翻译成物理地址。之后这个物理地址会被用来索引物理内存，并从物理内存加载，或者向物理内存存储数据。

为了能够完成虚拟内存地址到物理内存地址的翻译，MMU会有一个表单，表单中，一边是虚拟内存地址，另一边是物理内存地址。通常来说，内存地址对应关系的表单也保存在内存中。

页表会将内存分解为页(Page)和偏移量(offset)，通过页参数定位区块，通过偏移量参数定位字节。页参数+偏移量参数的总长度代表了实际支持的内存大小，一一般来说每个页的大小是 4 KB ，故偏移量参数就可以确定是 12 位。在处理器架构上会针对虚拟地址进行不同的长度设计。当页的数量过多的时候内存也会有不少的空间被浪费，所以可以通过将页参数进行分块处理例如可以将 27 位长度的分成 L2 , L1 , L0 三块。L2,L1 可以当作索引进行处理，L2 存储了 L1 的地址空间 L1 存储了 L0 的存储空间。

### 参考资料

[MIT 公开课 6.S081 操作系统工程](https://www.bilibili.com/video/BV19k4y1C7kA/?spm_id_from=333.788.recommend_more_video.0&vd_source=519553681f7d25c891ac4cfdc33d4884)

[xv6-public 源码](https://github.com/mit-pdos/xv6-public)

[MIT6.S081 视频中文翻译文本](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081)

[MIT6.S081 教案](https://pdos.csail.mit.edu/6.828/2020/xv6/book-riscv-rev1.pdf)

[MIT6.S081 教案中文翻译](https://github.com/zhenyu-zang/xv6-riscv-book-Chinese)

[Memory Layout of Kernel and UserSpace in Linux.](https://learnlinuxconcepts.blogspot.com/2014/03/memory-layout-of-userspace-c-program.html)

[Linux 内核相关书籍](https://www.kernel.org/doc)

[MIT 公开课 6.824 分布式系统](https://www.bilibili.com/video/BV1R7411t71W)
