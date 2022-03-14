---
title: Spring 注入 Bean
date: 2021-10-28 21:32:58
tags:
- "Java"
- "Spring Boot"
id: import
no_word_count: true
no_toc: false
categories: Spring
---

## Spring 注入 Bean

### 简介

我们谈到 Spring 的时候一定会提到 IOC 容器、DI 依赖注入，Spring通过将一个个类标注为 Bean 的方法注入到 IOC 容器中，达到了控制反转的效果。

### 注入方式

Spring 有如下种注入方式

- 属性注入
- 构造函数注入
- 工厂方法注入

而在一般的使用过程中可以选择使用 

`@Autowired` 注解或者 `@Resource` 注解进行注入。

### 参考资料

[Spring @Autowired](https://blog.csdn.net/bigtree_3721/article/details/87014878)

[@autowired和@resource注解的区别是什么？](https://www.php.cn/java/base/463170.html)