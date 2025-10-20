---
title: OpenSpec
date: 2025-10-20 22:26:13
tags:
- "AI"
id: openspec
no_word_count: true
no_toc: false
---

## OpenSpec

### 简介

为了规范 AI 写出来的代码可以使用 OpenSpec 项目，通过文档和 AI 提问的方式来生成代码。

### 使用方式

首先需要一款 cli 工具，当前支持项目如下：

- Claude Code
- Cursor
- Factory Droid
- OpenCode
- Kilo Code
- Windsurf
- Codex
- GitHub Copilot
- Amazon Q Developer
- Auggie (Augment CLI)

然后需要保证 `Node.js >= 20.19.0` 之后就可以安装应用了:

```bash
npm install -g @fission-ai/openspec@latest
```

验证安装需要如下命令：

```bash
openspec --version
```

进入项目需要先进行初始化：

```bash
openspec init
```

> 注：之后会收到命令，在对应平台发送即可

然后可以创建一个提案：

```text
/openspec:proposal <proposal>
```

> 注：根据提示回答问题即可

检查并修复之前的文档，之后可以使用如下命令进行变更：

```bash
openspec list
openspec validate <content>
```

```text
/openspec:apply <content>
```

之后即可进行测试验证，在测试验证后可以使用如下命令进行归档：

```text
/openspec:archive <content>
```

归档后推送代码即可。

### 参考资料

[官方项目](https://github.com/Fission-AI/OpenSpec)

[开发者福音！现有项目用AI迭代？OpenSpec规范驱动开发！让AI按规范写代码，真正做到零失误！支持Cursor、Claude Code、Codex！比SpecKit更强大！三分钟为iOS新增功能](https://www.youtube.com/watch?v=ANjiJQQIBo0)
