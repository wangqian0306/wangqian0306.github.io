---
title: MySQL 安装
date: 2021-08-04 22:12:59
tags: "MySQL"
id: mysql
no_word_count: true
no_toc: false
categories: MySQL
---

## MySQL 安装

### 单机安装

访问 [Yum Repository](https://dev.mysql.com/downloads/repo/yum/) 下载仓库包，然后进行安装：

```bash
yum localinstall mysql80-community-release-el7-3.noarch.rpm
yum install mysql-community-server
systemctl enable mysqld --now
```

检查临时密码

```bash
grep 'temporary password' /var/log/mysqld.log
```

进行登录

```bash
mysql -uroot -p
```

更新密码

```bash
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
```

开放远程访问：

```sql
use mysql;
update user set host = '%' where user = '<user>';
flush privileges;
```

> 注：本文以 CentOS 7 为例，详情参照 [官方文档](https://dev.mysql.com/doc/mysql-linuxunix-excerpt/5.7/en/linux-installation.html)

### 容器化安装

```bash
version: '3'
services:
  db:
    image: mysql:latest
    command: --default-authentication-plugin=mysql_native_password
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
```

### 容器化安装集群

```yaml
version: "3"
services:
  mysql-1:
    image: mysql:8
    environment:
      - TZ=CST-8
      - MYSQL_ROOT_PASSWORD=123456
    ports:
      - "13062:3306"
    command: --character-set-server=utf8 --collation-server=utf8_general_ci
    volumes:
      - ./mysql-volume/my-1.cnf:/etc/mysql/my.cnf
      - ./mysql-volume/data/mysql-1:/var/lib/mysql
  mysql-2:
    image: mysql:8
    environment:
      - TZ=CST-8
      - MYSQL_ROOT_PASSWORD=123456
    ports:
      - "13061:3306"
    command: --character-set-server=utf8 --collation-server=utf8_general_ci
    volumes:
      - ./mysql-volume/mysql-2:/var/lib/mysql
      - ./mysql-volume/data/my-2.cnf:/etc/mysql/my.cnf
  mysql_nginx:
    image: nginx:1.19.2
    ports:
      - "3306:3306"
    volumes:
      - ./nginx-volume/nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - mysql-1
```

my.cnf 样例

```text
[mysqld]
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
secure-file-priv= NULL

server_id=2
log-bin= mysql-bin

replicate-ignore-db=mysql
replicate-ignore-db=sys
replicate-ignore-db=information_schema
replicate-ignore-db=performance_schema

default_authentication_plugin=mysql_native_password

read-only=0
relay_log=mysql-relay-bin
log-slave-updates=on

max_connections=5000

mysqlx_max_connections=5000

# Custom config should go here
!includedir /etc/mysql/conf.d/
```

nginx.conf 样例

```text
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    use   epoll;
    worker_connections  1024;
}

stream {
    upstream mysql {
        server mysql-1:3306 max_fails=3 fail_timeout=30s;
        server mysql-2:3306 backup;
    }
 
    server {
        listen    3306;
        proxy_connect_timeout 3000s;
        proxy_timeout 6000s;
        proxy_pass mysql;
    }
}
```