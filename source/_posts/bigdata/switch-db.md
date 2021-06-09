---
title: CDH 集群修改元数据库
date: 2020-12-04 22:26:13
tags: "CDH"
id: cdh-switch-db
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 集群修改元数据库

CDH 集群可能存在如下数据库:

|组件|数据库|
|:---:|:---:|
|Cloudera Manager Server|scm|
|Activity Monitor|amon|
|Reports Manager|rman|
|Hue|hue|
|Hive Metastore Server|metastore|
|Sentry Server|sentry|
|Cloudera Navigator Audit Server|nav|
|Cloudera Navigator Metadata Server|navms|
|Oozie|oozie|

### Cloudera Manager Server 数据库修改

- 关闭集群大数据服务

- 关闭 `Cloudera Management Service` 服务

- 关闭服务(所有设备)

```bash
systemctl restart cloudera-scm-server
systemctl restart cloudera-scm-agent
```

- 迁移数据库

在迁移时可以使用 `Navicat Premium` 的数据传输功能，具体位置如下：

```text
工具->数据传输
```

选择需要传输的源地址和目标地址之后按照界面提示操作即可。

- 重新初始化数据库

```bash
/opt/cloudera/cm/schema/scm_prepare_database.sh -h <new_host> mysql scm mariadb <password>
```

或者可以手动编辑配置文件

```bash
vim /etc/cloudera-scm-server/db.properties
```


- 启动集群(所有设备)

```bash
systemctl start cloudera-scm-server
systemctl start cloudera-scm-agent
```

> 注：先启动 cloudera-scm-server 待页面工作正常时再启动 cloudera-scm-agent, 在观测到服务运行正常后再启动服务

- 启动服务

### 其他服务数据库修改

除了 Cloudera Manager Server 之外所有的服务都可以在页面当中进行配置,具体位置如下：

```text
Configuration -> Database Settings
```
