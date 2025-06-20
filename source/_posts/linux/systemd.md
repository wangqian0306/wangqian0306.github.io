---
title: systemd 
date: 2025-06-17 23:52:33
tags:
- "Linux"
id: systemd
no_word_count: true
no_toc: false
categories: Linux
---

## systemd

### 简介

systemd 软件套件作为 Linux 作系统的系统和服务管理器，提供用于控制、报告和系统初始化的工具和服务。主要负责如下功能：

- 在启动期间并行启动系统服务
- 按需激活守护程序
- 基于依赖关系的服务控制逻辑

从管理内容上则主要面向以下对象：

- **服务**（.service）
- **设备**（.device）
- **挂载点**（.mount）
- **目标**（.target）
- **定时器**（.timer）
- 套接字（.socket）
- 自动挂载点（.automount）
- 交换分区（.swap）
- 路径（.path）

配置文件通常位于如下地址

|目录|描述|
|:---:|:---:|
| `/usr/lib/systemd/system/` | 与安装的 RPM 软件包一起分发的 `systemd` 单元文件。|
| `/run/systemd/system/` | 在运行时创建的 `systemd` 单元文件。该目录优先于安装了的服务单元文件的目录。|
| `/etc/systemd/system/` | 使用 `systemctl enable` 命令创建的 `systemd` 单元文件，以及添加的用于扩展服务的单元文件。这个目录优先于带有运行时单元文件的目录。|

> 注：优先级由上到下从低到高。

### systemtcl 命令

- 列出系统服务

```bash
systemctl list-units --type service
```

- 查看服务状态

```bash
systemctl status <name>
```

- 查看服务是否开机启动

```bash
systemctl is-enabled <name>
```

- 查看服务前置依赖

```bash
systemctl list-dependencies --before <name>
```

- 查看服务后置依赖

```bash
systemctl list-dependencies --after <name>
```

- 启动服务

```bash
systemctl start <name>
```

- 关闭服务

```bash
systemctl stop <name>
```

- 开机启动服务

```bash
systemctl enable <name>
```

- 关闭开机启动服务

```bash
systemctl disable <name>
```

- 配置开机启动且现在也启动

```bash
systemctl enable <name> --now
```

- 重新启动服务

```bash
systemctl restart <name>
```

### 配置文件

#### .service 配置文件

样例文件如下：

```text
[Unit]
Description=Demo service
After=network.target
Requires=docker.service

[Service]
RemainAfterExit=true
WorkingDirectory=/home/xxx/xxx
ExecStart=/bin/bash -c "/usr/bin/docker-compose down && /usr/bin/docker-compose up -d"
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

Type 部分可选参数如下：

|Type|功能|
|:---:|:---:|
|simple|服务主进程前台运行(默认)|
|exec|Systemd v250+ 的改进型 simple|
|forking|服务会自行 fork 到后台|
|oneshot|一次性命令|
|dbus|D-Bus 服务|
|notify|服务自己发送启动完成通知|
|notify-reload|类似notify但增强重载|
|idle|延迟低优先级版本的 simple|

### 参考资料

[管理 systemd](https://docs.redhat.com/zh-cn/documentation/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/managing-systemd_configuring-basic-system-settings#unit-files-locations_managing-systemd)

[systemd.unit — Unit configuration](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html)

[systemd.service — Service unit configuration](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
