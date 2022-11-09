---
title: Spring for Apache Kafka
date: 2022-11-09 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Kafka"
id: spring-for-apache-kafka
no_word_count: true
no_toc: false
categories: Spring
---

## Spring for Apache Kafka

### 简介

Spring 官方封装了 Kafka 相关的 API，可以让 Spring 应用程序更方便的使用 Kafka。

### 使用

#### 引入依赖

maven

```xml
<dependency>
    <groupId>org.springframework.kafka</groupId>
    <artifactId>spring-kafka</artifactId>
</dependency>
```

gradle

```groovy
dependencies {
    compileOnly 'org.springframework.kafka:spring-kafka'
}
```

#### 链接配置

```yaml
spring:
  kafka:
    bootstrap-servers: <host_1>:<port_1>;<host_2>:<port_2>
    listener:
      ack-mode: manual
    producer:
      retries: 6
```

> 注：可以根据需求调整 ack-mode 如需手动则可进行上述配置，默认则无需配置此项。`producer.retries` 代表生产者遇到故障时的重试次数。

#### Producer

```java
@Slf4j
@RestController
@RequestMapping("/kafka")
public class KafkaDemoController {

    @Resource
    KafkaTemplate<String, String> kafkaTemplate;

    @GetMapping
    public HttpEntity<String> get() {
        kafkaTemplate.send("topic", "key", "value");
        return new HttpEntity<>("success");
    }
}
```

#### Consumer

```java
@Slf4j
@Component
public class CustomKafkaListener implements ConsumerSeekAware {

    public Long seekOffset = 0L;

    private final ThreadLocal<ConsumerSeekCallback> seekCallBack = new ThreadLocal<>();

    @KafkaListener(topics = "topic", groupId = "group", concurrency = "${consumer-concurrency:2}")
    public void listenTestTopic(ConsumerRecord<String, String> record) {
        log.error(record.key() + " " + record.value() + " " + record.partition() + " " + record.offset());
    }

    @KafkaListener(topics = "topic", groupId = "group", concurrency = "${consumer-concurrency:2}")
    public void listenTestTopicAndCommit(ConsumerRecord<String, String> record, Acknowledgment ack) {
        log.error(record.key() + " " + record.value() + " " + record.partition() + " " + record.offset());
        ack.acknowledge();
    }

    @Override
    public void registerSeekCallback(ConsumerSeekCallback callback) {
        this.seekCallBack.set(callback);
    }

}
```

> 注: consumer-concurrency 可以配置 Consumer 的线程数。

### 参考资料

[官方文档](https://docs.spring.io/spring-kafka/docs/current/reference/html/#preface)
