---
title: htpc
date: 2023-08-14 21:57:04
tags:
- "Linux"
- "HTPC"
- "Jellyfin"
- "Sonarr"
- "Radarr"
- "Jackett"
id: htpc
no_word_count: true
no_toc: false
categories: Linux
---

## HTPC

### 简介

HTPC(Home Theater Personal Computer) 即家庭影院电脑。

本方案由以下组件构成：

- Sonarr：流媒体(电视)下载流程编辑软件
- Radarr：电影下载流程编辑软件
- NZBGet：nzb 格式下载器
- Deluge：种子下载器
- Bazarr：字幕刮削工具
- Jackett：网关
- Jellyfin：影音库

### 使用方式

编写 `docker-compose.yaml` 文件，内容如下：

```bash
version: "2.1"
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./sonarr/config:/config
      - ./content/tvseries:/tv
      - ./content/downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped
  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./radarr/config:/config
      - ./content/movies:/movies
      - ./content/downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped
  nzbget:
    container_name: nzbget
    image: linuxserver/nzbget:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./nzbget/config:/config
      - ./content/downloads:/downloads
    ports:
      - 6789:6789
    restart: unless-stopped
  deluge:
    image: lscr.io/linuxserver/deluge:latest
    container_name: deluge
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - DELUGE_LOGLEVEL=error
    volumes:
      - ./deluge/config:/config
      - ./content/downloads:/downloads
    ports:
      - 8112:8112
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
  jackett:
    image: lscr.io/linuxserver/jackett:latest
    container_name: jackett
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - AUTO_UPDATE=true
    volumes:
      - ./jackett/data:/config
      - ./content/downloads:/downloads
    ports:
      - 9117:9117
    restart: unless-stopped
  bazarr:
    container_name: bazarr
    image: linuxserver/bazarr
    restart: unless-stopped
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./bazarr/config:/config
      - ./content/movies:/movies
      - ./content/tv:/tv
```


### 参考资料

[Sonarr 项目](https://github.com/Sonarr/Sonarr)

[Sonarr 容器页](https://hub.docker.com/r/linuxserver/sonarr)

[Radarr 项目](https://github.com/Radarr/Radarr)

[Radarr 容器页](https://hub.docker.com/r/linuxserver/radarr)

[Jackett 项目](https://github.com/Jackett/Jackett)

[Jackett 容器页](https://hub.docker.com/r/linuxserver/jackett)

[Bazarr 项目](https://github.com/morpheus65535/bazarr)

[Bazarr 容器页](https://hub.docker.com/r/linuxserver/bazarr)

[NZBGet 项目](https://github.com/nzbget/nzbget)

[NZBGet 容器页](https://hub.docker.com/r/linuxserver/nzbget)

[Deluge 项目](https://hub.docker.com/r/linuxserver/deluge)

[Deluge 容器页](https://hub.docker.com/r/linuxserver/deluge)
