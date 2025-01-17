---
title: Spring Boot 缓存
date: 2020-07-12 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Redis"
id: caching
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

### 简介

Spring Boot 可以使用 Spring Framework 提供的功能组件来实现缓存的功能。

### 支持的存储库

可以使用如下所示的缓存

- Generic
- JCache (JSR-107) (EhCache 3, Hazelcast, Infinispan, and others)
- EhCache 2.x
- Hazelcast
- Infinispan
- Couchbase
- Redis
- Caffeine
- Cache2k
- Simple

详情请参阅[官方文档](https://docs.spring.io/spring-boot/reference/io/caching.html)

> 注：后续将使用 Redis 作为缓存库进行说明。

### Redis

#### 环境依赖

使用 Redis 缓存需要新增下面的依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

#### 链接配置

由于使用了 Redis 作为存储组件，所以需要配置 Redis 的链接。

详细内容请参照[官方文档](https://docs.spring.io/spring-data/redis/reference/redis.html)

##### 单机模式

简单使用和测试的话可以使用单机模式进行配置，仅需要在配置文件中写入如下内容即可:

```yaml
spring:
  data:
    redis:
      host: <host>
      port: 6379
      database: 0
```

##### 主从 + 哨兵模式

主从加哨兵模式可以使用如下的配置项:

```yaml
spring:
  data:
    redis:
      sentinel:
        master: mymaster
        nodes: 192.168.1.1:26379,192.168.1.2:26379,192.168.1.3:26379
        password: <password>
```

##### 集群模式

集群模式可以使用如下的配置项:

```yaml
spring:
  data:
    redis:
      cluster:
        nodes: 192.168.1.1:16379,192.168.1.2:16379,192.168.1.3:16379
```

### Caffeine

#### 简介

Caffeine 是一款本地缓存的框架，详细技术栈参照如下文档：

[Design Of A Modern Cache](http://highscalability.com/blog/2016/1/25/design-of-a-modern-cache.html)

[Design Of A Modern Cache—Part Deux](http://highscalability.com/blog/2019/2/25/design-of-a-modern-cachepart-deux.html)

#### 环境依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
```

```xml
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
</dependency>
```

#### 配置项

```yaml
spring:
  cache:
    cache-names: "cache1,cache2"
    caffeine:
      spec: "maximumSize=500,expireAfterAccess=600s"
```

### 相关注解及说明

|       注解       |      说明       |
|:--------------:|:-------------:|
| @EnableCaching |    启用缓存功能     |
|   @Cacheable   |    缓存方法的标识    |
|   @CachePut    |    强制更新缓存     |
|  @CacheEvict   |    强制删除缓存     |
|    @Caching    | 自定义缓存功能，做功能拼接 |
|  @CacheConfig  |     缓存配置项     |

详情请参阅[官方文档](https://docs.spring.io/spring-framework/reference/integration/cache.html)

### 简单试用

编写如下 application.yaml 配置文件：

```yaml
spring:
  application:
    name: cache-test
  data:
    redis:
      host: 192.168.2.77
      port: 6379
  cache:
    redis:
      time-to-live: 23h
```

编写 `TestService.java` ：

```java
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
public class TestService {

    @Cacheable(cacheNames = {"echo"})
    public String echo(Integer id) {
        try {
            Thread.sleep(4000);
        } catch (Exception ignore) {
        }
        return LocalDateTime.now() + " " + id;
    }

    @CacheEvict(cacheNames = {"echo"})
    public void evict(Integer id) {
    }

}
```

编写 `TestController.java` :

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/test")
public class TestController {

    @Resource
    private TestService testService;

    @GetMapping("/cache/{id}")
    public String cache(@PathVariable int id) {
        return testService.echo(id);
    }

    @DeleteMapping("/cache/{id}")
    public void delete(@PathVariable int id) {
        testService.evict(id);
    }

}
```

编写测试文件 `test.http` ：

```text
### set and read cache
GET http://localhost:8080/test/cache/1

### delete cache
DELETE http://localhost:8080/test/cache/1

### test read with out cache
GET http://localhost:8080/test/cache/2
```

之后运行服务，然后尝试调用测试文件即可。

### 缓存的常见配置

#### FastJson 序列化 

在使用 Redis 的时候需要将缓存数据进行传输和下载，所以需要将对象进行序列化，可以通过如下代码实现：

```java
import com.alibaba.fastjson2.support.spring6.data.redis.GenericFastJsonRedisSerializer;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory redisConnectionFactory) {
        GenericFastJsonRedisSerializer fastJsonRedisSerializer = new GenericFastJsonRedisSerializer();
        RedisCacheConfiguration defaultCacheConfig = RedisCacheConfiguration.defaultCacheConfig()
                .serializeKeysWith(SerializationPair.fromSerializer(new StringRedisSerializer()))
                .serializeValuesWith(SerializationPair.fromSerializer(fastJsonRedisSerializer));

        return RedisCacheManager.builder(redisConnectionFactory)
                .cacheDefaults(defaultCacheConfig)
                .build();
    }
}
```

#### 定义不同的过期时间

```java
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager(RedisConnectionFactory redisConnectionFactory) {
        RedisCacheConfiguration defaultCacheConfig = RedisCacheConfiguration.defaultCacheConfig();

        Map<String, RedisCacheConfiguration> cacheConfigurations = new HashMap<>();
        cacheConfigurations.put("ocean", defaultCacheConfig.entryTtl(Duration.ofDays(1)));
        cacheConfigurations.put("weather", defaultCacheConfig.entryTtl(Duration.ofHours(2)));
        
        return RedisCacheManager.builder(redisConnectionFactory)
                .cacheDefaults(defaultCacheConfig)
                .withInitialCacheConfigurations(cacheConfigurations)
                .build();
    }
}
```

#### 利用浏览器的缓存机制

在响应结果中加入 LastModified 头可以让浏览器缓存响应结果，节省开销：

```java
import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.Calendar;

@Service
public class TestService {

    @Cacheable(cacheNames = {"test"})
    public ResponseEntity<String> test() {
        HttpHeaders headers = new HttpHeaders();
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        calendar.set(Calendar.MILLISECOND, 0);
        headers.setLastModified(calendar.getTime().toInstant());
        return new ResponseEntity<>("test", headers, HttpStatusCode.valueOf(200));
    }

}
```

### 缓存常见问题如何解决

#### 缓存雪崩

缓存雪崩的意思是大量缓存同时过期导致大量请求被发送到了数据库的问题。

> 注：此处内容尚且没有进行过验证，抽时间再补下吧。

此处可以使用自定义CacheManager(RedisCacheManager)的方式来进行实现。

#### 缓存穿透

缓存击穿指的是

- 查询必然不存在的数据来直击数据库

通常来说此问题可以通过 `@Cacheable` 注解中的`unless` 配置项配合缓存空对象或者布轮过滤器的方式来进行补充和完善。

##### 缓存空对象

可以直接使用下面的配置项开启空对象缓存。

```properties
spring.cache.redis.cache-null-values=true
```

##### 布隆过滤器

> 注：此处内容尚且没有进行过验证，抽时间再补下吧。

此处可以使用自定义CacheManager(RedisCacheManager)的方式来进行实现。

#### 缓存击穿

缓存击穿，是指非常热点的数据在失效的瞬间，持续的大量请求就穿破缓存，直接请求数据库的情况。

解决此处的问题可以配置 `@Cacheable` 注解中的 `sync` 配置项为 `True` 来解决。
