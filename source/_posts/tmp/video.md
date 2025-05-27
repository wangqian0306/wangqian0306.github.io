---
title: 视频服务器
date: 2024-07-17 22:26:13
tags:
- "Video"
id: video-server
no_word_count: true
no_toc: false
---

## 视频服务器

### 简介

为了实现对接多个视频源并对外提供统一协议和接口，现针对市面上的视频服务器和协议进行了初步调研。

目前的解决方案：

- 现有的网络摄像头等大多采用 RTSP 协议
- 现有的视频会议服务大多采用 WebRTC 协议
- 现有的直播平台大多采用 RTMP 协议

### 服务搭建

### 视频推流

可以使用 `ffmpeg` 命令进行推流，安装方式如下：

```bash
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install ffmpeg-free -y
```

推流

- RTMP

```bash
ffmpeg -re -stream_loop -1 -i test.mp4 -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -f flv rtmp://<host>:<port>/live/stream
```

- RTSP

```bash
ffmpeg -re -stream_loop -1 -i test.mp4 -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -c:a aac -b:a 128k -rtsp_transport tcp -f rtsp rtsp://<host>:<port>/live/stream
```

- RTP

```bash
ffmpeg -re -stream_loop -1 -i test.mp4 -an -c:v libx264 -preset veryfast -maxrate 3000k -bufsize 6000k -c:a aac -b:a 128k -f rtp rtp://<host>:<port>
```

拉流：

使用 potplayer 填入地址即可。

### 视频处理

#### 减少分辨率并指定帧数

```bash
ffmpeg -i rtsp://xxxx:xxxx@xxx.xxx.xxx.xxx:xxx/xxx/xxx \
       -vf "scale=640:360:force_original_aspect_ratio=decrease,pad=640:360:(ow-iw)/2:(oh-ih)/2" \
       -c:v h264 \
       -b:v 512k \
       -r 25 \
       -f rtsp \
       rtsp://xxx.xxx.xxx.xxx:xxx/xxx/xxx
```

### WVP PRO

有对于视频平台有相应的国标 GB28181-2016 ，WEB VIDEO PLATFORM(wvp) 是一款网络视频平台，负责实现核心信令与设备后台管理功能。

[官方项目](https://github.com/648540858/wvp-GB28181-pro)

但是想运行需要很多的配置和代码修改，需要参照容器部署项目配合使用:

[容器部署项目](https://github.com/SaltFish001/wvp_pro_compose)

可以使用如下方式进行部署：

```yaml
services:
  redis:
    image: redis:7-alpine
    restart: always
    environment:
      TZ: ${TZ}
    ports:
      - 6379:6379
    healthcheck:
      start_period: 5s
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 5s
      timeout: 5s
      retries: 5
    command: redis-server --port 6379 --requirepass ${REDIS_PASSWORD}  --appendonly yes
  mysql:
    image: mariadb:10
    restart: always
    ports:
      - 3306:3306
    environment:
      - MARIADB_ROOT_PASSWORD=${MYSQL_PASSWORD}
      - MARIADB_DATABASE=wvp
      - MARIADB_USER=wvp
      - MARIADB_PASSWORD=${MYSQL_PASSWORD}
      - TZ=Asia/Shanghai
    volumes:
      - ./config/mysql/:/etc/mysql/conf.d
      - ./config/initSql/:/docker-entrypoint-initdb.d/
    healthcheck:
      start_period: 15s
      test: [ "CMD", "mysqladmin", "ping", "-h", "localhost" ]
      timeout: 20s
      retries: 10
  zlm:
    image: zlmediakit/zlmediakit:master
    restart: always
    environment:
      TZ: ${TZ}
    network_mode: "host"
    volumes:
      - ./config/zlm/config.ini:/opt/media/conf/config.ini
    healthcheck:
      start_period: 30s
      test: [ "CMD", "curl", "-sS", "http://localhost:3001" ]
      timeout: 10s
      retries: 10
  nginx:
    image: nginx:1-alpine
    ports:
      - "2000:2000"
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./config/nginx/www:/opt/ylcx/www
    environment:
      - TZ=Asia/Shanghai
  wvp:
    image: openjdk:11-jre-slim-buster
    environment:
      - TZ=Asia/Shanghai
    ports:
       - 5060:5060
       - 5060:5060/udp
       - 3000:3000
    volumes:
      - ./config/wvp:/app
    command: java -jar wvp.jar --spring.config.location=/app/application.yaml
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
      zlm:
        condition: service_healthy
```

具体配置参考项目实现即可。

> 注：目前版本界面不好用，登录不进去，需要修改源码。

测试摄像头则可以采用 [EasyGBD](https://github.com/EasyDarwin/EasyGBD)

若有配置不是很清楚也可用收费软件进行试用调试 [EasyGBS](https://www.tsingsee.com/download) 解压之后内含配置手册，依照进行配置即可。

### 参考资料

[Janus WebRTC Server](https://janus.conf.meetecho.com/)

[Ant Media Server](https://github.com/ant-media/Ant-Media-Server)

[MediaMTX](https://github.com/bluenviron/mediamtx)

[ZLMediaKit](https://github.com/ZLMediaKit/ZLMediaKit)

[EasyGBS通过抓包来分析不能播放的原因](https://www.bilibili.com/video/BV1x54y1e7A5)
