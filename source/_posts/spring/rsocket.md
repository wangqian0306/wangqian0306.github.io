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

编写配置文件 `application.yaml`：

```yaml
server:
  port: 8080
spring:
  rsocket:
    server:
      port: 7000
```

编写单元测试：

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.messaging.rsocket.RSocketRequester;
import org.springframework.messaging.rsocket.RSocketStrategies;
import org.springframework.util.MimeTypeUtils;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

import static org.assertj.core.api.Assertions.assertThat;


@SpringBootTest
public class TestControllerTest {

    private RSocketRequester requester;

    @Autowired
    private RSocketStrategies rSocketStrategies;

    @BeforeEach
    public void setup() {
        requester = RSocketRequester.builder()
                .rsocketStrategies(rSocketStrategies)
                .dataMimeType(MimeTypeUtils.APPLICATION_JSON)
                .tcp("localhost", 7000);
    }

    @Test
    public void testGetByName() {
        Mono<Message> result = requester
                .route("getByName")
                .data("demo")
                .retrieveMono(Message.class);

        // Verify that the response message contains the expected data
        StepVerifier
                .create(result)
                .consumeNextWith(message -> {
                    assertThat(message.name()).isEqualTo("demo");
                })
                .verifyComplete();
    }

    @Test
    public void testCreate() {
        Mono<Message> result = requester
                .route("create")
                .data(new Message("TEST", "Request"))
                .retrieveMono(Message.class);

        // Verify that the response message contains the expected data
        StepVerifier
                .create(result)
                .consumeNextWith(message -> {
                    assertThat(message.name()).isEqualTo("TEST");
                    assertThat(message.content()).isEqualTo("Request");
                })
                .verifyComplete();
    }

}
```

### WebSocket 

除了使用 tcp 链接之外还可以采用 WebSocket 协议，仅需完成如下配置:

```yaml
server:
  port: 8080
spring:
  rsocket:
    server:
      port: 7000
      mapping-path: /rsocket
      transport: websocket
```

测试类的部分则需要修改链接的建立方式：

```java
@BeforeEach
public void setup() {
    requester = RSocketRequester.builder()
            .rsocketStrategies(rSocketStrategies)
            .dataMimeType(MimeTypeUtils.APPLICATION_JSON)
            .websocket(URI.create("ws://localhost:7000/rsocket"));
}
```

### 调试工具

#### RSocket Requests In HTTP Client

在 JetBrains Marketplace 中寻找 `RSocket Requests In HTTP Client` 插件并安装即可使用如下的 `test.http` 文件进行测试：

```text
### rsocket getByName
RSOCKET getByName
Host: localhost:9090
Content-Type: application/json

1

### rsocket create
RSOCKET create
Host: localhost:9090
Content-Type: application/json

{
  "name": "wq",
  "content": "wqnice"
}

### rsocket getByName websocket
RSOCKET getByName
Host: ws://localhost:7000/rsocket
Content-Type: application/json

1
```

#### RSocket Client CLI (RSC)

访问 [https://github.com/making/rsc/releases](https://github.com/making/rsc/releases) 即可获取到最新的命令行工具。

使用如下命令即可完成测试：

```bash
java -jar rsc.jar --debug --request --data "wq" --route getByName tcp://localhost:7000
```

或：

```bash
java -jar rsc.jar --debug --request --data '{"name":"wq","content":"nice"}' --route create tcp://localhost:7000
```

> 注：不要使用 CMD 或 Power Shell 直接用 Bash，否则会报错。

在 WebSocket 协议中应该采用下面的命令：

```bash
java -jar rsc.jar --debug --request --data '1' --route getByName ws://localhost:7000/rsocket
```

### 参考资料

[Spring Framework 官方文档](https://docs.spring.io/spring-framework/reference/rsocket.html)

[Spring Boot 官方文档](https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#messaging.rsocket)

[Getting Started With RSocket On Spring Boot](https://github.com/benwilcock/spring-rsocket-demo)

[RSocket Client CLI (RSC)](https://github.com/making/rsc)
