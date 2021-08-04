---
title: RabbitMQ 入门
date: 2021-08-04 20:26:13
tags:
- "RabbitMQ"
- "Python"
id: zeromq
no_word_count: true
no_toc: false
categories: MQ
---

## RabbitMQ 入门

### 容器化安装

```yaml
version: "3"
services:
  rabbitmq:
    image: rabbitmq:3
    container_name: rabbit
    ports:
      - "5672:5672"
```

### 简单使用

安装软件包

```bash
pip install pica --user
```

写消息

```python
import pika

connection = pika.BlockingConnection()
channel = connection.channel()
channel.basic_publish(exchange='test', routing_key='test',
                      body=b'Test message.')
connection.close()
```
