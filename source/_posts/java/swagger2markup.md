---
title: Swagger2Markup
date: 2022-08-26 21:32:58
tags:
- "Java"
- "Swagger2Markup"
id: swagger2markup
no_word_count: true
no_toc: false
categories: JAVA
---

## Swagger2Markup

### 简介

此项目是 swagger 转 AsciiDoc 或 Markdown 的一款开源工具，通过将手写文档与自动生成的 API 文档相结合，简化了 RESTful API
文档的生成方式。

### 使用方式

首先需要引入如下依赖包：

```xml

<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
    <version>3.0.0</version>
</dependency>
```

```xml

<plugins>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
            <systemPropertyVariables>
                <io.springfox.staticdocs.outputDir>${swagger.output.dir}</io.springfox.staticdocs.outputDir>
                <io.springfox.staticdocs.snippetsOutputDir>${swagger.snippetOutput.dir}
                </io.springfox.staticdocs.snippetsOutputDir>
            </systemPropertyVariables>
        </configuration>
    </plugin>
    <plugin>
        <groupId>io.github.swagger2markup</groupId>
        <artifactId>swagger2markup-maven-plugin</artifactId>
        <version>${swagger2markup.version}</version>
        <configuration>
            <swaggerInput>${swagger.input}</swaggerInput>
            <outputDir>${generated.asciidoc.directory}</outputDir>
            <config>
                <swagger2markup.markupLanguage>ASCIIDOC</swagger2markup.markupLanguage>
                <swagger2markup.pathsGroupedBy>TAGS</swagger2markup.pathsGroupedBy>
            </config>
        </configuration>
        <executions>
            <execution>
                <phase>test</phase>
                <goals>
                    <goal>convertSwagger2markup</goal>
                </goals>
            </execution>
        </executions>
    </plugin>
</plugins>
```

> 注：此处需要读取 spring 的 repo 建议使用 Nexus 做个本地源，或者手动添加也可。

并进行如下配置：

```xml

<properties>
    <asciidoctor.input.directory>${project.basedir}/src/docs/asciidoc</asciidoctor.input.directory>
    <swagger.output.dir>${project.build.directory}/swagger</swagger.output.dir>
    <swagger.snippetOutput.dir>${project.build.directory}/asciidoc/snippets</swagger.snippetOutput.dir>
    <generated.asciidoc.directory>${project.build.directory}/asciidoc/generated</generated.asciidoc.directory>
    <asciidoctor.html.output.directory>${project.build.directory}/asciidoc/html</asciidoctor.html.output.directory>
    <asciidoctor.pdf.output.directory>${project.build.directory}/asciidoc/pdf</asciidoctor.pdf.output.directory>
    <swagger.input>${swagger.output.dir}/swagger.json</swagger.input>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <asciidoctor-plugin.version>1.5.6</asciidoctor-plugin.version>
</properties>
```

编写如下文档配置和测试用例：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;

@Configuration
public class OpenapiConf {

    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.any())
                .paths(PathSelectors.any())
                .build();
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title("demo")
                .description("demo")
                .version("0.1.0")
                .build();
    }

}
```

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.io.BufferedWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class Swagger2MarkupTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void createSpringfoxSwaggerJson() throws Exception {
        String outputDir = System.getProperty("io.springfox.staticdocs.outputDir");
        MvcResult mvcResult = this.mockMvc.perform(get("/v2/api-docs")
                        .accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();
        MockHttpServletResponse response = mvcResult.getResponse();
        String swaggerJson = response.getContentAsString();
        Files.createDirectories(Paths.get(outputDir));
        try (BufferedWriter writer = Files.newBufferedWriter(Paths.get(outputDir, "swagger.json"), StandardCharsets.UTF_8)) {
            writer.write(swaggerJson);
        }
    }

}
```

在主类中新增如下注解：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import springfox.documentation.oas.annotations.EnableOpenApi;

@EntityScan
@EnableJpaRepositories
@EnableOpenApi
@SpringBootApplication
public class TestApplication {
}
```

然后使用如下命令即可在 `target/asciidoc/generated` 文件夹下即可获得如下文档：

```bash
mvn test
```

- definitions.adoc
- overview.adoc
- paths.adoc
- security.adoc

> 注：目前尚且不支持 openapi(swagger3)

### 参考资料

[官方项目](https://github.com/Swagger2Markup/swagger2markup)

[使用手册](http://swagger2markup.github.io/swagger2markup/1.3.3/)

[样例代码](https://github.com/Swagger2Markup/spring-swagger2markup-demo)
