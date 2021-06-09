---
title: Chocolatey 的简单使用
date: 2020-04-03 21:41:32
tags:
- "Chocolatey"
- "Windows"
id: chocolate
no_word_count: true
no_toc: false
categories: Windows
---

## 简介

Chocolatey 像是个命令行版本的windows软件包管理工具。

## 安装方式

1. 右键点击开始菜单
2. 选择 `Windows PowerShell (管理员)`
3. 输入如下命令即可安装
```bash
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

如有问题请查阅[官方安装手册](https://www.chocolatey.org/install)

## 使用方式

可以在[软件仓库](https://www.chocolatey.org/search)中寻找你需要的软件包，然后使用下面的命令来对它们进行管理。

安装软件包
```bash
choco install <软件包名>
```

升级软件包
```bash
choco upgrade <软件包名>
```

删除已安装的某个软件包
```
choco uninstall <软件包名> 
```