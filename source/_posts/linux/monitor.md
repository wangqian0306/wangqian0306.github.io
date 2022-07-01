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

#### htop

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

##### CPU 核心使用率图示

蓝色：显示低优先级(low priority)进程使用的CPU百分比。
绿色：显示用于普通用户(user)拥有的进程的CPU百分比。
红色：显示系统进程(kernel threads)使用的CPU百分比。
橙色：显示IRQ时间使用的CPU百分比。
洋红色(Magenta)：显示Soft IRQ时间消耗的CPU百分比。
灰色：显示IO等待时间消耗的CPU百分比。
青色：显示窃取时间(Steal time)消耗的CPU百分比。

##### 内存及交换内存使用率图示

绿色：显示内存页面占用的 RAM 百分比
蓝色：显示缓冲区页面占用的 RAM 百分比
橙色：显示缓存页面占用的 RAM 百分比

##### 进程状态汇总

R: Running：表示进程(process)正在使用CPU
S: Sleeping: 通常进程在大多数时间都处于睡眠状态，并以固定的时间间隔执行小检查，或者等待用户输入后再返回运行状态。
T/S: Traced/Stopped: 表示进程正在处于暂停的状态
Z:Zombie or defunct:已完成执行但在进程表中仍具有条目的进程。

#### dstat

> 注：此软件需要在软件管理工具中独立安装，例：`yum install -y dstat`

可以使用 `dstat -vtns [<option>] <second> ` 命令，查看当前的 CPU 和一些 IO 状况，其中 `option` 参数表示需要查看的内容 `second` 参数代表每隔多少秒进行一次统计，参数详解如下：

- CPU 使用率(total-cpu-usage)，可以在 `option` 参数中添加 `-C <core_num>,total` 来查看某个核心及总量的使用情况
    - 用户时间占比(usr)
    - 系统时间占比(sys)
    - 空闲时间占比(idl)
    - 等待时间占比(wai)
    - 硬中断次数(hiq)
    - 软中断次数(siq)
- 内存使用率(memory-usage)
    - 已用内存(used)
    - 缓冲区(buff)
    - 缓存(cache)
    - 可用内存(free)
- 交换内存使用率(swap)
    - 已用内存(used)
    - 可用内存(free)
- 磁盘使用率(dsk)，可以在 `option` 参数中添加 `-D <disk_name>,total` 参数查看某个磁盘的使用情况
    - 读取带宽(read)
    - 写入带宽(writ)
- 网络使用率(net)，可以在 `option` 参数中添加 `-N <network_name>,total` 参数查看某个网卡的使用情况
    - 输入带宽(recv)
    - 输出带宽(send)
- 系统使用情况(system)
    - 中断数量(int)
    - 上下文切换次数(csw)
- 系统的分页活动(paging)
    - 换入次数(in)
    - 换出次数(out)

除此之外 dstat 命令还可以监控如下内容：

- aio 状态：`--aio`
- 文件系统状态：`--fs`
- ipc 状态：`--ipc`
- 锁状态：`--lock`
- Socket 状态(raw)`：--raw`
- Socket 状态`：--socket`
- TCP 状态：`--tcp`
- UPD 状态：`--udp`
- unix 状态：`--unix`
- 虚拟内存状态：`--vm`

### CPU 检测

