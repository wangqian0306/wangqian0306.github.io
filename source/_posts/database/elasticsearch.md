---
title: Elasticsearch 入门
date: 2020-07-04 23:09:32
tags:
- "Elasticsearch"
- "Elastic Stack"
id: elasticsearch
no_word_count: true
no_toc: false
categories: "Elastic Stack"
---

## 简介

Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎。

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

在写入完成后可以使用如下命令安装软件

```bash
yum install elasticsearch -y
```

## 配置

软件配置在 `/etc/elasticsearch` 目录中。

默认日志在 `/var/log/elasticsearch` 目录中。

## 常见问题

### 索引不可写入

使用如下方式修改配置即可

`POST`: `http://<host>:<port>/_settings`

```
{
  "index": {
    "blocks": {
      "read_only_allow_delete": "false"
    }
  }
}
```

> 注：若修改之后不生效请检查磁盘剩余空间。
