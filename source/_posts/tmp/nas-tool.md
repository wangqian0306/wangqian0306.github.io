---
title: NAS 媒体库管理工具
date: 2024-04-17 22:26:13
tags:
- "HTPC"
id: nas-tool
no_word_count: true
no_toc: false
---

## NAS 媒体库管理工具

### 简介

nas-tool 是一款 NAS 媒体库管理工具，需要结合 qbittorrent 和 Jellyfin 进行使用。

### 使用方式

编写如下 `docker-compose.yaml` 文件：

```yaml
version: '3'
services:
  nas-tools:
    image: hsuyelin/nas-tools:latest
    ports:
      - 3000:3000
    volumes:
      - ./nas-config:/config
      - ./media:/media
    environment: 
      - PUID=3333
      - PGID=3333
      - UMASK=022
      - NASTOOL_AUTO_UPDATE=false
      - NASTOOL_CN_UPDATE=false
    restart: always
    hostname: nas-tools
    container_name: nas-tools
  qbittorrent-nox:
    container_name: qbittorrent-nox
    environment:
      - PGID=3333
      - PUID=3333
      - QBT_EULA=accept
      - QBT_VERSION=latest
      - QBT_WEBUI_PORT=8090
      - TZ=CST
      - UMASK=022
    image: qbittorrentofficial/qbittorrent-nox:latest
    ports:
      - 6881:6881/tcp
      - 6881:6881/udp
      - 8090:8090/tcp
    read_only: true
    stop_grace_period: 30m
    tmpfs:
      - /tmp
    tty: true
    hostname: qbittorrent
    volumes:
      - ./qbit-config:/config
      - ./media:/downloads
  jellyfin:
    image: nyanmisaka/jellyfin:latest
    container_name: jellyfin
    user: 3333:3333
    volumes:
      - ./jellyfin/config:/config
      - ./jellyfin/cache:/cache
      - ./media/movies:/media/movies
      - ./media/tv:/media/tv
    restart: 'unless-stopped'
    ports:
      - 8096:8096
    hostname: jellyfin
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=3333
      - PGID=3333
      - TZ=Asia/Shanghai
      - AUTO_UPDATE=true
    volumes:
      - ./jackett/data:/config
      - ./content/downloads:/downloads
    ports:
      - 9117:9117
    restart: unless-stopped
```

> 注：可以把 uid 和 gid 改为部署用户的对应值。

之后就可以访问下列地址按照提示进行配置：

[http://localhost:8090](http://localhost:8090) 配置 qBittorrent-nox 下载器

[http://localhost:8096](http://localhost:8096) 配置 Jellyfin 

[http://localhost:9117](http://localhost:9117) 配置 Jackett

[http://localhost:3000](http://localhost:3000) 配置 nas-tools 链接 Jellyfin, qBittorrent-nox(WEB-UI) 和 Jackett ，并且填入 TMDB API Key  

### 参考资料

[项目地址](https://github.com/hsuyelin/nas-tools)