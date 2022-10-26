---
title: Consul
date: 2022-06-23 23:09:32
tags:
- "Consul"
id: consul
no_word_count: true
no_toc: false
categories: "工具"
---

## Consul

### 简介

Consul 是一种多网络管理工具，提供功能齐全的服务网格(ServiceMesh)解决方案，可解决运营微服务和云基础设施（多云和混合云）的网络和安全挑战。

### 部署

> 注：此方案仅供测试，在生产环境上部署请参照官方文档。

```yaml
version: '3.8'

services:
  consul-server1:
    image: consul
    ports:
      - 8510:8500
      - 8310:8300
      - 8311:8301
      - 8312:8302
      - 8610:8600
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    command: >
      agent -server -ui
      -node=consul-server1
      -bootstrap-expect=3
      -client=0.0.0.0
      -retry-join=consul_consul-server2
      -retry-join=consul_consul-server3
      -retry-join=consul_consul-server4
      -data-dir=/consul/data
      -datacenter=dc1
    volumes:
      - <path>:/consul/data
    networks:
      consul-net:
  consul-server2:
    image: consul
    ports:
      - 8520:8500
      - 8320:8300
      - 8321:8301
      - 8322:8302
      - 8620:8600
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    command: >
      agent -server -ui
      -node=consul-server2
      -bootstrap-expect=3
      -client=0.0.0.0
      -retry-join=consul_consul-server1
      -retry-join=consul_consul-server3
      -retry-join=consul_consul-server4
      -data-dir=/consul/data
      -datacenter=dc1
    volumes:
      - <path>:/consul/data
    networks:
      consul-net:
  consul-server3:
    image: consul
    ports:
      - 8530:8500
      - 8330:8300
      - 8331:8301
      - 8332:8302
      - 8630:8600
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    command: >
      agent -server -ui
      -node=consul-server3
      -bootstrap-expect=3
      -client=0.0.0.0
      -retry-join=consul_consul-server1
      -retry-join=consul_consul-server2
      -retry-join=consul_consul-server4
      -data-dir=/consul/data
      -datacenter=dc1
    volumes:
      - <path>:/consul/data
    networks:
      consul-net:
  consul-server4:
    image: consul
    ports:
      - 8540:8500
      - 8340:8300
      - 8341:8301
      - 8342:8302
      - 8640:8600
    environment:
      - CONSUL_BIND_INTERFACE=eth0
    command: >
      agent -server -ui
      -node=consul-server4
      -bootstrap-expect=3
      -client=0.0.0.0
      -retry-join=consul_consul-server1
      -retry-join=consul_consul-server2
      -retry-join=consul_consul-server3
      -data-dir=/consul/data
      -datacenter=dc1
    volumes:
      - <path>:/consul/data
    networks:
      consul-net:
networks:
  consul-net:
    ipam:
      driver: default
      config:
        - subnet: "192.168.87.0/24"
```

### API 

Consul 中的服务是不会随着平台而变化的，如需编辑可调用 API ：

```http request
### 检查服务状态
GET http://<host>:8500/v1/agent/checks

### 查看服务列表
GET http://<host>:8500/v1/agent/services

### 刪除空服务
PUT http://<host>:8500/v1/agent/service/deregister/gateway-consul
```

### 参考资料

[官方文档](https://www.consul.io/docs/k8s/installation/install)
