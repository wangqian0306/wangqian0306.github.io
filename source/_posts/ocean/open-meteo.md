---
title: Open-Meteo
date: 2024-07-04 23:09:32
tags:
- "Container"
id: open-meteo
no_word_count: true
no_toc: false
categories: "Ocean"
---

## Open-Meteo

### 简介

Open-Meteo 是一个开源天气 API，可供非商业用途免费使用。无需 API 密钥。其中包含很多预测模型的数据。

### 使用方式

可以编写如下 `docker-compose.yaml` 使用： 

```yaml
services:
  open-meteo:
    image: ghcr.io/open-meteo/open-meteo
    volumes:
      - "./data:/app/data"
    ports:
      - '8080:8080'
    command: ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```

### 数据同步

使用 `openmeteo-api sync` 命令可以从 AWS S3 上下载最新的数据集到本地，此处可以自己构建一个镜像利用 cron 命令实现定时拉取数据。

编写 `sync-cron` ：

```text
* * * * * /usr/local/bin/openmeteo-api sync ecmwf_ifs04 temperature_2m >> /var/log/cron.log 2>&1

```

编写 `Dockerfile` ：

```text
FROM ubuntu:jammy

RUN apt-get update && apt-get -y install cron gpg curl

RUN curl -L https://apt.open-meteo.com/public.key | gpg --dearmour -o /etc/apt/trusted.gpg.d/openmeteo.gpg

RUN echo "deb [arch=amd64] https://apt.open-meteo.com jammy main" | tee /etc/apt/sources.list.d/openmeteo-api.list

RUN apt-get update

RUN apt-get install openmeteo-api -y

COPY sync-cron /etc/cron.d/sync-cron

RUN chmod 0644 /etc/cron.d/sync-cron

RUN crontab /etc/cron.d/sync-cron

RUN touch /var/log/cron.log

CMD cron && tail -f /var/log/cron.log
```

之后编写 `docker-compose.yaml` ：

```yaml
services:
  open-meteo:
    image: ghcr.io/open-meteo/open-meteo
    volumes:
      - "./data:/app/data"
    ports:
      - '8080:8080'
    command: ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
  sync:
    build: .
    image: cron-meteo:latest
    volumes:
      - "./data:/var/lib/openmeteo-api/data"
```

使用如下命令构建容器：

```bash
docker-compose build --no-cache
```

使用如下命令运行容器：

```bash
docker-compose up -d
```

### 参考资料

[官网](https://open-meteo.com/)

[同步教程](https://github.com/open-meteo/open-meteo/blob/main/docs/getting-started.md)