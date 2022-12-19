---
title: Git 常见问题
date: 2022-08-05 20:41:32
tags:
- "Windows Terminal"
- "Git Bash"
id: terminal
no_word_count: true
no_toc: false
categories: Windows
---

## Git Bash 中文乱码的问题

### 简介

在运行 Git Bash 的时候会出现命令行中无法正常显示中文，但是在文件部分却可以正常显示的问题。此问题可以通过如下方法修复：

1. 打开 Git Bash 
2. 右键 `Bash` 窗口中的任意位置，选择 Options 选项
3. 在 Text 栏中选择 Locale 选项为 `zh_CN` 将 Character set 选项设定为 `GBK` 即可。

## 配置 git 代理

```bash
git config --global http.proxy http://host:port
git config --global https.proxy http://host:port
```

## 取消 git 代理

```bash
git config --global --unset http.proxy
git config --global --unset https.proxy
```
