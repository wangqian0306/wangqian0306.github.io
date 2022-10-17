---
title: CDH 集群设备 Hostname 修改
date: 2020-12-04 22:26:13
tags: "CDH"
id: cdh-switch-host
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 集群设备 Hostname 修改

### 关闭集群

- 在页面中正常关闭集群和 Cloudera Management Service

- 关闭 `cloudera-scm-agent` 服务

```bash
systemctl stop cloudera-scm-agent
```

- 关闭 `cloudera-scm-server` 服务

```bash
systemctl stop cloudera-scm-server
```

### 修改 hostname

- 修改配置项

```bash
vim /etc/sysconfig/network
```

```text
HOSTNAME=<hostname>
```

- 全局配置

```bash
hostnamectl set-hostname <hostname>
```

### 修改数据库

登录 SCM 数据库，然后修改如下表

- HOSTS
- HOSTS_AUD

将其中的域名全部修改为最新值。

### 启动集群

```bash
systemctl start cloudera-scm-server
systemctl start cloudera-scm-agent
```

### 重新部署配置并启动集群

在集群配置中需要注意含有数据库的配置项，如果数据库主机 hostname 变化则可能造成集群启动异常。

在 CDH 集群中需要数据库进行持久化存储的服务如下：

- Cloudera Manager Server
- Activity Monitor
- Reports Manager
- Hue
- Hive Metastore Server
- Sentry Server
- Cloudera Navigator Audit Server
- Cloudera Navigator Metadata Server
- Oozie

### 常见问题

#### Hadoop Failover Controller 启动异常

- 由于 HDFS HA 是通过 ZooKeeper 来实现的所以可以通过如下命令进行重置

```bash
hdfs zkfc -formatZK -force -nonInteractive
```
