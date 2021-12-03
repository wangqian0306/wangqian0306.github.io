---
title: Superset 安装
date: 2021-12-03 23:09:32
tags:
- "Superset"
- "Python"
id: superset-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Superset 安装

### 简介

Apache Superset 是一个现代的、企业就绪的商业智能 Web 应用程序。它快速、轻量、直观，并且可配置，任何用户都可以轻松的探索和可视化他们的数据。对于简单的饼图到高度详细的 deck.gl 地理空间图表都有良好的支持。

> 注：类似于 Grafana。

### 安装

#### Docker 安装

```bash
git clone https://github.com/apache/superset.git
cd superset
docker-compose -f docker-compose-non-dev.yml up -d
```

### 使用步骤

- 新建数据源(链接到数据库)
- 新建数据集(链接到数据表)
- 新建仪表板
- 新建图像

> 注：默认的检索时间为 60 秒，若 60 秒内还没能完成检索则图像无法正常展示。
