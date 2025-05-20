---
title: digital-signage
date: 2024-11-13 22:26:13
tags:
- "digital-signage"
id: digital-signage
no_word_count: true
no_toc: false
---

## Digital Signage

### 简介

数字标牌项目可以用来做大屏展示。

### 前置处理

如果有多块屏幕需要统一处理时，可以将其进行融合，来最大化展示窗口。具体方案如下：

|平台|Windows 推荐方式|	Linux 推荐方式|
|:---:|:---:|:---:|
|Intel|Intel 控制中心扩展|xrandr 手动合并|
|NVIDIA|Mosaic 或 Surround|xorg.conf + nvidia-settings|
|AMD|Eyefinity|xrandr（有限支持）|

#### Intel

##### Windows

操作方法：

1. 安装最新版 Intel 显卡驱动：[Intel Drivers](https://www.intel.com/content/www/us/en/support/products/80939/graphics.html)
2. 进入 Intel Graphics Command Center：
    - 选择【显示】>【多显示器】
    - 拖动显示器到合并排列
    - 选择“扩展”模式
3. 保存设置后，多块屏幕将合并成一个逻辑桌面

[官方手册](https://www.intel.cn/content/www/cn/zh/support/articles/000092856/graphics.html)

##### Linux 

使用 xrandr 命令：

```bash
xrandr --output HDMI1 --mode 1920x1080 --output eDP1 --mode 1920x1080 --right-of HDMI1
```

#### Nvidia 

##### Windows

操作方法：

- 安装 NVIDIA 官方驱动：[NVIDIA Drivers](https://www.nvidia.com/en-us/drivers/)
- 右键桌面打开 NVIDIA 控制面板
- 寻找【Mosaic 模式】
- 添加显示器，选择布局
- 启用 Mosaic 模式并保存

> 注：Mosaic 需 Quadro / RTX A 系列显卡，GeForce 通常不支持正式 Mosaic，但可使用 Surround 替代

[NVIDIA Mosaic 官方文档](https://www.nvidia.com/en-us/design-visualization/solutions/nvidia-mosaic-technology/)

[NVIDIA Surround](https://www.nvidia.com/en-us/geforce/technologies/surround/)

##### Linux 

操作方法：

1. 安装 NVIDIA 官方驱动
2. 编辑 `/etc/X11/xorg.conf`，添加以下内容：

```text
Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Device0"
    Monitor "Monitor0"
    Option "MetaModes" "DP-0: 1920x1080 +0+0, DP-1: 1920x1080 +1920+0"
EndSection
```

3. 重启

#### AMD

略

### Anthias

#### 部署样例

[参考文件](https://github.com/Screenly/Anthias/blob/master/docker-compose.yml.tmpl)

> 注：在 x86 系统中部署时遇到了 viewer 卡住没能正常启动的问题，暂时没有使用树莓派测试。

#### 参考资料

[Anthias](https://anthias.screenly.io/)

### Xibo

#### 部署样例

[参考项目](https://github.com/xibosignage/xibo-docker)

[客户端](https://github.com/xibosignage/xibo-dotnetclient)

> 注：在链接时不要使用代码方式，输入在配置中看到的 CMS Secret Key 点击链接后在 Display 页面选择 Authorize 即可，进入界面后按 i 即可得到相关日志。之后的使用可以参考使用文档。

#### 参考资料

[官方网站](https://xibosignage.com/open-source)
