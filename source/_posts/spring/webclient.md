---
title: WebClient
date: 2023-04-14 22:32:58
tags:
- "Java"
- "Spring Boot"
id: webclient
no_word_count: true
no_toc: false
categories: Spring
---

## WebClient

### 简介

WebClient 是 Spring 除了 RestTemplate 之外支持的一种请求方式。

### 实现

引入 WebFlux 包：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

编写请求结果类：

```java
public record JokeResponse(String id, String joke, Integer status) {
}
```

编写请求类：

```java
import org.springframework.web.service.annotation.GetExchange;

public interface JokeClient {

    @GetExchange("/")
    JokeResponse random();

}
```

编写主类和 Bean：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.support.WebClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    JokeClient dadJokeClient() {
        WebClient client = WebClient.builder()
                .baseUrl("https://icanhazdadjoke.com")
                .defaultHeader("Accept", "application/json")
                .build();
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builder(WebClientAdapter.forClient(client)).build();
        return factory.createClient(JokeClient.class);
    }

}
```

编写测试：

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping
public class TestController {

    @Resource
    JokeClient jokeClient;

    @GetMapping("/")
    public String test() {
        JokeResponse response = jokeClient.random();
        return response.joke();
    }

}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-framework/docs/6.0.7/reference/html/web-reactive.html#webflux-client)
