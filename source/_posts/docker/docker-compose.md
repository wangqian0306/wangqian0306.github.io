---
title: Docker Compose 安装和基础命令
date: 2020-04-04 20:41:32
tags:
- "Container"
- "Docker Compose"
id: docker-compose
no_word_count: true
no_toc: false
categories: Container
---

## Docker Compose 安装

推荐使用如下命令进行安装(但是需要python3环境)

```bash
pip3 install docker-compose
```

## Docker Compose 样例文件

```yaml
version: '3'
services:
  demo: # 服务名
    build: ../../.. # Dockerfile 的相对路 build: . # Dockerfile 的相对路径
    image: demo:0.0.1 # 镜像名
    command: [ ] # 覆写容器启动命令
    ports: # 开启端口
      - "5000:5000" # 本地端口:容器端口
    environment:
      - JAVA_HOME=/opt/java/bin #环境变量(程序运行时生效，构建时不生效)
    deploy:
      resources:
        limits: # 资源限制
          cpus: '0.50'
          memory: 50M
    volumes:
      - /opt/data:/var/lib/mysql
#    depends_on: # 启动依赖
#      - db # 依赖服务名
```

[官方文档地址](https://docs.docker.com/compose/compose-file/)

## Docker Compose 常用命令

构建镜像
```bash
docker-compose build --no-cache
```

以后台模式启动容器
```bash
docker-compose up -d
```

查看容器运行状态
```bash
docker-compose ps
```

运行命令
```bash
docker-compose exec <服务名> <运行命令>
```

> 注: 使用bash或者sh进入交互式执行模式。

关闭容器
```
docker-compose down
```

## 使用 Makefile 优化使用流程

在实际项目中可以使用 Makefile 的方式来简化输入命令

## Make 命令安装

### windows

推荐使用 chocolate 安装

```bash
choco install make
```

### CentOS

```bash
yum install bash -y
```

### 文件样例

在项目中创建名为`Makefile`的文件然后填入如下内容即可：

```
IMAGE=docker.io/wangq/demo:latest
PROJECT=demo

.PHONY: build clean push save load

build:
	docker-compose build --no-cache

clean:
	docker rmi $(IMAGE)

push: build
	docker push $(IMAGE)

save:
	docker image save $(IMAGE) --output $(PROJECT).tar

load:
	docker load --input $(PROJECT).tar
```

### 使用方式

使用make命令中写明的快捷方式即可, 例如
```bash
make build
```