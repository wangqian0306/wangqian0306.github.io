---
title: AutoBangumi
date: 2023-08-23 22:26:13
tags:
- "Jellyfin"
id: autobangumi
no_word_count: true
no_toc: false
---

## AutoBangumi

### 简介

AutoBangumi 一个是基于 Mikan Project、qBittorrent 的全自动追番整理下载工具。只需要在 Mikan Project 上订阅番剧，就可以全自动追番。并且整理完成的名称和目录可以直接被 Plex、Jellyfin 等媒体库软件识别，无需二次刮削。

### 使用

```yaml
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    ports:
      - 8989:8989
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - WEBUIPORT=8989
    volumes:
      - ./qbittorrent/config:/config
      - ./content/downloads:/downloads
    restart: unless-stopped
  autobangumi:
    image: estrellaxd/auto_bangumi:latest
    container_name: autobangumi
    ports:
      - 7892:7892
    depends_on:
      - qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./autobangumi/config:/app/config
      - ./autobangumi/data:/app/data
    restart: unless-stopped
```

配置流程：

- 进入 qBittorrent 配置账号密码下载路径
- 进入 AutoBangumi WebUI 然后配置 qBittorrent 的链接信息
- 在 MiKan Project 中注册账号订阅内容然后获取到 token
- 将 token 导入 AutoBangumi 中

### 参考资料

[项目官网](https://www.autobangumi.org/)
