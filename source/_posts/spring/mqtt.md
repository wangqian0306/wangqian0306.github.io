---
title: Spring MQTT
date: 2024-06-19 21:32:58
tags:
- "Java"
- "Spring Boot"
- "MQTT"
id: spring-mqtt
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring MQTT

### 简介

Spring 提供了 Message Queueing Telemetry Transport(MQTT) 协议的插件。

### 使用

安装依赖(maven)：

```xml
<dependency>
    <groupId>org.springframework.integration</groupId>
    <artifactId>spring-integration-mqtt</artifactId>
    <version>6.3.1</version>
</dependency>
```

安装依赖(gradle)：

```groovy
compile "org.springframework.integration:spring-integration-mqtt:6.3.1"
```

#### 读取消息

#### 写入消息

```java
@Bean
public MessageChannel mqttOutboundChannel() {
    return new DirectChannel();
}

@Bean
public MessageHandler mqttOutbound() {
    MqttPahoMessageHandler messageHandler = new MqttPahoMessageHandler("spring-boot-client", mqttClientFactory());
    messageHandler.setAsync(true);
    messageHandler.setDefaultTopic("testTopic");
    return messageHandler;
}

@Bean
public MqttPahoClientFactory mqttClientFactory() {
    DefaultMqttPahoClientFactory factory = new DefaultMqttPahoClientFactory();
    MqttConnectOptions options = new MqttConnectOptions();
    options.setServerURIs(new String[] { "tcp://localhost:1883" });
    factory.setConnectionOptions(options);
    return factory;
}

@Bean
@ServiceActivator(inputChannel = "mqttOutboundChannel")
public MessageHandler mqttOutboundHandler() {
    MqttPahoMessageHandler messageHandler = new MqttPahoMessageHandler("spring-boot-client", mqttClientFactory());
    messageHandler.setAsync(true);
    messageHandler.setDefaultTopic("testTopic");
    return messageHandler;
}
```

```java
import org.springframework.integration.annotation.MessagingGateway;

@MessagingGateway(defaultRequestChannel = "mqttOutboundChannel")
public interface MqttGateway {

    void sendToMqtt(String data);
}
```

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MqttSenderService {

    @Autowired
    private MqttGateway mqttGateway;

    public void sendData(String data) {
        mqttGateway.sendToMqtt(data);
    }
}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-integration/reference/mqtt.html)
