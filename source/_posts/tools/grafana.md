---
title: Grafana
date: 2021-10-11 23:09:32
tags:
- "Grafana"
id: grafana
no_word_count: true
no_toc: false
categories: "工具"
---

## Grafana

### 简介

Grafana 开源是开源可视化和分析软件。可以接入多种数据源，并对数据进行展示和检索。

### 部署

#### Docker

```yaml
services:
  grafana:
    image: grafana/grafana:latest
    ports:
      - 3000:3000
```

> 注：在安装时可以指定环境变量的方式附带插件 `GF_INSTALL_PLUGINS=grafana-clock-panel, grafana-simple-json-datasource`

[官方 Docker 部署说明](https://grafana.com/docs/grafana/latest/installation/docker/)

#### Kubernetes

在 Kubernetes 上可以使用 [Helm](https://grafana.com/docs/grafana/latest/setup-grafana/installation/helm/) 部署服务。

### 插件

#### 监控 CDH

- 安装 CDH 插件

![安装插件](https://i.loli.net/2021/10/12/n821BURpjIumv3H.png)

- 配置数据源

![配置数据源](https://i.loli.net/2021/10/12/R17gxEFlMmPGs8c.png)

- 填写配置信息

![配置连接信息](https://i.loli.net/2021/10/12/eGlgpPNcYZDkhw9.png)

- 进行连接测试
- 新建 panel 填入如下 SQL 进行测试 

```sql
select total_read_bytes_rate_across_disks, total_write_bytes_rate_across_disks where category = CLUSTER
```

### 参考资料

[官方文档](https://grafana.com/docs/grafana/latest/)
