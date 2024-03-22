---
title: SRS
date: 2024-03-22 22:26:13
tags:
- "SRS"
id: srs
no_word_count: true
no_toc: false
---

## SRS

### 简介

SRS 是一个开源的(MIT协议)简单高效的实时视频服务器，支持RTMP、WebRTC、HLS、HTTP-FLV、SRT、MPEG-DASH和GB28181等协议。SRS 媒体服务器和FFmpeg、OBS、VLC、 WebRTC 等客户端配合使用，提供流的接收和分发的能力，是一个典型的发布(推流)和订阅(播放)服务器模型。SRS 支持互联网广泛应用的音视频协议转换，比如可以将 RTMP或SRT， 转成 HLS 或 HTTP-FLV 或 WebRTC 等协议。

### 部署和使用

#### 使用容器部署

```yaml
version: '3'

services:
  srs-stack:
    image: registry.cn-hangzhou.aliyuncs.com/ossrs/srs-stack:5
    container_name: srs-stack
    restart: always
    ports:
      - "2022:2022"
      - "2443:2443"
      - "1935:1935"
      - "8000:8000/udp"
      - "10080:10080/udp"
    volumes:
      - ./data:/data
```

#### 使用介绍

在启动服务后会有使用样例的说明，具体请参照 [B站视频](https://space.bilibili.com/430256302)

> 注：有视频需求的尽量考虑公共平台。

### 参考资料

[SRS 官方网站](https://ossrs.net/lts/zh-cn/)
