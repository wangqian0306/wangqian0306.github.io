---
title: WebClient 和 RestClient
date: 2023-04-14 22:32:58
tags:
- "Java"
- "Spring Boot"
id: webclient-restclient
no_word_count: true
no_toc: false
categories: 
- "Spring"
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
    JokeClient jokeClient(WebClient.Builder builder) {
        WebClient client = builder
                .baseUrl("https://icanhazdadjoke.com/")
                .defaultHeader("Accept", "application/json")
                .build();
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(WebClientAdapter.create(client)).build();
        return factory.createClient(JokeClient.class);
    }

}
```

编写测试接口：

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

更换支持库(可选)：

```java
@Bean
public JettyResourceFactory resourceFactory() {
	return new JettyResourceFactory();
}

@Bean
public WebClient webClient() {

	HttpClient httpClient = new HttpClient();
	ClientHttpConnector connector =
			new JettyClientHttpConnector(httpClient, resourceFactory()); 

	return WebClient.builder().clientConnector(connector).build(); 
}
```

> 注：每种库的日志需要单独调节，支持库的清单参阅官方文档。

配置代理(可选)：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.support.WebClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;
import reactor.netty.http.client.HttpClient;
import reactor.netty.transport.ProxyProvider;

@Bean
JokeClient jokeClient(WebClient.Builder builder) {
    HttpClient httpClient = HttpClient.create()
            .proxy(proxy -> proxy
                    .type(ProxyProvider.Proxy.HTTP)
                    .host("localhost")
                    .port(7890));
    WebClient client = builder
            .clientConnector(new ReactorClientHttpConnector(httpClient))
            .baseUrl("https://icanhazdadjoke.com/")
            .defaultHeader("Accept", "application/json")
            .build();
    HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(WebClientAdapter.create(client)).build();
    return factory.createClient(JokeClient.class);
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
    JokeClient jokeClient(RestClient.Builder builder) {
        RestClient client = builder
                .baseUrl("https://icanhazdadjoke.com/")
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

更换支持库(可选)：

```java
import org.springframework.boot.web.client.RestClientCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JettyClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class CustomRestClientConf {

    @Bean
    public RestClient restClient(RestClient.Builder builder) {
        return builder.build();
    }

    @Bean
    public RestClientCustomizer restClientCustomizer() {
        JettyClientHttpRequestFactory requestFactory = new JettyClientHttpRequestFactory();
        return (restClientBuilder) -> restClientBuilder
                .requestFactory(requestFactory)
                .baseUrl("http://localhost:8080/");
    }

}
```

> 注：每种库的日志需要单独调节，支持库的清单参阅官方文档。

设置代理(可选)：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.support.RestClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;

import java.net.InetSocketAddress;
import java.net.Proxy;

@Bean
JokeClient jokeClient(RestClient.Builder builder) {
    Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress("localhost", 7890));
    SimpleClientHttpRequestFactory simpleClientHttpRequestFactory = new SimpleClientHttpRequestFactory();
    simpleClientHttpRequestFactory.setProxy(proxy);
    RestClient client = builder
            .requestFactory(simpleClientHttpRequestFactory)
            .baseUrl("https://icanhazdadjoke.com/")
            .defaultHeader("Accept", "application/json")
            .build();
    HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(RestClientAdapter.create(client)).build();
    return factory.createClient(JokeClient.class);
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

#### Mock 测试

编写如下测试程序即可：

```java
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.client.RestClientTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;


@RestClientTest(JokeClient.class)
public class JokeTest {

    @Autowired
    MockRestServiceServer server;

    @Autowired
    JokeClient jokeClient;

    @Autowired
    ObjectMapper objectMapper;

    @Test
    public void shouldReturnAllPosts() throws JsonProcessingException {
        JokeResponse jokeResponse = new JokeResponse("1", "demo", 1);
        this.server
                .expect(requestTo("https://icanhazdadjoke.com/"))
                .andRespond(withSuccess(objectMapper.writeValueAsString(jokeResponse), MediaType.APPLICATION_JSON));

        JokeResponse result = jokeClient.random();
        assertThat(result.joke()).isEqualTo("demo");
    }
}
```

#### 拦截器

可以使用拦截器的方式改变请求中的内容样例如下：

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class TokenInterceptor implements ClientHttpRequestInterceptor {

    private static final Logger log = LoggerFactory.getLogger(TokenInterceptor.class);

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {
        log.info("Intercepting request: " + request.getURI());
        request.getHeaders().add("x-request-id", "12345");
        return execution.execute(request, body);
    }

}
```

```java
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class JokeClient {

    private final RestClient restClient;

    public JokeClient(RestClient.Builder builder, ClientHttpRequestInterceptor tokenInterceptor) {
        this.restClient = builder
                .baseUrl("https://icanhazdadjoke.com")
                .defaultHeader("Accept", "application/json")
                .requestInterceptor(tokenInterceptor)
                .build();
    }

    public JokeResponse random() {
        return restClient.get()
                .uri("/")
                .retrieve()
                .body(JokeResponse.class);
    }

}
```

#### 处理不同的返回状态码和对象

```java
import org.springframework.http.HttpStatus;
import org.springframework.web.reactive.function.client.ClientResponse;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

public class AsyncRequestService {

    private final WebClient webClient;

    public AsyncRequestService(WebClient.Builder webClientBuilder) {
        this.webClient = webClientBuilder.baseUrl("http://xxx.xxx.xxx").build();
    }

    public Mono<ClientResponse> asyncFetchDataWithStatus() {
        return webClient.get()
                .uri("/xxx")
                .exchangeToMono(response -> {
                    if (response.statusCode().equals(HttpStatus.OK) || response.statusCode().equals(HttpStatus.ACCEPTED)) {
                        return Mono.just(response);
                    }
                    return Mono.error(new RuntimeException("Failed to fetch data"));
                });
    }
}
```

```java
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
public class AsyncRequestController {

    private final AsyncRequestService asyncRequestService;

    public AsyncRequestController(AsyncRequestService asyncRequestService) {
        this.asyncRequestService = asyncRequestService;
    }

    @GetMapping("/fetch-data")
    public Mono<ResponseEntity<String>> fetchData() {
        return asyncRequestService.asyncFetchDataWithStatus()
                .flatMap(response -> {
                    if (response.statusCode().equals(HttpStatus.OK)) {
                        return response.bodyToMono(String.class)
                                .map(body -> ResponseEntity.ok(body));
                    } else if (response.statusCode().equals(HttpStatus.ACCEPTED)) {
                        return Mono.just(ResponseEntity.status(HttpStatus.ACCEPTED).body("Processing..."));
                    } else {
                        return Mono.just(ResponseEntity.status(response.statusCode()).body("Unhandled status code"));
                    }
                })
                .onErrorResume(e -> {
                    return Mono.just(ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error occurred"));
                });
    }
}
```

### 参考资料

[WebClient 文档](https://docs.spring.io/spring-framework/reference/web/webflux-webclient.html)

[WebClient 单元测试样例项目](https://github.com/danvega/async-client/blob/main/src/test/java/dev/danvega/post/PostClientTest.java)

[RestClient 文档](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html)

[Spring Security 6.4 中 OAuth2 的 RestClient 支持](https://spring.io/blog/2024/10/28/restclient-support-for-oauth2-in-spring-security-6-4)
