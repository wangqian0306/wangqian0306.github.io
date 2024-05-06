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
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.ai.parser.ListOutputParser;
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

    @GetMapping("/ollama/outputParser")
    public List<String> getWithOutputParser(@RequestParam(value = "artist", defaultValue = "Taylor Swift") String artist) {
        String message = """
                Please give me a list of top 10 songs for the artist {artist}.  If you don't know the answer , just say "I don't know".And Just give me the important part.
                {format}
                """;
        ListOutputParser outputParser = new ListOutputParser(new DefaultConversionService());
        PromptTemplate promptTemplate = new PromptTemplate(message, Map.of("artist", artist, "format", outputParser.getFormat()));
        Prompt prompt = promptTemplate.create();
        ChatResponse response = chatClient.call(prompt);
        return outputParser.parse(response.getResult().getOutput().getContent());
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
          model: llama3
```

> 注：此处返回的结果与格式和模型有较大的关系，建议使用 `ollama run llama3` 先进行测试。

多种提示词则可以使用如下代码：

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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.document.Document;
import org.springframework.ai.embedding.EmbeddingClient;
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
public class RagConfiguration {

    private static final Logger log = LoggerFactory.getLogger(RagConfiguration.class);

    @Value("./vectorstore.json")
    private String vectorStorePath;

    @Value("classpath:/docs/olympic-faq.txt")
    private Resource faq;

    @Bean
    SimpleVectorStore simpleVectorStore(EmbeddingClient embeddingClient) {
        var simpleVectorStore = new SimpleVectorStore(embeddingClient);
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

然后修改 `ChatController` : 

```java
import org.springframework.ai.chat.prompt.PromptTemplate;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.ai.chat.ChatResponse;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.OllamaChatClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/chat")
public class OllamaChatController {

    private final OllamaChatClient chatClient;
    private final VectorStore vectorStore;
    @Value("classpath:/prompts/rag-prompt-template.st")
    private Resource ragPromptTemplate;

    public OllamaChatController(OllamaChatClient chatClient, VectorStore vectorStore) {
        this.chatClient = chatClient;
        this.vectorStore = vectorStore;
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

    @GetMapping("/ollama/rag")
    public String faq(@RequestParam(value = "message", defaultValue = "How can I buy tickets for the Olympic Games Paris 2024") String message) {
        List<Document> similarDocuments = vectorStore.similaritySearch(SearchRequest.query(message).withTopK(2));
        List<String> contentList = similarDocuments.stream().map(Document::getContent).toList();
        PromptTemplate promptTemplate = new PromptTemplate(ragPromptTemplate);
        Map<String, Object> promptParameters = new HashMap<>();
        promptParameters.put("input", message);
        promptParameters.put("documents", String.join("\n", contentList));
        Prompt prompt = promptTemplate.create(promptParameters);
        return chatClient.call(prompt).getResult().getOutput().getContent();
    }

}
```

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

> 注：在初次启动时需要拉取 hugginface 和 github 当中的内容，启动时间较长且对网络环境要求很高。

### 参考资料

[官方文档](https://docs.spring.io/spring-ai/reference/index.html)

[spring-into-ai](https://github.com/danvega/spring-into-ai)
