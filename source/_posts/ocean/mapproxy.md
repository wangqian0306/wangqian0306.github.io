---
title: MapProxy
date: 2022-07-05 23:09:32
tags:
- "Python"
id: mapproxy
no_word_count: true
no_toc: false
categories: "Ocean"
---

## MapProxy

### 简介

MapProxy 是地理空间数据的开源代理。它可以缓存、加速和转换现有地图服务中的数据，并为任何桌面或 web GIS 客户端提供服务。

### 安装和使用

#### 本地运行

依赖包安装：

```bash
dnf install -y python3-pyyaml python3-pyproj python3-lxml geos-devel gdal-devel python3-shapely 
pip install Pillow six MapProxy
```

服务检测：

```bash
mapproxy-util --version
```

创建配置样例：

```bash
mapproxy-util create -t base-config mapproxy
```

运行服务：

```bash
mapproxy-util serve-develop mapproxy/mapproxy.yaml
```

#### 容器安装

```dockerfile
FROM python:alpine

WORKDIR /opt

RUN apk add py3-yaml py3-build geos-dev py3-lxml gdal-dev py3-shapely proj-util gcc g++
RUN pip install Pillow pyproj six MapProxy
RUN mapproxy-util create -t base-config mapproxy

EXPOSE 8080

ENTRYPOINT ["mapproxy-util","serve-develop"]
CMD ["/opt/mapproxy/mapproxy.yaml"]
```

```yaml
version: "3.8"

services:
  mapproxy:
    build: .
    image: mapproxy:latest
    ports:
      - "8080:8080"
```

> 注：默认 run 起来没效果，目标地址直接访问是失效的，没有任何报错。暂时尝试其他方案。

### 参考资料

[项目原文](https://github.com/mapproxy/mapproxy)

[配置样例](https://wiki.openstreetmap.org/wiki/MapProxy)