---
title: Apache Benchmark
date: 2024-10-31 23:09:32
tags:
- "Apache Benchmark"
id: ab
no_word_count: true
no_toc: false
categories: "工具"
---

## Apache Benchmark

### 简介

Apache Benchmark (ab) 是一个开源的压力测试工具，它是 Apache HTTP 服务器的一部分。ab 工具主要用于测试Web服务器软件（如Apache、Nginx等）的并发性能和吞吐量。

### 使用方式

使用如下命令即可完成安装：

```bash
sudo yum insatll httpd-tools
```

使用如下命令即可完成测试：

```bash
ab -n 200 -c 8 https://xxx.xxx.xxx/xxx
```

> 注：`-n` 表示请求的总数 `-c` 表示并发量。

### 参考资料

[Apache Benchmark 使用手册](https://httpd.apache.org/docs/current/programs/ab.html)
