---
title: 域控
date: 2021-11-09 23:09:32
tags:
- "FreeIPA"
- "NIS"
- "Windows AD"
id: freeipa
no_word_count: true
no_toc: false
categories: "工具"
---

## 域控

### 简介

域控制器是指在“域”模式下，至少有一台服务器负责每一台联入网络的电脑和用户的验证工作。

### 相关产品

- FreeIPA
- NIS
- Windows AD

### 相关技术

- LDAP
- Kerberos
- DNS
- NTP

### 适用情况

- 需要统一管理 Windows 设备则使用 Windows AD。
- 需要开源免费且适用性交广则采用 FreeIPA

### 公网试用

目前 FreeIPA 提供了一个公网的试用版本，可以进行一些基本的测试。

访问 [ipa.demo1.freeipa.org](http://ipa.demo1.freeipa.org)

使用如下账号都可以进行登录：

- admin: 超级管理员
- helpdesk: 普通用户，具有运维权限，可以编辑用户或者编辑组
- employee: 普通用户
- manger: 普通用户，被设定成 employee 的管理员

密码都是统一的 `Secret123`。

> 注：在 Chrome 浏览器弹出的登录框需要手动关闭，然后在页面的登录表单中进行登录。