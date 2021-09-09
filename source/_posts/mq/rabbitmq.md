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
    image: rabbitmq:3-management
    container_name: rabbit
    ports:
      - "5672:5672"
      - "15672:15672"
```

> 注：management 代表自带的管理工具，可以使用网页的方式进行管理。

### 简单使用

安装软件包

```bash
pip install pica --user
```

写消息

```python
import json
import random
import pika
from pika.exchange_type import ExchangeType

print('pika version: %s' % pika.__version__)

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost', credentials=pika.PlainCredentials('guest', 'guest')))
main_channel = connection.channel()

main_channel.exchange_declare(exchange='com.micex.sten', exchange_type=ExchangeType.direct)
main_channel.exchange_declare(
    exchange='com.micex.lasttrades', exchange_type=ExchangeType.direct)

tickers = {
    'MXSE.EQBR.LKOH': (1933, 1940),
    'MXSE.EQBR.MSNG': (1.35, 1.45),
    'MXSE.EQBR.SBER': (90, 92),
    'MXSE.EQNE.GAZP': (156, 162),
    'MXSE.EQNE.PLZL': (1025, 1040),
    'MXSE.EQNL.VTBR': (0.05, 0.06)
}


def getticker():
    return list(tickers.keys())[random.randrange(0, len(tickers) - 1)]


_COUNT_ = 10

for i in range(0, _COUNT_):
    ticker = getticker()
    msg = {
        'order.stop.create': {
            'data': {
                'params': {
                    'condition': {
                        'ticker': ticker
                    }
                }
            }
        }
    }
    main_channel.basic_publish(
        exchange='com.micex.sten',
        routing_key='order.stop.create',
        body=json.dumps(msg),
        properties=pika.BasicProperties(content_type='application/json'))
    print('send ticker %s' % ticker)

connection.close()
```


### 注意事项

在使用 Java AMQP 链接到 RabbitMQ 的时候出现了如下问题：

```text
503, NOT_ALLOWED - vhost / not found
```

解决方案是在 RabbitMQ 容器中使用如下配置项，添加自定义 vhost：

```text
RABBITMQ_DEFAULT_VHOST: <vhost>
```

然后在代码中指明 vhost 即可解决问题。
