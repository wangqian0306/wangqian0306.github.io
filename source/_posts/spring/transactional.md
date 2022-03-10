---
title: Transactional
date: 2021-10-28 21:32:58
tags:
- "Java"
- "Spring Boot"
id: transactional
no_word_count: true
no_toc: false
categories: Spring
---

## Transactional

### 简介

事务(transaction)是指业务逻辑上对数据库进行的一系列持久化操作，要么全部成功，要么全部失败。

`@Transactional` 是 SpringBoot 中一种常见的事务实现方式。

### 配置建议

建议将此注解采用如下写法：

```text
@Transactional(rollbackFor = Exception.class, propagation = Propagation.REQUIRED)
```

### 参考资料

[SpringBoot中@Transactional事务控制实现原理及事务无效问题排查](https://blog.csdn.net/hanchao5272/article/details/90343882)