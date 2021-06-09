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
categories: Spring
---

### 简介

Spring Boot 可以使用 Spring Framework 提供的功能组件来实现缓存的功能。

### 支持的存储库

可以使用如下所示的缓存

- JCache(JSR-107)
- EhCache 2.x
- Hazelcast
- Infinispan
- Couchbase
- Redis
- Caffeine
- ConcurrentHashMap

详情请参阅[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/spring-boot-features.html#boot-features-caching-provider)

> 注：后续将使用 Redis 作为缓存库进行说明。

### 环境依赖

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

### 链接配置

由于使用了 Redis 作为存储组件，所以需要配置 Redis 的链接。

详细内容请参照[官方文档](https://docs.spring.io/spring-data/redis/docs/2.3.1.RELEASE/reference/html/#redis)

#### 单机模式

简单使用和测试的话可以使用单机模式进行配置，仅需要在配置文件中写入如下内容即可:

```properties
spring.redis.host=localhost
spring.redis.port=6379
spring.redis.database=0
```

#### 主从 + 哨兵模式

主从加哨兵模式可以使用如下的配置项:

```properties
spring.redis.sentinel.master=mymaster
spring.redis.sentinel.nodes=192.168.1.1:26379,192.168.1.2:26379,192.168.1.3:26379
spring.redis.sentinel.password=123456789
```

#### 集群模式

集群模式可以使用如下的配置项:

```properties
spring.redis.cluster.nodes=192.168.1.1:16379,192.168.1.2:16379,192.168.1.3:16379
```

### 相关注解及说明

|注解|说明|
|:---:|:---:|
|@EnableCaching|启用缓存功能|
|@Cacheable|缓存方法的标识|
|@CachePut|强制更新缓存|
|@CacheEvict|强制删除缓存|
|@Caching|自定义缓存功能|
|@CacheConfig|缓存配置项|

详情请参阅[官方文档](https://docs.spring.io/spring/docs/5.2.7.RELEASE/spring-framework-reference/integration.html#cache)

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

##### 布轮过滤器

> 注：此处内容尚且没有进行过验证，抽时间再补下吧。

此处可以使用自定义CacheManager(RedisCacheManager)的方式来进行实现。

#### 缓存击穿

缓存击穿，是指非常热点的数据在失效的瞬间，持续的大量请求就穿破缓存，直接请求数据库的情况。

解决此处的问题可以配置 `@Cacheable` 注解中的 `sync` 配置项为 `True` 来解决。
