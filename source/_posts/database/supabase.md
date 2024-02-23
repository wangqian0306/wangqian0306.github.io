---
title: Supabase
date: 2021-08-04 22:12:59
tags: 
- "Supabase"
- "Next.js"
id: supabase
no_word_count: true
no_toc: false
categories: "前端"
---

## Supabase

### 简介

Supabase 是一个应用开发平台，可以实现如下功能：

- Postgres 数据库托管
- 身份验证和授权
- 自动生成的 API
  - REST
  - 实时订阅
  - GraphQL（测试版）
-  函数
  - 数据库函数
  - 边缘函数
- 文件存储
- 仪表盘

> 注：此项目当前还处于Public Beta

### 使用

#### 建立项目(Next.js + Supabase)

#### 本地部署(Docker)

使用如下命令即可在本地部署一套 Supabase 服务：

```bash
# Get the code
git clone --depth 1 https://github.com/supabase/supabase

# Go to the docker folder
cd supabase/docker

# Copy the fake env vars
cp .env.example .env

# Pull the latest images
docker compose pull

# Start the services (in detached mode)
docker compose up -d
```

待程序启动后即可访问 [http://localhost:8000](http://localhost:8000) 进入服务

### 参考资料

[官方项目](https://github.com/supabase/supabase)

[官方网站](https://supabase.com/)