![CPU 性能指标梳理](https://s6.jpg.cm/2022/07/01/Pqwn1t.png)

![CPU 检测分析工具梳理](https://s2.loli.net/2022/06/30/NkUu4LwH35bqns7.png)

具体指标的分析方式参见下表：

|    性能指标    |                    分析工具                     | 说明                                                            |
|:----------:|:-------------------------------------------:|:--------------------------------------------------------------|
|    平均负载    |       `uptime` `htop` `/proc/loadavg`       | 最后一个常用于监控系统                                                   |
| 系统 CPU 使用率 | `vmstat` `mpstat` `htop` `sar` `/proc/stat` | `sar` 还可以记录历史数据，`/proc/stat` 常用于监控系统                          |
| 进程 CPU 使用率 |            `htop` `ps` `pidstat`            | `pidstat` 只显示实际使用了 CPU 的进程                                    |
|  系统上下文切换   |                  `vmstat`                   | 除了上下文切换次数，还提供运行状态和不可中断状态进程的数量                                 |
|  进程上下文切换   |                  `pidstat`                  | 注意加上 `-w` 选项                                                  |                                      |
|    软中断     |      `htop` `mpstat` `/proc/softirqs`       | `htop` 提供使用率，其他内容则提供了在每个 CPU 上的运行次数                           |
|    硬中断     |         `vmstat` `/proc/interrupts`         | `vmstat` 提供总的中断次数，而 `/proc/interrupts` 提供各种中断在每个 CPU 上运行的累计次数 |
|   CPU 缓存   |                   `pref`                    | 使用 `pref stat` 子命令                                            |
|  CPU 基础信息  |           `lscpu` `/proc/cpuinfo`           | `lscpu` 更直观                                                   |
|    事件剖析    |           `pref` 火焰图 `execsnoop`            | `pref` 和火焰图用户来分析热点函数以及调用栈，`execsnoop` 用来监测短时进程                |
|    动态追踪    |         `ftrace` `bcc` `systemtap`          | `ftrace` 用于跟踪内核函数调用栈，而 `bcc` 和 `systemtap` 则用于跟踪内核或应用程序的执行过程  |

### 内存检测

![内存性能指标梳理](https://s6.jpg.cm/2022/07/01/PqwRC5.png)

具体指标的分析方式参见下表：

|       性能指标       |                             分析工具                              | 说明                                                                          |
|:----------------:|:-------------------------------------------------------------:|:----------------------------------------------------------------------------|
|   系统已用，可用，剩余内存   |         `free` `vmstat` `dstat` `sar` `/proc/meminfo`         | `/proc/meminfo` 常用于监控系统                                                     |
| 进程虚拟内存，常驻内存，共享内存 | `ps` `htop` `pidstat` `/proc/<pid>/stat` `/proc/<pid>/status` | `pidstat` 命令需要加上 `-r` 选项，`/proc/<pid>/stat` 和 `/proc/<pid>/status` 常用于监控系统中 |
|      进行内存分布      |                   `pmap` `/proc/<pid>/maps`                   | `/proc/<pid>/maps` 是 `pmap` 的数据来源，常用于监控系统中                                  |
|   进程 swap 换出内存   |                  `htop` `/proc/<pid>/status`                  | `/proc/<pid>/status` 是 `htop` 的数据来源，常用于监控系统中                                |
|      进程缺页异常      |                     `ps` `htop` `pidstat`                     | `pidstat` 命令需要加上 `-r` 选项                                                    |
|      系统换页情况      |                             `sar`                             | `sar` 命令需要加上 `-B` 选项                                                        |
|     缓存/缓冲区用量     |           `free` `vmstat` `dstat` `sar` `cachestat`           | `cachestat` 需要安装 `bcc`                                                      |
|     缓存缓冲区命中率     |                          `cachetop`                           | 需要安装 `bcc`                                                                  |
|   swap 已用和剩余空间   |                         `free` `sar`                          | `sar` 可以记录历史                                                                |
|    swap 换入换出     |                        `vmstat` `sar`                         | `sar` 可以记录历史                                                                |
|      内存泄漏检测      |                           `memleak`                           | `memleak` 需要安装 `bcc`                                                        |

### 磁盘检测

![磁盘性能指标梳理](https://s6.jpg.cm/2022/07/01/Pq4KTG.png)

![磁盘检测分析工具梳理](https://s6.jpg.cm/2022/07/01/Pq4jQ4.png)

|                   性能指标                    |                   分析工具                    | 说明                                                                             |
|:-----------------------------------------:|:-----------------------------------------:|:-------------------------------------------------------------------------------|
|            文件系统空间容量，使用量以及剩余空间             |                   `df`                    |                                                                                |
|              索引节点容量，使用量以及剩余量              |                   `df`                    | 需要加上 `-r` 选项                                                                   |
|              页缓存和可回收 Slab 缓存              |      `/proc/meminfo` `sar` `vmstat`       | `sar` 命令需要加上 `-r` 选项，`/proc/meminfo` 常用于监控系统中                                  |
|                    缓冲区                    |      `/proc/meninfo` `sar` `vmstat`       | `sar` 命令需要加上 `-r` 选项，`/proc/meminfo` 常用于监控系统中                                  |
|             目录项，索引节点以及文件系统的缓存             |        `/proc/slabinfo` `slabtop`         | `/proc/slabinfo` 常用于监控系统中                                                      |
| 磁盘 I/O 使用率，IOPS，吞吐量，响应时间，I/O 平均大小以及等待队列长度 | `iostat` `sar` `dstat` `/proc/diskstatus` | `sar` 命令需要加上 `-d` 选项，`/proc/diskstatus` 常用于监控系统中                               |
|            进程 I/O 大小以及 I/O 延迟             |            `pidstat`  `iotop`             | `pidstat` 命令需要加上 `-d` 选项                                                       |
|               块设备 I/O 事件跟踪                |                `blktrace`                 | 需要跟 `blkparse` 配合使用，例如  `blktrace -d /dev/<disk_name> -o- &#124; blkparse -i-` |
|               进程 I/O 系统调用跟踪               |          `strace` `pref` `trace`          | `strace` 只可以跟踪单个进程，`pref` 和 `trace` 还可以跟踪所有进程的系统调用                             |
|              进程块设备 I/O 大小跟踪               |            `biosnoop` `biotop`            | 需要安装 `bcc`                                                                     |
|                   动态追踪                    |        `ftrace` `bcc` `systemtap`         | `ftrace` 用于跟踪内核函数调用栈，而 `bcc` 和 `systemtap` 则用于跟踪内核或应用程序的执行过程                   |

### 网络检测

![网络性能指标梳理](https://s6.jpg.cm/2022/07/01/Pq08xt.png)

![磁盘检测分析工具梳理](https://s6.jpg.cm/2022/07/01/Pq0fDU.png)

|   性能指标   |                                                   分析工具                                                   | 说明                                                           |
|:--------:|:--------------------------------------------------------------------------------------------------------:|:-------------------------------------------------------------|
| 吞吐量(BPS) |                                 `sar` `nethogs` `iftop` `/proc/net/dev`                                  | 分别可以查看网络接口，进程以及 IP 地址的网络吞吐量；`/proc/net/dev` 常用于监控系统          |
| 吞吐量(PPS) |                                          `sar` `/proc/net/dev`                                           | `sar` 命令需要加上 `-n DEV` 选项                                     |
|  网络连接数   |                                              `netstat` `ss`                                              | `ss` 速度更快                                                    |
|  网络错误数   |                                             `netstat` `sar`                                              | 注意使用 `netstat -s` 或 `sar -n EDEV/EIP`                        |
|   网络延迟   |                                             `ping` `hping3`                                              | `ping` 基于 ICMP，而 `hping3` 基于 TCP 协议                          |
|  连接跟踪数   | `conntrack` `/proc/sys/net/netfilter/nf_connectrack_count` `/proc/sys/net/netfilter/nf_connectrack_max`  | `conntrack` 可以查看所有连接                                         |
|    路由    |                                        `mtr` `traceroute` `route`                                        | `route` 用于查询路由表，而 `mtr` 和 `traceroute` 通常用于排查定位路由问题          |
|   DNS    |                                             `dig` `nslookup`                                             | 用于排查 DNS 解析的问题                                               |
| 防火墙和 NAT |                                                `iptables`                                                | 用于排查防火墙和 NAT 问题                                              |
|   网卡选项   |                                                `ethtool`                                                 | 用于查看和配置网络接口的功能选项                                             |
|   网络抓包   |                                                `tcpdump`                                                 | 通常用 `tcpdump` 抓包后再使用 Wireshark 工具进行分析                        |
|   动态追踪   |                                        `ftrace` `bcc` `systemtap`                                        | `ftrace` 用于跟踪内核函数调用栈，而 `bcc` 和 `systemtap` 则用于跟踪内核或应用程序的执行过程 |

### 参考资料

[Linux性能问题分析流程与性能优化思路](https://mp.weixin.qq.com/s?__biz=Mzg2MzU2MDYzOA==&mid=2247497271&idx=1&sn=35c94a05c2f8119963f426feaa131a84&chksm=ce7400e6f90389f072d6abefe1c14676b86b51eaa1c681b66b94fa7040e97768f937275bfb96&mpshare=1&scene=1&srcid=06290au4y21HUZyHAConEJvM&sharer_sharetime=1656465189420&sharer_shareid=50fa697c70389182b3ee50f3e931b174&version=4.0.8.6027&platform=win#rd)

[Linux htop 详解](https://zhuanlan.zhihu.com/p/296803907)

[dstat Command Examples in Linux](https://www.thegeekdiary.com/dstat-command-examples-in-linux/)
