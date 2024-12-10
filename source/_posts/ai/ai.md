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

### 基础知识

#### 课程和基础概念

[LLM/AI 大模型入门指南](https://zhuanlan.zhihu.com/p/722000336)

[李宏毅2024春《生成式人工智能导论》](https://www.bilibili.com/video/BV1BJ4m1e7g8)

#### 量化(Quantization)

LLM 越大效果越好，但是同时也会造成需要更多的内存，量化是目前最突出的解决方案。目前的模型通常会用 32 位的浮点数来表示权重(weights) 和激活函数 (activations) ，但是实际在使用中会将其转化至 `float32 -> float16` 和 `float32 -> int8` 。

[A Guide to Quantization in LLMs](https://symbl.ai/developers/blog/a-guide-to-quantization-in-llms/)

[Optimum Document Quantization](https://huggingface.co/docs/optimum/en/concept_guides/quantization)

#### RAG

RAG(Retrieval-Augmented Generation)，检索增强生成，即从外部获取额外信息辅助模型生成内容。

[学习检索增强生成(RAG)技术，看这篇就够了——热门RAG文章摘译](https://zhuanlan.zhihu.com/p/673392898)

### 相关项目

#### LongChain

项目地址：[LongChain](https://github.com/langchain-ai/langchain)

LangChain 是一个用于开发由语言模型驱动的应用程序的框架。它使应用程序能够：

感知上下文：将语言模型连接到上下文源(提示指令、少量镜头示例、内容以使其响应为基础等)

理解原因：依靠语言模型进行推理(关于如何根据提供的上下文回答、采取什么行动等)

此框架还提供了网页和插件规范。

#### Text generation web UI

项目地址：[Text generation web UI](https://github.com/oobabooga/text-generation-webui)

此项目可以在本地搭建一个聊天服务器，并且可以替换各种模型

#### Tabby

项目地址：[Tabby](https://github.com/TabbyML/tabby)

此项目可以在本地搭建一个代码提示服务器，并且可以使用不同参数的 CodeLama 和 StarCoder 等模型。

> 注：目前已有 VS Code，IntelliJ Platform 和 VIM 的支持插件。 

#### Continue 

项目地址：[Continue](https://github.com/continuedev/continue)

使用 Continue 可以让 Ollama 和 IDE 结合起来。

> 注：具体配置参见 [An entirely open-source AI code assistant inside your editor](https://ollama.com/blog/continue-code-assistant) 博客。

#### Void

项目地址：[Void](https://github.com/voideditor/void)

Void 项目是个开源版本的 Cursor 编辑器。

#### Docling

项目地址：[Docling](https://github.com/DS4SD/docling)

Docling 可以轻松快速地解析文档并将其导出为所需的格式。

> 注：此项目可以接受不同格式的文件，并使用 OCR 的方案将其进行格式转化，供 AI 读取。

#### OpenHands

项目地址：[OpenHands](https://github.com/All-Hands-AI/OpenHands)

OpenHands 是一款网页端的 WebIDE 支持很多的大模型，可以独立分解问题并读取项目文件并进行在线调试和修改。

可以使用如下 `docker-compose.yaml` 文件运行：

```yaml
services:
  openhands:
    image: ghcr.io/all-hands-ai/openhands:0.11
    pull_policy: always
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=ghcr.io/all-hands-ai/runtime:0.11-nikolaik
      - SANDBOX_USER_ID=${UID}
      - WORKSPACE_MOUNT_PATH=${WORKSPACE_BASE}
    volumes:
      - ${WORKSPACE_BASE}:/opt/workspace_base
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "3000:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

环境配置项如下 `.env`：

```env
WORKSPACE_BASE=./workspace
UID=$(id -u)
```

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
