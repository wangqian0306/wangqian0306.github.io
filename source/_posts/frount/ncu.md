---
title: ncu
date: 2021-11-11 21:41:32
tags:
- "nodejs"
- "ncu"
id: ncu
no_word_count: true
no_toc: false
categories: 前端
---

## ncu

### 简介

ncu(npm-check-updates) 插件，用于更新 NPM 配置文件中的依赖软件包的版本。

### 安装方式

```bash
npm i -g npm-check-updates
```

### 使用方式

- 更新当前目录对应的软件依赖包配置文件

```bash
ncu -u
```

### 常见问题

ncu : 无法加载文件 ...ncu.ps1，因为在此系统上禁止运行脚本。有关详细信息，请参阅 https:/go.microsoft.com/fwlink/?LinkID=135170 中的 about_Execution_Policies。

在管理员 PowerShell 中输入如下命令即可：

```PowerShell
set-ExecutionPolicy RemoteSigned
```

然后输入 `Y` 确认即可 