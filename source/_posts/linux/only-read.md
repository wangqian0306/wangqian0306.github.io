---
title: Linux 系统单个磁盘变为只读问题
date: 2021-08-16 23:52:33
tags:
- "Linux"
id: only-read
no_word_count: true
no_toc: false
categories: Linux
---

## Linux 系统单个磁盘变为只读问题

### 简介

访问文件系统中的特定目录之后无法创建和写入文件，结合 `df -TH` 命令进行检查发现问题出现在对应磁盘。

### 解决方法

#### 重启

怀疑是挂载与操作系统相关问题，尝试使用重启的方式解决问题。

在重启过后问题依旧存在。

#### 修复磁盘

使用此种方式完成了修复

- 强制卸载磁盘

```bash
umount -vl <mount_path>
```

- 修复磁盘

```bash
fsck -t <type> -y /dev/<disk_name>
```

> 注：type 字段指的是磁盘格式，例如 ext4。且此命令的执行时间会比较长。

- 重新挂载磁盘

```bash
mount /dev/<disk_name> <mount_path>
```
