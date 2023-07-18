---
title: HTTPie
date: 2023-07-18 21:32:58
tags:
- "HTTP"
id: httpie
no_word_count: true
no_toc: false
categories: "工具"
---

## HTTPie

### 简介

HTTPie 是一个命令行HTTP客户端。其目标是尽可能人性化的实现 CLI 与 web 服务的交互。

### 安装方式

- Windows

```bash
choco install httpie
```

- CentOS

```bash
yum install epel-release
yum install httpie
```

### 常用命令

请求模板：

```bash
http [METHOD] URL [REQUEST_ITEM ...]
```

参数说明：

- `:` 参数代表此参数会被入 header 中
- `==` 参数代表请求参数会被放在 URL 中
- `=` 参数代表请求参数会被放在 body 中，如果数据类型是 JSON 则需要添加 `-j` 参数，如果数据类型是 FORM 则需要添加 `-f` 参数
- `:=` 参数代表请求参数会被放在 body 中，且此参数为非 String 类型
- `@` 参数代表请求参数是文件路径，文件会被放在 body 中
- `=@` 参数和 `=` 参数一样，只不过接收的是文件路径，并将其放置在参数内
- `:=@` 参数和 `:=` 参数一样，只不过接收的是文件路径，并将其放置在参数内

- GET 请求

```bash
https httpie.io/hello
```

- PUT 请求

```bash
http PUT pie.dev/put X-API-Token:123 name=John -v
```

- POST 请求

```bash
http POST pie.dev/post < files/data.json
```

### 参考资料

[官方文档](https://httpie.io/docs/cli)
