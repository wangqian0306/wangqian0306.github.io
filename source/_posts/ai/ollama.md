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

想要更新 ollama 可以使用如下命令：

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### Chat

使用如下命令可以拉取大模型：

```bash
ollama pull llama2:latest
```

然后可以使用如下命令测试模型运行情况：

```bash
ollama run llama2
```

然后可以用如下命令进入调试模式：

```bash
ollama run llama2 --verbose
```

若可以正常使用则可以尝试调用 API：

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt":"Why is the sky blue?"
}'
```

##### 微调后的模型

除了官方模型清单内的模型之外，还可以使用 [huggingface](https://huggingface.co/models?library=gguf) 上的其他模型。

```bash
ollama run hf.co/arcee-ai/SuperNova-Medius-GGUF
```

自然也可以通过修改模型文件的方式，添加自定义的提示词等内容。

#### Embedding

使用如下命令可以拉取嵌入模型：

```bash
ollama pull nomic-embed-text:latest
```

可以尝试调用 API：

```bash
curl http://localhost:11434/api/embeddings -d '{
  "model": "nomic-embed-text",
  "prompt": "Llamas are members of the camelid family"
}'
```

### 模型

对于 Ollama 来说，除了基本的权重文件之外还需要一个 Modelfile 。这个 Modelfile 包含如下元素：

- 系统提示词(system prompt)
- 回答问题的模板(template)
- 参数(parameters，可选)
- 适配器(adapter，可选)

样例如下：

编写 `modelfile`

```text
FROM llama3.2
PARAMETER temperature 1
```

通过如下命令即可创建一个模型：

```bash
ollama create <name> -f ./modelfile
```

检查一个 model 的模型文件也可以通过如下命令完成：

```bash
ollama show --modelfile <name>
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

### 使用前端库调用

使用如下代码安装依赖：

```bash
npm install ollama
```

然后即可编写如下程序访问 API：

```typescript jsx
'use client';

import {Ollama} from 'ollama/browser'
import React,{ useState } from 'react';

export default function Dashboard() {
  const ollama = new Ollama({host: 'http://localhost:11434'})
  const [data, setData] = useState<String>();
  const [isLoading, setIsLoading] = useState(false);

  const fetchData = async () => {
    try {
      setIsLoading(true);
      const response = await ollama.chat({
        model: 'llama3',
        messages: [{role: 'user', content: 'Why is the sky blue?'}],
      })
      setData(response.message.content);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div>
      <h1>Example Page</h1>
      <button onClick={fetchData} disabled={isLoading}>
        {isLoading ? 'Loading...' : 'Fetch Data'}
      </button>
      {data && (
        <div>
          <p>{data}</p>
        </div>
      )}
    </div>
  );
}
```

### 软件清理与卸载

如果需要删除服务可以使用如下命令：

```bash
sudo rm /etc/systemd/system/ollama.service
sudo rm /etc/systemd/system/ollama.service.d
```

删除软件则可以使用：

```bash
sudo rm $(which ollama)
```

模型文件位于：

```bash
sudo rm -r /usr/share/ollama
```

> 注：需要检查下 OLLAMA_MODELS 环境变量，它可以进行额外配置。

删除用户和组：

```bash
sudo userdel ollama
sudo groupdel ollama
```

### Gollama 模型管理工具

Gollama 是一款支持 macOS / Linux 的模型管理工具。可以使用如下代码安装软件：

```bash
go install github.com/sammcj/gollama@HEAD
export PATH=$PATH:$(go env GOPATH)/bin
```

然后即可使用命令查看模型了：

```bash
gollama
```

### 参考资料

[官方项目](https://github.com/ollama/ollama)

[官方文档](https://github.com/ollama/ollama/blob/main/docs/)

[大模型清单](https://ollama.com/library)

[Embedding models](https://ollama.com/blog/embedding-models)

[The Ollama Course](https://www.youtube.com/watch?v=luH9j_eOEi4&list=PLvsHpqLkpw0fIT-WbjY-xBRxTftjwiTLB&index=5)

[The Ollama Course: Advanced](https://www.youtube.com/watch?v=aMe1mCD6AEI&list=PLvsHpqLkpw0f8YFdnxVCId7FwIOoqkne5)

[Gollama 项目](https://github.com/sammcj/gollama)