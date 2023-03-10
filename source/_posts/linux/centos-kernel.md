---
title: CentOS 内核更新
date: 2022-12-15 21:57:04
tags:
- "Linux"
- "CentOS"
id: centos-kernel
no_word_count: true
no_toc: false
categories: Linux
---

## CentOS 内核更新

### 操作方式

查看当前内核版本：

```bash
uname -mrs
```

更新软件包：

```bash
yum update -y
```

引入内核更新相关依赖包：

```bash
rpm -import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

> 注：此处样例引入的是 CentOS 7 

查看更新包中的内核：

```bash
yum list available -disablerepo='*' -enablerepo=elrepo-kernel
```

安装最新稳定版内核：

```bash
yum -enablerepo=elrepo-kernel install kernel-lt
```

设置默认内核为最新版：

```bash
grub2-set-default 0
```

生成内核启动文件：

```bash
grub2-mkconfig -o /boot/grub2/grub.cfg
```

重启之后检查内核版本即可

### 常见问题

#### pstore: unknown compression: deflate

开机报错，但是 ssh 可以正常链接，可以使用如下命令

```bash
vim /etc/default/grub
```

参照如下内容新增 `mgag200.modeset=0` 配置:

```text
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto spectre_v2=retpoline rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet mgag200.modeset=0"
GRUB_DISABLE_RECOVERY="true"
```

重新生成 grub

```bash
grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```

设置默认内核为最新版：

```bash
grub2-set-default 0
```

### 参考资料

[How to Upgrade Linux Kernel on CentOS 7](https://www.geeksforgeeks.org/how-to-upgrade-linux-kernel-on-centos-7/)

[centos7更换内核后出现 pstore: unknown compression: deflate 问题解决](https://blog.csdn.net/q1403539144/article/details/105391441)
