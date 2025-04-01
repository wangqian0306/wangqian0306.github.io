---
title: MCP
date: 2025-03-31 22:26:13
tags:
- "AI"
- "MCP"
id: mcp
no_word_count: true
no_toc: false
---

## MCP

### 简介

MCP 是一种开放协议，它标准化了应用向 AI 应用提供上下文的方式。

### 实现方式

使用 Spring AI 即可实现 MCP 服务器的编写，具体流程如下：

建立 `Course.java` 数据模型

```java
public record Course(String title, String url) {
}
```

建立检索服务 `CourseService.java`

```java
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CourseService {

    private static final Logger log = LoggerFactory.getLogger(CourseService.class);
    private List<Course> courses = new ArrayList<>();

    @Tool(name = "get_courses", description = "Get a list of courses")
    public List<Course> getCourses() {
        return courses;
    }

    @Tool(name = "get_course", description = "Get a single courses by title")
    public Course getCourse(String title) {
        return courses.stream().filter(course -> course.title().equals(title)).findFirst().orElse(null);
    }

    @PostConstruct
    public void init() {
        courses.addAll(List.of(
                new Course("Building Web Applications with Spring Boot (FreeCodeCamp)", "https://youtu.be/31KTdfRH6nY"),
                new Course("Spring Boot Tutorial for Beginners - 2023 Crash Course using Spring Boot 3","https://youtu.be/UgX5lgv4uVM")
        ));
    }
}
```

暴漏外部接口，在主类中注册 Bean ：

```java
import org.springframework.ai.tool.ToolCallback;
import org.springframework.ai.tool.ToolCallbacks;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.util.List;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public List<ToolCallback> demoTools(CourseService courseService) {
        return List.of(ToolCallbacks.from(courseService));
    }
}
```

修改 `application.yaml` 文件：

```yaml
spring:
  main:
    web-application-type: none
    banner-mode: off
  ai:
    mcp:
      server:
        name: mcp-demo
        version: 0.0.1

logging:
  pattern:
    console:
```

### 测试流程

在 VScode 中安装 Cline 然后使用 Cline MCP 的配置文件即可：

```json
{
  "mcpServers": {
    "demo-mcp": {
       "command": "java",
       "args": [
        "-jar",
        "/workspace/dv-courses-mcp/target/courses-0.0.1-SNAPSHOT.jar"  
       ]
    }
  }
}
```

### 参考资料

[官网](https://modelcontextprotocol.io/introduction)

[Awesome MCP Servers](https://mcpservers.org/)

[Spring AI MCP](https://docs.spring.io/spring-ai/reference/1.0/api/mcp/mcp-overview.html)

[Build Your Own MCP Server in Under 15 Minutes | Spring AI Tutorial](https://www.youtube.com/watch?v=w5YVHG1j3Co)
