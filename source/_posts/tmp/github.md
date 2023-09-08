---
title: GitHub 小技巧
date: 2020-04-01 21:57:04
tags: 
- "Codespaces"
- "Gitpod"
id: github
no_word_count: true
no_toc: true
---

## GitHub 小技巧

### 高级搜索

[高级搜索入口](https://github.com/search/advanced)

### 文件和代码检索

- 在项目中时可以使用 `t` 键进入文件检索页面
- 在项目中时可以使用 `.` 键进入 Web IDE
- 在浏览代码文件时可以使用 `l` 键进行行号跳转
- 在浏览代码文件时可以使用 `b` 键查看文件的改动记录
- 使用 `ctrl` + `k` 可以打开控制面板，具体操作请参照官方文档

### Codespaces

Github Codespaces 是官方提供的在线 IDE 工具，可以方便的通过网页进行项目测试。

> 注：目前使用体验还是比 GitPod 略差。

### GitPod 

GitPod 是一款在线的 IDE 工具，提供了本地和网页端运行的两种功能，可以通过此工具快速的运行项目。

使用方式：

在浏览项目时，可以在地址栏添加 `gitpod.io/#/<repo>` 访问 Web IDE。样例如下：

```text
https://github.com/wangqian0306/wangqian0306.github.io
https://gitpod.io/#/github.com/wangqian0306/wangqian0306.github.io
```

> 注：建议使用 VSCode 作为在线编辑工具，JetBrains 系列需要配合 Gateway 一起使用，不是很方便。

### Vercel

Vercel 是一个框架、它提供了工作流程和基础设施，可以将 github 项目部署到外网。

使用方式：

- 从 GitHub 项目创建(详情参照官方手册)
- 从 [模板项目](https://vercel.com/new/templates) 创建

### OpenCommit

OpenCommit 是一款根据提交文件的变动自动生成 commit-log 的软件。

使用方式：

```bash
npm install -g opencommit
oco config set OCO_OPENAI_API_KEY=<your_api_key>
```

> 注：需要 OpenAI 的 Token，目前可以使用 Azure 免费搭建个人版。

### 参考资料

[GitHub 官方手册](https://docs.github.com/cn)

[GitPod 官方手册](https://www.gitpod.io/docs)

[Codespaces 官方手册](https://docs.github.com/en/codespaces)

[Vercel 官方手册](https://vercel.com/docs)

[OpenCommit](https://github.com/di-sukharev/opencommit)
