---
title: Tabby
date: 2024-01-10 23:09:32
tags:
- "AI"
id: tabby
no_word_count: true
no_toc: false
categories: "工具"
---

## Tabby

### 简介

Tabby 是一个自托管的人工智能编码助手 (GitHub Copilot 的开源和本地版)。

### 安装

在 Linux 环境中可以使用 Docker Compose 进行便捷的部署，在运行之前设备已经安装和配置了 GPU 驱动和容器直通。如果有此方面的配置问题可以参照博客中的 nvidia 文档。

首先需要编写 `docker-compose.yaml` 文件：

```yaml
version: '3.5'

services:
  tabby:
    restart: always
    image: tabbyml/tabby
    command: serve --model TabbyML/StarCoder-1B --device cuda
    volumes:
      - "./tabby/data:/data"
    ports:
      - 8080:8080
    environment:
      TZ: Asia/Shanghai
      TABBY_DOWNLOAD_HOST: modelscope.cn
      TABBY_DISABLE_USAGE_COLLECTION: 1
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

> 注：此处为了测试，所以采用的模型比较小，在实际使用时需按照硬件和需求调整 [模型](https://tabby.tabbyml.com/docs/models/)。

然后即可使用如下命令运行容器：

```bash
docker-compose up -d
```

由于在初次启动时需要拉取模型所以耗时有些高，可以通过查看日志的方式确认服务的运行情况：

```bash
docker-compose logs -f
```

若出现如下字样则代表程序运行正常。

```text
INFO tabby::routes: crates/tabby/src/routes/mod.rs:35: Listening at 0.0.0.0:8080
```

在 IDE 中下载 `tabby` 插件，并参照 [插件配置文档](https://tabby.tabbyml.com/docs/extensions/installation/) 进行配置即可。

### 参考资料

[官方文档](https://tabby.tabbyml.com/docs/getting-started)

[官方项目](https://github.com/TabbyML/tabby)

[NVIDIA CONTAINER TOOLKIT](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt)
