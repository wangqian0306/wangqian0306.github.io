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

> 注：在更新 Ollama 0.9.0 后可以管理思考模式

关闭思考：

```text
/set nothink
```

打开思考(默认)：

```text
/set think
```

在调用时也可以使用如下参数：

```bash
curl http://localhost:11434/api/chat -d '{
  "model": "deepseek-r1",
  "messages": [
    {
      "role": "user",
      "content": "how many r in the word strawberry?"
    }
  ],
  "think": true,
  "stream": false
}'
```

在 Message 中读取 `thinking` 字段即可获取输出。

##### 微调后的模型

除了官方模型清单内的模型之外，还可以使用 [huggingface](https://huggingface.co/models?library=gguf) 上的其他模型。

```bash
ollama run hf.co/arcee-ai/SuperNova-Medius-GGUF
```

自然也可以通过修改模型文件的方式，添加自定义的提示词等内容。在对话中也可以使用命令修改参数，例如：

```text
\set parameter 'num_ctx' 32768
```

之后也可以将其存储为新的模型：

```text
\save <name>
```

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

### 结构化输出

Ollama 提供了官方的结构化输出 API，可以将数据统一转化为对象进行响应。相较于之前的 JSON 模式来说对于枚举的处理更好，但是在转化失败时可能会返回空对象，需按情况使用。

```bash
curl -X POST http://localhost:11434/api/chat -H "Content-Type: application/json" -d '{
  "model": "llama3.1",
  "messages": [{"role": "user", "content": "Tell me about Canada."}],
  "stream": false,
  "format": {
    "type": "object",
    "properties": {
      "name": {
        "type": "string"
      },
      "capital": {
        "type": "string"
      },
      "languages": {
        "type": "array",
        "items": {
          "type": "string"
        }
      }
    },
    "required": [
      "name",
      "capital", 
      "languages"
    ]
  }
}'
```

### 图形化界面

#### Open WebUI

参见 Open WebUI 文档。

#### LobeChat

编写如下 `docker-compose.yaml` 文件：

```bash
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

### 内存优化

在上下文过多的情况下也可以通过量化的方式去减少内存占用量，修改如下配置：

```text
OLLAMA_FLASH_ATTENTION=true
OLLAMA_KV_CACHE_TYPE=f16
```

> 注：需要重启服务才能生效，且不同模型效果可能不同，建议先用 Qwen2.5 看下显存占用，修改配置后启动服务再看下。

### 调试

在问题回答有明显问题时建议开启调试模式，看到 OLLAMA 的处理逻辑和给到模型的提示词。

```text
OLLAMA_DEBUG=1 
```

> 注：若日志没有显示则将其调整为 2 。

### 参考资料

[官方项目](https://github.com/ollama/ollama)

[官方文档](https://github.com/ollama/ollama/blob/main/docs/)

[大模型清单](https://ollama.com/library)

[Embedding models](https://ollama.com/blog/embedding-models)

[The Ollama Course](https://www.youtube.com/watch?v=luH9j_eOEi4&list=PLvsHpqLkpw0fIT-WbjY-xBRxTftjwiTLB&index=5)

[The Ollama Course: Advanced](https://www.youtube.com/watch?v=aMe1mCD6AEI&list=PLvsHpqLkpw0f8YFdnxVCId7FwIOoqkne5)

[Gollama 项目](https://github.com/sammcj/gollama)

[Structured outputs](https://ollama.com/blog/structured-outputs)

[How to troubleshoot issues](https://github.com/ollama/ollama/blob/main/docs/troubleshooting.md)

[Debugging Ollama](https://www.youtube.com/watch?v=ofrXnkZxIkw)
