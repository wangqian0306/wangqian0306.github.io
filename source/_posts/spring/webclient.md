---
title: WebClient 和 RestClient
date: 2023-04-14 22:32:58
tags:
- "Java"
- "Spring Boot"
id: webclient-restclient
no_word_count: true
no_toc: false
categories: Spring
---

## WebClient 和 RestClient

### 简介

```text
Fourteen years ago, when RestTemplate was introduced in Spring Framework 3.0, we quickly discovered that exposing every capability of HTTP in a template-like class resulted in too many overloaded methods. 
```

十四年前，当在 Spring Framework 3.0 中引入时 RestTemplate，我们很快发现，在类似模板的类中公开HTTP的所有功能会导致太多的重载方法。

所以在 Spring Framework 中实现了如下两种客户端，用来执行 Http 请求：

- WebClient：异步客户端
- RestClient：同步客户端

### WebClient 实现

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
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(WebClientAdapter.forClient(client)).build();
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

### RestClient 实现

引入 Web 包：

```grovvy
dependencies {
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
import org.springframework.web.client.RestClient;
import org.springframework.web.client.support.RestClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    JokeClient dadJokeClient() {
        RestClient client = RestClient.builder()
                .baseUrl("https://icanhazdadjoke.com")
                .defaultHeader("Accept", "application/json")
                .build();
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(RestClientAdapter.create(client)).build();
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


### 常见问题

#### 获取请求状态码

可以使用如下样例获取请求结果对象，然后读取状态码等信息

```java
import org.springframework.http.ResponseEntity;
import org.springframework.web.service.annotation.GetExchange;

public interface JokeClient {

    @GetExchange("/")
    ResponseEntity<JokeResponse> random();

}
```

### 参考资料

[WebClient 文档](https://docs.spring.io/spring-framework/docs/6.0.7/reference/html/web-reactive.html#webflux-client)

[RestClient 博客](https://spring.io/blog/2023/07/13/new-in-spring-6-1-restclient)
