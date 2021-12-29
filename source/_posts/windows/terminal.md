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

1. 在 Windows Terminal 中选择设置，在 `profiles` 配置项中的 `list`中新增如下内容

```json
{
    // guid 需要单独生成，参见注释
    "guid": "{5b47b1d0-ea4d-4997-be5e-4c9224c561a1}",
    "name": "Git Bash",
    // commandline 需要填写 Git Bash 的启动路径
    "commandline": "C:\\Program Files\\Git\\bin\\bash.exe",
    "icon": "%SystemDrive%\\Program Files\\Git\\mingw64\\share\\git\\git-for-windows.ico",
    // startingDirectory 为 Git Bash 的默认启动路径
    "startingDirectory": "~",
    "fontFace": "YaHei Consolas Hybrid",
    "hidden": false
}
```

> 注：guid 生成[链接](http://www.ofmonkey.com/transfer/guid)

2. (可选)配置 Git Bash 为 Windows Terminal 默认启动项，修改配置文件中的 defaultProfile 为 Git Bash 的 guid 即可

3. 配置环境变量(解决Git Bash 中文显示的问题)

```text
LANG="zh_CN"
OUTPUT_CHARSET="utf-8"
```

4. 重新启动 Windows Terminal 即可
