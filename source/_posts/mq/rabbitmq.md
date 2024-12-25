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
services:
  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbit
    ports:
      - "5672:5672"
      - "15672:15672"
```

> 注：management 代表自带的管理工具，可以使用网页的方式进行管理，默认用户名和密码都为 guest，容器的详细配置请参照 [Dockerhub 文档](https://registry.hub.docker.com/_/rabbitmq/)。

### 简单使用

安装软件包

```bash
pip install pica --user
```

写消息

```python
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost', credentials=pika.PlainCredentials('guest', 'guest')))
channel = connection.channel()
channel.exchange_declare(exchange='test')
channel.queue_declare(queue='test')
channel.queue_bind(queue='test', exchange='test')
channel.basic_publish(
    exchange='test',
    routing_key='test',
    body=b'{"wq":"111"}',
    properties=pika.BasicProperties(content_type='text/plain', delivery_mode=pika.DeliveryMode.Transient))
connection.close()
```

读消息

```python
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost', credentials=pika.PlainCredentials('guest', 'guest')))
channel = connection.channel()

# Get ten messages and break out
for method_frame, properties, body in channel.consume('test'):

    # Display the message parts
    print(method_frame)
    print(properties)
    print(body)

    # Acknowledge the message
    channel.basic_ack(method_frame.delivery_tag)

    # Escape out of the loop after 10 messages
    if method_frame.delivery_tag == 10:
        break

# Cancel the consumer and return any pending messages
requeued_messages = channel.cancel()
print('Requeued %i messages' % requeued_messages)

# Close the channel and the connection
channel.close()
connection.close()
```

### 延迟消息

启用延时消息需要开启 `rabbitmq_delayed_message_exchange` 插件，此插件需要自行下载并放置到插件文件夹中：

[下载地址](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases)

启用命令如下：

```bash
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```

> 注：启用完成后需要重启服务。

如果在 Docker 上运行则可以采用以下方式构建容器：

创建 `Dockerfile`

```dockerfile
FROM rabbitmq:3.9.20-management
ADD rabbitmq_delayed_message_exchange-3.9.0.ez /opt/rabbitmq/plugins
RUN rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```

创建 `docker-compose `

```yaml
services:
  rabbitmq:
    build: .
    image: rabbitmq:3.9.20-management-delay
    container_name: rabbit
    ports:
      - "5672:5672"
      - "15672:15672"
```

使用此命令构建容器

```bash
docker-compose build --no-cache
```

> 注：之后可以依据 docker-compose 文件管理 rabbitmq。

使用延迟消息：

- 在构建 `channel` 时需要选择类型为 `x-delayed-message` 且配置 `x-delayed-type` 为 `direct`
- 在发送消息时需要配置 `header` 中包含 `x-delay` 参数，其内容为延迟的毫秒数。

详细内容请参阅[官方文档](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange)

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
