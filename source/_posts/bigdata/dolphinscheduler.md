---
title: DolphinScheduler
date: 2022-11-14 22:43:13
tags: "DolphinScheduler"
id: dolphin-scheduler
no_word_count: true
no_toc: false
categories: 大数据
---

## DolphinScheduler

### 简介

Apache DolphinScheduler 提供了一个分布式且易于扩展的可视化工作流任务调度开源平台。适用于企业级场景。它提供了一种可视化操作任务、工作流和整个数据处理程序的解决方案。

Apache DolphinScheduler 旨在解决复杂的大数据任务依赖关系，并触发各种大数据应用的数据 OPS 编排中的关系。解决了数据研发 ETL 错综复杂的依赖关系，以及无法监控任务健康状态的问题。
DolphinScheduler 以有向无环图(DAG)流模式组装任务，可以及时监控任务的执行状态，并支持重试、指定节点恢复失败、暂停、恢复和终止任务等操作。

> 注：定时执行部分采用 Quartz 作为调度器。

### 安装及运行

#### 单机容器试用

```yaml
version: "3.8"

services:
  dolphin-scheduler-standalone-server:
    image: apache/dolphinscheduler-standalone-server:latest
    ports:
      - "12345:12345"
      - "25333:25333"
```

使用如下信息即可完成登录试用：

登录页面：[http://localhost:12345/dolphinscheduler](http://localhost:12345/dolphinscheduler)

默认用户名：admin

默认密码：dolphinscheduler123

#### 容器化部署

在使用容器化部署的时候需要下载软件包，并在软件包中进入 `apache-dolphinscheduler-"${DOLPHINSCHEDULER_VERSION}"-src/deploy/docker` 目录中并按照如下命令启动服务：

```bash
# 初始化数据库
docker-compose --profile schema up -d

# 启动所有服务
docker-compose --profile all up -d
```

> 注：如有需求可以在 env 文件和 docker-compose.yml 中自行配置 Zookeeper 和 PostgresSQL。

### 参考资料

[官方文档](https://dolphinscheduler.apache.org/en-us/docs/latest/user_doc/about/introduction.html)

[架构解析](https://www.bilibili.com/read/cv18608992)
