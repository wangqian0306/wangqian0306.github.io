---
title: Project CRaC
date: 2024-03-18 21:32:58
tags:
- "Java"
- "Spring Boot"
id: crac
no_word_count: true
no_toc: false
categories: Spring
---

## Procject CRac

### 简介

Coordinated Restore at Checkpoint(CRaC) 是一个 JDK 项目，它允许您以更短的首次事务时间启动 Java 程序，同时减少时间和资源以实现完整的代码速度。CRaC 在完全预热 Java 进程(检查点)时有效地获取 Java 进程(检查点)的快照，然后使用该快照从此捕获状态启动任意数量的 JVM。并非所有现有的 Java 程序都可以在不修改的情况下运行，因为在创建检查点之前，需要显式关闭所有资源(使用 CRaC API)，并且必须在还原后重新初始化这些资源。Spring、Micronaut 和 Quarkus 等流行框架支持开箱即用的 CRaC 检查点。

### 使用方式

> 注：目前的运行版本还比较初级，需要以 privileged 权限运行容器，安全性较差。待之后发版更新后再来完善此内容。

### 参考资料

[Introduction to Project CRaC: Enhancing Runtime Efficiency in Java & Spring Development](https://www.youtube.com/watch?v=sVXUx_Y4hRU)

[CRaC Project Wiki](https://wiki.openjdk.org/display/crac)

[JVM Checkpoint Restore](https://docs.spring.io/spring-framework/reference/integration/checkpoint-restore.html)

[What is CRaC?](https://docs.azul.com/core/crac/crac-introduction)

[Spring Boot CRaC demo](https://github.com/sdeleuze/spring-boot-crac-demo/tree/main)