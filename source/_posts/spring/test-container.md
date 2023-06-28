---
title: Testcontainers
date: 2023-06-28 21:32:58
tags:
- "Java"
- "Spring Boot"
- "container"
id: test-containers
no_word_count: true
no_toc: false
categories: Spring
---

## Testcontainers

### 简介

Testcontainers 是一个开源框架，用于提供数据库、消息总线、WEB 浏览器或任何可以在 Docker 容器中运行的东西的一次性轻量级实例。

目前，SpringBoot 支持了如下这些容器：

- `CassandraContainer`
- `CouchbaseContainer`
- `ElasticsearchContainer`
- `GenericContainer` 可以使用 `redis` 或 `openzipkin/zipkin`
- `JdbcDatabaseContainer`
- `KafkaContainer`
- `MongoDBContainer`
- `MariaDBContainer`
- `MSSQLServerContainer`
- `MySQLContainer`
- `Neo4jContainer`
- `OracleContainer`
- `PostgreSQLContainer`
- `RabbitMQContainer`
- `RedpandaContainer`

### 使用方式

在项目创建的时候引入 `Testcontainer`，在样例中以 MySQL 作为样例，依赖如下：

```grovvy
dependencies {
	implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
	implementation 'org.springframework.boot:spring-boot-starter-web'
	compileOnly 'org.projectlombok:lombok'
	developmentOnly 'org.springframework.boot:spring-boot-devtools'
	runtimeOnly 'com.mysql:mysql-connector-j'
	annotationProcessor 'org.projectlombok:lombok'
	testImplementation 'org.springframework.boot:spring-boot-starter-test'
	testImplementation 'org.springframework.boot:spring-boot-testcontainers'
	testImplementation 'org.testcontainers:junit-jupiter'
    testImplementation 'org.testcontainers:mysql'
}
```

单元测试样例如下：

```java
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Testcontainers;

import net.bytebuddy.utility.dispatcher.JavaDispatcher.Container;

@SpringBootTest
@Testcontainers
class DemoApplicationTests {

	@Container
    @ServiceConnection
    static MySQLContainer<?> mysqlContainer() {
        return new MySQLContainer<>("mysql:latest");
    }

	@Test
	void contextLoads() {
		
	}

}
```

> 注：除了单元测试之外，还可以直接使用容器作为开发环境。从 test 包中启动如下代码即可：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.MySQLContainer;

@TestConfiguration(proxyBeanMethods = false)
public class TestDemoApplication {

    @Bean
    @ServiceConnection
    MySQLContainer<?> mysqlContainer() {
        return new MySQLContainer<>("mysql:latest");
    }

    public static void main(String[] args ) {
        SpringApplication.from(xxxx::main).with(TestDemoApplication.class).run(args);
    }
    
}
```

### 参考资料

[官方网站](https://testcontainers.com/)

[SpringBoot Testcontainers 文档](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#features.testing.testcontainers)

[Improved Testcontainers Support in Spring Boot 3.1](https://spring.io/blog/2023/06/23/improved-testcontainers-support-in-spring-boot-3-1)
