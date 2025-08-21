---
title: Airflow 安装
date: 2021-08-02 23:09:32
tags:
- "Airflow"
- "Python"
id: airflow-install
no_word_count: true
no_toc: false
categories: "工具"
---

## Airflow 入门

### 简介

Airflow 是一款 Python 编写的工作流控制软件。它使用 DAG(有向无环图) 的方式将不同的任务组织起来，按照编码顺序进行执行。

### 容器化部署

使用 curl 命令拉取启动脚本

```bash
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.1.2/docker-compose.yaml'
```

创建 DAG 脚本路径

```bash
mkdir ./dags ./logs ./plugins
echo -e "AIRFLOW_UID=$(id -u)\nAIRFLOW_GID=0" > .env
```

系统初始化

```bash
docker-compose up airflow-init
```

启动容器

```bash
docker-compose up -d 
```

检查容器运行情况

```bash
docker-compose ps
```

登录网页

```text
http://localhost:8080
```

> 注：`airflow` 同时作为账号和密码

### 实体服务安装

```bash
export AIRFLOW_HOME=~/airflow

pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# 初始化数据库
airflow db init

airflow users create \
    --username admin \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email spiderman@superhero.org

# 开启服务
airflow webserver --port 8080 --deamon

# 开启执行器
airflow scheduler --daemon

# 关闭服务
airflow scheduler --daemon stop
airflow webserver --daemon stop
```

### 参考资料

[官方文档](https://airflow.apache.org/docs/apache-airflow/stable/index.html)
