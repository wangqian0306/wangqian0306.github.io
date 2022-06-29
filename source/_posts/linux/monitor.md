---
title: Linux 系统性能排查
date: 2022-06-29 21:57:04
tags: "Linux"
id: monitor
no_word_count: true
no_toc: false
categories: Linux
---

## Linux 系统性能排查

### 整体情况排查

> 注：此软件需要在软件管理工具中独立安装，例：`yum install -y htop`

可以使用 `htop` 命令获取当前系统的整体情况，在此页面可以对如下参数项进行进行一些基本排查。

软件上半部分为系统基础信息：

- CPU 核心使用率(数字编号的图形)
- 内存使用情况(Mem)
- 交换内存使用情况(Swp)
- 进程总览(Tasks 即总进程数，thr 线程数，running 代表处于此状态的进程数)
- 系统平均负载倍数(平均负载部分有三个值分别为：最近 1 分钟负载，最近 5 分钟负载，最近 15 分钟负载)
- 系统持续运行时间(Uptime)

软件下半部分为进程详细清单，参数解释如下：

- PID – 描述进程的ID号
- USER – 描述进程的所有者（谁跑的）
- PRI – 描述Linux内核查看的进程优先级
- NI – 描述由用户或root重置的进程优先级
- VIR – 它描述进程正在使用的虚拟内存 （virtual memory）
- RES – 描述进程正在消耗的物理内存（physical memory）
- SHR – 描述进程正在使用的共享内存（shared memory）
- S – 描述流程的当前状态 (state)
- CPU％ – 描述每个进程消耗的CPU百分比
- MEM％ – 描述每个进程消耗的内存百分比
- TIME+ – 显示自流程开始执行以来的时间
- Command –它与每个进程并行显示完整的命令执行 (比如/usr/lib/R)

#### CPU 核心使用率图示

蓝色：显示低优先级(low priority)进程使用的CPU百分比。
绿色：显示用于普通用户(user)拥有的进程的CPU百分比。
红色：显示系统进程(kernel threads)使用的CPU百分比。
橙色：显示IRQ时间使用的CPU百分比。
洋红色(Magenta)：显示Soft IRQ时间消耗的CPU百分比。
灰色：显示IO等待时间消耗的CPU百分比。
青色：显示窃取时间(Steal time)消耗的CPU百分比。

#### 内存及交换内存使用率图示

绿色：显示内存页面占用的 RAM 百分比
蓝色：显示缓冲区页面占用的 RAM 百分比
橙色：显示缓存页面占用的 RAM 百分比

#### 进程状态汇总

R: Running：表示进程(process)正在使用CPU
S: Sleeping: 通常进程在大多数时间都处于睡眠状态，并以固定的时间间隔执行小检查，或者等待用户输入后再返回运行状态。
T/S: Traced/Stopped: 表示进程正在处于暂停的状态
Z:Zombie or defunct:已完成执行但在进程表中仍具有条目的进程。

### CPU 检测



### 内存检测



### 磁盘检测



### 网络检测



### 参考资料

[Linux性能问题分析流程与性能优化思路](https://mp.weixin.qq.com/s?__biz=Mzg2MzU2MDYzOA==&mid=2247497271&idx=1&sn=35c94a05c2f8119963f426feaa131a84&chksm=ce7400e6f90389f072d6abefe1c14676b86b51eaa1c681b66b94fa7040e97768f937275bfb96&mpshare=1&scene=1&srcid=06290au4y21HUZyHAConEJvM&sharer_sharetime=1656465189420&sharer_shareid=50fa697c70389182b3ee50f3e931b174&version=4.0.8.6027&platform=win#rd)

[Linux htop 详解](https://zhuanlan.zhihu.com/p/296803907)
