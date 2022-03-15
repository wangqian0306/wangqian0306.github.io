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

### Autowired 与 Resource 的区别

Spring 不但支持自己定义的 @Autowired 注解，还支持几个由 JSR-250 规范定义的注解，它们分别是 @Resource、@PostConstruct 以及 @PreDestroy。

@Resource 的作用相当于 @Autowired，只不过 @Autowired 按 byType 自动注入，而 @Resource 默认按 byName 自动注入罢了。
@Resource 有两个属性是比较重要的，分是 name 和 type，Spring 将 @Resource 注解的 name 属性解析为 bean 的名字，而 type 属性则解析为 bean 的类型。
所以如果使用 name 属性，则使用 byName 的自动注入策略，而使用 type 属性时则使用 byType 自动注入策略。
如果既不指定 name 也不指定 type 属性，这时将通过反射机制使用 byName 自动注入策略。

### 参考资料

[Spring @Autowired](https://blog.csdn.net/bigtree_3721/article/details/87014878)

[@autowired和@resource注解的区别是什么？](https://www.php.cn/java/base/463170.html)