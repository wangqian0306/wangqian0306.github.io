---
title: Flink
date: 2021-11-25 22:26:13
tags:
- "Flink"
- "Docker"
id: flink
no_word_count: true
no_toc: false
categories: 大数据
---

## Flink

### 简介

Apache Flink 是一个框架和分布式处理引擎，用于在无界和有界数据流上进行有状态的计算。

Flink 能在所有常见集群环境中运行，并能以内存速度为限制进行任意规模的计算。

### 运行方式

Flink 可以通过如下三种方式运行程序：

- 应用模式(Application Mode)
    - 集群生命周期和应用进行绑定，当应用执行完成才会停止集群。
    - 应用程序公用公共资源。
- 任务模式(Per-Job Mode)
    - 集群生命周期和任务周期绑定。
    - 单个任务独享所需资源。
    - 节点需要一定的启动时间，适合长时间运行的程序。
    - 资源利用率相对低。
- 会话模式(Session Mode)
    - 集群生命周期不受任务影响，只有手动关闭会话，集群才会被停止。
    - 所有任务争抢一套系统资源。
    - 集群所有节点都预先启动，无需每次启动作业都申请资源、启动节点，适合对于作业执行时间段、对任务启动时间敏感的任务。
    - 资源充分共享，资源利用率高。

所以一般情况下建议使用应用模式运行。

### 部署方式

- 独立(适合试用 Flink)
- Kubernetes
- Yarn

#### 命令行工具安装及配置

- 从官网下载对应版本的安装包，然后进行解压。
- 编辑环境变量配置文件，然后填入如下内容

```bash
vim /etc/profile.d/flink.sh
```

```bash
export PATH=<flink_path>/bin:$PATH
```

- 修改配置文件 `flink-conf.yaml`

```text
rest.bind-port: 8080-8090
rest.bind-address: 0.0.0.0
```

#### 独立部署(Docker-Compose,Session Mode)

- 编写 `docker-compose.yaml` 配置文件

```yaml
services:
  jobmanager:
    image: flink:1.14.0-scala_2.12-java11
    ports:
      - "8081:8081"
      - "6123:6123"
    command: jobmanager
    environment:
      - |
        FLINK_PROPERTIES=
        jobmanager.rpc.address: jobmanager        

  taskmanager:
    image: flink:1.14.0-scala_2.12-java11
    depends_on:
      - jobmanager
    command: taskmanager
    scale: 1
    environment:
      - |
        FLINK_PROPERTIES=
        jobmanager.rpc.address: jobmanager
        taskmanager.numberOfTaskSlots: 8
```

- 启动集群

```bash
docker-compose up -d
```

### 基础命令

- 远程执行 Jar 包

```bash
flink run --detached <jar_path>
```

- 获取正在执行的任务

```bash
flink list
```

- 创建保存点

```bash
flink savepoint <job_id> /tmp/flink-savepoints
```

- 删除保存点

```bash
flink savepoint --dispose <savepoint_path> <job_id>
```

- 终止工作

```bash
flink stop --savepointPath <savepoint_path> <job_id>
```

- 取消作业

```bash
flink cancel <job_id>
```

- 从保存点启动作业

```bash
flink run --detached --fromSavepoint <savepoint_path> <jar_path>
```