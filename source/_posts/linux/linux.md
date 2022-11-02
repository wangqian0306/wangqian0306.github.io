---
title: Linux 基础知识整理
date: 2020-04-01 21:57:04
tags: "Linux"
id: linux_dir
no_word_count: true
no_toc: false
categories: Linux
---

## 基础系统目录及说明

|地址|说明|
|:---:|:---:|
|/tmp|缓存目录|
|/opt|程序额外安装位置|
|/home|用户文件存储根目录|
|/usr|系统应用程序目录|
|/etc|系统管理和配置文件|
|/bin|系统必备的二进制可执行文件|
|/proc|虚拟文件系统目录|
|/root|系统管理员目录|
|/sbin|系统管理必备文件|
|/dev/|设备相关文件|
|/mnt|临时挂载路径|
|/boot|系统引导文件|
|/var|日志文件|

## 查看配置

|查看内容|查看命令|
|:---:|:---:|
|CPU|cat /proc/cpuinfo|
|MEM|free -m|
|DISK|fdisk -l|
|NET|ethtool xxx(网卡名)|

## sudo免密配置

```bash
sudo touch /etc/sudoers.d/admin
echo "<用户名> ALL=(root)NOPASSWD:ALL" | sudo tee /etc/sudoers.d/admin
```

## 配置 SELinux

查看目前的配置状态

```bash
getenforce
```

设置SELinux为宽容模式
```bash
setenforce 0
```

修改SELinux运行模式(配置完后需要重启系统)
```bash
vim /etc/selinux/config
```

配置文件如下
```text
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled   # change to disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted
```

## 常用文件或目录整理

|        地址         |        说明        |
|:-----------------:|:----------------:|
|  /etc/profile.d/  |   每个用户都有的环境变量    |
|     ~/.bashrc     | 用户终端(shell)的相关配置 |
|    /etc/hosts     |      host文件      |
|   /etc/exports    |      NFS配置       |
|    /var/named*    |      DNS配置       |
| /etc/chrony.conf  |      NTP配置       |
|    /etc/fstab     |      磁盘挂载配置      |
|/etc/selinux/config|    SELinux配置     |
|   /etc/*release   |    Linux 版本说明    |

## 配置 Terminal 快捷键

在 Fedora 系统上没有快捷打开 Terminal 的快捷键，需要进行如下设置：

1. 打开 `Settings` 系统设置页
2. 选择 `Keyborad` 键盘配置项
3. 点击 `Keyboard Shortcuts` 配置中的 `View and Customize Shortcuts` 选项 
4. 选择 `Custom Shortcut` 并新增自定义快捷键即可：

- Name: `Terminal`
- Command: `gnome-terminal`
- Shortcut: `Ctrl + Alt + T`