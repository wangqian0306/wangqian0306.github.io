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

### 参考资料

[官方文档](https://docs.spring.io/spring-cloud-openfeign/docs/4.0.1/reference/html/)
