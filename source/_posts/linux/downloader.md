---
title: Linux 下载器
date: 2023-02-07 21:57:04
tags:
- "Linux"
- "aria2"
id: downloader
no_word_count: true
no_toc: false
categories: Linux
---

## Linux 下载器

### Aria2 

aria2 是一款下载软件 AriaNg 是针对 aria2 研发的前端网页。

#### 安装方式

CentOS

```bash
yum install epel-release -y
yum install aria2 -y
```

Debian

```bash
apt-get install aria2 -y
```

然后编写配置文件 `/etc/aria2/aria2.conf`：

```text
dir=/downloads
continue=true
max-concurrent-downloads=5
max-connection-per-server=5
min-split-size=10M
input-file=/etc/aria2/aria2.session
save-session=/etc/aria2/aria2.session
enable-rpc=true
rpc-allow-origin-all=true
rpc-listen-all=true
rpc-listen-port=6800
listen-port=51413
enable-dht=false
enable-peer-exchange=false
seed-ratio=0
bt-seed-unverified=true
```

最后可以通过如下命令启动服务：

```bash
aria2c --conf-path=/etc/aria2/aria2.conf
```

#### 前端网页

AriaNg 项目可以使用 Web 服务器进行部署，在 Nginx 服务器上部署的参考命令如下：

```bash
cd /usr/share/nginx/html
wget https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip
unzip master.zip
mv AriaNg-DailyBuild-master/* .
rm -rf AriaNg-DailyBuild-master
```

#### 统一部署

可以使用编写 `docker-compose.yaml` 来快速部署服务

```yaml
version: "3.8"
services:
  Aria2-Pro:
    container_name: aria2-pro
    image: p3terx/aria2-pro
    environment:
      - PUID=65534
      - PGID=65534
      - UMASK_SET=022
      - RPC_SECRET=P3TERX
      - RPC_PORT=6800
      - LISTEN_PORT=6888
      - DISK_CACHE=64M
      - IPV6_MODE=false
      - UPDATE_TRACKERS=true
      - CUSTOM_TRACKER_URL=
      - TZ=Asia/Shanghai
    volumes:
      - ${PWD}/aria2-config:/config
      - ${PWD}/aria2-downloads:/downloads
# If you use host network mode, then no port mapping is required.
# This is the easiest way to use IPv6 networks.
    network_mode: host
#    network_mode: bridge
#    ports:
#      - 6800:6800
#      - 6888:6888
#      - 6888:6888/udp
    restart: unless-stopped
# Since Aria2 will continue to generate logs, limit the log size to 1M to prevent your hard disk from running out of space.
    logging:
      driver: json-file
      options:
        max-size: 1m

# AriaNg is just a static web page, usually you only need to deploy on a single host.
  AriaNg:
    container_name: ariang
    image: p3terx/ariang
    command: --port 6880 --ipv6
    network_mode: host
#    network_mode: bridge
#    ports:
#      - 6880:6880
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: 1m
```

### Deluge 

一体化容器部署

```yaml
version: "2.1"
services:
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
```

### qBittorrent

一体化容器部署

```yaml
version: "2.1"
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - WEBUI_PORT=8080
    volumes:
      - ./qbittorrent/config:/config
      - ./content/downloads:/downloads
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped
```

### 参考资料

[Aria2 项目](https://github.com/aria2/aria2)

[AriaNg 项目](https://github.com/mayswind/AriaNg)

[aria2-ariang-docker](https://github.com/wahyd4/aria2-ariang-docker)

[配置参考](https://aria2c.com/usage.html)

[Aria2 Pro - 更好用的 Aria2 Docker 容器镜像](https://github.com/P3TERX/Aria2-Pro-Docker)
