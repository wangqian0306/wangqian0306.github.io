---
title: Spring Boot Configuration Metadata
date: 2022-07-22 21:32:58
tags:
- "Java"
- "Spring Boot"
id: conf
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Boot Configuration Metadata

### 简介

除了使用 `@Value` 注解之外还可以引入此包来实现配置项的引入功能。

> 注：这样使用还可以避免 IDEA 读取配置项报警的问题。

### 使用方式

首先需要引入依赖包

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

```groovy
dependencies {
    annotationProcessor "org.springframework.boot:spring-boot-configuration-processor"
}
```

然后需要编写配置项文件

```java
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Setter
@Getter
@ConfigurationProperties(prefix = "xxx.xxx")
public class XxxProperties {

    private Integer xxx = 10;

    private Integer yyy = 10;

}
```

最后要在启动类中标识配置项文件

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties({XxxProperties.class})
public class XxxApplication {

    public static void main(String[] args) {
        SpringApplication.run(Xxx.class, args);
    }

}
```

### 配置 IDEA

进入如下配置项

`Settings` -> `Build,Execution,Deployment` -> `Compiler` -> `Annotation Processors` 

打开如下配置即可

`Enable annotation processing`

### 参考资料

[Properties with Spring and Spring Boot](https://www.baeldung.com/properties-with-spring)

[SpringBoot 中的 ConfigurationProperties](https://www.cnblogs.com/54chensongxia/p/15250479.html)

[官方网站](https://docs.spring.io/spring-boot/docs/current/reference/html/configuration-metadata.html#appendix.configuration-metadata)
