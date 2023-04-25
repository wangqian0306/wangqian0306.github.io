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

##### 本地运行版

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
      - NEXTCLOUD_ADMIN_USER=<username>
      - NEXTCLOUD_ADMIN_PASSWORD=<password>
      - NEXTCLOUD_TRUSTED_DOMAINS=<domains_xxx.xxx.xxx xxx.xxx.xxx>
```

启动服务

```bash
docker-compose up -d 
```

登陆网页 [http://localhost:8080](http://localhost:8080) 并根据页面提示进行初始化即可

> 注：建议配合 [客户端](https://nextcloud.com/install/) 一起使用。

##### 公网运行版

此处 NextCloud 提供了 [官方示例](https://github.com/nextcloud/docker/tree/master/.examples)

可以使用如下样例 `db.env`：

```text
MYSQL_PASSWORD=<password>
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
```

样例 `docker-compoes.yaml`：

```yaml
version: '3.9'

services:
  db:
    image: mariadb:10.6
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    restart: always
    volumes:
      - <mariadb_storage_path>:/var/lib/mysql:Z
    environment:
      - MYSQL_ROOT_PASSWORD=rainbowfish
      - MARIADB_AUTO_UPGRADE=1
      - MARIADB_DISABLE_UPGRADE_BACKUP=1
    env_file:
      - db.env

  redis:
    image: redis:alpine
    restart: always

  app:
    image: nextcloud:apache
    restart: always
    volumes:
      - <nextcloud_storage_path>:/var/www/html:z
    environment:
      - VIRTUAL_HOST=<hostname>
      - LETSENCRYPT_HOST=<hostname>
      - LETSENCRYPT_EMAIL=<email>
      - MYSQL_HOST=db
      - REDIS_HOST=redis
      - NEXTCLOUD_ADMIN_USER=<username>
      - NEXTCLOUD_ADMIN_PASSWORD=<password>
      - NEXTCLOUD_TRUSTED_DOMAINS=<domains_xxx.xxx.xxx xxx.xxx.xxx>
    env_file:
      - db.env
    depends_on:
      - db
      - redis
    networks:
      - proxy-tier
      - default

  cron:
    image: nextcloud:apache
    restart: always
    volumes:
      - <nextcloud_storage_path>:/var/www/html:z
    entrypoint: /cron.sh
    depends_on:
      - db
      - redis

  proxy:
    build: ./proxy
    restart: always
    ports:
      - 80:80
      - 443:443
    labels:
      com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy: "true"
    volumes:
      - certs:/etc/nginx/certs:z,ro
      - vhost.d:/etc/nginx/vhost.d:z
      - html:/usr/share/nginx/html:z
      - /var/run/docker.sock:/tmp/docker.sock:z,ro
    networks:
      - proxy-tier

  letsencrypt-companion:
    image: nginxproxy/acme-companion
    restart: always
    volumes:
      - certs:/etc/nginx/certs:z
      - acme:/etc/acme.sh:z
      - vhost.d:/etc/nginx/vhost.d:z
      - html:/usr/share/nginx/html:z
      - /var/run/docker.sock:/var/run/docker.sock:z,ro
    networks:
      - proxy-tier
    depends_on:
      - proxy

volumes:
  certs:
  acme:
  vhost.d:
  html:

networks:
  proxy-tier:
```

> 注：仅仅改动上述文件就可以，还需要引入样例中的 proxy 文件夹才可以运行。

运行方式：

```bash
docker-compose build --pull
docker-compose up -d
```

### 参考资料

[容器页](https://hub.docker.com/_/nextcloud)

[官方文档](https://docs.nextcloud.com/server/latest/admin_manual/installation/#installation)

[容器样例](https://github.com/nextcloud/docker/tree/master/.examples)
