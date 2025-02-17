---
title: Spring AI Agent
date: 2025-02-17 21:32:58
tags:
- "Java"
- "Spring Boot"
- "AI"
id: spring-ai-agent
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring AI Agent

### 简介

Agent 技术可以通过很多种方式定义。一些人将其定义为一套完全自主的系统，这些系统在长时间内独立运行，用外界的各种工具来完成复杂的任务。还有一些人将其定义为让 AI 遵循一系列的工作流程，来获取好的结果。可以将其抽象为以下两种形式：

- 工作流(Workflows)，从之前定义的计划出发，利用各种 LLM 和工具达成目标。
- Agents，从 LLM 自行判断出发，自动完成分发任务，动态判断执行情况，结合实际需求选择工具等。

在利用 AI 处理问题的时候容易出现表达不明确的问题。可以借用 Agent 技术来解决复杂的问题，提升用户体验。

### 基本逻辑

![The augmented LLM](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2Fd3083d3f40bb2b6f477901cc9a240738d3dd1371-2401x1000.png&w=3840&q=75)

基本的运行逻辑是一致的，首先需要类似 RAG 做内容补充，之后调用接口，将运行信息进行记录。

### Workflow

#### Prompt Chaining

![Prompt Chaining](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F7418719e3dab222dccb379b8879e1dc08ad34c78-2401x1000.png&w=3840&q=75)

通过固定的流程，将职责分发给不同的 LLM，例如用 LLAMA 生成但是 Qwen 翻译成中文结果。

#### Routing

![Routing](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F5c0c0e9fe4def0b584c04d37849941da55e5e71c-2401x1000.png&w=3840&q=75)

通过让 LLM 选择不同的 LLM 来回答问题，例如用 LLAMA 回答英文问题，Qwen 回答中文问题。

#### Parallelization

![Parallelization](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F406bb032ca007fd1624f261af717d70e6ca86286-2401x1000.png&w=3840&q=75)

通过将不同的子问题发送到不同的 LLM 来加速生成结果。

#### Orchestrator-workers

![Orchestrator-workers](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F8985fc683fae4780fb34eab1365ab78c7e51bc8e-2401x1000.png&w=3840&q=75)

通过 LLM 将问题分解，然后转发给不同的 LLM 处理问题，例如用 code 模型处理代码，LLAMA 生成描述。

#### Evaluator-optimizer

![Evaluator-optimizer](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F14f51e6406ccb29e695da48b17017e899a6119c7-2401x1000.png&w=3840&q=75)

设立两个 LLM ,一个解答一个检查，如果遇到问题给到反馈，例如用 code 模型编码，LLAMA 检查代码风格和格式

### Agent

![Agent](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F58d9f10c985c4eb5d53798dea315f7bb5ab6249e-2401x1000.png&w=3840&q=75)

LLM 自行判断需要向外获取什么内容，结果是否可用。

### 参考资料

[Building effective agents](https://www.anthropic.com/research/building-effective-agents)

[官方博客](https://spring.io/blog/2025/01/21/spring-ai-agentic-patterns)

[示例代码](https://github.com/spring-projects/spring-ai-examples/tree/main/agentic-patterns)
