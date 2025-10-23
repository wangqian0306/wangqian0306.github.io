---
title: Spring 数据解密
date: 2025-10-21 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-decode
no_word_count: true
no_toc: falsede
categories: 
- "Spring"
---

## Spring 数据解密

### 简介

在涉及到数据加密时，此处的技术选型有如下区分：

| 特性  |RequestBodyAdvice| AbstractHttpMessageConverter|
|:---:|:---:|:---:|
|定位|AOP 式的拦截器（后处理）|底层消息转换器（核心机制）|
|执行时机|在消息转换之后，Controller 调用之前|在消息转换过程中，直接参与反序列化|
|是否影响 @RequestBody 解析过程|否，只能修改已解析的对象|是，完全控制从 InputStream 到对象的全过程|
|能否根据注解/参数类型选择性处理|✅ 可通过 supports() 精确控制|✅ 可通过 supports() 或 parameterAnnotations 控制|
|能否处理自定义 Content-Type|❌ 不能（转换已完成）|✅ 可以（如 application/encrypted+json）|
|能否读取原始 InputStream|❌ 不能（已被消耗）|✅ 可以|
|复用性|中等|高（可全局复用）|
|复杂度|低|高|
|推荐使用场景|日志、数据预处理、简单解密|自定义协议、加密、二进制数据、流式处理|

### 实现方式



### 参考资料

[]()

[]()
