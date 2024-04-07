---
title: Spring AI
date: 2024-03-29 21:32:58
tags:
- "Java"
- "Spring Boot"
- "AI"
id: spring-ai
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring AI

### 简介

类似于 LangChain，Spring 也提供了和大模型的相关库。目前主要支持文本对话和从文本生成图像。但是对于向量数据库的支持比较好。

### 使用方式

#### Ollama Chat

在 [Spring Initializer](https://start.spring.io/) 里可以引入如下内容：

- Ollama
- Spring Web
- Spring Reactive Web

可以得到如下样例：

```groovy
repositories {
    mavenCentral()
    maven { url 'https://repo.spring.io/milestone' }
}

ext {
    set('springAiVersion', "0.8.1")
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    implementation 'org.springframework.ai:spring-ai-transformers-spring-boot-starter'
    implementation 'org.springframework.ai:spring-ai-ollama-spring-boot-starter'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test'
}

dependencyManagement {
    imports {
        mavenBom "org.springframework.ai:spring-ai-bom:${springAiVersion}"
    }
}
```

之后编写如下接口即可：

```java
import org.springframework.ai.chat.ChatResponse;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.OllamaChatClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.Map;

@RestController
@RequestMapping("/chat")
public class OllamaChatController {

    private final OllamaChatClient chatClient;

    public OllamaChatController(OllamaChatClient chatClient) {
        this.chatClient = chatClient;
    }

    @GetMapping("/ollama/generate")
    public Map<String, String> generate(@RequestParam(value = "message", defaultValue = "Tell me a joke") String message) {
        return Map.of("generation", chatClient.call(message));
    }

    @GetMapping("/ollama/generateStream")
    public Flux<ChatResponse> generateStream(@RequestParam(value = "message", defaultValue = "Tell me a joke") String message) {
        Prompt prompt = new Prompt(new UserMessage(message));
        return chatClient.stream(prompt);
    }

}
```

然后需要进行如下配置：

```yaml
spring:
  application:
    name: xxx
  ai:
    ollama:
      base-url: http://xxx.xxx.xxx.xxx:11434
      chat:
        options:
          model: llama2
```

如果是提供自定义提示词则可以使用如下代码：

```java
@RestController
public class DadJokeController {

    private final ChatClient chatClient;

    public DadJokeController(ChatClient chatClient) {
        this.chatClient = chatClient;
    }

    @GetMapping("/api/jokes")
    public String jokes() {
        var system = new SystemMessage("You primary function is to tell Dad Jokes. If someone asks you for any other type of joke please tell them you only know Dad Jokes");
        var user = new UserMessage("Tell me a joke");
//        var user = new UserMessage("Tell me a very serious joke about the earth");
        Prompt prompt = new Prompt(List.of(system, user));
        return chatClient.call(prompt).getResult().getOutput().getContent();
    }
}
```

如果想要使用自定义数据源则可以采用如下方式：

```java

```

### 参考资料

[官方文档](https://docs.spring.io/spring-ai/reference/index.html)

[spring-into-ai](https://github.com/danvega/spring-into-ai)
