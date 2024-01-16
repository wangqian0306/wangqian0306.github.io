---
title: Samba 服务安装及配置流程
date: 2023-02-06 21:57:04
tags:
- "Linux"
- "Samba"
id: samba
no_word_count: true
no_toc: false
categories: Linux
---

## Samba 服务配置

### 简介

Samba 是种用来让 UNIX 系列的操作系统与微软 Windows 操作系统的 SMB/CIFS(Server Message Block/Common Internet File System)网络协议做链接的自由软件。

### 安装及使用

安装软件及依赖，并备份配置文件：

```bash
yum install -y samba
mv /etc/samba/smb.conf /etc/samba/smb.conf.bk
```

创建分享目录 `<path>`，编辑配置文件 `/etc/samba/smb.conf`：

```text
[global]
	workgroup = SAMBA
	security = user

	passdb backend = tdbsam

	printing = cups
	printcap name = cups
	load printers = yes
	cups options = raw
    map to guest = Bad User
    
	# Install samba-usershares package for support
	include = /etc/samba/usershares.conf

[homes]
	comment = Home Directories
	valid users = %S, %D%w%S
	browseable = No
	read only = No
	inherit acls = Yes

[printers]
	comment = All Printers
	path = /var/tmp
	printable = Yes
	create mask = 0600
	browseable = No

[print$]
	comment = Printer Drivers
	path = /var/lib/samba/drivers
	write list = @printadmin root
	force group = @printadmin
	create mask = 0664
	directory mask = 0775

[myshare]
	path=<path>            
	public=yes
	browseable=yes
	writable=yes
	create mask=0644
	directory mask=0755
```

```配置防火墙
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
```

启动服务

```bash
systemctl enable smb --now
```

### 账户配置

使用如下命令创建账户：

```bash
smbpasswd -a <username>
```

使用如下命令列出账户：

```bash
pdbedit -L
```

在 `[myshare]` 类似的配置单元中可以写入如下限制条件：

```text
valid users=<user_1>,<user_2>
write list=<user>
```

重新启动服务：

```bash
systemctl restart smb
```

### 参考资料

[Centos7下Samba服务器配置（实战）](https://cloud.tencent.com/developer/article/1720995)