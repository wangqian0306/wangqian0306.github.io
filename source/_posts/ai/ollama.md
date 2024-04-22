---
title: Ollama
date: 2024-03-07 22:26:13
tags:
- "AI"
id: Ollama
no_word_count: true
no_toc: false
---

## Ollama 

### 简介

Ollama 是一款在本地运行大模型的软件。

### 使用

使用如下命令即可安装：

```bash
curl -fsSL https://ollama.com/install.sh | sh
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo echo '[Service]' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo echo 'Environment="OLLAMA_HOST=0.0.0.0:11434"' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

使用如下命令可以拉取大模型：

```bash
ollama pull llama2:latest
```

然后可以使用如下命令测试 ollama 模型运行情况：

```bash
ollama run llama2
```

若可以正常使用则可以尝试调用 API：

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt":"Why is the sky blue?"
}'
```

### 图形化界面

#### Open WebUI

编写如下 `docker-compose.yaml` 文件：

```yaml
version: '3.8'

services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "3000:8080"
    environment:
      - 'OLLAMA_BASE_URL=<ollama_address>'
      - 'WEBUI_SECRET_KEY='
    volumes:
      - ./data:/app/backend/data
    extra_hosts:
      - host.docker.internal:host-gateway
    restart: always
```

然后使用如下命令启动即可：

```bash
docker-compose up -d 
```

> 注：启动时间有些长，记得使用 `docker-compose logs -f` 看日志。

#### LobeChat

编写如下 `docker-compose.yaml` 文件：

```bash
version: '3.8'

services:
  lobe-chat:
    image: lobehub/lobe-chat
    ports:
      - "3210:3210"
    environment:
      - OLLAMA_PROXY_URL=<ollama_address>/v1
```

然后使用如下命令启动即可：

```bash
docker-compose up -d 
```

### 参考资料

[官方项目](https://github.com/ollama/ollama)

[大模型清单](https://ollama.com/library)
