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

#### 构建容器

```dockerfile
FROM python:alpine

WORKDIR /opt

RUN apk add py3-pillow py3-yaml py3-build geos py3-lxml gdal py3-shapely proj-dev proj-util gcc g++
RUN pip install pyproj six MapProxy
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

### 参考资料

[项目原文](https://github.com/mapproxy/mapproxy)
