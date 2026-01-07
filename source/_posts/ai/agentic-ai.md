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

### 研发的基本路径

1. 明确当前的问题是否可以通过一次 Api Call 去解决，可以就去直接调用，无需后续逻辑。
2. 把问题分解成工作流，明确中间阶段是否需要用户介入，如果不需要则使用 Workflow。
3. 先采用最简单的技术，确定整条路线是否可以实现，再去按需增加复杂度。
4. 加上全套的日志。
5. 先收集一些数据根据 LLM 输出的格式化程度和在哪些问题上进行一些思考进行提示词优化。
6. 在 LLM 与现实出现差异或者需要能力增强的时候再去引入工具。
7. 在引入工具量太多时，需要考虑上下文问题，引入 Context Engineering。
8. 在任务实现的内容太多，不同情况需要不一样的上下文的时候再去引入规划者，针对任务进行切分。
9. 在规划者需要输出用户输入的相关信息给 Sub Agent 做复述的时候可以引入记忆体
10. 在记忆体研发的时候要注意将存储内容合理分配，区分只在单词对话存在还是在多轮对话中存在。
11. 排查出错的结果，明确在调用中出现了哪些问题，是否需要加入 Review
12. 优化规划者，明确用户意图，在多轮对话中检索工具或者去做 RAG 来优化用户输入。

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