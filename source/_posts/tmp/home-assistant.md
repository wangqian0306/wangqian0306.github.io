---
title: Home Assistant 折腾教程
date: 2022-11-11 21:41:32
tags: "Home Assistant"
id: home-assistant
no_word_count: true
no_toc: false
---

## Home Assistant 折腾教程

### 简介

Home Assistant 是一款开源的家庭自动化控制平台，主要针对于本地控制和隐私性。

### 安装方式

Home Assistant 可以通过四种方式进行安装：

- OS(系统级别安装)
- Container(独立容器)
- Core(使用 Python venv 手动安装)
- Supervised(在系统中安装软件，但是只支持 Debian 系统)

官方推荐的安装方式为：

- OS
- Container

不同的安装方式有不同的支持项：

|                                          功能                                          | OS  | Container | Core | Supervised |
|:------------------------------------------------------------------------------------:|:---:|:---------:|:----:|:----------:|
|             [Automations](https://www.home-assistant.io/docs/automation)             | :o: |    :o:    | :o:  |    :o:     |
|                [Dashboards](https://www.home-assistant.io/dashboards)                | :o: |    :o:    | :o:  |    :o:     |
|              [Integrations](https://www.home-assistant.io/integrations)              | :o: |    :o:    | :o:  |    :o:     |
|              [Blueprints](https://www.home-assistant.io/docs/blueprint)              | :o: |    :o:    | :o:  |    :o:     |
|                                    Uses container                                    | :o: |    :o:    | :x:  |    :o:     |
| [Supervisor](https://www.home-assistant.io/docs/glossary/#home-assistant-supervisor) | :o: |    :x:    | :x:  |    :o:     |
|                   [Add-ons](https://www.home-assistant.io/addons)                    | :o: |    :x:    | :x:  |    :o:     |
|          [Backups](https://www.home-assistant.io/common-tasks/os/#backups)           | :o: |    :o:    | :o:  |    :o:     |
|                                      Managed OS                                      | :o: |    :x:    | :x:  |    :x:     |

> 注：如果采用系统安装的方式则会遇到一些网络问题而且相对而言较为封闭，需要安装 ssh 插件之后就能链接到 Alpine 里去了 。

### 测试方式

可以使用 VMware Workstation 先在本地进行测试安装和试用：

创建虚拟机然后选择稍后安装操作系统，指定虚拟磁盘为下载解压后的虚拟磁盘并启用 UEFI 启动方式即可。

[测试安装文档](https://www.home-assistant.io/installation/windows)

### 插件

HomeAssistant 还支持很多官方插件，可以控制智能家居或者安装一些常用的服务，例如：

- Jellyfin(本地媒体库)
- Xiaomi(小米插件)
- Yeelight(易来插件)
- Matter(Matter 协议服务器)

除此之外还可以使用 HACS(Home Assistant Community Store) 社区版本的应用商店来安装新的应用：

- Xiaomi Miot Auto(小米独有规范集成插件)

### SSH

在 Home Assistant OS 中需要安装 SSH 插件才能通过 SSH 的方式链接进入 HomeAssistant。插件安装和配置流程如下：

- 进入设置
- 选择`Add-ons` 插件
- 点击右下角的 `ADD-ON STORE` 
- 检索 `SSH` 即可得到 `Advanced SSH & Web Terminal` 插件
- 点击安装即可
- 在插件导航栏中选择 `Configuration` 配置栏
- 填入如下配置信息即可

```yaml
username: hassio
password: xxxxx
authorized_keys: []
sftp: false
compatibility_mode: false
allow_agent_forwarding: false
allow_remote_port_forwarding: false
allow_tcp_forwarding: false
```

- 返回 `Info` 配置页
- 开启 `Start on boot` `Show in sidebar` 选项

> 注：如果想在 SSH 中使用 docker 命令还需关闭 `Protection mode` 选项。

### 获取 Root 权限

在安装完成 `Advanced SSH & Web Terminal` 插件后还需要如下操作才能获取到 Root 权限。

- 准备一个格式为 FAT, ext4 或 NTFS 格式的 U 盘，将其重命名为 `CONFIG` (注意大小写)
- 生成一个 ssh 公钥，并将其复制出来，写入一个换行符为 `LF` 文件编码为 `ISO 8859-1` 文件名为 `authorized_keys` 的文件将其放置在 U 盘中
- 将 U 盘从电脑上拔出，插入 Homeassistant 设备上
- 使用 `ha os import` 命令引入配置文件，之后即可使用如下命令 ssh 链接至 Homeassistant 了

```bash
ssh root@homeassistant.local -p 22222
```

### 自动化设置

#### 蓝图

[样例](https://github.com/home-assistant/core/blob/dev/homeassistant/components/automation/blueprints/motion_light.yaml)

### 自定义面板

在 GitHub 上有很多的 Home-Assistant 仪表盘配置样例，可以美化面板。

例如：

[hass-config-lajv](https://github.com/lukevink/hass-config-lajv)

教学视频地址如下：

[video](https://www.bilibili.com/video/BV1jA4y1f7av)

### 参考资料

[官方文档](https://www.home-assistant.io/)

[HACS](https://hacs.xyz/)

[配置方式](https://github.com/home-assistant/operating-system/blob/dev/Documentation/configuration.md)

[Debugging the Home Assistant Operating System](https://developers.home-assistant.io/docs/operating-system/debugging/)
