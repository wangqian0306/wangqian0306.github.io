---
title: Spring gzip
date: 2024-07-29 21:32:58
tags:
- "Java"
- "Spring Boot"
id: gzip
no_word_count: true
no_toc: false
categories:
- "Spring"
---

## Spring gzip

### 简介

遇到了需要返回大型 JSON 的需求，所以想对 JSON 进行一些压缩，降低带宽压力。

### 实现方式

编写如下 `application.yaml` 即可：

```yaml
server:
  compression:
    enabled: true
    min-response-size: 1024
```

> 注：在返回是 String 的情况下正常生效，但是在返回 Record 时默认压缩了，具体业务类定位到了 org.apache.coyote.CompressionConfig, 可能是在返回时没有读取到报文长度的问题。
