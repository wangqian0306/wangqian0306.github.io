---
title: Kafka 性能和高可用性调整
date: 2021-09-15 22:43:13
tags:
- "Kafka"
id: kafka-tuning
no_word_count: true
no_toc: false
categories: 大数据
---

## Kafka 性能和高可用性调整

### 操作系统部分

#### 文件描述符限制

- `ulimit -n 1000000`

- `vim /etc/sysctl.conf`

```text
vm.max_map_count=655360
```

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

### 配置部分

#### Broker 启动参数

```text
  -Xmx6g -Xms6g -XX:MetaspaceSize=96m -XX:+UseG1GC
  -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M
  -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80 -XX:+ExplicitGCInvokesConcurrent
```

#### 机架名

为了防止单个机架的故障导致服务不可用，可以设置 `broker.rack` 参数。这样一来 Kafka 会保证分区的副本被分布在多个机架上，从而获得更高的可用性。

#### 副本选举策略

`unclean.leader.election` 参数默认为 true，表示允许不同步的副本成为首领，可能会造成消息丢失。如果业务场景不能接受消息丢失则需要修改为 false。

`auto.leader.rebalance.enable` 参数设置为 false，表示禁止定期进行的重新选举。

### 监控部分

对于服务器需要监控如下参数：

- CPU 使用率
- 网络输入/输出吞吐量
- 磁盘平均等待时间
- 磁盘剩余空间
- 内存使用率
- TCP 链接数
- 打开文件数
- inode 使用情况

对于 JVM 需要监控如下内容：

- Full GC 发生频率和时间长度
- 活跃对象大小
- 应用线程总数

对于生产者来说需要监控如下参数：

- error-rate
- retry-rate

> 注：通过这两项参数明确生产者的错误率。

对于消费者来说需要监控如下参数：

- consumer-lag
- records-lag-max
- records-lead-min

> 注：Lag 表示距离最新消息还有多少积压。Lead 值是指消费者最新消费消息的位移与分区当前第一条消息位移的差值。一旦你监测到 Lead 越来越小，甚至是快接近于 0 了，你就一定要小心了，这可能预示着消费者端要丢消息了

对于 broker 来说需要监控如下参数：

- UnderReplicatedPartitions(未同步的分区)
- ActiveControllerCount(活跃度控制器数量)
- RequestHandlerAvgIdlePercent(请求处理器空闲率)
- BytesInPerSec(主题输入字节/秒)
- BytesOutPerSec(主题输出字节/秒)
- MessagesInPerSec(主题接收消息/秒)
- PartitionCount(分区数量)
- LeaderCount(首领数量)
- OfflinePartitionsCount(离线分区数量)

> 注：详情参阅 [官方文档](http://kafka.apache.org/documentation.html#monitoring)。

### 性能指标调优

#### 调优吞吐量

|参数位置|参数描述|
|:---:|:---:|
|Broker 端|适当增加 `num.replica.fetchers` 参数值，但不用超过 CPU 核心数|
|Broker 端|调优 GC 参数以避免经常性的 Full GC|
|Producer 端|适当增加 `batch.size` 参数值，比如从默认的 16 KB 增加到 512 KB 或 1MB|
|Producer 端|适当增加 `linger.ms` 参数值，比如 10~100 |
|Producer 端|设置 `compression.type=lz4` 或者 `zstd`|
|Producer 端|设置 `acks=0` 或 `1`|
|Producer 端|设置 `retries=0`|
|Producer 端|如果多线程共享同一个 Producer 实例，就增加 `buffer.memory` 参数值|
|Consumer 端|采用多 Consumer 进程或线程同时消费数据|
|Consumer 端|增加 `fetch.min.bytes` 参数值，比如设置成 1KB 或更大|

#### 调优延时

|参数位置|参数描述|
|:---:|:---:|
|Broker 端|适当增加 `num.replica.fetchers` 参数值|
|Producer 端|设置 `linger.ms=0`|
|Producer 端|不启用压缩，即设置 `compression.type=none`|
|Producer 端|设置 `acks=1`|
|Consumer 端|设置 `fetch.min.bytes=1`|

#### 批处理指标监控

- `batch-size-avg` ：此指标是批处理的实际大小。如果一切顺利，这将非常接近 batch.size。如果 batch-size-avg 始终低于设置的批量大小，则 linger.ms 可能不够高。同时，如果 linger.ms 很高，而批次仍然很小，则可能是记录生成速度不够快。如果已经很高了可以再调整回原来的值。
- `records-per-request-avg` ：每个请求跨批次的平均记录数。
- `record-size-avg` ：注意不要接近或超过 `batch.size`
- `buffer-available-bytes` ：内存余量。
- `record-queue-time-avg` ：在发送记录之前等待填充的时间。

### 参考资料

- [Kafka 官方文档](http://kafka.apache.org/documentation/)
- [Kafka 核心技术与实战](https://time.geekbang.org/column/intro/100029201)
- [Kafka Producer and Consumer Internals](https://www.confluent.io/blog/kafka-producer-and-consumer-internals-4-consumer-fetch-requests/)