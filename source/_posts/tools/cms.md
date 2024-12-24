---
title: CMS
date: 2024-12-24 23:09:32
tags:
- "CMS"
id: cms
no_word_count: true
no_toc: false
categories: "工具"
---

## CMS

### 简介

CMS (Content Management System，内容管理系统)是一种软件平台，用于创建、管理和修改数字内容，通常用于网站内容的管理和发布。它使得没有技术背景的用户也能轻松地创建、编辑和管理网站内容，而不需要编写代码。

在这类产品中 Strapi 的自托管方式是完全免费的。

### 使用方式

首先需要搭建一个数据库用来存储数据文件，通过本地或是线上服务商都可以。之后需要创建数据库 `strapi`

```SQL
CREATE DATABASE <dbname>
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
```

然后就可以新建项目了：

```bash
npx create-strapi@latest
```

> 注：安装依赖的时间会比较长，此处 不要按回车键 。

按照提示创建项目即可。

创建完成后可以使用如下命令启动服务，进行测试：

```bash
npm run build
npm run start
```

### 统一部署

可以使用如下方式进行部署，编写项目 `Dockerfile` :

```Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ENV NODE_ENV=production

CMD ["npm", "run", "start"]
```

记得新建 `.dockerignore` 文件：

```text
node_modules
README.md
```

之后即可修改数据库容器的 `docker-compose.yaml` 文件即可：

```yaml
services:
  db:
    image: mysql:8
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
    volumes:
      - ./mysql:/var/lib/mysql
    ports:
      - "3306:3306"
  strapi:
    build: ../demo
    image: demo/strapi:latest
    environment:
      DATABASE_HOST: db
    ports:
      - "1337:1337"
```

之后使用 `docker-compose up -d` 更新服务，就可以访问到管理页面了。

### 参考资料

[官方文档](https://docs.strapi.io/)

[官方项目](https://github.com/strapi/strapi)
