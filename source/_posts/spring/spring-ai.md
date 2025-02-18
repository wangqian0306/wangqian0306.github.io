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

之后为了使用更新版本的 Ollama 需要进行如下修改：

```groovy
repositories {
    mavenCentral()
    maven { url 'https://repo.spring.io/milestone' }
    maven { url 'https://repo.spring.io/snapshot' }
}

ext {
    set('springAiVersion', "1.0.0-SNAPSHOT")
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
public record Song(String song, Integer year) {
}
```

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.embedding.EmbeddingResponse;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.List;

@RestController
@RequestMapping("/ollama")
public class ChatController {

    private final ChatClient chatClient;
    private final EmbeddingModel embeddingModel;

    public ChatController(ChatClient.Builder builder, EmbeddingModel embeddingModel) {
        this.chatClient = builder.defaultOptions(OllamaOptions.builder().model("llama3.1").build()).build();
        this.embeddingModel = embeddingModel;
    }

    @GetMapping("/chat")
    public String simple(@RequestParam(required = false, defaultValue = "hello") String message) {
        return chatClient.prompt().user(message).call().content();
    }

    @GetMapping("/embedding")
    public EmbeddingResponse embedding(@RequestParam(required = false, defaultValue = "hello") String message) {
        return this.embeddingModel.embedForResponse(List.of(message));
    }

    @GetMapping("/chat/stream")
    public Flux<String> simpleFlux(@RequestParam(required = false, defaultValue = "hello") String message) {
        return chatClient.prompt().user(message).stream().content();
    }

