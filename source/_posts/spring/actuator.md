---
title: Spring Boot Actuator
date: 2023-06-30 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Actuator"
id: actuator 
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Boot Actuator

### 简介

spring-boot-actuator 模块提供了将 Spring Boot 程序部署向生产环境中的准备功能，比如说生命监控，版本信息，性能信息等。

### 使用方式

引入如下依赖即可：

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
}
```

在引入后访问 [http://localhost:8080/actuator](http://localhost:8080/actuator) 即可获得目前开放的所有 actuator 。

在使用时仅需要编辑 `application.yaml` 配置文件即可，具体样例如下： 

```yaml
management:
  endpoints:
    jmx:
      exposure:
        include: "health,info"
```

> 注：上面的样例表示了开放 health 和 info 信息，其他内容请参照官方文档。

#### 开启版本和服务信息

```yaml
management:
  info:
    env:
      enabled: true
    build:
      enabled: true
    git:
      enabled: true
      mode: full
    java:
      enabled: true
    os:
      enabled: true
  endpoints:
    web:
      exposure:
        include: "*"

info:
  app:
    name: demo
    description: demo server
    verion: 1.0.0
    author: demo
    docs: http://www.google.com
```

### 自定义端点

```java
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.stereotype.Service;

@Service
@Endpoint(id = "demo")
public class DemoEndpoint {

    @ReadOperation
    public String demo() {
        return "{\"hello\":\"demo\"}";
    }

}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
