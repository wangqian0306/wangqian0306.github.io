---
title: 单例模式
date: 2020-06-15 22:12:58
tags: "JAVA"
id: design-pattern-singleton
no_word_count: true
no_toc: false
categories: JAVA
---

### 饿汉式

```java
class Demo {
    private static Demo instance;
    
    private Demo() {}
    
    static {
        instance = new Demo();
    }
    
    public static Demo getInstance() {
        return instance;
    }
}
```

> 注：在类加载的时候就吃资源。

### 懒汉式

```java
class Demo {
    private static volatile Demo instance;
    
    private Demo() {}
    
    public static Demo getInstance() {
        if (instance==null){
            synchronized (Demo.class) {
                if (instance==null){
                    instance = new Demo();
                }
            }
        }
        return instance;
    }
}
```

> 注：在调用时才实例化对象。

### 静态内部类

```java
class Demo {
    private static volatile Demo instance;
    
    private Demo() {}
    
    private static class DemoInstance {
        private static final Demo INSTANCE = new Demo();
    }
    
    public static Demo getInstance() {
        return DemoInstance.INSTANCE;
    }
}
```

### 枚举

```java
enum Demo {
    INSTANCE;
    public void echo() {
        System.out.println("echo");
    }
}
```
