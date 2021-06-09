---
title: ZeroMQ 入门
date: 2021-04-25 20:26:13
tags:
- "ZeroMQ"
- "Python"
id: zeromq
no_word_count: true
no_toc: false
categories: MQ
---

## 简介

ZeroMQ（也称为ØMQ，0MQ或ZMQ）是一种高性能的异步消息传递库，旨在用于分布式或高并发的应用程序中。
ZeroMQ 提供了一个消息队列，但是与传统面向消息的中间件不同，ZeroMQ 可以在没有专有消息代理服务的情况下运行。

[官方文档](https://zeromq.org/)

## 连接例程

- 安装依赖包

```bash
pip3 install pyzmq --user
```

- 编写服务端代码

```python
#
#   Hello World server in Python
#   Binds REP socket to tcp://*:5555
#   Expects b"Hello" from client, replies with b"World"
#

import time
import zmq

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind(f"tcp://*:5555")

while True:
    #  Wait for next request from client
    message = socket.recv()
    print(f"Received request: {message}")

    #  Do some 'work'
    time.sleep(1)

    #  Send reply back to client
    socket.send(b"World")
```

- 编写客户端代码

```python
#
#   Hello World client in Python
#   Connects REQ socket to tcp://localhost:5555
#   Sends "Hello" to server, expects "World" back
#

import zmq

context = zmq.Context()

#  Socket to talk to server
print("Connecting to hello world server…")
socket = context.socket(zmq.REQ)
socket.connect(f"tcp://localhost:5555")

#  Do 10 requests, waiting each time for a response
for request in range(10):
    print(f"Sending request {request} …")
    socket.send(b"Hello")

    #  Get the reply.
    message = socket.recv()
    print(f"Received reply {request} [ {message} ]")
```
