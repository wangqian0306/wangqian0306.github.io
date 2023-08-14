---
title: aria2 下载器
date: 2023-02-07 21:57:04
tags:
- "Linux"
- "aria2"
id: aria2
no_word_count: true
no_toc: false
categories: Linux
---

## aria2 下载器

### 简介

aria2 是一款下载工具，AriaNg 是针对 aria2 研发的前端网页。

### 安装方式

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

### 前端网页

AriaNg 项目可以使用 Web 服务器进行部署，在 Nginx 服务器上部署的参考命令如下：

```bash
cd /usr/share/nginx/html
wget https://github.com/mayswind/AriaNg-DailyBuild/archive/master.zip
unzip master.zip
mv AriaNg-DailyBuild-master/* .
rm -rf AriaNg-DailyBuild-master
```

### 统一部署

可以使用编写 `docker-compose.yaml` 来快速部署服务

```yaml
version: '3'
services:
  ariang:
    image: wahyd4/aria2-ui
    ports:
      - "80:80"
      - "443:443"
    environment:
      - PUID=1000
      - PGID=1000
      - ENABLE_AUTH=true
      - RPC_SECRET=Hello
      - DOMAIN=https://example.com
      - ARIA2_SSL=false
      - ARIA2_USER=user
      - ARIA2_PWD=pwd
      - ARIA2_EXTERNAL_PORT=443
    volumes:
      - /yourdata:/data
      - /app/a.db:/app/filebrowser.db
      - /yoursslkeys/:/app/conf/key
      - /path/to/aria2.conf:/app/conf/aria2.conf
      - /path/to/aria2.session:/app/conf/aria2.session
```

### 参考资料

[官方项目](https://github.com/aria2/aria2)

[AriaNg 项目](https://github.com/mayswind/AriaNg)

[aria2-ariang-docker](https://github.com/wahyd4/aria2-ariang-docker)

[配置参考](https://aria2c.com/usage.html)
