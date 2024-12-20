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

之后参照 Spring Data 其他组件的使用方式进行使用即可，例如：

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

### 分布式锁

实现分布式锁有两种方案：

- 使用 Spring Integration 实现
- 使用 Redission 的 Redlock 实现

#### Spring Integration

引入如下依赖：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-integration'
    implementation 'org.springframework.boot:spring-boot-starter-data-redis'
    implementation 'org.springframework.integration:spring-integration-redis'
    implementation 'org.springframework.integration:spring-integration-http'
    testImplementation 'org.springframework.integration:spring-integration-test'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

编写如下配置 `application.yaml` ：

```yaml
spring:
  data:
    redis:
      host: <redis_host>
```

编写 `RedisLockConfig.java` ：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.integration.redis.util.RedisLockRegistry;
import org.springframework.stereotype.Component;

@Component
public class RedisLockConfig {

    @Bean
    public RedisLockRegistry redisLockRegistry(RedisConnectionFactory redisConnectionFactory) {
        return new RedisLockRegistry(redisConnectionFactory, "distributedLock");
    }

}
```

编写 `TestService.java` :

```java
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.integration.redis.util.RedisLockRegistry;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.Lock;

@Slf4j
@Service
public class TestService {

    @Resource
    private RedisLockRegistry redisLockRegistry;

    public String test(String id, Long time) throws InterruptedException {
        log.info("Attempting to acquire lock with id: {}", id);

        Lock lock = redisLockRegistry.obtain(id);

        boolean lockAcquired = lock.tryLock(2, TimeUnit.SECONDS);
        if (lockAcquired) {
            try {
                log.info("Lock acquired for id: {}, performing critical operation...", id);
                Thread.sleep(time);
            } finally {
                lock.unlock();
                log.info("Lock released for id: {}", id);
            }
            return "Operation completed successfully";
        } else {
            log.warn("Unable to acquire lock for id: {}", id);
            return "Unable to acquire lock, please try again later.";
        }
    }

}
```

编写 `TestController.java` :

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {

    @Resource
    TestService testService;

    @GetMapping("/{id}/{time}")
    public String test(@PathVariable String id, @PathVariable Long time) throws InterruptedException {
        return testService.test(id, time);
    }

}
```

之后启动服务，然后使用如下地址进行测试即可：

[http://localhost:8080/test/1/20000](http://localhost:8080/test/1/20000)

[http://localhost:8080/test/1/1000](http://localhost:8080/test/1/1000)

#### Redission

[与 Spring 集成](https://redisson.org/docs/integration-with-spring/)

### 客户端缓存

经过查找发现 Spring Data Redis 并不打算支持此功能。如需使用需要自行根据 [Lettuce](https://github.com/lettuce-io/lettuce-core/issues/1281) 实现。

[拒绝原文](https://github.com/spring-projects/spring-data-redis/issues/1937)

### 单元测试

在编写单元测试时需要加上 `@DataRedisTest` 注解，此注解会使用内存数据库进行测试，而不会产生多余的测试数据。 

### 参考资料

[官方文档](https://docs.spring.io/spring-data/redis/docs/current/reference/html/)

[Jedis](https://redis.github.io/jedis/)

[Lettuce](https://redis.github.io/lettuce/)

[Redssion](https://redisson.org/docs/)
