---
title: LangChain
date: 2024-01-08 21:41:32
tags: 
- "Python"
- "AI"
- "LLAMA"
id: langchain
no_word_count: true
no_toc: false
---

## LangChain

### 简介

LangChain 是一个用于开发由语言模型驱动的应用程序的框架，由以下几个部分组成：

- LangChain Libraries：Python 和 JavaScript 库，通过 LangChain 库可以更便捷的与大模型进行交互
- LangChain Templates：一组易于部署的参考架构，适用于各种任务
- LangServe：REST API 服务器
- LangSmith：调试监控平台(开发中，目前需要在云上)

### 使用方式

#### Llama-2

由于 Llama-2 官方下载工具并没有提供运行相关的客户端和交互式命令行等内容，所以此处可以通过 [Ollama](https://github.com/jmorganca/ollama) 项目运行，具体流程如下：

> 注：最好有 GPU 且可以运行的模型参数与显存相关，设备需要先安装驱动。

```bash
curl https://ollama.ai/install.sh | sh
ollama pull llama2
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo echo '[Service]' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo echo 'Environment="OLLAMA_HOST=0.0.0.0:11434"' >> /etc/systemd/system/ollama.service.d/environment.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
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

然后即可安装 `Langchain` ：

```bash
pip install langchain
pip install "langserve[all]"
pip install langchain-cli
pip install pydantic==1.10.13
pip install pdfminer
pip install pdfminer.six
```

然后可以编写服务端程序 `demo-server.py`：

```bash
import base64
from typing import Any, Dict, List, Tuple

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from langchain_community.chat_models import ChatOllama
from langchain.document_loaders.blob_loaders import Blob
from langchain.document_loaders.parsers.pdf import PDFMinerParser
from langchain.pydantic_v1 import BaseModel, Field
from langchain.schema.messages import (
    AIMessage,
    BaseMessage,
    FunctionMessage,
    HumanMessage,
)
from langchain.schema.runnable import RunnableLambda
from langchain_core.runnables import RunnableParallel

from langserve import CustomUserType
from langserve.server import add_routes

app = FastAPI(
    title="LangChain Server",
    version="1.0",
    description="Spin up a simple api server using Langchain's Runnable interfaces",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

class ChatHistory(CustomUserType):
    chat_history: List[Tuple[str, str]] = Field(
        ...,
        examples=[[("a", "aa")]],
        extra={"widget": {"type": "chat", "input": "question", "output": "answer"}},
    )
    question: str


def _format_to_messages(input: ChatHistory) -> List[BaseMessage]:
    """Format the input to a list of messages."""
    history = input.chat_history
    user_input = input.question

    messages = []

    for human, ai in history:
        messages.append(HumanMessage(content=human))
        messages.append(AIMessage(content=ai))
    messages.append(HumanMessage(content=user_input))
    return messages

model = ChatOllama(model="llama2")
chat_model = RunnableParallel({"answer": (RunnableLambda(_format_to_messages) | model)})
add_routes(
    app,
    chat_model.with_types(input_type=ChatHistory),
    config_keys=["configurable"],
    path="/chat",
)

class FileProcessingRequest(BaseModel):
    file: bytes = Field(..., extra={"widget": {"type": "base64file"}})
    num_chars: int = 100


def process_file(input: Dict[str, Any]) -> str:
    """Extract the text from the first page of the PDF."""
    content = base64.decodebytes(input["file"])
    blob = Blob(data=content)
    documents = list(PDFMinerParser().lazy_parse(blob))
    content = documents[0].page_content
    return content[: input["num_chars"]]


add_routes(
    app,
    RunnableLambda(process_file).with_types(input_type=FileProcessingRequest),
    config_keys=["configurable"],
    path="/pdf",
)

add_routes(
    app,
    model,
    path="/ollama",
)

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
```

使用如下命令即可运行服务端：

```bash
python demo-server.py
```

然后访问如下页面即可：

[doc](http://localhost:8000/docs/)

[ollama playground](http://localhost:8000/ollama/playground/)

[chat playground](http://localhost:8000/chat_message/playground/)

[pdf playground](http://localhost:8000/pdf/playground/)

### 参考资料

[官方手册](https://python.langchain.com/docs/get_started/introduction)

[官方项目](https://github.com/langchain-ai/langchain)

[Ollama](https://github.com/jmorganca/ollama)

[LangChain Tools](https://python.langchain.com/docs/integrations/tools)
