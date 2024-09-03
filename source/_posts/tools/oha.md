---
title: oha
date: 2024-09-03 23:09:32
tags:
- "oha"
id: oha
no_word_count: true
no_toc: false
categories: 
- "工具"
---

## oha

### 简介

在看 Spring IO 会议中看到演示使用的网页测试工具，看着还可以。

### 安装

使用如下命令即可安装：

```bash
wget https://github.com/hatoo/oha/releases/download/v1.4.6/oha-linux-amd64
mv oha-linux-amd64 oha
chmod a+x oha
sudo mv oha /usr/local/bin/
```

### 简单使用

可以通过 nginx 容器来快速使用 oha

```bash
docker pull nginx
docker run --rm --name nginx-demo -p 8080:80 -d nginx
oha http://localhost:8080 -z 10s
```

### 参考资料

[官方项目](https://github.com/hatoo/oha)
