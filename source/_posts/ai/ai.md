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

#### 微调(Fine Tuning)

微调是指对已经在大量通用文本数据上训练好的大型语言模型进行进一步的调整，以优化其在特定任务或领域中的性能。

> 注：如果需要引入最新的信息或对新内容进行检索，此时使用 RAG 是更合适的。

微调的方式有很多，可以全量微调也可以通过 [LoRA](https://github.com/microsoft/LoRA) 或 [QLoRa](https://github.com/artidoro/qlora) 方式来从数学方面减少微调的性能消耗。

下面是一些微调所必备的参数说明：

- Learning Rate 决定了优化算法在每次迭代中更新模型参数的步长大小。简单来说，学习率控制了模型权重调整的速度和幅度。太大会很难达到目标，太小微调要运行很久。
- Batch Size 决定了模型在更新知识之前查看的示例数量。批次越大学习越稳定，但要更多内存。
- Number of Epoch 决定了模型查看数据集的次数，太少可能没学到，太多则会出现过度拟合(只在训练数据上表现好，训练中拿到了很多噪声和异常值)。
- Optimizer Selection 决定了不同的教学方法，例如 AdamW 比较全能，其他优化器可能更适合特定情况。

通常来说当准备好几百个样例之后微调才能有好的结果，但是样例数量和实际的效果可能不是正相关的。必须要一致性强的数据才能达到目标。数据要清晰一致且专注于目标内容。通常来说最好遵循以下规范：

- 格式和风格一致
- 没有错误和矛盾
- 示例和实际用例相关

且最好要在训练数据中包含边缘情况和失败场景的处理方法。

[Is MLX the best Fine Tuning Framework?](https://www.youtube.com/watch?v=BCfCdTp-fdM)

[Fast Fine Tuning with Unsloth](https://www.youtube.com/watch?v=dMY3dBLojTk)

[Axolotl example](https://github.com/axolotl-ai-cloud/axolotl-cookbook/tree/main/examples/talk_like_a_pirate)

[Axolotl is a AI FineTuning Magician](https://www.youtube.com/watch?v=lj44Bt9UxYQ)

#### 量化(Quantization)

LLM 越大效果越好，但是同时也会造成需要更多的内存，量化是目前最突出的解决方案。目前的模型通常会用 32 位的浮点数来表示权重(weights) 和激活函数 (activations) ，但是实际在使用中会将其转化至 `float32 -> float16` 和 `float32 -> int8` 。

其中 Q2 Q4 Q8 代表位数，K 代表将数值按照分组然后进行按位优化，K 有 S M L (小中大)三种记录方式携带内容越多模型越大。

[A Guide to Quantization in LLMs](https://symbl.ai/developers/blog/a-guide-to-quantization-in-llms/)

[Optimum Document Quantization](https://huggingface.co/docs/optimum/en/concept_guides/quantization)

[Optimize Your AI - Quantization Explained](https://www.youtube.com/watch?v=K75j8MkwgJ0)

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

#### AutoGen

AutoGen 是一个用于创建多代理 AI 应用程序的框架，这些应用程序可以自主运行或与人类一起工作。

利用不同的 Agent 可以实现循环调用，使用工具，分角色处理问题等内容。

[微软最强AI智能体AutoGen史诗级更新！](https://www.youtube.com/watch?v=IrTEDPnEVvU)

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

#### MaxKB 

项目地址：[MaxKB](https://github.com/1Panel-dev/MaxKB/)

MaxKB 是一个基于大型语言模型（LLM）和检索增强生成（RAG）的聊天机器人。

可以使用如下 `docker-compose.yaml` 文件运行：

```yaml
services:
  maxkb:
    image: cr2.fit2cloud.com/1panel/maxkb
    container_name: maxkb
    restart: always
    ports:
      - "8080:8080"
    volumes:
      - ~/.maxkb:/var/lib/postgresql/data
      - ~/.python-packages:/opt/maxkb/app/sandbox/python-packages
```

之后即可访问 [http://localhost:8080](http://localhost:8080) 进入管理页面，查看 swagger 地址，新增知识库等功能。

默认用户名和密码如下：

```text
# username: admin
# pass: MaxKB@123..
```

### 在线工具

#### W&B (wandb)

项目地址：[W&B](https://github.com/wandb/wandb)

Weights & Biases (W&B) 是一种流行的工具，用于跟踪机器学习实验，与团队协作，以及管理模型。通过此工具可以监控在微调过程中的相关数据。

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
