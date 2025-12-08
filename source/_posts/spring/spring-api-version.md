---
title: Spring Api Version
date: 2024-12-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-api-version
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring Api Version

### 简介

在 SpringBoot 4 中，Spring 官方针对 API 版本控制提供了一种解决方案。

### 实现方式

#### 基于配置文件

新增如下配置：

```yaml
spring:
  mvc:
    apiversion:
      use:
        path-segment: 1
      default: 1
```

#### 基于代码

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.web.servlet.config.annotation.ApiVersionConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void configureApiVersioning(ApiVersionConfigurer configurer) {
        configurer
                .usePathSegment(1)
                .setDefaultVersion("1.0")
                .setVersionParser(new ApiVersionParser());
    }
}
```

#### 业务

编写如下 Controller :

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class VersionController {

    @GetMapping(value = "/{version}/version", version = "1.0")
    public String current() {
        return "Version 1";
    }

    @GetMapping(value = "/{version}/version", version = "2.0")
    public String next() {
        return "Version 2";
    }

}
```

或者将其放在 `@RequestMapping` 中也是生效的：

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/{version}/version")
public class VersionController {

    @GetMapping(version = "1.0")
    public String current() {
        return "Version 1";
    }

    @GetMapping(version = "2.0")
    public String next() {
        return "Version 2";
    }

}
```

新建请求测试文件 test.http :

```text
### Current

GET http://localhost:8080/api/1/version

### Next

GET http://localhost:8080/api/2/version
```

### 参考资料

[API Version](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-config/api-version.html)

[First-Class API Versioning in Spring Boot 4](https://www.danvega.dev/blog/spring-boot-4-api-versioning)
