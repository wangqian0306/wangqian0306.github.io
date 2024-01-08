---
title: LongChain
date: 2024-01-08 21:41:32
tags: 
- "Python"
- "AI"
- "LLAMA"
id: longchain
no_word_count: true
no_toc: false
---

## LongChain

### 简介

LangChain 是一个用于开发由语言模型驱动的应用程序的框架，由以下几个部分组成：

- LangChain Libraries：Python 和 JavaScript 库，通过 LangChain 库可以更便捷的与大模型进行交互
- LangChain Templates：一组易于部署的参考架构，适用于各种任务
- LangServe：REST API 服务器
- LangSmith：调试监控平台(开发中，目前需要在云上)

### 使用方式

#### Llama-2

由于 Llama-2 官方下载工具并没有提供运行相关的客户端和交互式命令行等内容，所以此处可以通过 [Ollama](https://github.com/jmorganca/ollama) 项目运行，具体流程如下：

> 注：最好有 GPU 且可以运行的模型参数与显存相关，设备需要先安装驱动。

```bash
curl https://ollama.ai/install.sh | sh
ollama pull llama2
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo echo '[Service]' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo echo 'Environment="OLLAMA_HOST=0.0.0.0:11434"' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

然后可以使用如下命令测试 ollama 模型运行情况：

```bash
ollama run llama2
```

若可以正常使用则可以尝试调用 API：

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt":"Why is the sky blue?"
}'
```

### 参考资料

[官方手册](https://python.langchain.com/docs/get_started/introduction)

[官方项目](https://github.com/langchain-ai/langchain)

[Ollama](https://github.com/jmorganca/ollama)
