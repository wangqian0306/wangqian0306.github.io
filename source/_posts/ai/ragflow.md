---
title: RAGFlow
date: 2024-08-09 16:17:00
tags: 
- "Python"
- "AI"
id: ragflow
no_word_count: true
no_toc: false
---

## RAGFlow

### 简介

RAGFlow 是一款基于深度文档理解构建的开源 RAG（Retrieval-Augmented Generation）引擎。RAGFlow 可以为各种规模的企业及个人提供一套精简的 RAG 工作流程，结合大语言模型（LLM）针对用户各类不同的复杂格式数据提供可靠的问答以及有理有据的引用。

### 使用方式

使用如下命令暂时设置 `vm.max_map_count` 配置：

```bash
sudo sysctl -w vm.max_map_count=262144
```

修改默认系统配置：

```bash
sudo vim /etc/sysctl.conf
```

新增或修改以下配置项：

```text
vm.max_map_count=262144
```

设置完成后可以使用如下命令进行检查：

```bash
sysctl vm.max_map_count
```

之后即可拉取项目，并修改环境配置项：

```bash
git clone https://github.com/infiniflow/ragflow.git
cd ragflow/docker
chmod +x ./entrypoint.sh
vim .env 
```

然后编辑如下配置项到最新的版本：

```text
RAGFLOW_VERSION=dev
```

使用如下命令启动服务并查看启动的容器日志：

```bash
docker-compose up -d
docker-compose logs -f 
```

> 注：docker 有 10G 多拉起来比较花时间。

启动完成后即可访问 [http://localhost](http://localhost) 即可。

在进入页面后即可配置 Ollama 地址和模型。

### 参考资料

[项目源码](https://github.com/infiniflow/ragflow)

[官方文档](https://ragflow.io/docs/dev/)
