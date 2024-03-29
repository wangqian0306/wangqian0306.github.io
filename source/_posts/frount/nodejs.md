---
title: Node.js 环境准备
date: 2021-11-11 21:41:32
tags:
- "nodejs"
id: nodejs
no_word_count: true
no_toc: false
categories: 
- "前端"
---

## Node.js 环境准备

### 简介

简单的说 Node.js 就是运行在服务端的 JavaScript。Node.js 是一个基于Chrome JavaScript 运行时建立的一个平台。

### 安装

#### Windows 平台

访问 [官网](https://nodejs.org/zh-cn/download/) 下载安装包即可。

#### Linux 平台

##### CentOS 7

访问 [官网](https://nodejs.org/zh-cn/download/) 下载二进制文件，然后使用如下命令进行安装

```bash
sudo mkdir -p /usr/local/lib/nodejs
sudo tar -xJvf node-<$VERSION-$DISTRO>.tar.xz -C /usr/local/lib/nodejs 
sudo vim /etc/profile.d/nodejs.sh
```

填入如下内容：

```text
export PATH=/usr/local/lib/nodejs/node-<$VERSION-$DISTRO>/bin:$PATH
```

刷新配置

```bash
source /etc/profile.d/nodejs.sh
```

##### CentOS 8/ Fedora

查看软件源及版本：

```bash
dnf module list nodejs
```

安装：

```bash
dnf install nodejs
```

### 配置国内软件源

配置源

```bash 
npm config set registry http://registry.npm.taobao.org/
```

获取当前源的配置情况

```bash 
npm config get registry
```

### 安装 Yarn 包管理工具

```bash 
npm install -g yarn
```

### 常见问题

#### ENOENT: no such file or directory, lstat 'C:\Users\xxx\AppData\Roaming\npm'

重新安装 npm 即可：

```bash
npm install -g npm@latest
```
