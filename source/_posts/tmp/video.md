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

### ZLMediaKit

可以使用如下方式进行部署：

```yaml
services:
  media:
    image: zlmediakit/zlmediakit:master
    ports:
      - "10935:10935"
      - "5540:5540"
      - "6080:6080"
    volumes:
      - ./conf:/opt/media/conf
    restart: unless-stopped
```

[配置文件样例](https://github.com/ZLMediaKit/ZLMediaKit/blob/master/conf/config.ini) 

### 参考资料

[Janus WebRTC Server](https://janus.conf.meetecho.com/)

[Ant Media Server](https://github.com/ant-media/Ant-Media-Server)

[MediaMTX](https://github.com/bluenviron/mediamtx)

[ZLMediaKit](https://github.com/ZLMediaKit/ZLMediaKit)
