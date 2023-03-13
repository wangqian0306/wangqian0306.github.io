---
title: Linux 网络配置
date: 2020-04-02 21:37:32
tags:
- "Linux"
- "Network"
id: linux_network
no_word_count: true
no_toc: false
categories: Linux
---

## 网络基础状态检查及配置

查看网卡列表及目前的配置信息
```bash
ifconfig
```

开启/关闭某个网卡
```bash
ifconfig <网卡名> up/down
```

主机名<Hostname> 设定
```bash
hostname-ctl set-hostname <主机名>
```

## 网卡配置

### 字符模式

查看网卡列表
```bash
nmcli connection show
```

查看网卡配置信息
```bash
nmcli connection show <name>
```

修改网卡配置
```bash
nmcli connection modify <name> <property> <content>
```

重启网卡
```bash
nmcli connection down <name>; nmcli connection up <name>
```

### 图形模式

字符界面图形模式配置网络(IP地址，子网掩码，DNS等)
```bash
nmtui
```

## 防火墙配置

查看防火墙状态
```bash
systemctl status firewalld
```

关闭防火墙
```bash
systemctl stop firewalld
```

开启防火墙
```bash
systemctl start firewalld
```

开机启动防火墙
```bash
systemctl enable firewalld
```

取消开机启动防火墙
```bash
systemctl disable firewalld
```

为防火墙添加允许通过的服务(需要防火墙重新配置命令完成后才会生效)
```bash
firewall-cmd --permanent --add-service=<服务名>
```

为防火墙开启端口(需要防火墙重新配置命令完成后才会生效)
```bash
firewall-cmd --permanent --add-port=<端口名>/<协议类型>
```

> 注: 协议类型有'tcp','udp','sctp','dccp'四种

重新配置防火墙
```bash
firewall-cmd --reload
```

查看目前开放的端口
```bash
firewall-cmd --zone=public --list-ports
```

## 查看端口状态

查看目前开放的端口及对应的服务：

```bash
netstat -lnpt
```
