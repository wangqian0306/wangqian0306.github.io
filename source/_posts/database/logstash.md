---
title: Logstash 入门
date: 2020-07-01 23:09:32
tags:
- "Logstash"
- "Elastic Stack"
id: logstash
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## 简介

Logstash 是免费且开放的服务器端数据处理管道，能够从多个来源采集数据，转换数据，然后将数据发送到“存储库”中。

## 安装

在 CentOS 中可以使用如下命令配置软件源

```bash
vim /etc/yum.repos.d/elastic.repo
```

写入如下配置项即可

```text
[elastic]
name=elastic
baseurl=https://mirrors.tuna.tsinghua.edu.cn/elasticstack/yum/elastic-7.x/
enable=1
gpgcheck=0
```

在写入完成后可以使用如下命令安装 logstash 软件

```bash
yum install logstash -y
```

## 配置

软件配置在 `/etc/logstash` 目录中。

默认日志在 `/var/log/logstash` 目录中。

要使用 Logstash 还需要针对特定场景编写配置文件。

将编写好的配置文件放入 `/etc/logstash/conf.d/` 目录中，然后重启 Logstash 服务即可。

[官方文档](https://www.elastic.co/guide/en/logstash/current/index.html)

> 注：具体配置文件参见`配置样例及说明`部分。

## 使用方式

### 启动服务

```bash
systemctl start logstash
```

### 关闭服务

```bash
systemctl stop logstash
```

### 查看服务状态

```bash
systemctl status logstash
```

### 配置服务开机自启动

```bash
systemctl enable logstash
```

### 关闭服务开机自启

```bash
systemctl disable logstash
```

## 配置样例及说明

### 读取 Kafka 将数据写入 Elasticsearch

```text
input {
    kafka {
        bootstrap_servers => ["demo.wqnice.local:9092"]
        auto_commit_interval_ms => "1000"
        group_id => "demo"
        codec => "json"
        auto_offset_reset => "latest"
        consumer_threads => 5
        decorate_events => true
        topics => ["demo"]
        type => "demo"
    }
}
output {
    if[type] == "demo" {
        elasticsearch {
            hosts => ["demo.wqnice.prod:9200"]
            index => "demo-%{+YYYY.MM.dd}"
            manage_template => true
            codec => "json"
        }
    }
}
```

### 从 Elasticsearch 迁移至 Elasticsearch

```text
input {
  elasticsearch {
    hosts => "demo.wqnice.local"
    index => "mydata-*"
    query => '{ "query": { "query_string": { "query": "*" } } }'
    size => 500
    scroll => "5m"
    docinfo => true
  }
}
output {
  elasticsearch {
    hosts => "demo.wqnice.prod"
    index => "%{[@metadata][_index]}"
    document_type => "%{[@metadata][_type]}"
    document_id => "%{[@metadata][_id]}"
  }
}
```
