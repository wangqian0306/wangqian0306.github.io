---
title: 网络爬虫
date: 2022-09-05 21:41:32
tags: "随笔"
id: spider
no_word_count: true
no_toc: false
---

## 网络爬虫

### 简介

爬虫是一种按照一定的规则，自动地抓取万维网信息的程序或者脚本。

### 管理平台

目前市面上有一些管理平台可以方便的管理爬虫：

#### crawlab

可以通过如下 `docker-compose` 快速启动社区单节点版本：

```yaml
version: '3.3'
services:
  master:
    image: crawlabteam/crawlab:0.6.0
    container_name: crawlab_master
    environment:
      CRAWLAB_NODE_MASTER: "Y"
      CRAWLAB_MONGO_HOST: "mongo"
    ports:
      - "8080:8080"
    depends_on:
      - mongo
  mongo:
    image: mongo:4.2
```

> 注：由于最新版无法正常登录，所以采用了最新 release 版。默认账户和密码都是 `admin`

### 参考资料

[crawlab](https://docs.crawlab.cn/)
