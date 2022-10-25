---
title: Spring Cloud Gateway
date: 2022-10-25 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring Cloud"
- "Gateway"
id: spring-cloud-gateway
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Cloud Gateway

### 简介

Spring Cloud Gateway 是 Spring Cloud 框架中的网关模块，负责转发请求至对应服务。

### 使用方式

正常编写一个空的 Spring Cloud 应用程序，并且引入 Spring Cloud Gateway 相关包即可。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-gateway</artifactId>
    <version>${spring-cloud-gateway.version}</version>
</dependency>
```

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class GatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class,args);
    }
}
```

根据需求编写重定向配置即可，具体配置样例请参照官方文档。

```yaml
server:
  port: 8080
spring:
  application:
    name: gateway
  cloud:
    gateway:
      routes:
        - id: demo
          uri: https://httpbin.org
```

### 参考资料

[官方文档](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)

[样例项目](https://github.com/spring-cloud/spring-cloud-gateway/tree/main/spring-cloud-gateway-sample)