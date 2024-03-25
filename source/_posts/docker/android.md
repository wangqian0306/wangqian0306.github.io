---
title: Docker-Android
date: 2024-3-25 21:41:32
tags:
- "Android"
- "Container"
id: android
no_word_count: true
no_toc: false
categories: Container
---

## Docker-Android

### 简介

Docker-Android 是一个 docker 映像，用于与 Android 相关的所有内容。可以使用 noVNC 和 adb 链接到虚拟机中，它可用于应用程序开发和测试(本机、Web 和混合应用程序)。

> 注：运行平台只能是 Ubuntu。

### 使用方式

使用如下命令监测 KVM 是否开启：

```bash
sudo apt install cpu-checker
kvm-ok
```

若输出字样如下则证明功能正常：

```text
INFO: /dev/kvm exists
KVM acceleration can be used
```

编写如下 `docker-compose.yaml` :

```yaml
version: '3.8'

services:
  android-container:
    image: budtmo/docker-android:emulator_14.0
    container_name: android-container
    ports:
      - "6080:6080"
    environment:
      - EMULATOR_DEVICE=Samsung Galaxy S10
      - WEB_VNC=true
    devices:
      - /dev/kvm
```

### 参考资料

[官方项目](https://github.com/budtmo/docker-android)

[容器清单](https://hub.docker.com/r/budtmo/docker-android/tags)

[在Docker中安装安卓11、12+Appium【web端android】](https://juejin.cn/post/7162415019332730917)
