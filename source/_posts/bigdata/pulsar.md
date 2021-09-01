---
title: Pulsar 初探
date: 2020-12-06 22:26:13
tags:
- "Pulsar"
id: pulsar
no_word_count: true
no_toc: false
categories: 大数据
---

## Pulsar 初探

### 简介

最近经常看到 Pulsar 相关的文章，所以初步了解了一下 Pulsar 项目。

相较于 Kafka 来说，Pulsar 主要做了以下两件事来更好的提供服务：

- 云原生(方便扩容缩容)
- 使用 Bookkeeper 存储数据

与 Kafka 类似 Pulsar 目前也使用了 Zookeeper 存储元数据，大致结构如下图所示。

![数据交互流](https://i.loli.net/2021/09/01/w2EkgqBOhdYcV6L.png)

### 初步使用

新建 `docker-compose.yaml` 文件然后填入如下内容：

```yaml
version: "3"
services:
  pulsar:
    image: apachepulsar/pulsar:latest
    container_name: pulsar
    ports:
      - "6650:6650"
      - "8080:8080"
    command: bin/pulsar standalone
    volumes:
      - ./volume/data:/pulsar/data
```

安装客户端库

```bash
pip install pulsar-client
```

编写消费者

```python
import pulsar

client = pulsar.Client('pulsar://localhost:6650')
consumer = client.subscribe('my-topic',
                            subscription_name='my-sub')

while True:
    msg = consumer.receive()
    print("Received message: '%s'" % msg.data())
    consumer.acknowledge(msg)

client.close()
```

编写生产者

```python
import pulsar

client = pulsar.Client('pulsar://localhost:6650')
producer = client.create_producer('my-topic')

for i in range(10):
    producer.send(('hello-pulsar-%d' % i).encode('utf-8'))

client.close()
```

### 参考资料

https://www.bilibili.com/video/BV1tV41127PD?from=search&seid=14981968776096759677
