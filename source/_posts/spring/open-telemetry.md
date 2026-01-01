---
title: OpenTelemetry
date: 2026-01-01 21:32:58
tags:
- "Java"
- "Spring"
- "OpenTelemetry"
id: open-telemetry
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## OpenTelemetry

### 简介

OpenTelemetry 是一组 API、SDK 和工具的集合。使用它来实现遥测数据（指标、日志和追踪）的监控、生成、收集和导出，帮助分析软件的性能和行为。

### 使用方式

在 SpringBoot 4.0.1 之后已经提供了 OpenTelemetry 的 starter，可以引入依赖：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-opentelemetry'
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-opentelemetry-test'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

准备 Docker 运行 Grafana :

```yaml
services:
  grafana-lgtm:
    image: 'grafana/otel-lgtm:latest'
    ports:
      - '3000'
      - '4317'
      - '4318'
```

修改配置连接到 Grafana :

```yaml
management:
  tracing:
    sampling:
      probability: 1.0
  otlp:
    metrics:
      export:
        url: http://localhost:4318/v1/metrics
  opentelemetry:
    tracing:
      export:
        otlp:
          endpoint: http://localhost:4318/v1/traces
```

> 注：注意采样率配置，在开发中可以用 1 默认是 0.1 不建议在生产环境中如此设置。

#### 导出日志(可选)

新增依赖：

```groovy
dependencies {
    implementation 'io.opentelemetry.instrumentation:opentelemetry-logback-appender-1.0:2.23.0-alpha'
}
```

新增配置：

```yaml
management:
  opentelemetry:
    logging:
      export:
        otlp:
          endpoint: http://localhost:4318/v1/logs
```

也可以编写 `src/main/resources/logback-spring.xml` 内容导出日志：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml"/>

    <appender name="OTEL" class="io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender">
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="OTEL"/>
    </root>
</configuration>
```

编写配置类：

```java
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.stereotype.Component;

@Component
class InstallOpenTelemetryAppender implements InitializingBean {

    private final OpenTelemetry openTelemetry;

    InstallOpenTelemetryAppender(OpenTelemetry openTelemetry) {
        this.openTelemetry = openTelemetry;
    }

    @Override
    public void afterPropertiesSet() {
        OpenTelemetryAppender.install(this.openTelemetry);
    }

}
```

### 参考资料

[Spring Boot 4 OpenTelemetry: From Zero to Full Observability in Minutes](https://www.youtube.com/watch?v=6_Y41z7OIv8)

[OpenTelemetry with Spring Boot](https://spring.io/blog/2025/11/18/opentelemetry-with-spring-boot)
