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
dnf insatll gcc -y
```

> 注：目前版本好像这个就够了，且由于 ld 包更新的原因导致最新版的 fedora 无法构建 native 容器。


然后使用如下命令即可完成构建：

```bash
./gradlew nativeCompile
```

若构建失败则可以尝试安装如下包：

```bash
dnf install libstdc++ libstdc++-docs libstdc++-static -y
dnf install zlib zlib-static -y
dnf install freetype freetype-devel -y
```

生成的二进制文件位于 `build/native/nativeCompile` 路径下，可以直接运行，用于检测打包是否完全。

> 注：如果遇到 137 代表构建内存不足，需要尝试清下内存或者使用如下环境变量限制内存：`export JAVA_TOOL_OPTIONS=-Xmx{size}m`。

### 自定义引入类

在引入 `GraalVM Native Support` 之后，打包过程中可能会忽略部分未使用的类，所以建议在运行时新增如下配置，手动标识引入内容。

#### ImportRuntimeHints

```java
import org.springframework.aot.hint.ExecutableMode;
import org.springframework.aot.hint.RuntimeHints;
import org.springframework.aot.hint.RuntimeHintsRegistrar;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ImportRuntimeHints;
import org.springframework.util.ReflectionUtils;

import java.lang.reflect.Method;

@Configuration
@ImportRuntimeHints(MyRuntimeHints.MyRuntimeRegistrar.class)
public class MyRuntimeHints {

    static class MyRuntimeRegistrar implements RuntimeHintsRegistrar {

        @Override
        public void registerHints(RuntimeHints hints, ClassLoader classLoader) {
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

}
```

> 注：生成的 hint 文件可以在 Maven 项目的 target/spring-aot/main/resources Gradle 项目的 build/generated/aotResources 目录中。

#### RegisterReflectionForBinding

在类上直接使用 `@RegisterReflectionForBinding` 注解。

#### Reflective

在方法上使用 `@Reflective` 注解。

### 安装其他命令

在项目中需要额外的软件或命令的时候，使用此方式就很烦了。spring 官方使用了 Paketo Buildpacks 作为 builder 但是它采用了 buildpack 弃用的 stack 方式来构建项目。自定义构建包难度好大，但是可以通过挂载卷的方式将命令挂载到容器中进行执行。



### 构建失败解决方案

由于 GraalVM Native Support 插件目前还没有正式完成，所以在容器构建时容易遇到很多小错误。此时就可以通过这些办法来得到类似的效果。

#### 自定义 jre

在本地构建项目，生成 jar 文件之后就可以通过此种方式来得到小型镜像了。

> 注：此处以 Java 23 和 gradle 作为构建工具。如果需要使用 maven 建议寻找参考资料中优化镜像的文档。

```bash
FROM eclipse-temurin:23-jdk-alpine AS jre-builder

WORKDIR /app
COPY build/libs/*.jar /app/app.jar
RUN apk update && \
    apk add --no-cache tar binutils
RUN jar xvf app.jar
RUN jdeps --ignore-missing-deps -q  \
    --recursive  \
    --multi-release 23  \
    --print-module-deps  \
    --class-path 'BOOT-INF/lib/*'  \
    app.jar > modules.txt
RUN $JAVA_HOME/bin/jlink \
         --verbose \
         --add-modules $(cat modules.txt) \
         --strip-debug \
         --no-man-pages \
         --no-header-files \
         --compress=2 \
         --output /optimized-jdk-23

FROM alpine:latest

WORKDIR /app
ENV JAVA_HOME=/opt/jdk/jdk-23
ENV PATH="${JAVA_HOME}/bin:${PATH}"
COPY --from=jre-builder /optimized-jdk-23 $JAVA_HOME
ARG APPLICATION_USER=spring
RUN addgroup --system $APPLICATION_USER &&  adduser --system $APPLICATION_USER --ingroup $APPLICATION_USER
RUN mkdir /app && chown -R $APPLICATION_USER /app
COPY build/libs/*.jar /app/app.jar
RUN chown $APPLICATION_USER:$APPLICATION_USER /app/app.jar
USER $APPLICATION_USER
EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "/app/app.jar" ]
```

### 参考资料

[Spring Boot Gradle Plugin 官方文档](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/htmlsingle/)

[官方文档](https://docs.spring.io/spring-boot/docs/current/reference/html/native-image.html)

[Gradle 插件官方文档](https://graalvm.github.io/native-build-tools/latest/gradle-plugin.html)

[成功优化！Java 基础 Docker 镜像从 674MB 缩减到 58MB 的经验分享](https://mp.weixin.qq.com/s/3Tzc4QyC8_5wiWqA73htQw)

[Spring Data Ahead of Time Repositories](https://spring.io/blog/2025/05/22/spring-data-ahead-of-time-repositories)