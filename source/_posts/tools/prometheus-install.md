---
title: Prometheus 安装
date: 2021-10-13 23:09:32
tags:
- "Prometheus"
id: prometheus-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Prometheus 安装

### 简介

Prometheus 是一个开源系统监控和警报工具包。Prometheus 将其指标收集并存储为时间序列数据，即指标信息与记录的时间戳一起存储，以及称为标签的可选键值对。

### 容器化部署

```yaml
version: '3'

services:
  prometheus:
    image: bitnami/prometheus:latest
    environment:
      TZ: Asia/Shanghai
    ports:
      - 9090:9090
    volumes:
      - ./prometheus.yml:/opt/bitnami/prometheus/conf/prometheus.yml
      - ./prometheus-data:/opt/bitnami/prometheus/data
```

> 注: 本地存储需要赋予用户 1001 读取文件夹的权限

```bash
mkdir prometheus-data
chown 1001:1001 prometheus-data
```

### 监控自身(测试)

- 编写配置文件

```yaml
global:
  scrape_interval:     15s # 默认情况下，每 15 秒提取一次数据

  # 在与外部系统（联邦集群、远程存储、报警系统）通信时，将这些标签附加到任何时间序列或警报。
  external_labels:
    monitor: 'codelab-monitor'

# 目标采集点配置
scrape_configs:
  # 作业名称将作为标签 “job=<job_name>” 添加到此配置中的读取到的数据上。
  - job_name: 'prometheus'

    # 覆盖全局默认值，并每隔 5 秒从该作业中读取数据。
    scrape_interval: 5s

    static_configs:
      - targets: ['localhost:9090']
```

- 启动服务
- 编写查询语句

```text
prometheus_target_interval_length_seconds
```

- 执行查询进行测试

> 注：此处后续内容可参照 [官方文档](https://prometheus.io/docs/prometheus/latest/getting_started/)
