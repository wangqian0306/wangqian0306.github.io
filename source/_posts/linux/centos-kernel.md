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
rpm –import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
```

> 注：此处样例引入的是 CentOS 7 

查看更新包中的内核：

```bash
yum list available –disablerepo=’*’ –enablerepo=elrepo-kernel
```

安装最新稳定版内核：

```bash
yum –enablerepo=elrepo-kernel install kernel-lt
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

### 参考资料

[How to Upgrade Linux Kernel on CentOS 7](https://www.geeksforgeeks.org/how-to-upgrade-linux-kernel-on-centos-7/)
