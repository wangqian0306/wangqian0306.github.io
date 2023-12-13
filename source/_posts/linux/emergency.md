---
title: Emengercy Mode
date: 2023-12-13 21:57:04
tags:
- "Linux"
id: emengercy
no_word_count: true
no_toc: false
categories: Linux
---

## Emengercy Mode

### 简介

当操作系统崩溃，无法正常启动时就会进入紧急模式。

### 常见问题及解决办法

进入紧急模式之后，需要输入 root 密码进入交互式命令行。然后可以使用如下命令查看启动日志：

```bash
journalctl -xb
```

#### 磁盘故障

> 注：日志比较杂需要多翻翻，如果出现 `mount xxx` 字样则代表磁盘故障。

可以使用如下命令看到出现故障的磁盘：

```bash
df -TH
```

出现故障的磁盘会有标识类似如下样例：

```
/dev/sdx1
```

解决此问题可以通过解除挂载的方式实现：

```bash
vim /etc/fstab
```

> 注：然后使用 `#` 注释该行即可。
