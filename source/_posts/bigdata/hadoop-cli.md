---
title: Hadoop CLI
date: 2020-06-14 22:26:13
tags:
- "Hadoop"
- "CDH"
id: hadoop-cli
no_word_count: true
no_toc: false
categories: 大数据
---

## CDH 与 HDP 的超级权限获取

在 HDP 集群上可以直接使用如下命令切换至 HDFS 用户，然后就可以为所欲为了
```bash
su hdfs
```

但是在 CDH 集群上可以通过配置环境变量的方式来切换 HDFS 用户
```bash
export HADOOP_USER_NAME=hdfs
```

又或者可以通过命令前置的环境变量方式来进行使用
```bash
HADOOP_USER_NAME=hdfs hdfs dfs -ls /
```

## HDFS 命令行梳理

列出目录
```bash
hdfs dfs -ls < path >
```

创建多层文件夹
```bash
hdfs dfs -mkdir -p < path >
```

从本地目录上传
```bash
hdfs dfs -put < local_path > < path >
```

从远程地址下载
```bash
hdfs dfs -get < path > < local_path >
```

修改文件夹权限
```bash
hdfs dfs -chmod -R ??? < path >
```

统计文件夹大小
```bash
hdfs dfs -du -h < path >
```

删除文件夹
```bash
hdfs dfs -rm -r -f -skipTrash < path >
```

重新整理集群之间的文件分布
```bash
hdfs balancer
```

多集群之间的文件拷贝
```bash
hadoop distcp hdfs://<from_host>:<from_port>/<from_path> hdfs://<to_host>:<to_port>/<to_path>
```

重新生成 HA 配置项
```bash
hdfs zkfc -formatZK -force -nonInteractive
```

查看 Namenode 状态
```bash
hdfs haadmin -getServiceState <service_name>
```

> 注：`service_name` 在配置项 `dfs.ha.namenodes.<area>`配置项中查看。

强制启用 Namenode
```bash
hdfs haadmin -transitionToActive --forcemanual <service_name>
```

## Yarn 命令行梳理

列出目前的任务列表
```bash
yarn application -list
```

根据任务状态筛选任务
```bash
yarn application -list -appStates < Status >
```

常用的任务状态分为以下几种

|任务|说明|
|:---:|:---:|
|ACCEPTED|队列中|
|RUNNING|正在运行|
|FAILED|运行失败|

查看任务状态
```bash
yarn application -status < Application ID >
```

终止任务
```bash
yarn application -kill < Application ID >
```