    @GetMapping("/chat/parser")
    public List<Song> simpleParser(@RequestParam(required = false, defaultValue = "Taylor Swift") String artist) {
        String question = """
                Please give me a list of top 10 songs and it's release year for the artist {artist}.  If you don't know the answer , just say "I don't know".
                """;
        return chatClient.prompt().user(u -> u.text(question).param("artist", artist)).call().entity(new ParameterizedTypeReference<>() {
        });
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
          model: llama3.1
          num-ctx: 2048
      embedding:
        options:
          model: nomic-embed-text
```

num-ctx 参数是程序上下文的大小配置，如果有需求可以从 2k 提升到 8k, 16k, 32k 最大值为 128k。需要注意的是越大的上下文会影响硬件的内存部分。

> 注：此处返回的结果与格式和模型有较大的关系，建议使用 `ollama run llama3` 先进行测试，其他参数详见 [配置参考](https://docs.spring.io/spring-ai/reference/api/chat/ollama-chat.html) 

##### 设置不同模型

如果需要为不同的接口使用不同的模型则可以使用如下代码：

```java
ChatResponse chatResponse = chatClient.prompt(
                new Prompt(
                        "Generate the names of 5 famous pirates.", 
                        OllamaOptions.builder().model("llama3.1").build()
                )).call().chatResponse();
```

##### RAG

如果想要使用 RAG 则可以采用如下方式：

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.reader.TextReader;
import org.springframework.ai.transformer.splitter.TextSplitter;
import org.springframework.ai.transformer.splitter.TokenTextSplitter;
import org.springframework.ai.vectorstore.SimpleVectorStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.File;
import java.util.List;

@Configuration
public class RagConfig {

    private static final Logger log = LoggerFactory.getLogger(RagConfig.class);

    @Value("./vectorstore.json")
    private String vectorStorePath;

    @Value("classpath:/docs/olympic-faq.txt")
    private Resource faq;

    @Bean
    SimpleVectorStore simpleVectorStore(EmbeddingModel embeddingModel) {
        var simpleVectorStore = SimpleVectorStore.builder(embeddingModel).build();;
        var vectorStoreFile = new File(vectorStorePath);
        if (vectorStoreFile.exists()) {
            log.info("Vector Store File Exists,");
            simpleVectorStore.load(vectorStoreFile);
        } else {
            log.info("Vector Store File Does Not Exist, load documents");
            TextReader textReader = new TextReader(faq);
            textReader.getCustomMetadata().put("filename", "olympic-faq.txt");
            List<Document> documents = textReader.get();
            TextSplitter textSplitter = new TokenTextSplitter();
            List<Document> splitDocuments = textSplitter.apply(documents);
            simpleVectorStore.add(splitDocuments);
            simpleVectorStore.save(vectorStoreFile);
        }
        return simpleVectorStore;
    }
}
```

然后编写 `RagController` : 

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.QuestionAnswerAdvisor;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/chat/ollama/v2/rag")
public class RagController {

    private final ChatClient chatClient;

    public RagController(ChatClient.Builder builder, VectorStore vectorStore) {
        this.chatClient = builder.defaultAdvisors(new QuestionAnswerAdvisor(vectorStore, SearchRequest.builder().build())).build();
    }

    @GetMapping
    public String rag(@RequestParam(value = "message", defaultValue = "How many athletes compete in the Olympic Games Paris 2024") String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
```

> 注：此处的 Advisors 是 Spring 在调用大模型时拦截并处理请求的组件。默认提供的 Advisor 有以下三项：历史记录管理(xxChatMemoryAdvistor)，RAG 增强(QuestionAnswerAdvisor)，敏感词过滤(SafeGuardAdvisor)。具体内容参见 [官方博客](https://spring.io/blog/2024/10/02/supercharging-your-ai-applications-with-spring-ai-advisors)

最后需要补充 `resources/prompts/rag-prompt-template.st` 提示词模板：

```text
You are a helpful assistant, conversing with a user about the subjects contained in a set of documents.
Use the information from the DOCUMENTS section to provide accurate answers. If unsure or if the answer
isn't found in the DOCUMENTS section, simply state that you don't know the answer.

QUESTION:
{input}

DOCUMENTS:
{documents}
```

和问答资料库 `resources/docs/olympic-faq.txt`：

```text

Q: How to buy tickets for the Olympic Games Paris 2024?
A: Tickets for the Olympic Games Paris 2024 are available for spectators around the world only on the official ticketing website. To buy tickets, click here.

The Paris 2024 Hospitality program offers packages that include tickets for sporting events combined with exceptional services in the competition venues (boxes, lounges) or in the heart of the city (accommodation, transport options, gastronomy, tourist activities, etc.).

The Paris 2024 Hospitality program is delivered by the official Paris 2024 Hospitality provider, On Location.

For more information about the Paris 2024 Hospitality & Travel offers, click here.

Q: What is the official mascot of the Olympic Games Paris 2024?
A: The Olympic Games Paris 2024 mascot is Olympic Phryge. The mascot is based on the traditional small Phrygian hats for which they are shaped after.

The name and design were chosen as symbols of freedom and to represent allegorical figures of the French republic.

The Olympic Phryge is decked out in blue, white and red - the colours of France’s famed tricolour flag - with the golden Paris 2024 logo emblazoned across its chest.

Q: When and where are the next Olympic Games?
A: The Olympic Games Paris 2024 will take place in France from 26 July to 11 August.

Q: What sports are in the Olympic Games Paris 2024?
A: 3X3 Basketball
Archery
Artistic Gymnastics
Artistic Swimming
Athletics
Badminton
Basketball
Beach Volleyball
Boxing
Breaking
Canoe Slalom
Canoe Sprint
Cycling BMX Freestyle
Cycling BMX Racing
Cycling Mountain Bike
Cycling Road
Cycling Track
Diving
Equestrian
Fencing
Football
Golf
Handball
Hockey
Judo
Marathon Swimming
Modern Pentathlon
Rhythmic Gymnastics
Rowing
Rugby Sevens
Sailing
Shooting
Skateboarding
Sport Climbing
Surfing
Swimming
Table Tennis
Taekwondo
Tennis
Trampoline
Triathlon
Volleyball
Water Polo
Weightlifting
Wrestling

Q:Where to watch the Olympic Games Paris 2024?
A: In France, the 2024 Olympic Games will be broadcast by Warner Bros. Discovery (formerly Discovery Inc.) via Eurosport, with free-to-air coverage sub-licensed to the country's public broadcaster France Télévisions. For a detailed list of the Paris 2024 Media Rights Holders here.

Q: How many athletes compete in the Olympic Games Paris 2024?
A: Around 10,500 athletes from 206 NOCs will compete.


Q: How often are the modern Olympic Games held?
A: The summer edition of the Olympic Games is normally held every four years.

Q: Where will the 2028 and 2032 Olympic Games be held?
A: Los Angeles, USA, will host the next Olympic Games from 14 to 30 July 2028. Brisbane, Australia, will host the Games in 2032.

Q: What is the difference between the Olympic Summer Games and the Olympic Winter Games?
A: The summer edition of the Olympic Games is a multi-sport event normally held once every four years usually in July or August.

The Olympic Winter Games are also held every four years in the winter months of the host location and the multi-sports competitions are practised on snow and ice.

Both Games are organised by the International Olympic Committee.

Q: Which cities have hosted the Olympic Summer Games?
A: 1896 Athens
1900 Paris
1904 St. Louis
1908 London
1912 Stockholm
1920 Antwerp
1924 Paris
1928 Amsterdam
1932 Los Angeles
1936 Berlin
1948 London
1952 Helsinki
1956 Melbourne
1960 Rome
1964 Tokyo
1968 Mexico City
1972 Munich
1976 Montreal
1980 Moscow
1984 Los Angeles
1988 Seoul
1992 Barcelona
1996 Atlanta
2000 Sydney
2004 Athens
2008 Beijing
2012 London
2016 Rio de Janeiro
2020 Tokyo
2024 Paris

Q: What year did the Olympic Games start?
A: The inaugural Games took place in 1896 in Athens, Greece.
```

> 注：如果不配置 Ollama embedding options model 的话在初次启动时需要拉取 hugginface 和 github 当中的内容，启动时间较长且对网络环境要求很高。

> 注： 读取 RAG 部分的官方文档在 [ETL Pipeline文档中](https://docs.spring.io/spring-ai/reference/api/etl-pipeline.html)

##### 对话记录

编写如下代码即可：

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.InMemoryChatMemory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import static org.springframework.ai.chat.client.advisor.AbstractChatMemoryAdvisor.CHAT_MEMORY_CONVERSATION_ID_KEY;

@RestController
@RequestMapping("/ollama")
public class MemoryController {

    private final ChatClient chatClient;

    public MemoryController(ChatClient.Builder builder) {
        this.chatClient = builder.defaultAdvisors(new MessageChatMemoryAdvisor(new InMemoryChatMemory()))
                .build();
    }

    @GetMapping("/chat/memory")
    public String rag(
            @RequestParam(defaultValue = "Here is chat room 1") String message,
            @RequestParam(defaultValue = "1") String conversionId) {
        return chatClient.prompt()
                .user(message)
                .advisors(a -> a.param(CHAT_MEMORY_CONVERSATION_ID_KEY, conversionId))
                .call()
                .content();
    }
}
```

##### 对话日志

> 注：此处需要 Spring AI 的版本要大于 1.0.0-SNAPSHOT 。

编写如下代码：

```java
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/ollama")
public class LogController {

    private final ChatClient chatClient;

    public LogController(ChatClient.Builder builder) {
        this.chatClient = builder.defaultAdvisors((new SimpleLoggerAdvisor()).build();
    }

    @GetMapping("/chat/log")
    public String rag(
            @RequestParam(defaultValue = "Hi") String message) {
        return chatClient.prompt()
                .user(message)
                .call()
                .content();
    }
}
```

然后修改日志配置即可：

```yaml
logging:
  level:
    org:
      springframework:
        ai:
          chat:
            client:
              advisor: DEBUG
```

##### 函数调用

> 注：此处需要 Spring AI 的版本要大于 1.0.0-SNAPSHOT 。

编写需要被调用的函数 `MockWeatherService.java` ：

```java
import java.util.function.Function;

public class MockWeatherService implements Function<MockWeatherService.Request, MockWeatherService.Response> {

    public enum Unit { C, F }
    public record Request(String location, Unit unit) {}
    public record Response(double temp, Unit unit) {}

    public Response apply(Request request) {
        System.out.println("call mock service");
        return new Response(30.0, Unit.C);
    }
}
```

编写配置类 `Config.java`：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Description;

import java.util.function.Function;

@Configuration
public class Config {

    @Bean
    @Description("Get the weather in location")
    public Function<MockWeatherService.Request, MockWeatherService.Response> currentWeatherFunction() {
        return new MockWeatherService();
    }

}
```

编写请求类：

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    private final ChatClient client;

    public TestController(ChatClient.Builder builder) {
        this.client = builder
                .defaultSystem("You are a helpful AI Assistant answering questions about cities around the world.")
                .defaultFunctions("currentWeatherFunction")
                .build();
    }

    @GetMapping("/weather")
    public String weather(@RequestParam String message) {
        return client.prompt()
                .user(message)
                .call()
                .content();
    }

}
```

之后启动服务然后编写如下请求即可：

```text
GET http://localhost:8080/weather?message=What's the weather like in Beijing
```

##### 指标监控

> 注：此处需要 Spring AI 的版本要大于 1.0.0-SNAPSHOT 。

可以搭配 Spring Boot Actuator 访问官方提供的 [监控端点](https://docs.spring.io/spring-ai/reference/api/generic-model.html)

如果想检查请求的执行逻辑还可以引入 Zipkin 检查用户输入查询后，Spring 请求 LLM 接口花费的时间等细节内容。

### 参考资料

[官方文档](https://docs.spring.io/spring-ai/reference/index.html)

[spring-into-ai](https://github.com/danvega/spring-into-ai)

[Spring AI 1.0.0 M1 released](https://spring.io/blog/2024/05/30/spring-ai-1-0-0-m1-released)

[Spring AI with Ollama Tool Support](https://spring.io/blog/2024/07/26/spring-ai-with-ollama-tool-support)

[Spring Tips: Spring AI Observability](https://www.youtube.com/watch?v=afU8cK0pnpY)

[AI Model Context Decoded](https://www.youtube.com/watch?v=-Lyk7ygQw2E)