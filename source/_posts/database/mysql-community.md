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
