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

> 注: 此时可能会导致无法正常进行图像显示，建议检查一次，如有问题可以参照参考资料。

使用如下命令可以显示驱动程序及显卡信息：

```bash
nvidia-smi
```

### 容器直通

运行如下命令：

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 参考资料

[如何在 Ubuntu 20.04 安装 Nvidia 驱动程序](https://www.myfreax.com/how-to-nvidia-drivers-on-ubuntu-20-04/)

[NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)

[BinaryDriverHowto/Nvidia](https://help.ubuntu.com/community/BinaryDriverHowto/Nvidia#Troubleshooting)

[黑屏解决方案](https://askubuntu.com/questions/1129516/black-screen-at-boot-after-nvidia-driver-installation-on-ubuntu-18-04-2-lts)
