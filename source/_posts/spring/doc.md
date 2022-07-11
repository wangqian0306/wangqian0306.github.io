---
title: springdoc-openapi
date: 2020-07-12 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Swagger"
id: springdoc-openapi
no_word_count: true
no_toc: false
categories: Spring
---

## springdoc-openapi

### 简介

springdoc-openapi 是一款类似于 springfox 的社区项目，可以通过注解生成文档，并且提供了 swagger-ui 方便调试。

### 使用方式

引入项目依赖：

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-ui</artifactId>
    <version>1.6.9</version>
</dependency>
```

配置 swagger 地址：

```properties
springdoc.swagger-ui.path=/swagger-ui.html
```

然后在程序代码中加入如下注解及其参数即可：

- controller
  - `@Tag`
  - `@Parameter`
  - `@Operation`
  - `@ApiResponse`
- module
  - `@Schema`

> 注：相关注解的详细说明参见 swagger 文档。

### 参考资料

[官方网站](https://springdoc.org/)

[官方例程](https://github.com/springdoc/springdoc-openapi-demos)

[注解说明文档](https://github.com/swagger-api/swagger-core/wiki/Swagger-2.X---Annotations)

[swagger 官网](https://swagger.io/)
