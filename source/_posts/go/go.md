---
title: Go 语言入门
date: 2021-04-1 21:41:32
tags: "go"
id: go
no_word_count: true
no_toc: false
categories: Go
---

## 安装

使用如下命令即可安装：

```bash
wget https://go.dev/dl/go<vesion>.linux-amd64.tar.gz
sudo rm -rf /usr/local/go 
sudo tar -C /usr/local -xzf go<vesion>.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

> 注：PATH 环境变量记得写入对应 profile 里。

## gvm

gvm 是一款 go 语言的管理工具，使用如下命令即可安装：

```bash
sudo apt-get install bison
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
```

使用如下命令即可完成特定版本的安装：

```bash
gvm install go1.23.3
```

## 软件源配置

配置国内软件源

```bash
go env -w GOPROXY=https://goproxy.cn,direct
```

## 安装第三方项目或命令

由于安装的权限与位置是和运行的用户有关系的所以需要配置如下环境变量：

```bash
export PATH=$PATH:$(go env GOPATH)/bin
```

## 常用 Web 框架

[Beego](https://beego.vip/)

> 注：此框架被很多国内公司采用。官网列出的企业有：华为企业云，京东，淘宝，美团，链家等。

[Gin](https://gin-gonic.com/)

[Echo](https://echo.labstack.com/)

> 注: 滴滴采用。

[Iris](https://www.iris-go.com/)

> 注：官网描述为等价于 expressjs 的 go 语言框架

[revel](https://revel.github.io/)

## 常用学习资料

[官网](https://golang.google.cn/)

[在线编程学习网站](https://tour.go-zh.org/list)
