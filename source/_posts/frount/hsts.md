---
title: HSTS
date: 2026-06-07 21:41:32
tags:
- "HSTS"
id: hsts
no_word_count: true
no_toc: false
categories:
- "前端"
---

## HSTS 问题

### 简介

HSTS（HTTP Strict Transport Security，HTTP 严格传输安全）是一种 Web 安全策略机制，服务器通过响应头 `Strict-Transport-Security` 告知浏览器：在指定时间内，所有对该域名的访问都必须使用 HTTPS，浏览器会自动将 HTTP 请求重定向为 HTTPS。

示例响应头：

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

| 参数 | 说明 |
|------|------|
| `max-age` | HSTS 策略的有效期（秒），`31536000` 即一年 |
| `includeSubDomains` | 策略同时适用于所有子域名 |
| `preload` | 允许将域名加入浏览器内置的 HSTS 预加载列表 |

### 清除浏览器的 HSTS 缓存

一旦浏览器缓存了某个域名的 HSTS 策略，在 `max-age` 过期之前，浏览器会强制使用 HTTPS。如果服务端取消了 HTTPS 配置或证书出现问题，浏览器将无法正常访问。此时需要手动清除 HSTS 缓存，让浏览器"忘记"该域名必须使用 HTTPS 的规则。

#### 清除 HSTS 安全策略

- 在 Chrome 地址栏输入：

```text
chrome://net-internals/#hsts
```

- 找到页面中的 **Delete domain security policies** 区域
- 在输入框中填入需要清除的域名（例如 `example.com`）
- 点击 **Delete** 按钮

> 注意：如果 HSTS 策略设置了 `includeSubDomains`，需要同时清除主域名及相关子域名的策略。

- 清除浏览器缓存

1. 按 `Ctrl + Shift + Delete` 打开清除浏览数据面板
2. 勾选 **缓存的图片和文件** 以及 **Cookie 和其他网站数据**
3. 选择合适的时间范围（建议选择"全部时间"）
4. 点击 **清除数据**

- 重启浏览器

彻底关闭浏览器（包括后台进程）后重新打开，确保所有缓存生效。

### 相关问题

在服务器的 HTTPS 证书比较旧的时候也会出现类似的情况，导致 SSL 认证出现问题，在遇到这样的问题时需要更新系统的 HTTPS 证书，命令如下：

```bash
sudo dnf update ca-certificates
sudo update-ca-trust
```

### 参考资料

- [MDN - Strict-Transport-Security](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Strict-Transport-Security)
- [Chrome HSTS Preload List](https://hstspreload.org/)
