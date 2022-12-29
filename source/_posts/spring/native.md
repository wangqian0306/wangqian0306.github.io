---
title: Spring Native
date: 2022-07-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: native
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Native

### 简介

Spring Native 支持使用 GraalVM native-image 编译器将 Spring 应用程序编译为本机可执行文件和容器，非常适合容器云平台。

### 使用

- 项目初始化
  - 建议访问 [Spring Initializr](https://start.spring.io/) ，创建初始化 `gradle` 项目，且引入 `Spring Native [Experimental]` Dependencies

- (可选配置)在 `build.gradle` 中可以填入如下配置：

```groovy
tasks.named("bootBuildImage") {
    environment["HTTP_PROXY"] = "http://<host>:<port>"
    environment["HTTPS_PROXY"] = "https://<host>:<port>"
    builder = "paketobuildpacks/builder:tiny"
    runImage = "paketobuildpacks/run:tiny"
    imageName = "<repository>/<dir>/${rootProject.name}:${project.version}"
}
```

- 运行打包命令 `./gradlew bootBuildImage` 等待镜像打包完成即可。

> 注：打包时间较长，且针对网络和内存需求比较严苛，建议提前配置好 github 加速，清理设备空余内存保证可用内存至少有 4 GB。

### 参考资料

[官方文档](https://docs.spring.io/spring-native/docs/current/reference/htmlsingle/)

[Introduction to Spring Native](https://www.baeldung.com/spring-native-intro)
