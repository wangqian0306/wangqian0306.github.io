---
title: Umami
date: 2024-02-27 22:26:13
tags:
- "Umami"
id: umami
no_word_count: true
no_toc: false
---

## Umami

### 简介

Umami 是一种简单、快速、注重隐私的开源分析解决方案。Umami 是 Google Analytics 的本地部署替代品。

### 使用方式

#### 云端使用

如果是个人使用，可以注册 [Umami Cloud](https://cloud.umami.is/signup) 账户，免费添加三个网站。

[收费说明](https://umami.is/pricing)

#### 本地部署

```bash
git clone https://github.com/umami-software/umami.git
cd umaimi
docker-compose up -d
```

之后即可访问 [http://localhost:3000](http://localhost:3000) 使用用户名 admin 和密码：umami 登录控制页，新增网站并插入脚本即可。 

### 参考资料

[官方文档](https://umami.is/docs)

[官方项目](https://github.com/umami-software/umami)
