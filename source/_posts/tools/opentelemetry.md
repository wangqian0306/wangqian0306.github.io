---
title: OpenTelemetry
date: 2023-10-19 23:09:32
tags:
- "OpenTelemetry"
- "SigNoz"
id: opentelemetry
no_word_count: true
no_toc: false
categories: 
- "工具"
---

## OpenTelemetry

### 简介

OpenTelemetry 是一个可观测性框架和工具包，旨在创建和管理遥测数据，如跟踪、指标和日志。至关重要的是，OpenTelemetry与供应商和工具无关，这意味着它可以与各种可观测性后端一起使用，包括Jaeger和Prometheus等开源工具，以及商业产品。

SigNoz 是一个开源的 APM 工具，它使用 OpenTelemetry 作为数据收集器，可以将数据发送到 Jaeger、Prometheus、Elasticsearch、Kafka 等后端。

### Kubernetes 部署

可以使用 Helm 部署 OpenTelemetry Collector，具体步骤如下：

[Kubernetes 部署](https://opentelemetry.io/docs/kubernetes/helm/collector/)

### 本地测试

[SigNoz 本地测试](https://signoz.io/docs/install/docker/)

### 参考资料

[官方文档](https://opentelemetry.io/docs/)
