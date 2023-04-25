---
title: OpenSSL
date: 2023-04-25 23:52:33
tags:
- "Linux"
- "OpenSSL"
id: openssl
no_word_count: true
no_toc: false
categories: Linux
---

## OpenSSL

### 简介

OpenSSL 是一个强大的、商业级的、功能齐全的通用加密和安全通信工具包。

### 安装及使用

目前 CentOS 应该默认安装了 OpenSSL 如果没有可以使用如下命令安装：

```
yum -y install openssl openssl-devel
```

> 注：实际使用中 [Let's Encrypt](https://letsencrypt.org/) 的情况更多些。


可以使用如下命令生成相关证书：

- 生成 Private key 和 CSR

```bash
openssl req -nodes -newkey rsa:2048 -keyout custom.key -out custom.csr
```

- 生成 Pem 证书

```bash
openssl req -x509 -sha512 -nodes -days 730 -newkey rsa:2048 -keyout custom.key -out custom.pem
```

- 验证 CSR

```bash
openssl req -noout -text -in custom.csr
```

- 验证私钥

```bash
openssl rsa -in private.key -check
```

- 检查 Pem 有效期

```bash
openssl x509 -in custom.pem -noout -issuer -issuer_hash
```

### 参考资料

[官方文档](https://www.openssl.org/)

[官方项目](https://github.com/openssl/openssl)

[使用OpenSSL生成SSL证书的教程](https://www.cnblogs.com/big-keyboard/p/16869547.html)
