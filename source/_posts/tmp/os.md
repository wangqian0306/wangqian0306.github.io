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

### 参考资料

[MIT 公开课 6.S081 操作系统工程](https://www.bilibili.com/video/BV19k4y1C7kA/?spm_id_from=333.788.recommend_more_video.0&vd_source=519553681f7d25c891ac4cfdc33d4884)

[xv6-public 源码](https://github.com/mit-pdos/xv6-public)

[MIT6.S081 视频中文翻译文本](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081)

[MIT6.S081 教案](https://pdos.csail.mit.edu/6.828/2020/xv6/book-riscv-rev1.pdf)

[MIT6.S081 教案中文翻译](https://github.com/zhenyu-zang/xv6-riscv-book-Chinese)

[Memory Layout of Kernel and UserSpace in Linux.](https://learnlinuxconcepts.blogspot.com/2014/03/memory-layout-of-userspace-c-program.html)

[Linux 内核相关书籍](https://www.kernel.org/doc)

[MIT 公开课 6.824 分布式系统](https://www.bilibili.com/video/BV1R7411t71W)
