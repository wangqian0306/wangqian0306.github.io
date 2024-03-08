---
title: 重构 grub 并重装内核
date: 2024-03-08 20:04:13
tags: "Linux"
id: grubfix
no_word_count: true
no_toc: false
categories: Linux
---

## 重构 grub 并重装内核

### 简介

在导出阿里云虚拟机并将其转储在虚拟机平台上时遇到了 `dracut-initqueue timeout could not boot` 问题，经过与售后工程师的交流整理出了如下解决方案。

### 解决方案

1. 进入虚拟机 grub 模式或阿里云 ECS，使用如下命令检查系统版本，之后关闭虚拟机电源。

```bash
cat /etc/centos-release
```

> 注：建议小版本也要记录。

2. 访问 [CentOS Vault Mirror](https://vault.centos.org/) 下载历史版本的 DVD 版本 iso 镜像。

> 注：目录样例如下 `https://vault.centos.org/7.3.1611/isos/x86_64/CentOS-7-x86_64-DVD-1611.iso`

3. 进入虚拟机设置页面，挂载光驱并指定刚刚下载的镜像文件。
4. 进入虚拟机 BIOS 或 UEFI 指定将光驱的启动顺序移动至磁盘前。
5. 开启虚拟机，选择 `Troubleshooting` -> `Rescue a CentOS Linux system` -> `1) Continue` 。

> 注：进入交互式命令行后按 `1` 即可。

6. 挂载系统镜像和光盘并暂时移除数据盘。

输入如下命令进入 bash 并暂时移除数据盘：

```bash
chroot /mnt/sysimage
vim /etc/fstab
```

暂时把文件中 `/dev` 目录中的内容全部注释。

使用 `lsblk` 命令检查并挂载光盘：

```bash
lsblk
mount /dev/sr0 /mnt
lsblk
```

> 注：`NAME: sr0 TYPE: rom RM:1` 的是光盘，注意在挂载时会提示为只读模式。

7. 删除并重新安装内核与 boot 分区。

```bash
rm -rf /boot/*
ls -l /boot/
rpm -aq kernel*
yum -y remove kernel*
cd /mnt/Packages
yum -y install ./kernel*
cd /
rpm -aq kernel*
```

可以检查下两次内核是否有差异，然后重新构建内核映像即可：

```bash
dracut -f
ls -l /boot
```

若 boot 分区能展示内容则证明操作正常。

8. 更新 grub

```bash
grub2-install /dev/sda
mkdir /boot/grub2
grub2-mkconfig -o /boot/grub2/grub.cfg
```

之后可以检查启动配置中的内核

```bash
cat /boot/grub2/grub.cfg | grep menuentry
```

若 `menuentry` 和 `$menuentry_id_option` 中的子版本对应即证明操作正常。

9. 使用 `exit` 命令退出至图形化界面，选择 `Troubleshooting` -> `Boot from local drive` 进入系统即可正常启动。

10. 进入虚拟机设置中，卸载光驱。
