---
title: Open Interpreter
date: 2024-04-10 22:26:13
tags:
- "AI"
id: open-interpreter
no_word_count: true
no_toc: false
---

## Open Interpreter

### 简介

Open Interpreter 可以让大语言模型运行代码。

### 安装及使用

```bash
pip install open-interpreter
```

本地运行可以直接使用：

```bash
interpreter --local
```

远程运行可以使用：

```bash
interpreter --model ollama/codellama --api_base http://xxx.xxx.xxx.xxx:11434
```

### 参考资料

[官方网站](https://docs.openinterpreter.com/getting-started/introduction)
