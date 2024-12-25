---
title: Prometheus 警报
date: 2023-01-30 23:09:32
tags:
- "Prometheus"
id: prometheus-alert
no_word_count: true
no_toc: false
categories: "工具"
---

## Prometheus 警报

### 简介

Prometheus 的警报由两部分内容构成，分别是 Prometheus 中的警报规则和聚合消息向外发送警报的 Alertmanager 服务。

### 安装与部署

> 注：本示例采用 MySQL 作为监控源，邮件作为告警方式。

编写 Prometheus 配置文件 `prometheus.yml` ：

```yaml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'check-web'
    scrape_interval: 5s
    static_configs:
      - targets: [ 'mysqlexporter:9104' ]
alerting:
  alertmanagers:
    - scheme: http
      static_configs:
        - targets: [ 'alertmanager:9093' ]
rule_files:
  - "/etc/prometheus/mysql_rule.yml"
```

编写 MySQL 监控文件 `mysql_rule.yml` ：

```yaml
groups:
  - name: mysql_group
    rules:
      - alert: MySQL_Down
        expr: mysql_up == 0
        for: 15s
        labels:
          severity: page
        annotations:
          summary: MySQL Down
```

编写 Alertmanager 配置文件 `alertmanager.yml` ：

```yaml
global:
  smtp_smarthost: '<smtp_server>'
  smtp_from: '<email_sender>'
  smtp_auth_username: '<email_user>'
  smtp_auth_password: '<email_pass>'
route:
  receiver: 'demo'
  group_by: ['alertname', 'cluster']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h
receivers:
  - name: 'demo'
    email_configs:
      - to: '<receiver_email>'
```

编写 `docker-compose.yaml` 文件：

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
    ports:
      - "9090:9090"
    volumes:
      - type: bind
        source: ./prometheus.yml
        target: /etc/prometheus/prometheus.yml
      - type: bind
        source: ./mysql_rule.yml
        target: /etc/prometheus/mysql_rule.yml
  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - type: bind
        source: ./alertmanager.yml
        target: /etc/alertmanager/alertmanager.yml
```

启动测试服务

```bash
docker-compose up -d
```

关闭 MySQL 服务

```bash
docker-compose stop mysql
```

> 注：关闭之后即可访问 prometheus 和 alertmanager 页面，查看警报相关信息。

### 参考资料

[Alertmanager 配置](https://prometheus.io/docs/alerting/latest/configuration/)

[Prometheus 配置](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
