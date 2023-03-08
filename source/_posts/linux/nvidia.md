---
title: NVIDIA 相关配置
date: 2023-03-08 23:52:33
tags:
- "NVIDIA"
- "Linux"
id: nvidia
no_word_count: true
no_toc: false
categories: Linux
---

## NVIDIA 相关配置

### 驱动安装

#### 界面方式

在 Ubuntu 官方软件中寻找 `Additional Drivers` 软件，然后在软件中选择对应驱动即可，然后需要重启系统。

使用如下命令可以进行驱动配置

```bash
sudo nvidia-settings
```

#### 命令行方式

使用如下命令查看驱动版本号:

```bash
ubuntu-drivers devices
```

然后即可安装

```bash
sudo apt-get install nvidia-driver-<version>
```

待安装完成后重启即可

#### 验证

使用如下命令可以显示驱动程序及显卡信息：

```bash
nvidia-smi
```

### 容器直通



### 参考资料

[如何在 Ubuntu 20.04 安装 Nvidia 驱动程序](https://www.myfreax.com/how-to-nvidia-drivers-on-ubuntu-20-04/)

[NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)

[BinaryDriverHowto/Nvidia](https://help.ubuntu.com/community/BinaryDriverHowto/Nvidia#Troubleshooting)