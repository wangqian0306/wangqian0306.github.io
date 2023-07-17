---
title: screen 命令
date: 2023-07-17 21:57:04
tags:
- "Linux"
id: screen
no_word_count: true
no_toc: false
categories: Linux
---

## screen 命令

### 简介

Linux 中的 screen 命令提供了保存会话(session)的功能，可以让一个用户开启多个不同的会话并保存其状态。

### 使用方式

- 安装命令

```bash
yum install screen
```

- 查看终端列表

```bash
screen -ls
```

- 创建或进入终端

```bash
screen -R <name>
```

- 保存并退出终端

`ctrl` + `A` 然后按 `D`

> 注：在命令行中记得使用英文输入法。

- 删除终端

```bash
screen -R <pid/name> -X quit
```

或进入终端使用 `exit` 命令


### 参考资料

[终端命令神器--Screen命令详解](https://zhuanlan.zhihu.com/p/405968623?utm_id=0)

[screen command in Linux with Examples](https://www.geeksforgeeks.org/screen-command-in-linux-with-examples/)
