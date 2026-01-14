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

##### 注解方式

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

除了基本用法之外还可以指定如下参数

|     参数      |      作用      |
|:-----------:|:------------:|
|  includes   |   捕捉到异常时重试   |
|  excludes   |   排除异常外重试    |
| maxAttempts | 最多访问次数(包含初次) |
|    delay    |     延迟时长     |
| multiplier  | 连续失败的时长等待倍数  |
|  maxDelay   |    最大等待时长    |
|   jetter    |     抖动时长     |

除了重试之外，Spring 还提供了并发限制，用来保证不会有超过并发限制的请求导致产生新的问题：

```java
@ConcurrencyLimit(10)
public void sendNotification() {
}
```

##### 编码方式使用

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.retry.RetryException;
import org.springframework.core.retry.RetryPolicy;
import org.springframework.core.retry.RetryTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class RetryTestService {

    private static final Logger log = LoggerFactory.getLogger(RetryTestService.class);

    private final RetryTemplate retryTemplate;
    private final Random random = new Random();

    public RetryTestService() {
        var retryPolicy = RetryPolicy.builder()
                .maxRetries(10)
                .delay(Duration.ofMillis(2000))
                .multiplier(1.5)
                .build();
        retryTemplate = new RetryTemplate(retryPolicy);
    }

    public String test() throws RetryException {
        final AtomicInteger attempt = new AtomicInteger(0);
        return retryTemplate.execute( () -> {
            int currentAttempt = attempt.incrementAndGet();
            if (random.nextDouble() > 0.5) {
                log.error("retry in {} times", currentAttempt);
                throw new RuntimeException("designed failed");
            }
            log.error("request success");
            return "success";
        });
    }
}
```

###### 加入监听器做完整日志

```java
import org.jspecify.annotations.NonNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.retry.RetryListener;
import org.springframework.core.retry.RetryPolicy;
import org.springframework.core.retry.Retryable;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicInteger;

@Component
public class RetryTestListener implements RetryListener {

    private static final Logger log = LoggerFactory.getLogger(RetryTestListener.class);

    private final AtomicInteger totalRetries = new AtomicInteger(0);
    private final AtomicInteger successfulRecoveries = new AtomicInteger(0);
    private final AtomicInteger finalFailures = new AtomicInteger(0);

    private final ThreadLocal<Integer> currentAttempt = ThreadLocal.withInitial(() -> 0);

    @Override
    public void beforeRetry(@NonNull RetryPolicy retryPolicy, Retryable<?> retryable) {
        int attemptNumber = currentAttempt.get() + 1;
        currentAttempt.set(attemptNumber);
        totalRetries.incrementAndGet();
        log.info("🔁 RetryListener: Attempt #{} starting for operation '{}'",
                attemptNumber,
                retryable.getName());
    }

    @Override
    public void onRetrySuccess(@NonNull RetryPolicy retryPolicy, @NonNull Retryable<?> retryable, Object result) {
        int attemptCount = currentAttempt.get();

        if (attemptCount > 1) {
            successfulRecoveries.incrementAndGet();
            log.info("✅ RetryListener: Operation '{}' succeeded after {} attempt(s)",
                    retryable.getName(),
                    attemptCount);
        } else {
            log.debug("✅ RetryListener: Operation '{}' succeeded on first attempt",
                    retryable.getName());
        }

        currentAttempt.remove();
    }

    @Override
    public void onRetryFailure(@NonNull RetryPolicy retryPolicy, Retryable<?> retryable, Throwable throwable) {
        int attemptCount = currentAttempt.get();
        finalFailures.incrementAndGet();
        log.error("❌ RetryListener: Operation '{}' failed after {} attempt(s): {}",
                retryable.getName(),
                attemptCount,
                throwable.getMessage());
        currentAttempt.remove();
    }
}
```

在实际使用时修改如下代码：

```java
@Service
public class RetryTestService {

    private static final Logger log = LoggerFactory.getLogger(RetryTestService.class);

    private final RetryTemplate retryTemplate;
    private final Random random = new Random();

    public RetryTestService(RetryTestListener retryTestListener) {
        var retryPolicy = RetryPolicy.builder()
                .maxRetries(10)
                .delay(Duration.ofMillis(2000))
                .multiplier(1.5)
                .build();
        retryTemplate = new RetryTemplate(retryPolicy);
        retryTemplate.setRetryListener(retryTestListener);
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

与 Spring 原生方式对应，Resilience4j 也提供并发限制相关的注解：

```java
@Bulkhead(name = "paymentService", maxConcurrentCalls = 10)
public String pay(Order order) {
}
```

### 参考资料

[Core Spring Resilience Features: @ConcurrencyLimit, @Retryable, and RetryTemplate](https://spring.io/blog/2025/09/09/core-spring-resilience-features)

[Resilience Features](https://docs.spring.io/spring-framework/reference/7.0-SNAPSHOT/core/resilience.html)

[Retryable JavaDoc](https://docs.spring.io/spring-framework/docs/7.0.0-SNAPSHOT/javadoc-api/org/springframework/resilience/annotation/Retryable.html)

[Resilience4j](https://resilience4j.readme.io/)

[Resilience4j-SpringBoot 文档](https://resilience4j.readme.io/docs/getting-started-3)

[Spring　Retry 官方项目](https://github.com/spring-projects/spring-retry)
