---
title: Nextcloud
date: 2022-12-19 23:09:32
tags:
- "Nextcloud"
- "PHP"
id: nextcloud
no_word_count: true
no_toc: false
categories: "工具"
---

## Nextcloud

### 简介

Nextcloud 是一款开源网盘服务。提供了 Windows Linux 和 mac 平台的客户端，可以方便的存储文件。

### 部署方式

#### Docker

编写 `docker-compose.yaml` 文件：

```yaml
version: '2'

volumes:
  nextcloud:
  db:

services:
  db:
    image: mariadb:10.5
    restart: always
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=<root_password>
      - MYSQL_PASSWORD=<password>
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud
    restart: always
    ports:
      - "8080:80"
    links:
      - db
    volumes:
      - nextcloud:/var/www/html
    environment:
      - MYSQL_PASSWORD=<password>
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
```

启动服务

```bash
docker-compose up -d 
```

进入容器本地卷，修改 `/var/lib/docker/volumes/<name>_nextcloud/_data/config/config.php` 文件，修改信任的域名部分

```text
'trusted_domains' => 
  array (
    0 => 'localhost:8080',
  )
```

例如：

```text
'trusted_domains' => 
  array (
    0 => 'localhost:8080',
    1 => '192.168.1.xxx',
    2 => 'xxx.xxx.xxx'
  )
```

登陆网页 [http://localhost:8080](http://localhost:8080) 并根据页面提示进行初始化即可

> 注：建议配合 [客户端](https://nextcloud.com/install/) 一起使用。

### 参考资料

[容器页](https://hub.docker.com/_/nextcloud)

[官方文档](https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation)
