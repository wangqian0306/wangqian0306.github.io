---
title: 大模型
date: 2023-08-08 22:26:13
tags:
- "AI"
id: ai
no_word_count: true
no_toc: false
---

## 大模型

### 简介

大语言模型(large language model，LLM) 是一种语言模型，由具有许多参数(通常数十亿个权重或更多)的人工神经网络组成，使用自监督学习或半监督学习对大量未标记文本进行训练。

### 相关项目

#### Text generation web UI

项目地址：[Text generation web UI](https://github.com/oobabooga/text-generation-webui)

此项目可以在本地搭建一个聊天服务器，并且可以替换各种模型

### 环境准备

#### PyTorch

使用如下命令即可安装 PyTorch

```bash
pip3 install torch torchvision torchaudio
```

使用如下脚本可以监测默认设备

```python
import torch

if torch.cuda.is_available():
    device = torch.device("cuda")
    print("默认设备为GPU")
else:
    device = torch.device("cpu")
    print("默认设备为CPU")
```
