---
title: HTTPS 知识整理
date: 2020-06-30 23:26:13
tags: "HTTPS"
id: https
no_word_count: true
no_toc: false
categories: Web
---

## HTTPS 四次握手的流程

1. 客户端请求建立链接（443 端口），并向服务端发送一个随机数 client random 和客户端支持的加密方法，比如RSA公钥加密，此时是明文传输。
2. 服务端回复一种客户端支持的加密方法、一个随机数 server random 和服务器证书和非对称加密的公钥。
3. 客户端收到服务端的回复后利用服务端的公钥，加上新的随机数 premaster secret 通过服务端下发的公钥及加密方法进行加密，发送给服务器（80端口）。
4. 服务端收到客户端的回复，利用已知的加解密方式进行解密，同时利用 client random、server random 和 premaster secret 通过一定的算法生成 HTTP 链接数据传输的对称加密 key – session key。

## CA 在 HTTPS 当中的作用

CA 会用私钥将`服务器端的公钥+服务器域名+公钥的摘要`进行加密形成证书并将其将传输至客户端。

客户端会读取密文使用操作系统中内置的 CA 公钥进行解密，获取到服务端的公钥。

也就是说在第二次握手的过程中 CA 负责保证目标地址可信。

## 相关的关键词和说明

### HTTPS

HTTPS （全称：Hyper Text Transfer Protocol over SecureSocket Layer），是以安全为目标的 HTTP 通道，在HTTP的基础上通过传输加密和身份认证保证了传输过程的安全性。

### SSL 和 TLS

SSL(Secure Sockets Layer 安全套接字协议),及其继任者传输层安全（Transport Layer
 Security，TLS）是为网络通信提供安全及数据完整性的一种安全协议。

### X.509

X.509 是密码学里公钥证书的格式标准。 X.509 证书己应用在包括 TLS/SSL 在内的众多 Internet 协议里.同时它也用在很多非在线应用场景里。

## 免费 CA

[Let's Encrypt](https://letsencrypt.org/zh-cn/)
