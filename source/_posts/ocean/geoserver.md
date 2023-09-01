---
title: GeoServer
date: 2023-09-01 23:09:32
tags:
- "GeoServer"
- "Linux"
id: geoserver
no_word_count: true
no_toc: false
categories: "Ocean"
---

## GeoServer

### 简介

GeoServer 是一款支持多种 GIS 协议类型的自建服务器。

### 部署方式

可以使用 docker 部署

```yaml
version: '3'
services:
  geoserver:
    image: docker.osgeo.org/geoserver:2.24.x
    ports:
      - "8080:8080"
    environment:
      - INSTALL_EXTENSIONS=true
      - STABLE_EXTENSIONS=ysld,h2
    volumes:
      - ./data:/opt/geoserver_data
```

### 参考资料

[官方文档](https://geoserver.org/)
