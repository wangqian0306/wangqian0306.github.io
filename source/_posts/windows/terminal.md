---
title: Windows Terminal 集成 Git Bash
date: 2020-04-04 20:41:32
tags:
- "Windows Terminal"
- "Git Bash"
id: terminal
no_word_count: true
no_toc: false
categories: Windows
---

## 软件安装

- Windows Terminal 可以在 Microsoft Store 安装
- Git 可以在官网或者使用 Chocolatey 安装

## 软件配置

### 新增默认配置项方式

Windows Terminal 经过一段时间的更新目前可以完成使用 UI 配置 GitBash, 具体流程如下：

1. 打开 Windows Terminal 设置
2. 在配置文件一栏，选择添加新的配置文件
3. 然后即可自行添加如下配置：

- 名称: `Git Bash`
- 命令行：`C:\\Program Files\Git\bin\bash.exe`
- 启动目录：`~`
- 图标：`%SystemDrive%\\Program Files\\Git\\mingw64\\share\\git\\git-for-windows.ico`

4. 配置环境变量(解决Git Bash 中文显示的问题)

```text
LANG="zh_CN"
OUTPUT_CHARSET="utf-8"
```

5. 重新启动 Windows Terminal 即可

### 无法执行自定义脚本

以管理员权限运行如下指令即可

```bash
set-executionpolicy remotesigned
```