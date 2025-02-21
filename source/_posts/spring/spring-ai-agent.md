---
title: Spring AI Agent
date: 2025-02-17 21:32:58
tags:
- "Java"
- "Spring Boot"
- "AI"
id: spring-ai-agent
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring AI Agent

### 简介

Agent 技术可以通过很多种方式定义。一些人将其定义为一套完全自主的系统，这些系统在长时间内独立运行，用外界的各种工具来完成复杂的任务。还有一些人将其定义为让 AI 遵循一系列的工作流程，来获取好的结果。可以将其抽象为以下两种形式：

- 工作流(Workflows)，从之前定义的计划出发，利用各种 LLM 和工具达成目标。
- Agents，从 LLM 自行判断出发，自动完成分发任务，动态判断执行情况，结合实际需求选择工具等。

在利用 AI 处理问题的时候容易出现表达不明确的问题。可以借用 Agent 技术来解决复杂的问题，提升用户体验。

> 注：此文章会涉及到 Spring AI 的相关知识。

### 基本逻辑

![The augmented LLM](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2Fd3083d3f40bb2b6f477901cc9a240738d3dd1371-2401x1000.png&w=3840&q=75)

基本的运行逻辑是一致的，首先需要类似 RAG 做内容补充，之后调用接口，将运行信息进行记录。

### Workflow

#### Prompt Chaining

![Prompt Chaining](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F7418719e3dab222dccb379b8879e1dc08ad34c78-2401x1000.png&w=3840&q=75)

通过固定的流程，将职责分发给不同的 LLM，例如用 LLAMA 生成但是 Qwen 翻译成中文结果。

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/chat/ollama/v2/prompt-chain-agent")
public class PromptChainAgent {

    private static final Logger log = LoggerFactory.getLogger(PromptChainAgent.class);

    private static final String[] DEFAULT_SYSTEM_PROMPTS = {
            "You are an interpreter, help me explain what I am saying",
            "将输入内容转化为中文"
    };

    private static final String[] DEFAULT_MODEL_LIST = {
            "llama3.1",
            "qwen2.5:7b"
    };

    private final ChatClient chatClient;

    private final String[] systemPrompts;

    public PromptChainAgent(ChatClient.Builder builder) {
        this.chatClient = builder.build();
        this.systemPrompts = DEFAULT_SYSTEM_PROMPTS;
    }

    @GetMapping
    public String chat(@RequestParam(defaultValue = "hello world") String message) {
        int step = 0;
        String response = message;
        log.info(String.format("\nSTEP %s:\n %s", step++, response));
        for (String prompt : systemPrompts) {
            String input = String.format("{%s}\n {%s}", prompt, response);
            if (step%2 == 0) {
                response = chatClient.prompt(new Prompt(input, OllamaOptions.builder().model(DEFAULT_MODEL_LIST[1]).build())).call().content();
            } else {
                response = chatClient.prompt(new Prompt(input, OllamaOptions.builder().model(DEFAULT_MODEL_LIST[0]).build())).call().content();
            }
            log.info(String.format("\nSTEP %s:\n %s", step++, response));
            if (response == null || response.contains("I don't know")) {
                throw new RuntimeException("error");
            }
        }
        return response;
    }
}
```

#### Routing

![Routing](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F5c0c0e9fe4def0b584c04d37849941da55e5e71c-2401x1000.png&w=3840&q=75)

通过让 LLM 选择不同的 LLM 来回答问题，例如用 LLAMA 回答英文问题，Qwen 回答中文问题。

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/chat/ollama/v2/routing-agent")
public class RoutingAgent {

    private final ChatClient chatClient;

    public RoutingAgent(ChatClient.Builder builder) {
        this.chatClient = builder.defaultAdvisors(new SimpleLoggerAdvisor()).build();
    }

    private static final String[] DEFAULT_ROUTES_SYSTEM_PROMPTS = new String[]{
            "你是一个中国人，你知道怎么回答中文的问题",
            "You are an American, you know how to answer English questions"
    };

    private static final String[] DEFAULT_MODEL_LIST = {
            "qwen2.5:7b",
            "llama3.1"
    };

    public record RoutingResult(Integer answer, String reason) {}

    private RoutingResult determineRoute(String input) {
        String selectorPrompt = String.format("""
                Analyze the input and select the most appropriate support team from these options: 中国人, American
                If the American suit for answer return 1 else return 0 provide with json format.
                \\{
                    "reason": "Brief explanation of why this ticket should be routed to a specific team.
                                Consider key terms, user intent, and urgency level.",
                    "answer": "The chosen team name"
                \\}
                Input: %s
                """, input);
        return chatClient.prompt(selectorPrompt).call().entity(RoutingResult.class);
    }

    @GetMapping
    public String chat(@RequestParam(defaultValue = "什么是春节") String message) {
        int index = determineRoute(message).answer();
        return chatClient.prompt(new Prompt(DEFAULT_ROUTES_SYSTEM_PROMPTS[index], OllamaOptions.builder().model(DEFAULT_MODEL_LIST[index]).build())).user(message).call().content();
    }
}
```

#### Parallelization

![Parallelization](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F406bb032ca007fd1624f261af717d70e6ca86286-2401x1000.png&w=3840&q=75)

通过将不同的子问题发送到不同的 LLM 来加速生成结果。

```java
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.ollama.api.OllamaOptions;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/chat/ollama/v2/parallelization-agent")
public class ParallelizationAgent {

    private final ChatClient chatClient;

    public ParallelizationAgent(ChatClient.Builder builder) {
        this.chatClient = builder.defaultAdvisors(new SimpleLoggerAdvisor()).build();
    }

    @PostMapping
    public List<String> chat(@RequestBody List<String> messageList) {
        try (ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor()) {
            List<CompletableFuture<String>> futures = messageList.stream()
                    .map(input -> CompletableFuture.supplyAsync(() -> {
                        try {
                            return chatClient.prompt(new Prompt(input, OllamaOptions.builder().build())).call().content();
                        } catch (Exception e) {
                            throw new RuntimeException("Failed to process input: " + input, e);
                        }
                    }, executor))
                    .toList();
            CompletableFuture<Void> allFutures = CompletableFuture.allOf(
                    futures.toArray(new CompletableFuture[0]));
            allFutures.join();
            return futures.stream()
                    .map(CompletableFuture::join)
                    .collect(Collectors.toList());
        }
    }
}
```

#### Orchestrator-workers

![Orchestrator-workers](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F8985fc683fae4780fb34eab1365ab78c7e51bc8e-2401x1000.png&w=3840&q=75)

通过 LLM 将问题分解，然后转发给不同的 LLM 处理问题，例如用 code 模型处理代码，LLAMA 生成描述。

#### Evaluator-optimizer

![Evaluator-optimizer](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F14f51e6406ccb29e695da48b17017e899a6119c7-2401x1000.png&w=3840&q=75)

设立两个 LLM ,一个解答一个检查，如果遇到问题给到反馈，例如用 code 模型编码，LLAMA 检查代码风格和格式

### Agent

![Agent](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F58d9f10c985c4eb5d53798dea315f7bb5ab6249e-2401x1000.png&w=3840&q=75)

LLM 自行判断需要向外获取什么内容，结果是否可用。

### 参考资料

[Building effective agents](https://www.anthropic.com/research/building-effective-agents)

[官方博客](https://spring.io/blog/2025/01/21/spring-ai-agentic-patterns)

[示例代码](https://github.com/spring-projects/spring-ai-examples/tree/main/agentic-patterns)
