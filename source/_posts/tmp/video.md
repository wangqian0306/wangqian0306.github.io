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

可以使用 `ffmpeg` 命令进行推流：

```bash
ffmpeg -re -i input.mp4 -c:v libx264 -c:a aac -f flv rtmp://your_rtmp_server/live/stream_key
```

```bash
ffmpeg -re -i input.mp4 -c:v libx264 -c:a aac -f rtsp rtsp://your_rtsp_server/live/stream_key
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
    ports:
      - ${STREAM_PORT}:${STREAM_PORT}/udp
      - ${STREAM_PORT}:${STREAM_PORT}/tcp
      - 3001:3001
    volumes:
      - ./config/zlm/config.ini:/opt/media/conf/config.ini
    healthcheck:
      start_period: 30s
      test: [ "CMD", "curl", "-sS", "http://localhost:3001" ]
      timeout: 10s
      retries: 10
  wvp:
    build:
      context: ./buildFiles/wvp
    image: custom-wvp:latest
    restart: always
    environment:
      TZ: ${TZ}
      SIP_DOMAIN: ${SIP_DOMAIN}
      SIP_ID: ${SIP_ID}
      SIP_PASSWORD: ${SIP_PASSWORD}
      WVP_IP: ${WVP_IP}
      SIP_IP: ${SIP_IP}
      SHOW_IP: ${SHOW_IP}
      SDP_IP: ${SDP_IP}
      ZLM_IP: ${ZLM_IP}
      WVP_DB_PATH: ${WVP_DB_PATH}
      MYSQL_USERNAME: ${MYSQL_USERNAME}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      REDIS_HOST: ${REDIS_HOST}
      REDIS_PORT: ${REDIS_PORT}
      REDIS_PWD: ${REDIS_PASSWORD}
      STREAM_HOST: ${STREAM_HOST}
      DRUID_USER: ${DRUID_USER}
      DRUID_PASS: ${DRUID_PASS}
      JT1078_PORT: ${JT1078_PORT}
      JT1078_PASS: ${JT1078_PASS}
    ports:
      - 5060:5060
      - 5060:5060/udp
      - ${JT1078_PORT}:${JT1078_PORT}
      - ${JT1078_PORT}:${JT1078_PORT}/udp
      - 3000:3000
    volumes:
      - ./config/wvp:/config
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
```

具体配置参考项目实现即可。

> 注：目前版本界面不好用，登录不进去，需要修改源码。

### 参考资料

[Janus WebRTC Server](https://janus.conf.meetecho.com/)

[Ant Media Server](https://github.com/ant-media/Ant-Media-Server)

[MediaMTX](https://github.com/bluenviron/mediamtx)

[ZLMediaKit](https://github.com/ZLMediaKit/ZLMediaKit)
