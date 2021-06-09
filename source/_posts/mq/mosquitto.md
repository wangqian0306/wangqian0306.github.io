---
title: Mosquitto 入门
date: 2021-04-23 22:26:13
tags:
- "Mosquitto"
- "MQTT"
- "Python"
id: mosquitto
no_word_count: true
no_toc: false
categories: MQ
---

## 简介

Eclipse Mosquitto 是一款实现了 MQTT 协议 5.0，3.1.1 和 3.1 版本的开源消息代理软件（ EPL/EDL 许可证）。
Mosquitto 非常轻量化，能够在低功耗的单板计算机和完整服务器的上使用。

[官方文档](https://mosquitto.org/)

## 安装方式 (Docker)

- 编辑 `mosquitto.conf` 配置文件

```text
listener 1883 0.0.0.0
allow_anonymous true
```

- 编辑 `docker-compose.yaml`

```yaml
version: '3.7'
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

## 常用命令

- 订阅

```bash
mosquitto_sub -t <topic> -u <user> -P <password>
```

- 发布

```bash
mosquitto_pub -h <host> -t <topic> -m "<message>" -u <user> -P <password>
```

## 连接例程

- 安装软件包

```bash
pip3 install paho-mqtt --user
```

- 编写连接程序

```python
import paho.mqtt.client as mqtt


def on_connect(mq_client, user_data, flags, rc):
    print("Connected with result code " + rc)
    client.subscribe("#")


def on_message(mq_client, user_data, msg):
    print(msg.topic + " " + str(msg.payload))


if __name__ == "__main__":
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect("0.0.0.0", 1883)
    client.publish("test", b"nice")
    client.loop_forever()
```
