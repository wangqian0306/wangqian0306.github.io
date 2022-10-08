---
title: Nginx 代理
date: 2022-10-08 23:09:32
tags:
- "Nginx"
id: nginx
no_word_count: true
no_toc: false
categories: "工具"
---

## Nginx

### 简介

Nginx 是一个高性能的 HTTP 和反向代理 web 服务器。

### 部署

#### 容器部署

```yaml
version: "3"
services:
  nginx:
    image: "nginx:latest" 
    ports:
      - "80:80"
    volumes:
      - nginx.conf:/etc/nginx/nginx.conf
```

### 常见使用模式

#### 代理加密

Nginx 提供了 ngx_http_auth_basic_module 模块实现让用户只有输入正确的用户名密码才允许访问 web。可以通过如下步骤，完成此需求：

1. 生成用户名密码文件

```bash
yum install -y httpd-tools
htpasswd -bc <file_path> <username> <password>
```

> 注：htpasswd命令选项参数说明:
> 
> -c 创建一个加密文件
> 
> -n 不更新加密文件，只将htpasswd命令加密后的用户名密码显示在屏幕上
> 
> -m 默认 htpassswd 命令采用 MD5 算法对密码进行加密
> 
> -d htpassswd 命令采用 CRYPT 算法对密码进行加密
> 
> -p htpassswd 命令不对密码进行进行加密，即明文密码
> 
> -s htpassswd 命令采用 SHA 算法对密码进行加密
> 
> -b htpassswd 命令行中一并输入用户名和密码而不是根据提示输入密码
> 
> -D 删除指定的用户

2. 部署 Nginx 服务

编写配置文件，并将密码文件放置在 `/etc/nginx/passwd` 即可：

```text
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;

    keepalive_timeout  65;

    server {
        listen 80;
        server_name localhost;

        location / {
            auth_basic           "closed site";
            auth_basic_user_file /etc/nginx/passwd;
            proxy_pass http://xxx.xxx.xxx;
            client_max_body_size 10m;
        }
    }
}
```

### 参考资料

[官方文档](http://nginx.org/en/docs/)

[容器页](https://hub.docker.com/_/nginx)
