---
title: Spring 效率优化
date: 2025-07-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-runtime-efficiency-enhance
no_word_count: true
no_toc: false
categories: Spring
---

## Spring 效率优化

### 简介

在优化 SpringBoot 启动时间，运行所占用内存和 CPU 这样的需求时可以采用以下技术：

- GraalVM Native Images
- Project CraC
- Class Data Sharing (CDS)
- AOT(Ahead-of-Time) Cache (JDK 24)
- Project Leyden (JDK 25 +)

但每种技术都有自己的弊端，需要根据程序的需求进行权衡来选择方案。

### 性能对比

| Java / Spring Boot 版本 | 模式 | 启动时间（毫秒） | 时间变化（%） | 使用内存（MB） | 内存变化（%） |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 1.8.0_442 / 2.7.3 | Exec JAR | 3,440 | 0.0 | 495.75 | 0.0 |
| 21.0.6 / 3.4.5 | Exec JAR | 3,790 | +10.2 | 442.70 | -9.1 |
| 21.0.6 / 3.4.5 | Unpacked* | 3.01 | -7.0 | 418.11 | -15.6 |
| **21.0.6 / 3.4.5** | **GraalVM** | **0.39** | **-88.0** | **185.93** | **-37.5** |
| 21.0.6 / 3.4.5 | Project CraC | 0.55 | -82.9 | 367.23 | -14.6 |
| 21.0.6 / 3.4.5 | Spring AOT | 3.34 | 3.40 | 436.37 | -6.3 |
| 21.0.6 / 3.4.5 | CDS | 1.82 | -43.8 | 402.05 | -18.9 |
| 21.0.6 / 3.4.5 | CDS + Spring AOT | 1.52 | -55.8 | 409.98 | -17.3 |
| 24, Leyden EA | AOT code compilation + Spring AOT | 1.2 | -65.1 | 426 | -14.07 |

### 技术对比

| 技术 | 启动 | 预热 | 最佳峰值吞吐量 | 内存消耗 | 编译 | 兼容性问题 | 安全性 | 容器大小与JVM相比 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---: |:---:|
| 使用GraalVM的原生可执行文件 | 立即 | 立即 | 使用 Oracle GraalVM 进行训练运行 | 减少 | 重且慢 | 需要可达性元数据 | ✔ | 更小 |
| 使用 Project CRaC 的JVM | 立即 | 使用训练运行立即完成 | ✔ | 没有提升 | 快速 | 仅限 Linux 恢复 | 快照中存在秘密泄露 | 更大 |
| 使用CDS的JVM | 快1.5倍 使用 Spring AOT 快2倍 | 没有提升 | ✔ | 略微减少 | 快速 | 训练运行的副作用 | ✔ | 更大 |
| 使用 AOT 缓存 编译代码的 JVM | 快3倍 使用 Spring AOT 快4倍      | 使用 Java 25+ 中的训练运行快速 | ✔ | 在Java 25+ 中略微减少 | 快速 | 训练运行的副作用 | ✔ | 略微更大 |

### 参考资料

[Mastering Challenges of Cloud-Native Architectures With Spring by Timo Salm @ Spring I/O 2025](https://www.youtube.com/watch?v=hASsv4eQSgs)
