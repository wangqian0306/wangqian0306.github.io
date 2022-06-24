---
title: 磁盘管理
date: 2022-06-24 20:04:13
tags: "Linux"
id: disk
no_word_count: true
no_toc: false
categories: Linux
---

## 磁盘管理

### 简介

之前一直没有记录过相关文档，所以做个补充。

### 命令

使用此命令查看挂载情况，及分区格式：

```bash
lsblk -f
```

针对未分区磁盘进行分区

```bash
fdisk <disk_name>
```

- `m` 显示命令列表
- `p` 显示磁盘分区
- `n` 新增分区
- `d` 删除分区
- `w` 写入并退出

磁盘格式化(配置文件系统)

```bash
mkfs -t <fs_type> <disk_name>
```

`fs_type` 类型如下：

- xfs
- ext4
- tmpfs

挂载磁盘

```bash
mount <disk_name> <path>
```

取消挂载磁盘

```bash
umount <disk_name> <path>
```

查看磁盘 UUID

```bash
blkid <disk_name>
```

开机自动挂载

```bash
vim /etc/fstab
```

按照如下规则填写即可：

第一列-磁盘 UUID
第二列-需要挂载的目录
第三列-文件系统格式
第四列-系统的默认参数，一般填 defaults
第五列-是否做 dump 备份，0 表示不备份，1 表示每天备份，2 表示不定期备份
第六列-是否开机检查扇区：0 表示不检查，1 表示最早检验，2 表示在1之后开始检验
