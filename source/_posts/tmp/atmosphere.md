---
title: 大气层折腾教程
date: 2022-08-08 22:26:13
tags:
- "Atmosphere"
id: atmosphere
no_word_count: true
no_toc: false
---

## 大气层折腾教程

### 简介

大气层只是一个 Switch 的固件，还需要配合 hekate(bootloader) 和相关 Patch 包，才能代替 SX OS。

而为了管理这些软件和依赖的就产生了一堆的整合包，例如 [DeepSea](https://github.com/Team-Neptune/DeepSea)

### 安装软件

除了复制文件到内存卡上之外还可以通过 NS-USBloader 软件配合大气层携带的安装软件使用 USB 线的方式进行软件安装。安装软件可以选择很久没有更新的 awoo 或 DBI 等。

> 注：在安装软件时，需要保持按住 `R` 键打开任意一款游戏，然后等待弹出系统软件列表然后选择安装软件进行安装即可。

### 系统更新

在安装完成大气层之后，可以使用 DayBreak 软件升级虚拟系统版本。

> 注：系统版本与大气层版本直接相关。大气层版本决定了最高的系统版本，如需升级系统则首先需要升级大气层，建议采用整合包完成。

### 常见问题

#### 报错 010041544d530000

此问题是由于默认分区方式采用了 `exFAT` 而导致的系统异常，需要下载磁盘管理工具将内存卡格式化为 `FAT 32`(族大小为 64k) 即可。

> 注：这样一来单个文件无法超过 4G 但可以通过其他方式安装软件。

### 参考资料

[参考文档](https://github.com/laila509/hekate_ipl)

[Atmosphere](https://github.com/Atmosphere-NX/Atmosphere)

[hekate](https://github.com/CTCaer/hekate)

[NS-USBloader](https://github.com/developersu/ns-usbloader)

[DeepSea 整合包](https://github.com/Team-Neptune/DeepSea)
