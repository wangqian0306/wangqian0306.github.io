---
title: MQTT Server
date: 2021-04-23 22:26:13
tags:
- "Mosquitto"
- "EMQX"
- "MQTT"
- "Python"
id: mqtt-server
no_word_count: true
no_toc: false
categories: MQ
---

## MQTT Server

### Mosquitto

#### 简介

Eclipse Mosquitto 是一款实现了 MQTT 协议 5.0，3.1.1 和 3.1 版本的开源消息代理软件（ EPL/EDL 许可证）。
Mosquitto 非常轻量化，能够在低功耗的单板计算机和完整服务器的上使用。

[官方文档](https://mosquitto.org/)

#### 安装方式 (Docker)

- 编辑 `mosquitto.conf` 配置文件

```text
listener 1883 0.0.0.0
allow_anonymous true
```

- 编辑 `docker-compose.yaml`

```yaml
services:
  app-mosquitto:
    container_name: mosquitto
    hostname: mosquitto
    image: eclipse-mosquitto:latest
    ports:
      - 1883:1883
      - 8883:8883
    read_only: true
    volumes:
      - type: bind
        source: ./mosquitto.conf
        target: /mosquitto/config/mosquitto.conf
```

- 启动服务

```bash
docker-compose up -d 
```

- 关闭服务

```bash
docker-compose down
```

#### 常用命令

- 订阅

```bash
mosquitto_sub -t <topic> -u <user> -P <password>
```

- 发布

```bash
mosquitto_pub -h <host> -t <topic> -m "<message>" -u <user> -P <password>
```

### EMQX

#### 简介

EMQX 是一个高性能、可扩展的 MQTT 消息服务器，自带了管理 Web 端。

[官方文档](https://docs.emqx.com/zh/emqx/latest/)

#### 安装方式 (Docker)

- 编辑 `docker-compose.yaml`

```yaml
volumes:
  vol-emqx-data:
    name: foo-emqx-data
  vol-emqx-log:
    name: foo-emqx-log

services:
  emqx:
    image: emqx:latest
    container_name: emqx
    environment:
      - EMQX_DASHBOARD__DEFAULT_PASSWORD=mysecret
    ports:
      - "18083:18083"
      - "1883:1883"
    volumes:
      - vol-emqx-data:/opt/emqx/data
      - vol-emqx-log:/opt/emqx/log
    restart: unless-stopped
```

- 启动服务

```bash
docker-compose up -d 
```

- 关闭服务

```bash
docker-compose down
```

之后访问 [http://localhost:18083](http://localhost:18083) 使用 admin 账户和配置好的 EMQX_DASHBOARD__DEFAULT_PASSWORD 即可登录。

> 注：如果需要本地卷可以使用 named data volume 或者将目录权限设定为 777 。

### 连接例程

- 安装软件包

```bash
pip3 install paho-mqtt --user
```

- 编写生产者程序

```python
import time
from paho.mqtt import client as mqtt_client

broker = 'xxx.xxx.xxx.xxx'
port = 1883
topic = "python/mqtt"
client_id = 'producer-01'
username = 'xxxx'
password = 'xxxx'


def connect_mqtt():
    client = mqtt_client.Client(callback_api_version=mqtt_client.CallbackAPIVersion.VERSION2,client_id=client_id)
    client.username_pw_set(username, password)
    client.connect(broker, port)
    return client


def publish(client, topic, message):
    msg_info = client.publish(topic, message, qos=1)
    msg_info.wait_for_publish()


if __name__ == '__main__':
    client = connect_mqtt()
    client.loop_start()
    msg = f"messages: demo message {time.time()}"
    publish(client, topic, msg)
    client.disconnect()
    client.loop_stop()
```

- 编写消费者程序

```python
from paho.mqtt import client as mqtt_client

broker = 'xxx.xxx.xxx.xxx'
port = 1883
topic = "python/mqtt"
client_id = 'consumer-01'
username = 'xxxx'
password = 'xxxx'

userdata = {
    'topic': topic
}

def on_connect(client, userdata, flags, rc, properties):
    client.subscribe(userdata['topic'])
    print(f"Subscribed to topic: {userdata['topic']}")

def on_message(client, userdata, msg):
    print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")

def on_disconnect(client, userdata, disconnect_flags,reason_code, properties, rc):
    print(f"[MQTT] 已断开连接，原因码 rc={rc}")

def connect_mqtt(user_data) -> mqtt_client.Client:
    client = mqtt_client.Client(
        callback_api_version=mqtt_client.CallbackAPIVersion.VERSION2,
        client_id=client_id,
        userdata=user_data
    )

    client.username_pw_set(mqtt_username, mqtt_password)
    client.connect(broker, port, keepalive=60)

    client.on_connect = on_connect
    client.on_message = on_message
    client.on_disconnect = on_disconnect

    return client

if __name__ == '__main__':
    try:
        client = connect_mqtt(userdata)
        print(f"Connected to MQTT Broker: {broker}:{port}")
        client.loop_forever()
    except Exception as e:
        print(f"MQTT : {e}")
```

> 注：loop_forever 默认会断线重连
