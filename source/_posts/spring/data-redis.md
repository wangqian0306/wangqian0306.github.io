---
title: Spring Data Redis
date: 2022-06-21 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Redis"
id: spring-data-redis
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Data Redis

### 简介

Spring Data Redis 是更大的 Spring Data 系列的一部分，它提供了从 Spring 应用程序对 Redis 的轻松配置和访问。

### 使用

引入依赖包：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
}
```

配置连接地址：

```yaml
spring:
  redis:
    host: ${REDIS_HOST:xxx.xxx.xxx.xxx}
    port: ${REDIS_PORT:xxxx}
    database: ${REDIS_DB:xx}
    username: ${REDIS_USERNAME:xxxx}
    password: ${REDIS_PASSWORD:xxxx}
```

> 注: 此处为单节点模式，其他模式请参照官方文档进行配置。

之后参照 SpringData 其他组件的使用方式进行使用即可，例如：

```java
import jakarta.annotation.Resource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {

    @Resource
    private StringRedisTemplate redisTemplate;
    
    @GetMapping
    public Boolean test(@RequestParam String name) {
        return redisTemplate.hasKey(name);
    }

}

```

### 客户端缓存

经过查找发现 Spring Data Redis 并不打算支持此功能。如需使用需要自行根据 [Lettuce](https://github.com/lettuce-io/lettuce-core/issues/1281) 实现。

[拒绝原文](https://github.com/spring-projects/spring-data-redis/issues/1937)

### 单元测试

在编写单元测试时需要加上 `@DataRedisTest` 注解，此注解会使用内存数据库进行测试，而不会产生多余的测试数据。 

### 参考资料

[官方文档](https://docs.spring.io/spring-data/redis/docs/current/reference/html/)
