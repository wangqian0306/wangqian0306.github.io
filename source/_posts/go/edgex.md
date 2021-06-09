---
title: EdgeX 平台初探
date: 2021-04-16 21:41:32
tags: 
- "go"
- "EdgeX"
id: edgex
no_word_count: true
no_toc: false
categories: Go
---

## EdgeX 总体架构

![架构图](https://docs.edgexfoundry.org/1.3/general/EdgeX_architecture.png)

EdgeX 由以下四个基本模块构成

- 设备服务层 (DEVICE SERVICES)
- 核心服务层 (CORE SERVICES)
- 支持服务层 (SUPPORT SERVICES)
- 应用服务层 (APPLICATION SERVICES)

在上述层级的基础上扩展了以下服务

- 安全服务 (SECURITY)
- 系统管理服务 (MANAGEMENT)

### 设备服务层

设备服务层当中的服务可以自行选择进行安装，目前支持的内容如下：

- 测试设备
  - 随机数生成器(Go)
  - 虚拟设备(Go)
- 官方支持的设备
  - Modbus (Go)
  - MQTT (Go)
  - Grove (C)
  - Camera (Go)
  - Rest (Go)
  - BACnet (C)
- 研发中的设备
  - OPC UA (C)
  - Bluetooth (C)
  - GPS (C)
- 收费的连接器(IOTech 公司提供)
  - Modbus
  - BACnet
  - Bluetooth
  - CAN
  - EtherCAT
  - EtherNet/IP
  - FILE
  - zigbee
  - GPS
  - MQTT
  - OPC UA

### 核心服务层

核心服务层由以下微服务构成，必须在系统中安装：

|服务名|英文名|描述|
|:---:|:---:|:---:|
|核心数据存储微服务|Core data|集成了数据总线，完成接收数据并进行存储的功能|
|基础控制微服务|Command|调配系统上下层控制|
|元数据存储微服务|Metadata|存储元数据，关联设备与服务|
|配置中心微服务|Registry and Configuration|存储微服务配置|

> 注：配置中心微服务由 [Consul](https://www.consul.io/) 实现。

### 支持服务层

支持服务包括范围广泛的微服务，包括边缘分析。
正常的软件应用程序职责，如日志记录、调度和数据清理由支持服务层中的微服务执行。
支持服务层由以下微服务构成，如下服务都可以选择安装：

|服务名|英文名|描述|
|:---:|:---:|:---:|
|规则引擎微服务|Rules Engine|完成部分边缘分析功能|
|计划微服务|Scheduling|定时触发系统内的 REST API|
|警报微服务|Alerts and Notifications|输出报警信息|

> 注: 目前的规则引擎服务由 [EMQ X Kuiper](https://www.emqx.io/products/kuiper) 实现。

### 应用服务层

本层中尚且没有提供成品的微服务，而是提供了 SDK。

在 SDK 中主要实现了以下功能

- 基于 EdgeX 的消息总线触发器(支持 ZeroMQ, MQTT, Redis Streams)
- 基于 MQTT 的触发器
- 基于 HTTP 的触发器

### 安全服务

安全服务分为了以下功能

- 密钥管理（密钥）
- 网关
- 用户管理
- ACL 管理

以上功能是结合下列项目实现的:

- [KONG](https://konghq.com/)
- [Vault](https://www.vaultproject.io/)

> 注: 目前 KONG 项目支持 REST API 调用，Vault 有多种语言支持。

### 系统管理服务

系统管理服务目前有两种控制方式分别为

- System Management Agent
  - 通过对外开放接口的形式来让中心节点操控边缘端
- System Management Executor
  - 在集群内使用可执行文件的方式完成边缘端控制
