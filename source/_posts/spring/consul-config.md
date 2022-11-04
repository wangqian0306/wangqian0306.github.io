---
title: Spring Cloud Consul 动态配置
date: 2022-11-04 21:05:12
tags:
- "JAVA"
- "Spring Cloud"
- "Consul"
id: consul-config
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Cloud Consul 动态配置

### 简介

如同 Nacos 一样 Consul 也支持配置存储，并且也提供了配置自动更新的机制。

### 项目搭建

创建 Spring Cloud 项目，然后按照如下配置引入依赖包

```groovy
ext {
    set('springCloudVersion', "2022.0.0-M5")
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.cloud:spring-cloud-starter-consul-config'
    implementation 'org.springframework.cloud:spring-cloud-starter-consul-discovery'
    implementation('org.springframework.cloud:spring-cloud-starter-bootstrap')
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.springframework.boot:spring-boot-configuration-processor'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

dependencyManagement {
    imports {
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:${springCloudVersion}"
    }
}
```

编辑 Spring 配置文件 `application.yaml`：

```yaml
spring:
  application:
    name: <name>
  cloud:
    consul:
      host: ${CONSUL_HOST:localhost}
      port: ${CONSUL_PORT:8500}
      discovery:
        prefer-ip-address: true
        tags: version=1.0
        instance-id: ${spring.application.name}:${spring.cloud.client.hostname}:${spring.cloud.client.ip-address}:${server.port}
        healthCheckInterval: 15s

server:
  port: 8080
  error:
    include-message: always
    include-exception: true
  servlet:
    encoding:
      charset: UTF-8
```

编辑引入配置文件 `bootstrap.yaml`：

```yaml
spring:
  cloud:
    consul:
      config:
        enabled: true
        defaultContext: <name>
        profileSeparator: '-'
        prefixes: config
        format: YAML
```

编辑 Spring 主类并添加如下注解：

```java
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableDiscoveryClient
@EnableScheduling
@SpringBootApplication
public class DynApplication {
}
```

编辑 Spring 配置类

```java
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.context.annotation.Configuration;

@Slf4j
@Getter
@Setter
@RefreshScope
@Configuration
@ConfigurationProperties(prefix = "my")
public class MyProperties {

    private String prop;

}
```

编辑调试接口类：

```java
import com.example.dyn.conf.MyProperties;
import jakarta.annotation.Resource;
import org.springframework.http.HttpEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/demo")
public class DemoController {

    @Resource
    MyProperties myProperties;

    @GetMapping
    public HttpEntity<String> get() {
        return new HttpEntity<>(myProperties.getProp());
    }
}
```

进入 consul 中编辑配置文件目录及文件

```text
config/<name>/data
```

```yaml
my:
  prop:
    demo-1
```

### 流程测试

```http request
### 获取配置项
GET http://localhost:8080/demo

### 使用 HTTP 接口读取配置项
GET http://localhost:8500/v1/kv/config/dyn-default/data
```

### 参考资料

[Spring Cloud Consul 官方文档](https://docs.spring.io/spring-cloud-consul/docs/current/reference/html/#spring-cloud-consul-config)

[Consul KV store HTTP 接口手册](https://developer.hashicorp.com/consul/api-docs/kv)
