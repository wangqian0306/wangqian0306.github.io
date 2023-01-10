---
title: SDKMAN
date: 2020-12-01 21:57:04
tags:
- "Linux"
id: sdk
no_word_count: true
no_toc: false
categories: Linux
---

## SDKMAN

### 简介

SDKMAN 是一款在大多数基于 Unix 的系统上管理多个并行版本软件开发工具包的软件。它提供了命令行工具和 API，用于安装、切换、删除和列出候选项。

### 安装方式

首先需要确保以下依赖已经正确安装：

- unzip
- zip
- curl
- sed

然后可以使用如下命令安装：

```bash
curl -s "https://get.sdkman.io" | bash
```

如果需要采用不同的 sdk 可以使用如下命令：

查看 java 版本：

```bash
sdk list java
```

安装 java：

```bash
sdk install java 22.3.r17-nik
```

使用此版本 java：

```bash
sdk default java 22.3.r17-nik
```

### 参考资料

[官方文档](https://sdkman.io/usage)