---
title: AdGuardHome
date: 2023-02-17 22:26:13
tags:
- "AdGuardHome"
id: ad-guard
no_word_count: true
no_toc: false
---

## AdGuard Home

### 简介

AdGuard Home是一款用于拦截广告和跟踪的全网络软件，通过作为 DNS 服务器的方式来为所有家庭设备提供服务。

### 安装及配置

#### Docker

创建 `work`, `conf` 文件夹，编写如下 `docker-compose.yaml` 文件：

```yaml
version: "3.8"
services:
  adguardhome:
    image: adguard/adguardhome
    container_name: adguardhome
    ports:
      - "53:53"
      - "80:80"
      - "443:443"
      - "3000:3000"
    volumes:
      - ./work:/opt/adguardhome/work
      - ./conf:/opt/adguardhome/conf
```

> 注：此处还支持很多其他端口和功能，如有需要可以参照官方文档进行修改。

使用如下命令启动服务：

```bash
docker-compose up -d
```

访问如下地址即可完成初始化，及设置：

[http://localhost:3000](http://localhost:3000)

### 参考资料

[官方项目](https://github.com/AdguardTeam/AdGuardHome)

[容器主页](https://hub.docker.com/r/adguard/adguardhome)

[视频教程](https://www.bilibili.com/video/BV19B4y1s7n4)

[anti-AD 规则列表](https://github.com/privacy-protection-tools/anti-AD)

[Adguard 过滤规则分享](https://wsgzao.github.io/post/adguard/)
