---
title: ACME
date: 2023-04-28 23:09:32
tags:
- "ACME"
id: acme
no_word_count: true
no_toc: false
categories: "工具"
---

## ACME

### 简介

Automatic Certificate Management Environment (ACME) 协议是一种通信协议，用于自动化生成和续期 SSL 证书。

### 安装

使用如下命令即可完成安装：

```bash
curl https://get.acme.sh | sh -s email=<email>
```

（可选）设定默认 CA 为 Let's Encrypt ：

> 注：在国内由于网络问题建议切换 CA 。

```bash
acme.sh --set-default-ca --server letsencrypt
```

#### 签发证书(独立签发)

如果没有 nginx 服务器则使用如下命令：

```bash
yum install -y socat
acme.sh --issue -d <domain> --standalone
```

#### 签发证书(Nginx)

先编写基础的服务配置文件：

```text
server {
    listen 80;
    server_name xxx.xxx.xxx.xxx;

    location /.well-known/acme-challenge/ {
        root /usr/share/nginx/xxx;
    }
}
```

然后测试配置文件并启动 Nginx:

```bash
nginx -t
systemctl enable nginx --now
```

然后再使用如下语句即可签发证书：

```bash
acme.sh --issue -d <domain> --nginx
```

#### 安装证书

签发完成后可以修改 Nginx 配置文件如下：

```text
server {
    listen 80;
    server_name xxx.xxx.xxx;

    location /.well-known/acme-challenge/ {
        root /usr/share/nginx/xxx;
    }

}

server {
    listen 443 ssl;
    server_name xxx.xxx.xxx;
    client_max_body_size 5M;
    ssl_certificate     /etc/nginx/ssl/xxx-cert.pem;
    ssl_certificate_key /etc/nginx/ssl/xxx-key.pem;

    location / {
        proxy_pass http://xxx.xxx.xxx.xxx;
    }

    location /static {
        alias /usr/share/nginx/xxx-static;
    }
}
```

然后使用如下命令，将签发完成的证书转存至 Nginx 配置目录中去：

> 注：此外 acme 还会启动定时任务，自动刷新续期。

```bash
acme.sh --install-cert -d xxx.xxx.xxx \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"
```

#### 其他指令

查看证书相关信息：

```bash
acme.sh --info -d <domain>
```

查看当前的域名清单：

```bash
acme.sh --list
```

手动强制刷新域名有效期：

```bash
acme.sh --renew -d <domain> --force
```

### 参考资料

[维基百科](https://en.wikipedia.org/wiki/Automatic_Certificate_Management_Environment)

[acme.sh 官方项目](https://github.com/acmesh-official/acme.sh)
