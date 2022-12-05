---
title: Grafana 安装
date: 2021-10-11 23:09:32
tags:
- "Grafana"
id: grafana-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Grafana 安装

### 简介

Grafana 开源是开源可视化和分析软件。它提供了将时间序列数据库 (TSDB) 并且可以将数据转换为富有洞察力的图表来构造可视化仪表盘。

### 容器化部署

```yaml
version: '3'

services:
  grafana:
    image: grafana/grafana:latest
    ports:
      - 3000:3000
```

[官方 Docker 部署说明](https://grafana.com/docs/grafana/latest/installation/docker/)

### 监控 CDH

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
