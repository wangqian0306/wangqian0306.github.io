---
title: Sonarr And Radarr
date: 2023-08-14 21:57:04
tags:
- "Linux"
- "Sonarr"
id: sonarr_radarr
no_word_count: true
no_toc: false
categories: Linux
---

## Sonarr 和 Radarr

### 简介

Sonarr 和 Radarr 订阅剧集或视频并发送下载功能的软件。Sonarr 主要针对于电视剧而 Radarr 主要针对电影，这两个软件都需要配置独立的视频源和下载器以及字幕库实现整个功能。

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
      - ./data:/config
      - ./tvseries:/tv
      - ./downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped
```


### 参考资料

[Sonarr 项目](https://github.com/Sonarr/Sonarr)

[Sonarr 容器页](https://hub.docker.com/r/linuxserver/sonarr)

[Radarr 项目](https://github.com/Radarr/Radarr)

[Radarr 容器页](https://hub.docker.com/r/linuxserver/radarr)

[Jackett 项目](https://github.com/Jackett/Jackett)
