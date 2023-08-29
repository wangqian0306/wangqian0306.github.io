---
title: Spring RSocket
date: 2023-08-29 21:32:58
tags:
- "Java"
- "Spring Boot"
- "RSocket"
id: rsocket
no_word_count: true
no_toc: false
categories: Spring
---

## Spring RSocket

### 简介

RSocket 是一种使用异步二进制流提供 Reactive Streams 语义的应用程序协议，使用它可以不关注底层的实现方式。

### 使用方式

引入如下依赖：

```grovvy
dependencies {
  implementation 'org.springframework.boot:spring-boot-starter-rsocket'
  implementation 'org.springframework.boot:spring-boot-starter-webflux'
  developmentOnly 'org.springframework.boot:spring-boot-devtools'
  testImplementation 'org.springframework.boot:spring-boot-starter-test'
  testImplementation 'io.projectreactor:reactor-test'
}
```

编写测试 Record：

```java
public record Message(String name, String content) {
}
```

编写测试 Controller：

```java
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;
import reactor.core.publisher.Mono;

import java.time.Instant;

@Controller
public class TestController {

    @MessageMapping("getByName")
    Mono<Message> getByName(String name) {
        return Mono.just(new Message(name, Instant.now().toString()));
    }

    @MessageMapping("create")
    Mono<Message> create(Message message) {
        return Mono.just(message);
    }

}
```

### 调试工具

#### RSocket Requests In HTTP Client

在 JetBrains Marketplace 中寻找 `RSocket Requests In HTTP Client` 插件并安装即可使用如下的 `test.http` 文件进行测试：

```text
### rsocket get demo
RSOCKET getByName
Host: localhost:9090
Content-Type: application/json

1

### rsocket complex_param demo
RSOCKET create
Host: localhost:9090
Content-Type: application/json

{
  "name": "wq",
  "content": "wqnice"
}
```

#### RSocket Client CLI (RSC)

访问 [https://github.com/making/rsc/releases](https://github.com/making/rsc/releases) 即可获取到最新的命令行工具。

使用如下命令即可完成测试：

```bash
java -jar rsc.jar --debug --request --data "wq" --route getByName tcp://localhost:9090
```

或：

```bash
java -jar rsc.jar --debug --request --data '{"name":"wq","content":"nice"}' --route create tcp://localhost:9090
```

> 注：在本地它报错了，尚且不清楚原因。

### 参考资料

[官方文档](https://docs.spring.io/spring-framework/reference/rsocket.html)

[Getting Started With RSocket On Spring Boot](https://github.com/benwilcock/spring-rsocket-demo)

[RSocket Client CLI (RSC)](https://github.com/making/rsc)
