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

#### 开启版本和服务信息(开发环境)

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

### 生产环境中的使用

需要注意的是，Spring 官方除了当前 Spring 的基本状态之外，还针对很多其它的 [组件](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.health.auto-configured-health-indicators) 提供了健康检查(Health Check) 。

在生产环境中使用的时候就尤其需要区分不同的组来避免由于类似与数据库这样的基础服务出错导致服务循环重启的问题。

[Liveness State](https://docs.spring.io/spring-boot/reference/features/spring-application.html#features.spring-application.application-availability.liveness)

建议进行如下配置：

```yaml
management:
  endpoint:
    health:
      group:
        liveness:
          include: "ping"
        readiness:
          include: "mongo,redis" # Readiness 检查包括外部依赖
  endpoints:
    web:
      exposure:
        include: "health" # 暴露 health 端点

spring:
  data:
    mongodb:
      uri: "mongodb://<your-mongo-host>:27017/<your-db>" # MongoDB 配置
  redis:
    host: "<your-redis-host>" # Redis 配置
    port: 6379
```

之后即可访问如下地址获取到 liveness 状态：

[http://localhost:8080/actuator/health/liveness](http://localhost:8080/actuator/health/liveness)

### 参考资料

[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
