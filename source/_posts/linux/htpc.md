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
      - 58846:58846
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
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ./bazarr/config:/config
      - ./content/movies:/movies
      - ./content/tv:/tv
    ports:
      - 6767:6767
    restart: unless-stopped
```

在容器启动后需要按照下文顺序进行配置。

#### Deluge

访问 [http://localhost:8112](http://localhost:8112) 即可找到登录页面，然后按照如下指示进行配置：

- 在防火墙中开启 58846 端口
- 确认容器存储路径权限，例如 `downloads`
- 使用 admin/deluge 默认账户登录登录页面
- 配置连接信息 `<ip>` `58846` `admin` `deluge`, 若状态显示 Online 则证明配置无误 
- 配置文件下载地址为 `/downloasd`

> 注：配置完成后建议下个文件做验证

#### Jackett

访问 [http://localhost:9117](http://localhost:9117) 即可找到登录页面，然后按照如下指示进行配置：

- 配置 `Admin passoword`
- 配置 `Proxy type` `Proxy URL` `Proxy port` `Proxy username` `Proxy password`
- 添加 `Indexer` 例如：
  - 1337x
  - ACG.RIP
  - dmhy
  - EZTV
  - Nyaa.si
  - RuTracker(需要注册账号并配置密码)
  - The Pirate Bay
  - YTS
- 点击 `Test All` 按钮进行测试，若状态显示对勾则证明配置无误
- 点击对应 `Indexer` 中的搜索按钮即可进行资源搜索

> 注：为了保证后续流程也能正常识别所以建议在搜索的时候采用 [TVDB](https://thetvdb.com/search) 中的英文名。

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
