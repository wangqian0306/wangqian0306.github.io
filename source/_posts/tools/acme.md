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

### 使用方式

#### acme.sh

使用如下命令即可完成安装：

```bash
curl https://get.acme.sh | sh -s email=<email>
```

如果没有 nginx 服务器则使用如下命令：

```bash
yum install -y socat
acme.sh --issue -d <domain> --standalone
```

如有 Nginx 服务器则使用如下命令：

```bash
acme.sh --issue -d <domain> --nginx /etc/nginx/conf.d/<domain>.conf
```

> 注：配置需手动修改，默认签发的证书会在 `~/.acme.sh/` 目录下

使用证书(nginx):

```bash
acme.sh --install-cert -d <domain> \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"
```

查看证书相关信息：

```bash
acme.sh --info -d <domain>
```

在安装完成后会自动添加 `cronjob` ，检查 cronjob 可以使用如下命令：

```bash
crontab  -l
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
