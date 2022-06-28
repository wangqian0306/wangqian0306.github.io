---
title: Heroku  
date: 2022-06-28 21:41:32
tags: "Heroku"
id: heroku
no_word_count: true
no_toc: false
---

## Heroku 

### 简介

Heroku 是一个基于托管容器系统的平台即服务(PaaS)，具有集成的数据服务和强大的生态系统，用于部署和运行现代应用程序。

### 使用

> 注：本文采用免费的账户进行测试。

- 需要确定应用程序的语言，Heroku 支持以下语言:
  - Node.js
  - Ruby
  - Java
  - PHP
  - Python
  - Go
  - Scala
  - Clojure
- 登陆 Heroku 官网进行注册并完成登陆及创建服务
- 选择应用程序的接入方式：
  - 使用 Heroku 作为版本管理工具
    - 安装 Heroku 客户端，并按照官网样例进行操作
  - 使用 GitHub 仓库作为版本管理工具
    - 配置 GitHub 地址，及程序运行配置项
    - 配置自动部署或手动部署服务

之后 Heroku 会自动下载项目依赖并将服务打包为以 `Debian` 为基础系统的容器将其部署在公网上，可以通过页面跳转快速进行访问。

> 注：试用的容器仅有 512m 内存且仅能有 2 个进程，在闲置 30 分钟后会进入睡眠状态。

### 插件

Heroku 提供了一些存储后端，可以作为插件的形式引入到项目中。

目前的插件大致分为以下类：

- Postgres
- Redis
- Kafka
- IPFS
- MongoDB (收费)
- MySQL (收费)

当项目需要以上依赖时，可以快速将项目运行起来。

### 参考资料

[Heroku 官网](https://www.heroku.com/)
