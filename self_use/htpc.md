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
- Deluge：种子下载器
- Bazarr：字幕刮削工具
- Jackett：网关
- Jellyfin：影音库
- Jellyseerr: 请求管理和媒体发现工具

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
  jellyfin:
    image: nyanmisaka/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000
    volumes:
      - ./jellyfin/config:/config
      - ./jellyfin/cache:/cache
      - ./content/movies:/media/movies
      - ./content/tv:/media/tv
    restart: 'unless-stopped'
    ports:
      - 8096:8096
  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - LOG_LEVEL=error
      - TZ=Asia/Shanghai
    ports:
      - 5055:5055
    volumes:
      - ./jellyseerr/config:/app/config
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
- 点击 `Preferebce` 按钮
  - 选择 `Plugins` 插件
    - 启用 `Label` 插件

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
  - 52BT

- 点击 `Test All` 按钮进行测试，若状态显示对勾则证明配置无误
- 点击对应 `Indexer` 中的搜索按钮即可进行资源搜索

> 注：为了保证后续流程也能正常识别所以建议在搜索的时候采用 [TVDB](https://thetvdb.com/search) 中的英文名。可以访问 [Indexer 推荐站](http://www.ptyqm.com/) 新增一些资源检索站。

#### Radarr

访问 [http://localhost:7878](http://localhost:7878) 即可找到登录页面，然后按照如下指示进行配置：

- 进入 `Settings` 配置项
  - 选择 `Media Management` 子项
    - 开启 `Rename Movies` 功能
    - 编辑 `Root Folders` 添加 `/downloads` 文件夹
  - 选择 `Profiles` 子项
    - 点击 `Any` 类型
      - 勾选所有类型(包括 `Unknow`)
      - 将语言设置为 `Any` 即，不筛选下载语言，并针对想要的分辨率进行排序
    - 点击其他类型
      - 将语言设置为 `Any` 即，不筛选下载语言，并针对想要的分辨率进行排序
  - 选择 `Quality` 子项
    - 设置 `Unknow` 格式的大小限制为 `Unlimit`
  - 选择 `Indexers` 子项
    - 添加 `Torznab` 格式的 `Indexer` (此处添加方式参见 Jackett) 
  - 选择 `Download Clients` 子项
    - 添加 `deluge` 即可 (此处添加内容参见 deluge 部分) 
    - 添加远程路径映射 (全部映射至 `/downloads` 即可)

#### Sonarr 

访问 [http://localhost:8989](http://localhost:8989) 即可找到登录页面，然后按照如下指示进行配置：

- 进入 `Settings` 配置项
  - 选择 `Media Management` 子项
    - 开启 `Rename Episodes` 功能
    - 编辑 `Root Folders` 添加 `/downloads` 文件夹
  - 选择 `Profiles` 子项
    - 点击 `Any` 类型
      - 勾选所有类型(包括 `Unknow`)
      - 将语言设置为 `Any` 即，不筛选下载语言
    - 点击其他类型
      - 将语言设置为 `Any` 即，不筛选下载语言
  - 选择 `Quality` 子项
    - 设置 `Unknow` 格式的大小限制为 `Unlimit`
  - 选择 `Indexers` 子项
    - 添加 `Torznab` 格式的 `Indexer` (此处添加方式参见 Jackett) 
  - 选择 `Download Clients` 子项
    - 添加 `deluge` 即可 (此处添加内容参见 deluge 部分) 
    - 添加远程路径映射 (全部映射至 `/downloads` 即可)
  
#### Bazarr

访问 [http://localhost:6767](http://localhost:6767) 即可找到登录页面，然后按照如下指示进行配置：

- 进入 `Settings` 配置项
  - 选择 `General` 子项
    - 配置 `Proxy`
    - 关闭 `Analyics` (可选)
  - 选择 `Languages` 子项
    - 在 `Lanuguage Filter` 中添加所需语言
  - 选择 `Providers` 子项，并添加如下供应商
    - `YIFY Subtitles`
    - `OpenSubtitles.org` (需要账号)
  - 选择 `Sonarr` 子项
    - 开启开关
    - 配置链接地址
  - 选择 `Radarr` 子项
    - 开启开关
    - 配置链接地址
- 进入 `System` 配置项
  - 选择 `Backups` 子项
    - 点击 `Backup Now` 进行备份

#### Jellyseerr

访问 [http://localhost:5055](http://localhost:5055) 即可找到登录页面，然后按照如下指示进行配置：

- 选择使用 Jellyfin 模式进行登录
  - 输入链接地址 `http://jellyfin:8096` 
  - 输入任意邮箱
  - 输入 Jellyfin 用户名
  - 输入 Jellyfin 密码

#### 爱盼-网盘资源搜索

```bash
git clone https://github.com/unilei/aipan-netdisk-search.git
cd aipan-netdisk-search
docker-compose build --no-cache
docker-compose up -d
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

[Jellyfin 项目](https://github.com/jellyfin/jellyfin)

[Jellyfin 官方网站](https://jellyfin.org/)

[Jellyseerr 项目](https://github.com/Fallenbagel/jellyseerr)

[Jellyseerr 容器页](https://hub.docker.com/r/fallenbagel/jellyseerr)
