---
title: Electron
date: 2025-05-06 22:26:13
tags:
- "Electron"
id: electron
no_word_count: true
no_toc: false
---

## Electron

### 简介

Electron 是一个使用 JavaScript、HTML 和 CSS 构建桌面应用程序的框架。通过将 Chromium 和 Node.js 嵌入到其二进制文件中，Electron 允许您维护一个 JavaScript 代码库并创建可在 Windows、macOS 和 Linux 上运行的跨平台应用程序。

Electron⚡️Vite 项目是 Electron 与 Vite 结合的一个社区实践方案，可以简化开发上的代码配置部分！

### 使用方式

使用如下命令创建项目：

```bash
npm create electron-vite@latest
```

然后使用如下命令安装依赖：

```bash
ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/ npm install
```

若是 Windows 环境则可以使用 Powershell 命令如下：

```text
$env:ELECTRON_MIRROR = "https://npmmirror.com/mirrors/electron/"
npm install
```

> 注：在打包的时候也需要设置此环境变量。

使用如下命令即可运行程序：

```bash
npm run dev
```

若需要打开调试工具可以在 `electron/main.ts` 文件的 `createWindow()` 方法中加入如下内容：

```typescript
win.webContents.openDevTools()
```

### 参考资料

[electron-vite](https://electron-vite.github.io/)

[官方网站](https://www.electronjs.org/)
