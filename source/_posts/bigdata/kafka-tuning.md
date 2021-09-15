---
title: Kafka 性能调优
date: 2021-09-15 22:43:13
tags:
- "Kafka"
id: kafka-tuning
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka 性能调优

### 操作系统部分

#### 交换内存(swap)

- 打开交换内存 `vm.swapiness` 应当设置为 1
- 设置内存可以填充脏页的百分比 `vm.dirty_background_ratio` 应当设置为小于 10 大部分情况下可以直接设为 5 
- 设置脏页填充的绝对最大系统内存量`vm.dirty_ratio` 应当设置为大于 20，60~80 是一个比较合理的区间

在使用的过程中可以针对 swap 内的脏页数量进行监控，防止集群崩溃造成数据丢失。

```bash
cat /proc/vmstat | grep "dirty|writeback"
```

#### 磁盘及挂载参数

- 建议采用 XFS 文件系统
- 在挂载 Kafka 数据盘时建议采用 `noatime` 参数(屏蔽最后访问时间的更改，提高性能)

#### 网络配置

- socket 读写缓冲区配置为 131072 (128 KB)
  - `net.core.wmem_default`
  - `net.core.wmem_default`
- socket 读写缓冲最大值为 2097152 (2 MB)
  - `net.core.wmen_max`
  - `net.core.rmem_max`
- TCP socket 读写缓冲区大小设置为 4096 65536 2048000 (最小值 默认值 最大值)
  - `net.ipv4.tcp_wmem`
  - `net.ipv4.tcp_rmem`
- 打开 TCP 时间窗扩展 `net.ipv4.tcp_window_scaling` 设置为 1
- 提升并发量 `net.ipv4.tcp_max_syn_backlog` 设置为比 1024 更大的值
- 允许更多的数据包进入内核 `net.core.netdev_max_backlog` 设置为比 1000 更大的值

### JVM 部分

- 建议使用 Java 11

### 集群配置部分

#### broker 启动参数

```text
  -Xmx6g -Xms6g -XX:MetaspaceSize=96m -XX:+UseG1GC
  -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M
  -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80 -XX:+ExplicitGCInvokesConcurrent
```
