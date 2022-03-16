---
title: Open Feign
date: 2021-10-27 21:32:58
tags:
- "Java"
- "Spring Cloud"
id: caching
no_word_count: true
no_toc: false
categories: Spring
---

## Open Feign

### 使用

- 配置 pom

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

- 编写调用类

```text
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "<service_name>", path = "<url>")
public interface FeignTest {

    @GetMapping
    String getVersion();

}
```

### 参考资料

[手把手教你使用 OpenFeign](https://www.jianshu.com/p/f083660c65bf)