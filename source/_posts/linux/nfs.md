---
title: NFS 服务安装及配置流程
date: 2020-06-12 23:52:33
tags:
- "NFS"
- "OpenShift"
- "Linux"
id: nfs
no_word_count: true
no_toc: false
categories: Linux
---

## NFS 服务安装及配置流程

### 简介

NFS 是 Linux 的共享文件夹。

### 安装

安装 NFS 服务

```bash
yum -y install nfs-utils
```

### 远程目录配置

新增 NFS 远程目录
```bash
mkdir -p <path>
```

新增远程链接配置文件
```bash
vim /etc/exports.d/<config>.exports
```

然后可以填入下面的配置，来开放远程链接
```text
<path> *(<opreation>,<opreation1>...)
```

其中具体的配置信息参见下表

|配置项|说明|
|:---:|:---:|
|rw|可读可写|
|ro|只读|
|sync|在数据被写入持久化存储时才进行同步|
|async|数据持续同步|
|no_root_squash|当登录 NFS 主机使用共享目录的使用者是 root 时，其权限将被转换成为匿名使用者，通常它的UID与GID都会变成nobody身份。|
|root_squash|如果登录 NFS 主机使用共享目录的使用者是 root，那么对于这个共享的目录来说，它具有root的权限。|
|no_squash|访问用户先与本机用户匹配，匹配失败后再映射为匿名用户或用户组|

### 网络配置

使用如下命令进行防火墙配置

```bash
firewall-cmd --permanent --add-service=mountd
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
```

在配置完成防火墙后可以启动服务

```bash
systemctl enable rpcbind --now
systemctl enable nfs --now
```

如果新增了目录可以使用如下命令刷新服务

```bash
exportfs -a
```

### 检测

在需要连接的客户机上可以使用如下命令进行配置检测

```bash
showmount -e <host_ip>
```

如果可以看到之前配置的目录则证明安装正常。
