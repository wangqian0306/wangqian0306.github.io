---
title: Redis 持久化知识整理
date: 2020-06-04 21:41:32
tags: "Redis"
id: redis-storage
no_word_count: true
no_toc: false
categories: Redis
---

## 持久化

Redis 的数据持久化选项有以下两种：

- RDB
- AOF

在官方文档中明确说明：

- 如果可以承受少量的数据损失，可以单独使用 RDB 作为存储方式。
- 单独使用 AOF 也是不被推荐的，因为配合 RDB 可以实现更快的重启，并且当 AOF 存在错误时仍可以通过 RDB 找回数据。

### RDB(数据库快照)

RDB(Redis Database)，RDB 可以通过配置项来实现或者使用 SAVE 或者 BGSAVE 命令实现手动备份，这两个命令的区别在于：

- SAVE 命令会造成阻塞，直到 RDB 文件创建完毕为止，服务器都不能处理任何命令请求。
- BGSAVE 命令会派生出一个子进程，然后由子进程负责创建 RDB 文件，父进程继续处理命令请求。

详细配置请参照 RDB 相关配置项表：

|配置项|说明|
|:---:|:---:|
|save <m> <n>|在 m 秒内有 n 次数据变化则为数据库创建快照(此配置项可以书写多个)|
|stop-writes-on-bgsave-error <m> |在制作快照失败时阻止写入(此配置项默认为 yes)|
|rdbcompression <m>|使用 LZF 算法压缩快照文件(此配置项默认为 yes)|
|rdbchecksum <m>| 快照文件格式校验|
|dbfilename <m>|RDB 文件名|
|dir <m>|快照存储地址|

#### 优点：

- 备份方便，便于还原不同的版本，存储效率高
- 利于灾难恢复
- 对性能上的影响小
- 可以使集群快速重启

#### 缺点：

- 数据可能产生丢失
- 如果数据量较大则需要较长的时间处理

### AOF(日志记录)

AOF(Append Only File)，利用独立日志的方式记录写命令，在重启时重新执行 AOF 文件中的命令来实现数据恢复。

在实现的过程中，AOF 有以下三种策略：

- always(每次都执行)
- everysec(每秒)
- no(系统控制)

> 注：也可以使用手动输入命令 BGREWRITEAOF 触发。

详细配置请参照 AOF 相关配置表：

|配置项|说明|
|:---:|:---:|
|appendonly <m>| AOF 功能开关(可选: yes,no)|
|appendfilename <m>| AOF 日志文件(默认值为 appendonly.aof)|
|appendfsync <m>| 执行策略(可选: always,everysec,no)|
|no-appendfsync-on-rewrite <m>|在有线程调用时不进行 AOF 写入操作，如果开启可优化性能但是可能丢 30s 的数据(可选：yes,no) |
|auto-aof-rewrite-percentage <m>| 在AOF增长大小/AOF文件大小>=<m>时进行自动重写|
|auto-aof-rewrite-min-size <m>|当 AOF 文件达到<m>时进行自动重写|
|aof-load-truncated <m>| 在恢复数据时是否忽略最后一条可能存在问题的指令(默认值为 yes)|
|dir <m>|数据存储地址|

> 注：重写 AOF 文件可以减少恢复时的资源损耗，优化日志文件的存储空间。

#### 优点：

- 持久化策略更为灵活
- 备份文件不容易产生损坏的问题
- 可以通过重写的思路优化日志文件
- 利于手动编辑

#### 缺点：

- 与 RDB 相较而言 AOF 要占用更多的存储空间
- 效率可能低于 RDB

#### Redis 7.0 更新

从 Redis 7.0.0 开始，当计划进行 AOF 重写时，Redis 父进程会打开一个新的增量 AOF 文件(incremental AOF file)以继续写入。子进程将执行重写逻辑并生成新的基本 AOF(base AOF)。Redis 将使用临时清单文件(temporary manifest file)来跟踪新生成的基本文件和增量文件。在准备就绪后，Redis 将执行原子替换操作以使此临时清单文件生效。为了避免在 AOF 重写重复失败和重试的情况下创建许多增量文件的问题，Redis 引入了 AOF 重写限制机制，以确保以越来越慢的速度重试失败的 AOF 重写。

> 注：由于目前版本 AOF 是多个文件，所以在备份 AOF 文件的时候需要先关闭 AOF 自动重写，且确保有正在进行重写，如果正在进行重写需要等待重写完成之后再去复制文件。在复制完成后重新打开 AOF 重写功能。

### RDB VS AOF

将以上两种方式进行对比可以得到下表：

|持久化方式|RDB|AOF|
|:---:|:---:|:---:|
|占用存储空间|小|大|
|存储速度|慢|快|
|恢复速度|快|慢|
|数据安全性|容易丢失一段时间的数据|依据执行策略决定|
|资源消耗|高|低|
|启动优先级|低|高|

### 混合持久化

在 Redis 4.0 版本之后新增了混合持久化的方案，可以修改如下的配置项：

|配置项|说明|
|:---:|:---:|
|aof-use-rdb-preamble <m>|混合存储功能开关(可选: yes,no)|

> 注：需要打开 AOF 才能使用此功能。

#### 实现思路

Redis 是通过如下方式来实现混合持久化的。

```
[RDB file][AOF tail]
```

在 Redis 恢复数据时，如果读取到命令以 REDIS 字符串开始则使用 RDB 文件恢复，然后再去执行剩余的 AOF 命令。

### AOF 文件修复

由于磁盘空间不足，系统故障等原因 AOF 文件可能会存在错误，此时会有这样的日志：

```text
* Reading RDB preamble from AOF file...
* Reading the remaining AOF tail...
# !!! Warning: short read while loading the AOF file !!!
# !!! Truncating the AOF at offset 439 !!!
# AOF loaded anyway because aof-load-truncated is enabled
```

此时就需要制作 AOF 文件的备份，然后尝试使用如下命令修复 AOF 文件

```bash
redis-check-aof --fix <filename>
```

然后使用此 AOF 文件启动服务器即可。

### 参考资料

[Redis persistence](https://redis.io/docs/management/persistence)
