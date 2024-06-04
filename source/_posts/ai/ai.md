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
