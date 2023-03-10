---
title: FauxPilot
date: 2023-03-03 22:26:13
tags:
- "FauxPilot"
id: fauxpilot
no_word_count: true
no_toc: false
---

## FauxPilot

### 简介

FauxPilot 是一款在本地托管的 GitHub Copilot。

> 注：如果显卡不好就不要用了，单张 2060 或同等算力基本歇菜，同样数量 CUDA 核心怕是没用，且显存最好 16G 以上(8GB 模型单机使用都遇到卡顿)。

### 安装方式梳理

在安装项目前需要满足如下依赖：

- Docker
- Docker-Compose >= 1.28
- NVIDIA GPU(Compute Capability >= 6.0)
- nvidia-docker
- curl 和 zstd 命令

克隆项目：

```bash
git clone https://github.com/fauxpilot/fauxpilot.git
```

使用脚本下载模型：

```bash
cd fauxpilot
./setup.sh
```

启动服务：

```bash
./launch.sh
```

关闭服务

```bash
./shutdown.sh
```

### VSCode 插件

在配置页面修改 `settings.json` 配置文件并加入下面的内容：

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "codegen",
    "debug.testOverrideProxyUrl": "http://localhost:5000",
    "debug.overrideProxyUrl": "http://localhost:5000"
  }
}
```

### IDEA 配置

> 注：目前还没有官方插件可以使用，好像也没开发的意思，还是用官方插件 `github copilot`。

IDEA 官方插件当中并没有参数可以设置，但是在项目 [Issue](https://github.com/fauxpilot/fauxpilot/issues/10) 当中的表述则是看起来代码中应该也去获取了 `debug.overrideProxyUrl` 等。经过检索发现代码中还是有这方面的内容具体位置如下：

```text
windows: C:\Users\<user>\AppData\Roaming\JetBrains\<version>\plugins\github-copilot-intellij\copilot-agent\dist\agent.js
linux: ~/.local/share/JetBrains/<version>/github-copilot-intellij/copilot-agent/dist/agent.js
```

在配置中可以寻找如下配置项并进行修改：

```json
{
  "github.copilot.advanced": {
    "debug.overrideEngine": "codegen",
    "debug.testOverrideProxyUrl": "http://localhost:5000",
    "debug.overrideProxyUrl": "http://localhost:5000"
  }
}
```

> 注: 由于效果不好，没继续花时间进行测试，只修改默认值是不行的。

### 参考资料

[官方项目](https://github.com/fauxpilot/fauxpilot)

[客户端配置](https://github.com/fauxpilot/fauxpilot/blob/main/documentation/client.md)
