---
title: 中介者模式
date: 2021-07-22 20:32:58
tags: "JAVA"
id: design-mediator-pattern
no_word_count: true
no_toc: false
categories: 设计模式
---

```java
import java.util.Date;

class User {
    String name;

    public String getName() {
        return name;
    }

    public User(String name) {
        this.name = name;
    }

    public void sendMessage(String message) {
        ChatRoom.showMessage(this, message);
    }
}

class ChatRoom {
    public static void showMessage(User user, String message) {
        System.out.println(new Date() + " [" + user.getName() + "] : " + message);
    }
}

public class MediatorPatternDemo {
    public static void main(String[] args) {
        User robert = new User("Robert");
        User john = new User("John");

        robert.sendMessage("Hi! John!");
        john.sendMessage("Hello! Robert!");
    }
}
```
