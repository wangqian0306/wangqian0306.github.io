---
title: Open Feign
date: 2021-10-27 21:32:58
tags:
- "Java"
- "Spring Cloud"
id: openfeign
no_word_count: true
no_toc: false
categories: Spring
---

## Open Feign

### 使用

- 配置 pom

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

- 编写调用类

```text
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "<service_name>", path = "<url>")
public interface FeignTest {

    @GetMapping
    String getVersion();

}
```

在主类启用 OpenFeign

```java
@SpringBootApplication
@EnableFeignClients
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
```

配置请求方式

```yaml
spring:
    cloud:
        openfeign:
            client:
                config:
                    default:
                        connectTimeout: 5000
                        readTimeout: 5000
                        loggerLevel: basic
```

### 自定义异常类

在默认情况下 Feign 只会抛出 FeignException 异常，如有需求可以使用 ErrorDecoder 抛出异常。

```java
public class StashErrorDecoder implements ErrorDecoder {

    @Override
    public Exception decode(String methodKey, Response response) {
        if (response.status() >= 400 && response.status() <= 499) {
            return new StashClientException(
                    response.status(),
                    response.reason()
            );
        }
        if (response.status() >= 500 && response.status() <= 599) {
            return new StashServerException(
                    response.status(),
                    response.reason()
            );
        }
        return errorStatus(methodKey, response);
    }
}
```

```java
public class MyFeignClientConfiguration {

    @Bean
    public ErrorDecoder errorDecoder() {
        return new StashErrorDecoder();
    }
}
```

### fallback

Spring Cloud CircuitBreaker 支持回退的概念：当远程地址无法链接或出现错误时执行的默认代码。要为给定的 @FeignClient 启用 fallback，需要将该属性设置为实现回退的类名。

```java
@FeignClient(name = "test", url = "http://localhost:${server.port}/", fallback = Fallback.class)
protected interface TestClient {

    @RequestMapping(method = RequestMethod.GET, value = "/hello")
    Hello getHello();

    @RequestMapping(method = RequestMethod.GET, value = "/hellonotfound")
    String getException();

}

@Component
static class Fallback implements TestClient {

    @Override
    public Hello getHello() {
        throw new NoFallbackAvailableException("Boom!", new RuntimeException());
    }

    @Override
    public String getException() {
        return "Fixed response";
    }

}
```

并且配置如下参数：

```yaml
spring:
  cloud:
    openfeign:
      circuitbreaker:
        enabled: true
        alphanumeric-ids:
          enabled: true
```

### 参考资料

[官方文档](https://docs.spring.io/spring-cloud-openfeign/docs/4.0.1/reference/html/)
