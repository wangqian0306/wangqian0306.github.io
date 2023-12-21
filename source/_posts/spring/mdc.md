---
title: MDC
date: 2023-12-21 21:32:58
tags:
- "Java"
- "Spring Boot"
id: mdc
no_word_count: true
no_toc: false
categories: 
- Spring
---

## MDC

### 简介

MDC(Mapped Diagnostic Context) 是 Log4j 日志库的一个概念或功能，可用于将相关日志消息分组在一起。

### 使用方式

首先需要编写一个过滤器用于拦截请求：

```java
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;

@Slf4j
public class MdcFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        try {
            HttpServletRequest httpServletRequest = (HttpServletRequest) request;
            String traceId = httpServletRequest.getHeader("traceId");
            if (traceId == null) {
                traceId = UUID.randomUUID().toString();
            }
            MDC.put("traceId", traceId);
            MDC.put("ts", String.valueOf(LocalDateTime.now().toInstant(ZoneOffset.UTC).toEpochMilli()));
            log.info(httpServletRequest.getRequestURL() + " call received");
            chain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

然后需要将此过滤器加载到 Spring ：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {

    @Bean
    public FilterRegistrationBean<MdcFilter> loggingFilter() {
        FilterRegistrationBean<MdcFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(new MdcFilter());
        registrationBean.addUrlPatterns("/*");
        return registrationBean;
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
```

编写如下配置文件设置显示样式：

```yaml
server:
  port: 8080
spring:
  application:
    name: demo
Logging:
  pattern:
    level: '%5p [${spring.application.name:},%mdc{traceId:-},%mdc{ts:-}]'
```

然后需要编写一个样例的 `Controller` ：

```java
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping
public class DemoController {

    @GetMapping("/demo")
    public String hello() {
        log.info("TraceId: {} - Hello World!", MDC.get("traceId"));
        return "Hello World!";
    }

}
```

访问 [http://localhost:8080/demo](http://localhost:8080/demo) 即可看到结果日志。

### 参考资料

[How to distinguish logging per Client or Request in Java? Use MDC or Mapped Diagnostic Context in Log4j Example](https://javarevisited.blogspot.com/2017/04/log4j-tips-use-mdc-or-mapped-dignostic-context-to-log-per-client-or-request.html#axzz8MVOI3ez5)

[基于MDC实现长链路跟踪](https://www.bilibili.com/video/BV1cN4y187Xj)
