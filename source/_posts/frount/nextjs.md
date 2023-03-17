---
title: ncu
date: 2023-03-17 21:41:32
tags:
- "Node.js"
- "Next.js"
- "React"
- "Redux"
id: nextjs
no_word_count: true
no_toc: false
categories: 前端
---

## Next.js

### 简介

Next.js 是一个用于生产环境的 React 应用框架。Redux 则是一种模式和库，用于管理和更新应用程序状态，使用称为“操作”的事件。它是需要在整个应用程序中使用的状态的集中存储，规则确保状态只能以可预测的方式更新。

### 安装

在安装完 Node 之后就可以使用如下命令快速生成项目

```bash
npx create-next-app@latest --typescript
```

### 配置 Redux

```bash
npm install @reduxjs/toolkit redux react-redux @types/react-redux redux-persist
```

### 参考资料

[Next.js 官方文档](https://nextjs.org/docs/getting-started)

[Redux 官方文档](https://redux.js.org/tutorials/fundamentals/part-1-overview)
