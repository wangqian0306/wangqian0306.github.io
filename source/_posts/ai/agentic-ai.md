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