---
title: Jellyfin
date: 2023-07-06 21:57:04
tags:
- "Linux"
- "Jellyfin"
id: jellyfin
no_word_count: true
no_toc: false
categories: Linux
---

## Jellyfin

### 简介

Jellyfin 是一个开源的媒体解决方案。

### 容器安装

```yaml
version: '3.5'
services:
  jellyfin:
    image: nyanmisaka/jellyfin:latest
    container_name: jellyfin
    user: <uid:gid>
    network_mode: 'host'
    volumes:
      - /path/to/config:/config
      - /path/to/cache:/cache
      - /path/to/media:/media
      - /path/to/media2:/media2:ro
    restart: 'unless-stopped'
    # Optional - alternative address used for autodiscovery
    environment:
      - JELLYFIN_PublishedServerUrl=http://example.com
    # Optional - may be necessary for docker healthcheck to pass if running in host network mode
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### 参考资料

[官方网站](https://jellyfin.org/)

[官方项目](https://github.com/jellyfin/jellyfin)

[中文整合版容器](https://hub.docker.com/r/nyanmisaka/jellyfin)