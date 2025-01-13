---
title: Spring Modulith
date: 2024-09-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: modulith
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring Modulith

### 简介

Spring Modulith 是一个工具包，用于构建领域驱动的模块化应用程序。Modulith 通过使用 ApplicationEvent 的方式来分离不同的程序模块。并且支持了如下事件的持久化记录：

- JPA
- JDBC
- MongoDB
- Neo4j

除了将事件写入数据库之外，还可以将数据写出到如下平台：

- Kafka
- AMQP
- JMS
- AWS SQS
- AWS SNS

### 使用

首先需要在 [https://start.spring.io](https://start.spring.io) 上引入如下依赖：

- Spring Web
- Spring Data JPA
- MySQL
- Spring Modulith 

> 注：此处建议使用 Maven 管理依赖，Gradle 在单元测试部分有 Bug

新建项目，然后创建 `order` 包，并在其中建立 `package-info.java` 文件：

```java
@org.springframework.lang.NonNullApi
package com.xxx.xxx.order;
```

创建 `OrderCompleted.java` 文件：

```java
import java.util.UUID;

import org.jmolecules.event.types.DomainEvent;

public record OrderCompleted(UUID orderId) implements DomainEvent {}
```

创建 `OrderManagement.java` 文件：

```java
import jakarta.annotation.Resource;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class OrderManagement {

    @Resource
    private ApplicationEventPublisher events;

    @Transactional
    public void complete() {
        events.publishEvent(new OrderCompleted(UUID.randomUUID()));
    }

}
```

创建 `OrderController.java` 文件：

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/order")
public class OrderController {

    @Resource
    private OrderManagement orderManagement;

    @PostMapping
    public void completeOrder() {
        orderManagement.complete();
    }

}
```

创建 `inventory` 包，并在其中建立 `package-info.java` 文件：

```java
@org.springframework.lang.NonNullApi
package com.xxx.xxx.inventory;
```

创建 `InventoryUpdated.java` 文件：

```java
import java.util.UUID;

public record InventoryUpdated(UUID orderId) {
}
```

创建 `InventoryManagement.java` 文件：

```java
import com.rainbowfish.motest.order.OrderCompleted;
import jakarta.annotation.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.modulith.events.ApplicationModuleListener;
import org.springframework.stereotype.Service;

@Service
class InventoryManagement {

    private static final Logger LOG = LoggerFactory.getLogger(InventoryManagement.class);

    @Resource
    private ApplicationEventPublisher events;

    @ApplicationModuleListener
    void on(OrderCompleted event) throws InterruptedException {
        var orderId = event.orderId();
        LOG.info("Received order completion for {}.", orderId);
        Thread.sleep(1000);
        events.publishEvent(new InventoryUpdated(orderId));
        LOG.info("Finished order completion for {}.", orderId);
    }

}
```

之后就可以在 `test` 目录下新建单元测试 `ModularityTests.java` ：

```java
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.docs.Documenter;

class ModularityTests {

    ApplicationModules modules = ApplicationModules.of(Application.class);

    @Test
    void verifiesModularStructure() {
        modules.verify();
    }

    @Test
    void createModuleDocumentation() {
        new Documenter(modules).writeDocumentation();
    }
}
```

然后创建 `ApplicationIntegrationTests.java` 文件：

```java
import java.util.Collection;

import com.rainbowfish.motest.order.OrderManagement;
import com.rainbowfish.motest.inventory.InventoryUpdated;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.modulith.events.core.EventPublicationRegistry;
import org.springframework.modulith.test.EnableScenarios;
import org.springframework.modulith.test.Scenario;

@SpringBootTest
@EnableScenarios
class ApplicationIntegrationTests {

    @Autowired
    OrderManagement orders;
    @Autowired
    EventPublicationRegistry registry;

    @Test
    void bootstrapsApplication(Scenario scenario) throws Exception {
        scenario.stimulate(() -> orders.complete())
                .andWaitForStateChange(() -> registry.findIncompletePublications(), Collection::isEmpty)
                .andExpect(InventoryUpdated.class)
                .toArrive();
    }
    
}
```

通过单元测试后可以编写 `test.http` 文件进行测试：

```text
###
POST http://localhost:8080/order
```

### 参考资料

[官方文档](https://docs.spring.io/spring-modulith/reference/)

[示例代码](https://github.com/joshlong/bootiful-spring-boot-2024)

[Bootiful Spring Boot (SpringOne 2024)](https://www.youtube.com/watch?v=ex7rnzIMmlk)

[Bootiful Spring Boot 3.4: Spring Modulith](https://spring.io/blog/2024/11/24/bootiful-34-modulith)

[官方样例](https://github.com/spring-projects/spring-modulith/tree/main/spring-modulith-examples)

[mplementing Domain Driven Design with Spring by Maciej Walkowiak @ Spring I/O 2024](https://www.youtube.com/watch?v=VGhg6Tfxb60)
