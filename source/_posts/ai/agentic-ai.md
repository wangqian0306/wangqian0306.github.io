---
title: Agentic AI
date: 2025-05-09 22:26:13
tags:
- "AI"
id: agentic-ai
no_word_count: true
no_toc: false
---

## Agentic AI

### 简介

此处针对使用 AI 开发产品时的一些注意事项和技术流程进行基本的梳理。

### 技术选型

#### 什么时候需要 Agent 什么时候需要 Workflow

##### Agent

1. 在子功能数量多，且不适合做前端交互的时候。

##### Workflow

1. 在流程不需要用户介入的场景下。

### 构建注意事项

#### 治理

Agent 本身具备的如下特性：

- 会使用不同种类的实体
- 具有复杂的相互链接
- 动态的交互
- 具有一定的适应性，接收的数据类型多样

所以它的治理应该遵守如下的规则：

1. 给 Agent 一个唯一的身份 ID
2. 让 Agent 感知上下文环境和背景
3. 考虑短期访问的实现方式(单次授权/即时访问)
4. 细分和隔离(限制 AI 到特定的环境当中，明确功能和任务)
5. 可观察性

#### 避免风险

为了避免 Agentic AI 使用当中的风险，需要从以下几个角度进行处理：

- 模型，需要确保模型的安全措施，保证输出
- 编排，做额外捕捉，避免死循环和用户体验以及使用的 Token 数量
- 工具，限制代理使用的工具
- 测试，在开发完成后进行详细测试
- 监控，持续进行评估，记录幻觉或违反合规性的行为进行修改

### 参考资料

[What Are AI Identities? Understanding Agentic Systems & Governance](https://www.youtube.com/watch?v=AuV62XbiZcw)

[Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

[那些 Agent 神文没告诉你的事：照着做，系统只会更烂 【AI agent 搭建实操指南】](https://www.youtube.com/watch?v=b_9D7T0n4RA)

[AI agent 开发千万别越努力，越心酸！【AI agent 搭建实操指南 第二弹】](https://www.youtube.com/watch?v=j7Os40UFYH4)