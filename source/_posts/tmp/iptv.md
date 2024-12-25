---
title: IPTV
date: 2023-09-12 21:41:32
id: iptv
no_word_count: true
no_toc: false
---

## IPTV

### 简介

网络协议电视(Internet Protocol Television) 是宽带电视的一种。但是由于不同的运营商采用了不同的逻辑去处理 IPTV。所以在使用上需要找到适合自己的播放列表。

### 常见工具

#### wtv

[项目地址](https://github.com/biancangming/wtv)

原来叫 wtv 现在改名叫 一个橙子 pro 工具箱(当前仅支持 Windows 平台)，使用方式：

- 传入直播源
- 点击检测
- 保存检测完成且处于可用状态的直播源

> 注：延时超过 1000ms 可能都不会好用。

#### iptvchecker

[项目地址](https://github.com/zhimin-dev/iptv-checker)

使用方式，编写如下 `docker-compose.yaml` 文件:

```yaml
services:
  website:
    image: zmisgod/iptvchecker:latest
    ports:
      - "8081:8080"
    restart: always
```

启动容器，然后访问 [http://localhost:8081](http://localhost:8081) 即可上传文件进行测试。

### 参考资料

[iptv-org 直播源](https://github.com/iptv-org/iptv)

[zbefine 直播源](https://github.com/zbefine/iptv)

[wcb1969 直播源](https://github.com/wcb1969/iptv)

[wtv 直播源](https://github.com/biancangming/wtv/wiki/%E6%9C%80%E6%96%B0IPTV%E7%9B%B4%E6%92%AD%E6%BA%90m3u8%E4%B8%8B%E8%BD%BD%EF%BC%8C%E7%94%B5%E8%A7%86%E7%9B%B4%E6%92%AD%E7%BD%91%E7%AB%99%E6%8E%A8%E8%8D%90#%E6%9C%89%E7%94%A8%E7%BD%91%E7%AB%99%E6%8E%A8%E8%8D%90%E6%8E%88%E4%BA%BA%E4%BB%A5%E9%B1%BC%E4%B8%8D%E5%A6%82%E6%8E%88%E4%BA%BA%E4%BB%A5%E6%B8%94%E6%9C%89%E8%83%BD%E5%8A%9B%E7%9A%84%E8%87%AA%E5%B7%B1%E5%8E%BB%E7%8E%A9)
