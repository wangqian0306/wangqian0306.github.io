---
title: spring-rest-docs
date: 2020-07-12 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring REST Docs"
id: spring-rest-docs
no_word_count: true
no_toc: false
categories: Spring
---

## Spring REST Docs

### 简介

Spring REST Docs 是一款接口文档生成工具。主要是通过将 AsciiDoctor 和 Spring MVC Test 自动生成的请求片段相互结合的方式编写文档。

Spring MVC Test 自动生成的请求片段内容如下：

- curl-request
- http-request
- http-response
- httpie-request
- request-body
- response-body

> 注：此工具生成的文档还是有些简陋，建议酌情选用。

### 使用方式

首先需要引入相关依赖包：

Maven

```xml
<dependency>
    <groupId>org.springframework.restdocs</groupId>
    <artifactId>spring-restdocs-mockmvc</artifactId>
    <scope>test</scope>
</dependency>
```

Gradle

```groovy
dependencies {
    testImplementation "org.springframework.restdocs:spring-restdocs-mockmvc"
}
```

然后按需编写测试类即可，样例如下：

```java
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.restdocs.RestDocumentationContextProvider;
import org.springframework.restdocs.RestDocumentationExtension;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.restdocs.mockmvc.MockMvcRestDocumentation.document;
import static org.springframework.restdocs.mockmvc.MockMvcRestDocumentation.documentationConfiguration;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebAppConfiguration
@ContextConfiguration(classes = DemoApplication.class)
@ExtendWith({RestDocumentationExtension.class, SpringExtension.class})
public class DemoTest {

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    public void setUp(RestDocumentationContextProvider restDocumentation) {
        this.mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(documentationConfiguration(restDocumentation)).build();
    }

    @Test
    public void test() throws Exception {
        String url = "/test";
        mockMvc.perform(get(url)).andExpect(status().is2xxSuccessful()).andDo(document("sample"));
    }

}
```

> 注：在测试完成后需要指定 `andDo(document("<dir>"))` 方法，标明本测试生成的文件夹路径。在运行测试完成后会在 `target/generated-snippets` 文件夹内找到生成的 `adoc`格式文档。如有需求可以结合 asciidoctor-maven-plugin 生成完整文档。

### 参考资料

[官方手册](https://spring.io/projects/spring-restdocs#overview)

[官方例程](https://github.com/spring-projects/spring-restdocs/tree/main/samples/junit5)
