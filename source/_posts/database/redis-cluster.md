---
title: Redis 集群和高可用
date: 2020-06-08 21:58:01
tags: "Redis"
id: redis-cluster
no_word_count: true
no_toc: false
categories: Redis
---

### 主从模式

可以在 redis.conf 中编写下面的配置项来实现主从模式配置：

|配置项|说明|
|:---:|:---:|
|replicof <masterip> <masterport>|主机地址|
|masterauth <master-password>|主机密码|
|masteruser <username>|主机用户名|
|replica-read-only <m>|从机是否可以写数据|
|repl-backlog-size <size>|数据同步缓冲区大小|

> 在 Redis 6.0 中，将原先的`slaveof` 配置项修改为了 `replicof`

### 哨兵模式

哨兵模式是 Redis 官方提供的高可用解决方案。

> 注：哨兵模式并不负责数据相关内容仅仅负责在 Redis 中选举！

可以在 sentinel.conf 中编写下面的配置来实现哨兵模式配置：

|配置项|说明|
|:---:|:---:|
|bind <ip>|监听服务地址|
|port <port>|哨兵模式端口|
|sentinel monitor mymaster <masterip> <masterport> <quorum>|在 quorum 台设备同时检测到服务下线时进行重新选举|
|sentinel down-after-milliseconds mymaster <milliseconds>|主机最大无响应时长|
|sentinel parallel-syncs mymaster <num>|设置在故障转移后可以重新配置为使用新主服务器的副本数|
|sentinel failover-timeout mymaster <milliseconds>|故障转移超时配置|

在配置完成后可以使用如下命令启动哨兵服务。

```bash
redis-server sentinel.conf --sentinel
```

### 集群模式

相较于哨兵模式，集群模式可以更好的利用系统资源缓解数据写入压力。

可以在 redis.conf 中编写下面的配置项来开启集群模式：

|配置项|说明|
|:---:|:---:|
|cluster-enabled <status>|集群模式开关|
|cluster-config-file <filename>|集群模式配置文件名|
|cluster-node-timeout <milliseconds>|集群超时时间|

在配置完成上述内容后可以正常启动服务，然后使用如下的命令来创建集群：

```bash
redis-cli --cluster create <ip1>:<port1> <ip2>:<port2> ... --cluster-replicas 1
```

> 注：其中 cluster-replicas 参数表示的是1个主机所对应的从机数量。

在命令运行完成后 redis 集群会进行相应初始化操作，可以使用 cli 的方式进行功能验证：

```bash
redis-cli -c 
```

> 注：-c 为集群模式的标识。
