---
title: keytool
date: 2021-11-10 21:05:12
tags: 
- "JAVA"
- "keytool"
id: keytool
no_word_count: true
no_toc: false
categories: JAVA
---

## keytool

### 简介

keytool 是 JDK 自带的管理加密密钥、X.509 证书链和可信证书密钥库(数据库)的命令行工具。

### 命令相关参数

- 创建或者新增数据进入 Keystore
  - getcert
  - genkeypair
  - genseckey
  - importcert
  - importpassword
- 从另一个 Keystore 引入内容
  - importkeystore
- 生成证书请求
  - certreq
- 导出数据
  - exportcert
- 列出数据
  - list
  - printcert
  - printcertreq
  - printcrl
- 管理 Keystore
  - storepasswd
  - keypasswd
  - delete
  - changealias

### 使用方式

#### SSL/TLS

- 生成服务器 keystore 文件

```bash
keytool -genkey -alias tomcat -keypass 123456 -keyalg RSA -keysize 1024 -validity 365 -keystore ./tomcat.keystore -storepass 123456
```

- 生成客户端 p12 文件

```bash
keytool -genkey -alias client -keyalg RSA -storetype PKCS12 -keypass 123456 -storepass 123456 -keystore ./client.p12
```

- 生成客户端 cer 证书

```bash
keytool -export -alias client -keystore ./client.p12 -storetype PKCS12 -keypass 123456 -file ./client.cer
```

- 将客户端 cer 证书导入到 keystore 文件中

```bash
keytool -import -v -file ./client.cer -keystore ./tomcat.keystore
```

- 导出服务器 cer 证书(可选)

```bash
keytool -keystore ./tomcat.keystore -export -alias tomcat -file ./server.cer
```

证书生成完毕后可以在 SpringBoot 中进行如下配置，配置后即可使用 HTTPS 接口：

```text
server.ssl.key-store=classpath:tomcat.keystore
server.ssl.key-store-password=123456
server.ssl.keyStoreType=JKS
server.ssl.keyAlias:tomcat
```
