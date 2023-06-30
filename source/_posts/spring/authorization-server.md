---
title: Spring Authorization Server
date: 2023-06-30 21:32:58
tags:
- "Java"
- "Spring Boot"
- "OAuth"
id: authorization-server
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Authorization Server

### 简介

Spring Authorization Server 是一个框架，提供 OAuth 2.1 和 OpenID Connect 1.0 规范以及其他相关规范的实现。

### 使用方式

在创建项目时引入 `OAuth2 Authorization Server` 依赖即可，样例如下：

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-authorization-server'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    runtimeOnly 'com.h2database:h2'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
}
```

然后编辑如下配置项即可：

```yaml
spring:
  security:
    oauth2:
      authorizationserver:
        client:
          client-1:
            registration:
              client-id: "admin-client"
              # the client secret is "secret" (without quotes)
              client-secret: "{bcrypt}$2a$10$jdJGhzsiIqYFpjJiYWMl/eKDOd8vdyQis2aynmFN0dgJ53XvpzzwC"
              client-authentication-methods: "client_secret_basic"
              authorization-grant-types: "client_credentials"
              scopes: "user.read,user.write"
```

启动程序然后使用如下命令即可获得 Token:

```bash
http -f POST :8080/oauth2/token grant_type=client_credentials scope='user.read' -a admin-client:secret
```

> 注：如果没有 httpie 工具则可以使用 IDEA 自带的 Http 工具。

```http
POST http://localhost:8080/oauth2/token
Authorization: Basic admin-client secret
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=user.read
```

### 参考资料

[官方文档](https://docs.spring.io/spring-authorization-server/docs/current/reference/html/getting-started.html)

[官方博客](https://spring.io/blog/2023/05/24/spring-authorization-server-is-on-spring-initializr)

[视频教程](https://www.youtube.com/watch?v=7zm3mxaAFWk)

[样例源码](https://github.com/coffee-software-show/authorization-server-in-boot-31)
