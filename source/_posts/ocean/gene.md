---
title: SequenceServer
date: 2024-08-08 23:09:32
tags:
- "GENE"
id: sequenceserver
no_word_count: true
no_toc: false
categories:
- "Ocean"
---

## SequenceServer

### 简介

SequenceServer 是基于 BLAST 的一款基因检索服务。

### 使用方式

首先需要拉取镜像：

```bash
docker pull wurmlab/sequenceserver:latest
```

然后需要准备查询目标基因库文件，将其放入 `db` 目录中，然后根据基因库文件生成索引：

```bash
mdkir db
cp /xxx/demo.fna /xxx/db
docker run --rm -v /xxx/db:/db -it wurmlab/sequenceserver:latest /sequenceserver/bin/sequenceserver -m
```

之后可以编写 `docker-compose.yaml` 文件管理服务：

```yaml
services:
  sequenceserver:
    image: wurmlab/sequenceserver
    ports:
      - "4567:4567"
    volumes:
      - "./db:/db"
```

使用如下命令运行文件即可：

```bash
docker-compose up -d
```

之后访问 [http://localhost:4567](http://localhost:4567) 在文本输入框内进行检索即可，样例如下：

```text
>demo
CTCCTAAAGGGCCCAGCAAGACCAGCTGGTTGATAGGTCGGATGTGGACGCGCTGCAAGGCGTTGAGCTAACCGATACTA
```

### 参考资料

[官方网站](https://sequenceserver.com/)

[项目源码](https://github.com/wurmlab/sequenceserver)
