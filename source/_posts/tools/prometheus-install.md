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

### 本地容器化部署

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    environment:
      TZ: Asia/Shanghai
    ports:
      - 9090:9090
    volumes:
      - type: bind
        source: ./prometheus.yml
        target: /etc/prometheus/prometheus.yml
```

### 监控自身(测试)

- 编写配置文件

```yaml
global:
  scrape_interval: 15s # 默认情况下，每 15 秒提取一次数据

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
      - targets: [ 'localhost:9090' ]
```

- 启动服务
- 编写查询语句

```text
prometheus_target_interval_length_seconds
```

- 执行查询进行测试

### 监控 JMX

Prometheus 官方提供了 JMX 监控的导出工具 [JMX exporter](https://github.com/prometheus/jmx_exporter)，可以访问官网下载 jar 包：

然后即可在 prometheus.yml 文件下添加检测任务：

```yaml
  - job_name: '<name>'
    scrape_interval: <time_interval>
    static_configs:
      - targets: [ '<host>:<port>' ]
```

在项目中编写导出参数项的配置文件 `config.yaml` 内容样例如下：

```yaml
rules:
  - pattern: ".*"
```

然后通过 Java Agent 运行需要监控的程序即可：

```bash
java -javaagent:./jmx_prometheus_javaagent-0.17.0.jar=<port>:config.yaml -jar <jar_name>.jar
```

在程序启动后即可访问 `http://localhost:port` 看到监控数据。

### 监控 Mysql 

新建配置文件 `prometheus.yml` ：

```text
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'check-web'
    scrape_interval: 5s
    static_configs:
      - targets: [ 'mysqlexporter:9104' ]
```

新建 `docker-compose.yaml` ：

```yaml
services:
  mysql:
    image: mysql:latest
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: demo
    ports:
      - "3306:3306"
  mysqlexporter:
    image: prom/mysqld-exporter:latest
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=root:123456@(mysql:3306)/demo
    depends_on:
      - mysql
  prometheus:
    image: prom/prometheus:latest
    environment:
      TZ: Asia/Shanghai
    ports:
      - "9090:9090"
    volumes:
      - type: bind
        source: ./prometheus.yml
        target: /etc/prometheus/prometheus.yml
```

### 参考资料

[官方文档](https://prometheus.io/docs/prometheus/latest/getting_started/)
