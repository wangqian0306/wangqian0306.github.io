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

Dockerfile 

```dockerfile
FROM python:alpine

WORKDIR /opt

RUN apk add py3-yaml py3-build geos-dev py3-lxml gdal-dev py3-shapely proj-util gcc g++
RUN pip install Pillow pyproj six MapProxy
RUN mapproxy-util create -t base-config mapproxy

EXPOSE 8080

ENTRYPOINT ["mapproxy-util","serve-develop","-b","0.0.0.0"]
CMD ["/opt/mapproxy/mapproxy.yaml"]
```

Docker-compose file

```yaml
services:
  mapproxy:
    build: .
    image: mapproxy:latest
    ports:
      - "8080:8080"
    volumes:
      - ./xxx.yaml:/opt/mapproxy/mapproxy.yaml
      - <path>:/tmp/mapcenter/cache
```

#### 样例配置

代理服务可以进行如下配置：

```yaml
services:
  demo:
  wmts:
    md:
      title: demo
      abstract: demo
      online_resource: http://demo:8080

layers:
  - name: demo
    title: EPSG:3857
    sources: [ demo_cache ]

caches:
  demo_cache:
    sources: [ demo_tiles ]
    format: image/png
    grids: [ osm_grid ]

sources:
  demo_tiles:
    type: tile
    url: http://xxx.xxx.xxx:xxxx/xxxx/%(z)s/%(y)s/%(x)s.png
    grid: osm_grid

grids:
  osm_grid:
    name: EPSG:3857
    srs: EPSG:3857
    origin: nw
    num_levels: 19
    bbox: [ -20037508.3427892,-20037508.3427892,20037508.3427892,20037508.3427892 ]

globals:
  cache:
    base_dir: '/tmp/mapcenter/cache'
    lock_dir: '/tmp/mapcenter/cache/locks'
```

#### 手动缓存

如需缓存数据可以编写如下配置和命令：

```yaml
seeds:
  demo_seed:
    caches: [ demo_cache ]
    levels:
      to: 2
    refresh_before:
      mtime: ./reseed.time

cleanups:
  demo_remove:
    caches: [ demo_cache ]
    remove_all: true
```

```bash
mapproxy-seed -f mapcenter.yaml -s seed.yaml -c 1 --reseed-interval 14d --reseed-file reseed.time --progress-file .mapproxy_seed_progress
```

> 注：此命令代表重新缓存需要间隔 14 天，且保存执行过程和时间到缓存文件中，如果有需要可以配合 `--continue` 命令继续执行。

#### 独立部署

如果需要将缓存之后的文件单独部署为服务可以使用如下配置：

```text
services:
  demo:
  wmts:
    md:
      title: demo
      abstract: demo
      online_resource: http://demo:8080

layers:
  - name: demo
    title: EPSG:3857
    sources: [ demo_cache ]

caches:
  demo_cache:
    sources: []
    format: image/png
    grids: [ osm_grid ]

grids:
  osm_grid:
    name: EPSG:3857
    srs: EPSG:3857
    origin: nw
    num_levels: 19
    bbox: [ -20037508.3427892,-20037508.3427892,20037508.3427892,20037508.3427892 ]

globals:
  cache:
    base_dir: '/tmp/mapcenter/cache'
    lock_dir: '/tmp/mapcenter/cache/locks'
```

> 注：在缓存目录中应该存在如下名称的数据文件夹 `demo_cache_EPSG3857`,`tile_locks`

### 参考资料

[项目原文](https://github.com/mapproxy/mapproxy)

[配置样例](https://wiki.openstreetmap.org/wiki/MapProxy)
