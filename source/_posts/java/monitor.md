---
title: monitor
date: 2022-09-07 21:05:12
tags:
- "JAVA"
- "Go"
- "Python"
- "Elastic Stack"
- "SkyWalking"
- "Prometheus"
id: monitor
no_word_count: true
no_toc: false
categories: JAVA
---

## 性能监控

### 简介

为了监控线上环境运行情况可以采用如下组件：

### Elastic Stack

Elastic Stack 在 8 版本之前提供了 APM Server 和 Beats 作为性能监控工具，而在 8 版本之后则采用了 Fleet Server 替代了 APM Server。目前 APM agent 可以兼容如下语言的性能指标采集：

- GO
- iOS
- JAVA
- .NET
- Node.js
- PHP
- Python
- Ruby
- RUM
- OpenTelemetry

可以使用如下新版的 Elastic Agent 收集数据：

```yaml
version: "3"
services:
  agent:
    image: docker.elastic.co/beats/elastic-agent:8.4.1
    container_name: elastic-agent
    user: root
    environment:
      - FLEET_ENROLLMENT_TOKEN=<enrollment_token>
      - FLEET_ENROLL=1
      - FLEET_URL=<server_url>
      - FLEET_SERVER_ENABLE=true
      - FLEET_SERVER_ELASTICSEARCH_HOST=<es_host>
      - FLEET_SERVER_SERVICE_TOKEN=<service_token>
      - FLEET_SERVER_POLICY=<policy>
    ports:
      - "8200:8200"
      - "8220:8220"
```

### Prometheus

Prometheus 有如下采集的方式：

- Client Library
- Exporter 

> 注：针对与 JVM 的性能都可以通过 JMX exporter 完成。

其中有一些内容是官方编写的一些是第三方编写的，在使用时需要格外注意。

### SkyWalking

SkyWalking 则依赖于 K8s，相较于以上两种来说更针对与微服务之间的数据流监控。目前提供如下语言的监控：

- Java
- Python
- NodeJS
- Nginx LUA
- Kong
- Client JavaScript
- Rust
- PHP

### 参考资料

[Elastic Stack](https://www.elastic.co/guide/en/apm/guide/current/apm-quick-start.html)

[Prometheus](https://prometheus.io/docs/instrumenting)

[SkyWalking](https://skywalking.apache.org/docs/)
