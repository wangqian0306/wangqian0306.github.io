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

#### MCP Inspector

使用如下命令安装 uv：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

然后使用如下命令运行服务：

```bash
npx @modelcontextprotocol/inspector uvx
```

在其中填写如下 Arguments ：

```text
mcp-server-time --local-timezone=America/New_York
```

点击链接后即可在页面内看到运行结果。

#### Cline

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

等待一会即可看见 MCP 清单中出现了绿色的点，此时即可进行提问。

### 常见问题

### spawn uvx ENOENT

在使用第三方使用 uv 的 MCP 服务器时出现了此问题，可以通过修改安装方式进行处理。

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

> 注：只测试过 linux 环境。

### 参考资料

[官网](https://modelcontextprotocol.io/introduction)

[Model Context Protocol servers](https://github.com/modelcontextprotocol/servers)

[Awesome MCP Servers](https://mcpservers.org/)

[Spring AI MCP](https://docs.spring.io/spring-ai/reference/1.0/api/mcp/mcp-overview.html)

[Build Your Own MCP Server in Under 15 Minutes | Spring AI Tutorial](https://www.youtube.com/watch?v=w5YVHG1j3Co)

[Inspector](https://modelcontextprotocol.io/docs/tools/inspector)

[Securing Spring AI MCP servers with OAuth2 视频](https://www.youtube.com/watch?v=gBUnLYFwwyE)

[Securing Spring AI MCP servers with OAuth2 博文](https://spring.io/blog/2025/04/02/mcp-server-oauth2)

[Securing Spring AI MCP servers with OAuth2 代码](https://github.com/spring-projects/spring-ai-examples/tree/main/model-context-protocol/weather/starter-webmvc-server)
