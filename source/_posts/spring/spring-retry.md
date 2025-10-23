---
title: Spring Retry
date: 2025-10-21 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-retry
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring 中的重试

### 简介

Spring 官方提供了关于重试的注解方法，可以在程序运行异常后进行自动重试。

在 Spring Framework 7 之前，使用的是 [Spring　Retry](https://github.com/spring-projects/spring-retry) 项目，在之后则是 [Resilience Features](https://docs.spring.io/spring-framework/reference/7.0-SNAPSHOT/core/resilience.html)

而在 Spring Cloud 中则建议采用 [Resilience4j](https://resilience4j.readme.io/) 

### 实现方式

#### Resilience Features

需要在配置类或者主类上开启如下注解：

```java
import org.springframework.resilience.annotation.EnableResilientMethods;

@EnableResilientMethods
public class XXX {
}
```

```java
import org.springframework.resilience.annotation.Retryable;
import org.springframework.stereotype.Service;

@Service
public class TestService {

    @Retryable
    public String test() {
        System.out.println("Attempting remote call (sync) …");
        // 模拟失败
        throw new RuntimeException("Remote call failed");
    }
}
```

#### Resilience4j

在使用 Resilience4j 时需要引入如下包：

```groovy
dependencies {
    implementation 'org.springframework.cloud:spring-cloud-starter-circuitbreaker-resilience4j'
    implementation 'org.springframework.cloud:spring-cloud-starter'
    implementation 'org.springframework.boot:spring-boot-starter-aop'
}
```

然后需要编写如下配置项：

```yaml
resilience4j:
  retry:
    instances:
      externalService:
        max-attempts: 4
        wait-duration: 1s
        enable-exponential-backoff: false
        retry-exceptions:
          - java.lang.RuntimeException
```

需要在配置类或者主类上开启如下注解：

```java
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@EnableAspectJAutoProxy
public class XXX {
}
```

编写 Service ：

```java
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.stereotype.Service;

@Service
public class TestService {

    private int count = 0;

    @Retry(name = "externalService")
    public String test() {
        count++;
        System.out.println("Attempt " + count);
        throw new RuntimeException("Remote call failed");
    }
}
```

编写 Controller ：

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class TestController {

    @Resource
    private TestService testService;

    @GetMapping
    public String test() {
        return testService.test();
    }

}
```

### 参考资料

[Resilience Features](https://docs.spring.io/spring-framework/reference/7.0-SNAPSHOT/core/resilience.html)

[Retryable JavaDoc](https://docs.spring.io/spring-framework/docs/7.0.0-SNAPSHOT/javadoc-api/org/springframework/resilience/annotation/Retryable.html)

[Resilience4j](https://resilience4j.readme.io/)

[Resilience4j-SpringBoot 文档](https://resilience4j.readme.io/docs/getting-started-3)

[Spring　Retry 官方项目](https://github.com/spring-projects/spring-retry)
