---
title: Node Version Manager
date: 2023-08-01 21:41:32
tags:
- "nodejs"
id: nvm
no_word_count: true
no_toc: false
categories: 前端
---

## Node Version Manager

### 简介

Node Version Manager(NVM) 是一个管理 Node 版本的工具。

### 安装方式

#### Windows 

访问 [https://github.com/coreybutler/nvm-windows/releases](https://github.com/coreybutler/nvm-windows/releases) 获取最新的 exe 安装包，双击安装即可。

#### Linux 

使用如下命令安装软件：

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/<version>/install.sh | bash
source ~/.bashrc
```

> 注：此处需要提供具体的安装版本，详情参见官方项目。

### 基本使用

- 列出 node 版本

```bash
nvm ls-remote
```

- 安装最新版本

```bash
nvm install node
```

- 安装对应版本

```bash
nvm install <version>
```

- 查看当前版本列表

```bash
nvm ls
```

- 切换版本

```bash
nvm use <version>
```

### 参考资料

[官方项目](https://github.com/nvm-sh/nvm)

[Windows 端官方项目](https://github.com/coreybutler/nvm-windows)
