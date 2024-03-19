---
title: OpenRewrite
date: 2024-03-19 21:05:12
tags:
- "JAVA"
id: open-rewrite
no_word_count: true
no_toc: false
categories:
- "JAVA"
---

## OpenRewrite

### 简介

OpenRewrite 是一个用于源代码的自动重构生态系统，可以便捷的完成新版本的代码适配与迁移。

### 使用方式

首先需要在 Gradle 的 build.gradle 文件中添加如下代码：

```groovy
plugins {
    id 'org.openrewrite.rewrite' version '6.10.0'
}
rewrite {
}
```

之后就可以通过 `./gradlew rewriteDiscover ` 命令来查看 OpenRewrite 中的规则。

例如可以编辑如下所示的 [规则](https://docs.openrewrite.org/recipes/java/spring/boot3/springbootproperties_3_2) ，升级 Spring Boot 到 3.2 版本：

```groovy
plugins {
    id 'java'
    id 'org.openrewrite.rewrite' version '6.10.0'
    id 'org.springframework.boot' version '3.1.10-SNAPSHOT'
    id 'io.spring.dependency-management' version '1.1.4'
}

java {
    sourceCompatibility = '17'
}

rewrite {
    activeRecipe("org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_2")
}

configurations {
    compileOnly {
        extendsFrom annotationProcessor
    }
}

repositories {
    mavenCentral()
    maven { url 'https://repo.spring.io/milestone' }
    maven { url 'https://repo.spring.io/snapshot' }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    rewrite("org.openrewrite.recipe:rewrite-spring:5.6.0")
}

tasks.named('bootBuildImage') {
    builder = 'paketobuildpacks/builder-jammy-base:latest'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

之后即可使用 `./gradlew rewriteRun` 命令来运行 OpenRewrite。

除此之外还有很多的 OpenRewrite 的规则，可以参考 [规则官方页面](https://docs.openrewrite.org/recipes)。

### 参考资料

[官方网站](https://docs.openrewrite.org/)

[Upgrading your Java & Spring Boot applications with OpenRewrite in IntelliJ](https://www.youtube.com/watch?v=e4R6AZHpAD8)

[Upgrading your Java & Spring Applications with OpenRewrite](https://github.com/danvega/rewrite)
