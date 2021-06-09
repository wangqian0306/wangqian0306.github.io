---
title: 状态模式
date: 2020-07-13 21:06:58
tags: "JAVA"
id: design-pattern-state
no_word_count: true
no_toc: false
categories: JAVA
---

```java
abstract class State {
    void doWork() {
    }
}

class Happy extends State {
    @Override
    void doWork() {
        System.out.println("happy");
    }
}

class Sad extends State {
    @Override
    void doWork() {
        System.out.println("sad");
    }
}

class Context {
    private State state;

    public void setState(State state) {
        this.state = state;
    }

    public void work() {
        state.doWork();
    }
}

public class StatePatternDemo {
    public static void main(String[] args) {
        Context context = new Context();
        context.setState(new Happy());
        context.work();
        context.setState(new Sad());
        context.work();
    }
}
```