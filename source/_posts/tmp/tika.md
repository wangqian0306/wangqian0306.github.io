---
title: Apache Tika
date: 2024-10-14 22:26:13
tags:
- "Apache Tika"
- "Python"
id: tika
no_word_count: true
no_toc: false
---

## Apache Tika

### 简介

Apache Tika 可以检测并提取来自一千多种不同文件类型（如PPT、XLS和PDF）的元数据和文本。

### 使用方式

#### 启动服务

可以选用 Docker 的方式使用：

```dockerfile
FROM apache/tika:latest
USER root
RUN apt update && apt install fonts-wqy-zenhei fonts-wqy-microhei xfonts-wqy -y
USER 35002:35002
```

```yaml
services:
  tika:
    build: .
    image: custom/tika:latest
    ports:
      - "9998:9998"
```

也可以通过下载包，并通过 java 来使用，[下载地址](https://tika.apache.org/download.html) 

#### 读取数据

首先可以准备好要解析的数据文件，然后安装依赖：

```bash
pip install tika 
```

然后编写如下程序即可：

```python
from tika import parser

def read_docx(file_path):
    parsed = parser.from_file(file_path)
    text = parsed.get('content', '')
    return text.strip()

if __name__ == "__main__":
    file_path = 'xxx.xxx' 
    content = read_docx(file_path)
    print(content)
```

### 参考资料

[官方网站](https://tika.apache.org/)
