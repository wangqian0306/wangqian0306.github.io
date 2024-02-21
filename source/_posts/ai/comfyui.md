---
title: ComfyUI
date: 2024-02-20 21:41:32
tags: 
- "Python"
- "AI"
id: comfyui
no_word_count: true
no_toc: false
---

## ComfyUI

### 简介

Comfy 是一款 stable diffusion 的 GUI 和后端。

### 安装

> 注：建议使用带 GPU 的设备，本文以 Ubuntu 20.04 系统 CUDA 12.2 Python 3.10 做为样例。

使用如下命令进行安装：

```bash
sudo apt-get install nvidia-cudnn -y
pip3 install torch torchvision torchaudio
git clone https://github.com/comfyanonymous/ComfyUI.git
pip3 install -r requirements.txt
```

在运行前需要先获取到 [sdxl 模型](https://huggingface.co/stabilityai/sdxl-turbo/tree/main)

下载后将其放置在 `models/checkpoints` 目录。

然后需要获取 [sdxl-vae 模型](https://huggingface.co/stabilityai/sdxl-vae/tree/main)

下载后将其放置在 `models/vae` 目录。

之后即可使用如下命令开启服务：

```bash
python3 main.py --listen 0.0.0.0
```

点击 `Queue Prompt` 即可触发一次绘制。

点击 `View Queue` 即可查看任务清单。

### 参考资料

[官方项目](https://github.com/comfyanonymous/ComfyUI)

[客制化模型下载](https://civitai.com/models)
