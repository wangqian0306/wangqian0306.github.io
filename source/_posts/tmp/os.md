---
title: 操作系统
date: 2024-08-13 22:26:13
tags:
- "OS"
id: os
no_word_count: true
no_toc: false
---

## 操作系统

### 简介

在 B 站刷视频的时候发现自己大学的知识像没学一样，回头捡捡操作系统。

### xv6 教学操作系统的安装

首先可以通过如下命令安装相关依赖并拉取项目进行编译

```bash
sudo apt update
sudo apt upgrade -y 
sudo apt install build-essential qemu-system -y
git clone https://github.com/mit-pdos/xv6-public.git
cd xv6-public
make
```

在编译完成后即可使用如下命令进入系统：

```bash
make qemu-nox
```

> 注：退出系统时则需要同时按住 `Ctrl` + `A` 然后松开，接着按下 `X` 即可退出虚拟机。

如果需要清除之前编译的内容则可以使用如下命令：

```bash
make clean
```

### 参考资料

[MIT 公开课 6.S081 操作系统工程](https://www.bilibili.com/video/BV19k4y1C7kA/?spm_id_from=333.788.recommend_more_video.0&vd_source=519553681f7d25c891ac4cfdc33d4884)

[MIT 公开课 6.824 分布式系统](https://www.bilibili.com/video/BV1R7411t71W)

[MIT6.S081 中文翻译文本](https://mit-public-courses-cn-translatio.gitbook.io/mit6-s081)

[xv6-public](https://github.com/mit-pdos/xv6-public)
