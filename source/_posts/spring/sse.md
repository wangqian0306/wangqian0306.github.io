---
title: Spring Boot SSE
date: 2023-05-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: sse
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Boot SSE

### 简介

Server-Sent Events (SSE) 是一种服务器推送技术，使客户端能够通过HTTP连接从服务器接收自动更新。

### 实现方式

编写 `Message` 类：

```java
import lombok.Data;

@Data
public class Message {

    private String userId;

    private String message;

}
```

编写 `EventHandler`：

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter.SseEventBuilder;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class EventHandler {

    private static final long DEFAULT_TIMEOUT = 60 * 60 * 1000L;
    private final ConcurrentHashMap<String, SseEmitter> emitterConcurrentHashMap = new ConcurrentHashMap<>();

    public SseEmitter registerClient(String userId) {
        if (emitterConcurrentHashMap.containsKey(userId)) {
            return emitterConcurrentHashMap.get(userId);
        } else {
            SseEmitter emitter = new SseEmitter(DEFAULT_TIMEOUT);
            emitter.onCompletion(() -> emitterConcurrentHashMap.remove(userId));
            emitter.onError((err) -> removeAndLogError(userId));
            emitter.onTimeout(() -> removeAndLogError(userId));
            return emitterConcurrentHashMap.put(userId, emitter);
        }
    }

    private void removeAndLogError(String userId) {
        log.info("Error during communication. Unregister client {}", userId);
        emitterConcurrentHashMap.remove(userId);
    }

    public void broadcastMessage(Message message) {
        emitterConcurrentHashMap.forEach((k, v) -> sendMessage(k, message));
    }

    private void sendMessage(String userId, Message message) {
        var sseEmitter = emitterConcurrentHashMap.get(userId);
        try {
            log.info("Notify client " + userId + " " + message.toString());
            SseEventBuilder eventBuilder = SseEmitter.event().data(message, MediaType.APPLICATION_JSON).name("chat");
            sseEmitter.send(eventBuilder);
        } catch (IOException e) {
            sseEmitter.completeWithError(e);
        }
    }

}
```

编写接口 `SSEController`：

```java
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
public class SSEController {

    @Resource
    private EventHandler eventHandler;

    @PostMapping("/message")
    public void sendMessage(@RequestBody Message message) {
        eventHandler.broadcastMessage(message);
    }

    @GetMapping("/connect")
    public SseEmitter connect(@RequestParam(defaultValue = "admin") String userId) {
        return eventHandler.registerClient(userId);
    }

}
```

#### 使用 IDEA Httpclient 检测

```text
### SSE
GET http://localhost:8080/connect
Accept: text/event-stream

### Message
POST http://localhost:8080/message
Content-Type: application/json

{
    "userId": "admin",
    "message": "Hello"
}
```

#### 使用前端代码检测

编写 `src/main/resources/static/chat.js` 前端业务逻辑：

```javascript
"use strict";

async function postData(url, data) {
  const response = await fetch(url, {
    method: 'POST',
    mode: 'cors',
    cache: 'no-cache',
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json'
    },
    redirect: 'follow',
    referrerPolicy: 'no-referrer',
    body: JSON.stringify(data)
  });
  return response;
}

function send() {
  const input = document.getElementById('messageInput').value;
  console.error(window.assignedName);
  postData('/message',{ message: input, userId: window.assignedName});
}

function handleChatEvent(eventData) {
  const userNameNode = document.createElement('span');
  userNameNode.innerHTML = eventData.userId + ': ';
  const li = document.createElement("li");
  li.appendChild(userNameNode);
  li.appendChild(document.createTextNode(eventData.message));
  const ul = document.getElementById("list");
  ul.appendChild(li);
}

function registerSSE(url) {
  const source = new EventSource(url);
  source.addEventListener('chat', event => {
    console.error("ininini");
    handleChatEvent(JSON.parse(event.data));
  })
  source.onopen = event => console.log("Connection opened");
  source.onerror = event => console.error("Connection error");
  source.onmessage = event => console.error("ininini");
  return source;
}

function connect() {
  let url = "/connect?userId=" + document.getElementById('username').value
  document.getElementById('connect').hidden = true;
  window.assignedName = document.getElementById('username').value;
  window.eventSource = registerSSE(url);
}
```

编写页面 `src/main/resources/static/index.html`:

```html
<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width,  initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>

<div class="center">
    <input class="text" id="username" placeholder="">
    <button id="connect" type="submit" value="Connect" onclick="connect()">Connect</button>
</div>

<div>
    <input class="text" id="messageInput" placeholder="">
    <button type="submit" value="Send" onclick="send()">Send Message</button>
    <ul id="list"></ul>
</div>

<script src="chat.js"></script>

</body>
</html>
```

### 常见问题

#### 链接超时

由于是长连接所以可能出现链接超时的情况，例如在 k8s 上使用 nginx-ingress-controller 就可能遇到，建议参照 ingress 文档进行配置。

### 参考资料

[Server-Sent Events in Spring](https://www.baeldung.com/spring-server-sent-events)

[demo-chat-app-sse-spring-boot](https://github.com/Christian-Oette/demo-chat-app-sse-spring-boot)
