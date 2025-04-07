---
title: Open WebUI
date: 2025-04-07 22:26:13
tags:
- "AI"
id: open-webui
no_word_count: true
no_toc: false
---

## Open WebUI

### 简介

Open WebUI 是一个可扩展 、功能丰富且用户友好的自托管 AI 平台，旨在完全离线运行。它支持各种运行器（如 Ollama） 和与 OpenAI 兼容的 API ，并具有用于 RAG 的内置推理引擎。

### 使用方式

编写如下 `docker-compose.yaml` 文件：

```yaml
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

### 接入 MCP

> 注： 在本地使用需要 Python 3.8 +

可以使用如下方式构建容器，或本地运行：

```Dockerfile
FROM python:3.11-slim
WORKDIR /app
ADD mcp_settings.json .
RUN pip install mcpo uv mcp-server-time
EXPOSE 8000
CMD ["uvx", "mcpo", "--config", "mcp_settings.json"]
```

配置样例如下：

```json
{
  "mcpServers": {
    "time": {
      "command": "uvx",
      "args": [
        "mcp-server-time",
        "--local-timezone=America/New_York"
      ]
    }
  }
}
```

访问如下地址即可进行测试：

[http://localhost:8000/docs](http://localhost:8000/docs)

> 注：可以使用接口测试 MCP 的响应结果

测试结束后需要配置 Open WebUI ：

在 Open WebUI 的设置 tools 里填入 MCPO 的地址和端口即可，例如 `http://localhost:8000`

### 参考文档

[官方文档](https://docs.openwebui.com/)

[官方项目](https://github.com/open-webui/open-webui)

[mcpo](https://github.com/open-webui/mcpo)

[颠覆MCP！Open WebUI新技术mcpo横空出世！支持ollama！轻松支持各种MCP Server！Cline+Claude3.7轻松开发论文检索MCP Server！3分钟本地部署 mcpo](https://www.youtube.com/watch?v=AAiG_j4Lx4c)
