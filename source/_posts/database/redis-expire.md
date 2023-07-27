---
title: Redis Expire
date: 2023-07-27 21:41:32
tags: "Redis"
id: redis-expire
no_word_count: true
no_toc: false
categories: Redis
---

## Redis Expire

### 简介

在 Redis 中可以设置 Key 的过期时间，在过期后删除或覆盖 Key。自从 Redis 6 之后的实现方式有变化，所以进行整理记录。

### 实现方式

Redis 采用了两种方式实现过期策略：一种是被动的方式，另一种是主动的方式。

当某个客户端尝试访问某个 Key，但发现该 Key 已经过期时，该密钥就以被动方式处理。

当然，这还不够，因为有些过期的 Key 将永远不会被访问。这些密钥无论如何都应该过期，所以 Redis 会定期在带有过期集合的 Key 中随机测试一些密钥。所有已过期的 Key 都将从此空间中移除。

具体来说，Redis 每秒执行 10 次下面的操作：

1. 测试随机 20 个 设置了过期时间的 Key。
2. 删除已经过期的 Key。
3. 如果已过期的 Key 数量超过 25%，则重复步骤 1。

这是一个简单的概率算法，基本上假设我们的样本代表所有 Key，并且我们持续运行主动过期策略，直到可能过期的 Key 与所有 Key 的百分比低于 25%。

这意味着在任何给定时刻，正在使用内存中已过期 Key 的最大数量等于每秒最大写入操作量除以 4。

### 参考资料

[EXPIRE 命令手册](https://redis.io/commands/expire/)

[过期业务源码](https://github.com/redis/redis/blob/unstable/src/expire.c)
