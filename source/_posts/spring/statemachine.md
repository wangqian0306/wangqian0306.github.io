---
title: Spring Statemachine
date: 2023-05-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: statemachine
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Statemachine

### 简介

Spring Statemachine (SSM) 是一个允许应用程序开发人员在 Spring 应用程序中使用传统状态机概念的框架。 

> 注：状态机，是表示有限个状态以及在这些状态之间的转移和动作等行为的数学计算模型。

### 使用方式

首先需要在 `build.gradle` 中引入 starter：

```groovy
dependencies {
	compileOnly 'org.springframework.statemachine:spring-statemachine-starter:4.0.0'
}
```

然后创建以下枚举类：

```java
public enum StatesEnum {
    SI, S1, S2
}
```

```java
public enum  EventsEnum {
    E1, E2
}
```

创建以下任务配置类：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.statemachine.config.EnableStateMachine;
import org.springframework.statemachine.config.EnumStateMachineConfigurerAdapter;
import org.springframework.statemachine.config.builders.StateMachineConfigurationConfigurer;
import org.springframework.statemachine.config.builders.StateMachineStateConfigurer;
import org.springframework.statemachine.config.builders.StateMachineTransitionConfigurer;
import org.springframework.statemachine.listener.StateMachineListener;
import org.springframework.statemachine.listener.StateMachineListenerAdapter;
import org.springframework.statemachine.state.State;

import java.util.EnumSet;

@Configuration
@EnableStateMachine
public class StateMachineConfig
        extends EnumStateMachineConfigurerAdapter<StatesEnum, EventsEnum> {

    @Override
    public void configure(StateMachineConfigurationConfigurer<StatesEnum, EventsEnum> config)
            throws Exception {
        config
                .withConfiguration()
                .autoStartup(true)
                .listener(listener());
    }

    @Override
    public void configure(StateMachineStateConfigurer<StatesEnum, EventsEnum> states)
            throws Exception {
        states
                .withStates()
                .initial(StatesEnum.SI)
                .states(EnumSet.allOf(StatesEnum.class));
    }

    @Override
    public void configure(StateMachineTransitionConfigurer<StatesEnum, EventsEnum> transitions)
            throws Exception {
        transitions
                .withExternal()
                .source(StatesEnum.SI).target(StatesEnum.S1).event(EventsEnum.E1)
                .and()
                .withExternal()
                .source(StatesEnum.S1).target(StatesEnum.S2).event(EventsEnum.E2);
    }

    @Bean
    public StateMachineListener<StatesEnum, EventsEnum> listener() {
        return new StateMachineListenerAdapter<>() {
            @Override
            public void stateChanged(State<StatesEnum, EventsEnum> from, State<StatesEnum, EventsEnum> to) {
                System.out.println("State change to " + to.getId());
            }
        };
    }
}
```

创建如下测试类：

```java
import jakarta.annotation.Resource;
import org.springframework.messaging.Message;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.statemachine.StateMachine;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("/demo")
public class TestController {

    @Resource
    private StateMachine<StatesEnum, EventsEnum> stateMachine;

    @GetMapping
    public String test() {
        Message<EventsEnum> eventMessage1 = MessageBuilder
                .withPayload(EventsEnum.E1)
                .build();
        stateMachine.sendEvent(Mono.just(eventMessage1)).subscribe();
        Message<EventsEnum> eventMessage2 = MessageBuilder
                .withPayload(EventsEnum.E2)
                .build();
        stateMachine.sendEvent(Mono.just(eventMessage2)).subscribe();
        return "success";
    }

}
```

之后启动程序，访问 [http://localhost:8080/demo](http://localhost:8080/demo) 即可获取到输出。

### 参考资料

[官方文档](https://docs.spring.io/spring-statemachine/docs/current/reference/)

[【IT老齐476】十分钟上手Spring 状态机](https://www.bilibili.com/video/BV1bF4m157jM)
