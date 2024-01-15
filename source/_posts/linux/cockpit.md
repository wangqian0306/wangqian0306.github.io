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

默认的组件中没有文件管理工具，需要额外安装 [插件](https://cockpit-project.org/applications.html) ：


```bash
git clone https://github.com/45Drives/cockpit-navigator.git
cd cockpit-navigator/
make install
systemctl restart cockpit.socket
```

### 参考资料

[官方网站](https://cockpit-project.org/)

[Cockpit安装配置速记](https://zhile.io/2023/12/30/cockpit-configuration.html)
