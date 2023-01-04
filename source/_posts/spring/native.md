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

> 注：

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

- 修改配置文件

项目可执行文件和根目录都位于 `/workspace` 路径下，可以挂载配置文件至此位置。

### 自定义引入类

由于打包过程中可能会忽略部分未使用的类，所以建议在运行时新增如下配置，保证引入内容。

```java
@Configuration
public class MyRuntimeHints implements RuntimeHintsRegistrar {

    @Override
    public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
        // Register method for reflection
        Method method = ReflectionUtils.findMethod(MyClass.class, "sayHello", String.class);
        hints.reflection().registerMethod(method, ExecutableMode.INVOKE);

        // Register resources
        hints.resources().registerPattern("my-resource.txt");

        // Register serialization
        hints.serialization().registerType(MySerializableClass.class);

        // Register proxy
        hints.proxies().registerJdkProxy(MyInterface.class);
    }

}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/native-image.html)
