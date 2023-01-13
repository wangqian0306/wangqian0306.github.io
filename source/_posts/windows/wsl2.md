---
title: Windows 打开 WSL2
date: 2022-04-27 20:41:32
tags:
- "wsl2"
id: terminal
no_word_count: true
no_toc: false
categories: Windows
---

## Windows 打开 WSL2

### 简介

WSL 是 windows推出的可让开发人员不需要安装虚拟机或者设置双系统启动就可以原生支持运行 GNU/Linux 的系统环境，简称 WSL 子系统。

### 开启 wsl

在管理员模式下打开 PowerShell 并输入如下命令，待命令完成后重启计算机。

```bash
wsl --install
```

### 常见问题

#### 安装失败默认回退

在重启时显示遇到问题进行回滚

> 注：经过查看 windows 日志可能是由于系统版本和激活的问题引起的，具体问题有待进一步排查。

### 参考资料

[官方文档](https://learn.microsoft.com/zh-cn/windows/wsl/install)