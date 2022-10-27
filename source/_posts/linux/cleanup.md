---
title: Linux 环境清理
date: 2022-10-27 21:57:04
tags: "Linux"
id: cleanup
no_word_count: true
no_toc: false
categories: Linux
---

## Linux 环境清理

### 简介

随着系统使用时间变长，日志和缓存等文件会占据很多的存储空间。故环境清理方式整合如下：

### 清理内容

- 用户缓存

```bash
rm -r /home/<user>/.cache/*
```

- journal 日志

```bash
rm -r /var/log/journal/*
```

- dnf/yum 缓存

```bash
dnf clean all
```

- docker 数据清除

```bash
docker system prune -a --volumes
```

- 清除 docker volumes

```bash
docker volume prune
```

- 清除 mvn repository

```bash
rm -rf ~/.m2/repository/*
```

- 清除 python package

```bash
pip freeze > modules.txt
pip uninstall -r modules.txt -y
```

- 清除 go pkg

```bash
rm -rf ~/.m2/pkg/*
```

### 参考资料

[Cleaning system](https://forums.fedoraforum.org/showthread.php?322190-Cleaning-system)
