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

    @Bean
    public NewTopic topic() {
        return TopicBuilder.name("topic1")
                .partitions(10)
                .replicas(1)
                .build();
    }

    @GetMapping("/sync")
    public HttpEntity<String> syncSend() {
        try {
            kafkaTemplate.send("wq", "asd", "123").get();
        } catch (InterruptedException | ExecutionException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
        return new HttpEntity<>("success");
    }

    @GetMapping("/async")
    public HttpEntity<String> asyncSend() {
        kafkaTemplate.send("wq", "asd", "123");
        return new HttpEntity<>("success");
    }
    
}
```

> 注：异步方式可能会导致发送失败，建议在配置当中声明重试次数或者配置回调。

回调配置

```java
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.springframework.kafka.support.ProducerListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class CustomProducerListener implements ProducerListener<String, String> {

    @Override
    public void onSuccess(ProducerRecord<String, String> producerRecord,
                        RecordMetadata recordMetadata) {
        log.error("success callback");
    }

    @Override
    public void onError(ProducerRecord<String, String> producerRecord,
                        RecordMetadata recordMetadata,
                        Exception exception) {
        log.error("error callback");
    }

}
```

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;

import javax.annotation.Resource;

@Slf4j
@Configuration
public class CustomKafkaConf {

    @Resource
    DefaultKafkaProducerFactory<String, String> defaultKafkaProducerFactory;

    @Resource
    CustomProducerListener customProducerListener;

    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        KafkaTemplate<String, String> kafkaTemplate = new KafkaTemplate<>(defaultKafkaProducerFactory);
        kafkaTemplate.setProducerListener(customProducerListener);
        return kafkaTemplate;
    }

}
```

#### Consumer

```java
@Slf4j
@Component
public class CustomKafkaListener implements ConsumerSeekAware {

    public Boolean seekFlag = false;

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

    @KafkaListener(topics = "topic", groupId = "group")
    public void seekListener(ConsumerRecord<String, String> record) {
        if (seekFlag) {
            seekToOffset("topic", null, 0L);
            this.seekFlag = false;
        }
    }

    @Override
    public void registerSeekCallback(ConsumerSeekCallback callback) {
        this.seekCallBack.set(callback);
    }
    
    public void seekToOffset(String topic, Integer partition, Long offset) {
        if (partition == null) {
            Map<String, TopicDescription> result = kafkaAdmin.describeTopics(topic);
            TopicDescription topicDescription = result.get(topic);
            List<TopicPartitionInfo> partitions = topicDescription.partitions();
            for (TopicPartitionInfo topicPartitionInfo : partitions) {
                this.seekCallBack.get().seek(topic, topicPartitionInfo.partition(), offset);
            }
        } else {
            this.seekCallBack.get().seek(topic, partition, offset);
        }
    }

}
```

> 注: consumer-concurrency 可以配置 Consumer 的线程数。且 seek 操作需要在有数据消费时才能触发。

### 参考资料

[官方文档](https://docs.spring.io/spring-kafka/docs/current/reference/html/#preface)
