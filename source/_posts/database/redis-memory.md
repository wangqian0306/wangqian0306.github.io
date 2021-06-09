---
title: Redis 内存淘汰知识整理
date: 2020-06-07 17:48:32
tags: "Redis"
id: redis-memory
no_word_count: true
no_toc: false
categories: Redis
---

## 简介

Redis 可以通过 maxmemory 参数来限制最大可用内存，主要为了避免内存溢出，从而导致服务器响应变慢甚至死机的情况。

> 注：这是64位系统的默认将 maxmemory 设定为了0(代表不限制大小)，而32位系统则默认为3 GB。

### 内存淘汰策略

在 Redis 使用内存达到配置上限的时候可以设定 maxmemory-policy 配置项为下面的策略来进行回收：

|配置项|说明|
|:---:|:---:|
|noeviction|返回写入错误(默认)|
|allkeys-lru|在所有键中采用 LRU 算法删除键，直到腾出足够内存为止|
|volatile-lru|在设置了过期时间的键中采用 LRU 算法删除键，直到腾出足够内存为止|
|allkeys-random|在所有键中采用随机删除键，直到腾出足够内存为止|
|volatile-random|在设置了过期时间的键中随机删除键，直到腾出足够内存为止|
|volatile-ttl|在设置了过期时间的键空间中，具有更早过期时间的键优先移除|
|allkeys-lfu|在所有键中采用 LFU 算法删除键，直到腾出足够内存为止|
|volatile-lfu|在设置了过期时间的键中采用 LFU 算法删除键，直到腾出足够内存为止|

那么 LRU 算法和 LFU 算法有什么差异呢

LFU(Least Frequently Used)：最近最少使用，跟使用的次数有关，淘汰使用次数最少的。

LRU(Least Recently Used)：最近最不经常使用，跟使用的最后一次时间有关，淘汰最近使用时间离现在最久的。
