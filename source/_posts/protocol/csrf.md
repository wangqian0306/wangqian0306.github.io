---
title: CSRF 知识整理
date: 2020-06-21 21:44:32
tags: "CSRF"
id: csrf
no_word_count: true
no_toc: false
categories: Web
---

## 简述

CSRF(Cross-site request forgery)，中文名称：跨站请求伪造，也被称为：one click attack/session riding，缩写为：CSRF/XSRF。

## 原理

攻击者通过一些技术手段欺骗用户的浏览器去访问一个自己以前认证过的站点并运行一些操作。

本质上来说CSRF攻击是利用了 Web 端程序的隐式身份验证机制。对于后台而言虽然可以认为请求是来自于某个已登录用户的浏览器发出的，但却无法保证该请求是用户批准发送的。

## 如何进行保护

### 前后端融合的项目

对于前后台融合的项目可以通过“模板”相关的技术来解决此问题。

> 对于 Java 来说有 JSP, Python 相关的技术有 Jinja2 等等。

### 前后端分离的项目

对于前后端分离的项目来说就有些难办，可以通过后台操作 Cookie 的方式来讲数据传输至浏览器，然后由前端读取 Cookie 再传输回后台进行校验。

具体实现上来说可以使用下面的样例(Spring Security)

```java
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;

public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf()
            .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse());
    }
}
```
