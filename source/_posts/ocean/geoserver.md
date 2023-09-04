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

> 注：若没有数据可以不填写数据目录。

之后即可访问 [http://localhost:8080/geoserver/web](http://localhost:8080/geoserver/web) ，然后使用如下账号密码即可完成登录。

账号：admin

密码：geoserver

### 常见问题

#### 忘记密码

在容器中的 `/opt/geoserver_data/security/usergroup/default` 目录中有一个 `users.xml` 文件，该文件存储的就是用户有和密码信息。可以通过修改该文件的方式来完成密码重置，默认的用户信息如下：
 
```xml
<user enabled="true" name="admin" password="digest1:D9miJH/hVgfxZJscMafEtbtliG0ROxhLfsznyWfG38X2pda2JOSV4POi55PQI4tw"/>
```

> 注：此处情况仅适用于默认加密方式，如果还出了问题就直接覆盖 `security` 文件夹。 

### 参考资料

[官方文档](https://geoserver.org/)
