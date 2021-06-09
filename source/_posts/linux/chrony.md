---
title: Chrony 入门
date: 2020-12-28 21:57:04
tags: "Linux"
id: chrony
no_word_count: true
no_toc: false
categories: Linux
---

## Chrony 服务安装及配置流程

### 简介

Chrony 是一个时钟同步程序。

### 软件安装和配置

#### 服务端

- 软件安装

```bash
yum -y install chrony
```

- 服务配置

```bash
vim /etc/chrony.conf
```

可以按照如下样例进行配置

```text
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

driftfile /var/lib/chrony/drift

makestep 1.0 3

rtcsync

allow <area>

logdir /var/log/chrony
```

> 注：此处的 area 需要调整为目标网段，例如: 192.168.1.0/24。

- 启动服务并配置开机启动

```bash
systemctl enable chronyd
systemctl restart chronyd
```

- 配置服务端防火墙

```bash
firewall-cmd --permanent --add-service=ntp
firewall-cmd --reload
```

- 手动刷新时间

```bash
chronyc sources
```

> 注：此命令的结果列表即是目标服务器列表，如发现问题请及时修改。

#### 客户端

- 软件安装

```bash
yum -y install chrony
```

- 配置同步目标服务器

```bash
vim /etc/chrony.conf
```

然后填入如下内容

```text
server <ip> iburst
```

> 注：此处的 IP 需要填写之前配置服务端的 IP 地址。

- 启动服务并配置开机启动

```bash
systemctl enable chronyd
systemctl restart chronyd
```

- 手动刷新时间

```bash
chronyc sources
```

> 注：此命令的结果列表即是目标服务器列表，如发现问题请及时修改。

#### 测试

在服务端和客户端都可以使用如下命令确定服务运行情况：

- 检查服务状态

```bash
timedatectl
```

如果发现下面两项内容则证明服务正常:

```text
NTP enabled: yes
NTP synchronized: yes
```
