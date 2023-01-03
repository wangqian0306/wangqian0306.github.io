---
title: Gradle 的初步使用
date: 2020-07-01 23:09:32
tags:
- "JAVA"
- "Gradle"
id: gradle-quick-start
no_word_count: true
no_toc: false
categories: JAVA
---

## Gradle 的初步使用

### 使用 IDEA 如何配置 Gradle

在 IDEA 2020.1 中默认会下载并配置 Gradle。所以在没有安装的情况下也可以正常使用 Gradle。

需要注意的是在使用 IDEA 自带 Gradle 的时候无法使用 gradle 命令。

如果有特殊需求可以通过项目中的 gradlew 脚本文件进行使用。

### 配置软件源

在 `~/.gradle/` 目录中创建 `init.gradle` 文件并填入下面的内容即可配置阿里云加速：

```text
allprojects{
    repositories {
        def ALIYUN_REPOSITORY_URL = 'https://maven.aliyun.com/repository/public'
        def ALIYUN_JCENTER_URL = 'https://maven.aliyun.com/repository/jcenter'
        maven {
            url ALIYUN_REPOSITORY_URL
            allowInsecureProtocol true
        }
        maven {
            url ALIYUN_JCENTER_URL
            allowInsecureProtocol true
        }
        google()
    }
}
```

### 切换本地的 Gradle

在 IDEA 的 `Settings` -> `Build, Execution, Deployment` -> `Build Tools` -> `Gradle` 中可以对 Gradle 进行配置。

如果需要选用本地的 Gradle 可以选择 `Gradle projects` 栏中的 `Use Gradle from` 选项卡，将其内容配置为 `Specified location` 即可。

### 常用命令

- 生成模板项目

```bash
gradle init
```

> 注：在生成的时候可以仔细观察输入参数，可以简单的生成多模板项目等内容。

- 编译 java 文件

```bash
gradle compileJava
```

- 运行程序

```bash
gradle run
```

- 构建程序

```bash
gradle build
```

### 指定程序主类

在 `build.gradle` 文件中新增如下内容即可

```groovy
jar {
    manifest {
        attributes 'Main-Class': 'xxx.xxx.xxx'
    }
}
```

### 包的引入模式

在 `dependencies` 模块中有如下的引入模式

- implementation(正常引入)
- compileOnly(仅编译)
- compileClasspath
- testImplementation
- testRuntimeOnly
- testCompileClasspath

### 参考资料

[官方文档](https://docs.gradle.org/current/userguide/userguide.html)
