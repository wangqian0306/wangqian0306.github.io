---
title: VNC
date: 2023-09-07 21:57:04
tags: "Linux"
id: vnc
no_word_count: true
no_toc: false
categories: Linux
---

## VNC

### 简介

VNC (Virtual Network Console) 为一种使用 RFB 协议的屏幕画面分享及远程操作软件。此软件借由网络，可发送键盘与鼠标的动作及即时的屏幕画面。

### 服务端

使用如下命令进行安装：

```bash
dnf install tigervnc-server
firewall-cmd --add-service=vnc-server
firewall-cmd --runtime-to-permanent
```

然后使用如下命令配置密码：

```bash
vncpasswd
```

然后编写如下链接偏好配置文件 `~/.vnc/config`：

```text
# create new
# session=(display manager you use)
# securitytypes=(security options)
# geometry=(screen resolution)
session=gnome
securitytypes=vncauth,tlsvnc
geometry=1920x1080
```

编写链接端口和远程用户 `/etc/tigervnc/vncserver.users` 

```text
# add to the end
# specify [:(display number)=(username] as comments
# display number 1 listens port 5901
# display number n + 5900 = listening port
#
# This file assigns users to specific VNC display numbers.
# The syntax is <display>=<username>. E.g.:
#
# :2=andrew
# :3=lisa
:1=fedora
:2=redhat
```

使用如下命令启动服务：

```bash
systemctl enable --now vncserver@:1 vncserver@:2
```

> 注：此处的编号既是用户，如有多个用户需要自行添加。

### 客户端

#### Windows

可以使用 [TightVNC](https://www.tightvnc.com/) 开源软件。

#### Linux

```bash
dnf -y install tigervnc
```

### 参考资料

[VNC Server](https://docs.fedoraproject.org/en-US/fedora/latest/system-administrators-guide/infrastructure-services/TigerVNC/)

[Desktop Environment : Configure VNC Server](https://www.server-world.info/en/note?os=Fedora_36&p=desktop&f=6)
