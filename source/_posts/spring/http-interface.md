---
title: HTTP Interface
date: 2022-12-06 21:32:58
tags:
- "Java"
- "Spring Boot"
id: http-interface
no_word_count: true
no_toc: false
categories: Spring
---

## HTTP Interface

### 简介

HTTP Interface 是 Spring 框架在 6.0 版本提供的新接口。

### 使用方式

引入依赖包

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
}
```

> 注：需要升级 SpringBoot 到 3.0.0 以上，且使用 Java 17 及以上版本。

编写数据模型类

```java
import lombok.Data;

@Data
public class Album {

    private Long id;

    private Long userId;

    private String title;

}
```

编写请求接口

```java
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.service.annotation.GetExchange;
import org.springframework.web.service.annotation.HttpExchange;

@HttpExchange
public interface RemoteService {

    @GetExchange("/albums/{id}")
    Album getAlbumById(@PathVariable Long id);

}
```

编写配置类

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.support.WebClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;

@Configuration
public class WebClientConfig {

    @Bean
    RemoteService remoteService() {
        WebClient client = WebClient.builder().baseUrl("https://jsonplaceholder.typicode.com").build();
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builder(WebClientAdapter.forClient(client)).build();
        return factory.createClient(RemoteService.class);
    }

}
```

编写 Controller

```java
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/remote")
public class RemoteController {

    @Resource
    RemoteService remoteService;

    @GetMapping("/{id}")
    HttpEntity<Album> getAlbumById(@PathVariable Long id) {
        return new HttpEntity<>(remoteService.getAlbumById(id));
    }

}
```

完成请求测试

```http request
GET http://localhost:8080/remote/1
```

### 参考资料

[官方文档](https://docs.spring.io/spring-framework/docs/current/reference/html/integration.html#rest-http-interface)

[Spring 6.0/Spring Boot 3.0新特性：简单的远程调用HTTP Interfaces](https://zhuanlan.zhihu.com/p/574269406)
