---
title: Grafana Loki
date: 2024-09-06 23:09:32
tags:
- "Grafana"
- "Loki"
- "Spring"
id: loki
no_word_count: true
no_toc: false
categories: "工具"
---

## Grafana Loki 

### 简介

Grafana 日志汇集的组件。在看 SpringOne 大会视频的时候了解到 Spring 对日志的处理方式。

### 安装

#### Docker

使用如下命令即可：

```yaml
mkdir loki
cd loki
wget https://raw.githubusercontent.com/grafana/loki/v3.0.0/production/docker-compose.yaml -O docker-compose.yaml
docker-compose up -d 
```

#### Kubernetes

在 Kubernets 上安装分成了如下种安装方式：

- monolithic 单体
- scalable 弹性(支持每日数 TB)
- microservice 微服务

具体流程参照 [官方文档](https://grafana.com/docs/loki/latest/setup/install/helm/)

##### Istio

在 Istio 环境下需要进行 [额外配置](https://grafana.com/docs/loki/latest/setup/install/istio/)

### 参考资料

[官方文档](https://grafana.com/docs/loki/latest/)

[视频教程](https://www.youtube.com/watch?v=TLnH7efQNd0&list=PLDGkOdUX1Ujr9QOsM--ogwJAYu6JD48W7)

[样例代码和配置](https://github.com/jonatan-ivanov/teahouse)

[Is Your JVM App Flying Blind? Unmask Issues With Observability Superpowers! (SpringOne 2024)](https://www.youtube.com/watch?v=IB89ZmBslY4)

[Micrometer Mastery: Unleash Advanced Observability In Your JVM Apps (SpringOne 2024)](https://www.youtube.com/watch?v=X7rODR2m63c&t=1941s)

[Dapper, a Large-Scale Distributed Systems Tracing Infrastructure](http://research.google.com/archive/papers/dapper-2010-1.pdf)

[Dapper，大规模分布式系统的跟踪系统](https://bigbully.github.io/Dapper-translation/)
