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

Spring Boot 可以通过默认的 `gradle` 或 `maven` 插件省略 `Dockerfile` 的形式构建容器，而且在 3.0 版本之后也支持使用 GraalVM native-image 编译器将 Spring 应用程序编译为本机可执行文件和容器，非常适合容器云平台。

### 使用

- 项目初始化
  - 建议访问 [Spring Initializr](https://start.spring.io/) ，创建初始化 `gradle` 项目，(可选)引入 `GraalVM Native Support` Dependencies

- (可选)在 `build.gradle` 中可以配置加速和镜像名：

```groovy
tasks.named("bootBuildImage") {
    environment["HTTP_PROXY"] = "http://<host>:<port>"
    environment["HTTPS_PROXY"] = "https://<host>:<port>"
    imageName = "<repository>/<dir>/${rootProject.name}:${project.version}"
}
```

> 注: 如果引入了 `GraalVM Native Support` 则会默认使用 `paketobuildpacks/builder:tiny` 否则使用 `paketobuildpacks/builder:base`，且首次拉取镜像所花的时间会比较长。

- 运行打包命令 `./gradlew bootBuildImage` 等待镜像打包完成即可。

> 注：打包时间较长，且针对网络和内存需求比较严苛，建议提前配置好 github 加速。

- 修改配置文件

项目可执行文件和根目录都位于 `/workspace` 路径下，可以挂载配置文件至此位置。

### 测试构建的二进制包

在引入 `GraalVM Native Support` 之后会将程序打包成二进制包，然后再引入 Docker 中，构建时间较长，为了解决频繁打包的问题建议在本地打包二进制程序进行测试：

首先可以安装如下 `c++` 依赖：

```bash
dnf install libstdc++ libstdc++-docs libstdc++-static -y
dnf install zlib zlib-static -y
dnf install freetype freetype-devel -y
```

然后使用如下命令即可完成构建：

```bash
./gradlew nativeCompile
```

生成的二进制文件位于 `build/native/nativeCompile` 路径下，可以直接运行，用于检测打包是否完全。

> 注：如果遇到 137 代表构建内存不足，需要尝试清下内存或者使用如下环境变量限制内存：`export JAVA_TOOL_OPTIONS=-Xmx{size}m`。

### 自定义引入类

在引入 `GraalVM Native Support` 之后，打包过程中可能会忽略部分未使用的类，所以建议在运行时新增如下配置，手动标识引入内容。

#### ImportRuntimeHints

```java
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

然后在主类中写入注解：

```java
@ImportRuntimeHints(MyRuntimeHints.class)
```

#### RegisterReflectionForBinding

在类上直接使用 `@RegisterReflectionForBinding` 注解。

#### Reflective

在方法上使用 `@Reflective` 注解。

### 参考资料

[Spring Boot Gradle Plugin 官方文档](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/htmlsingle/)

[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/native-image.html)
