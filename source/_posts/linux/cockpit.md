---
title: Cockpit
date: 2024-01-15 21:57:04
tags: "Linux"
id: cockpit
no_word_count: true
no_toc: false
categories: Linux
---

## Cockpit

### 简介

Cockpit 是一个基于 Web 的服务器管理图形界面。

### 安装

> 注：本文以 Rocky Linux 做为样例。

```bash
sudo yum install cockpit
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --permanent --zone=public --add-service=cockpit
sudo firewall-cmd --reload
```

### 插件

Cockpit 还提供了很多 [插件](https://cockpit-project.org/applications.html) ：

#### 文件管理

```bash
git clone https://github.com/45Drives/cockpit-navigator.git
cd cockpit-navigator/
sudo make install
sudo systemctl restart cockpit.socket
```

[cockpit-navigator](https://github.com/45Drives/cockpit-navigator)

#### 用户及 NFS 与 Samba 管理

且在安装此服务的时候需要提前配置好 NFS 和 Samba 服务与网络，且将 Selinux 设置为 Permissive。

```bash
sudo yum install coreutils glibc-common hostname passwd psmisc samba-common-tools shadow-utils util-linux util-linux-user perl openssh -y
curl -LO https://github.com/45Drives/cockpit-identities/releases/download/v0.1.12/cockpit-identities_0.1.12_generic.zip
cd cockpit-identities_0.1.12_generic/
sudo make install
sudo yum install attr coreutils glibc-common nfs-utils samba-common-tools samba-winbind-clients gawk -y
curl -LO https://github.com/45Drives/cockpit-file-sharing/releases/download/v3.2.9/cockpit-file-sharing_3.2.9_generic.zip
cd cockpit-file-sharing_3.2.9_generic
sudo make install
```

> 注：在安装时出现了文件移动错误的问题 `cp: cannot stat 'system_files/*': No such file or directory`, 可以忽略。

[cockpit-identities](https://github.com/45drives/cockpit-identities)

[cockpit-file-sharing](https://github.com/45Drives/cockpit-file-sharing)

### 参考资料

[官方网站](https://cockpit-project.org/)

[Cockpit安装配置速记](https://zhile.io/2023/12/30/cockpit-configuration.html)
