---
title: MyBatis-Plus 
date: 2021-03-03 21:05:12 
tags:
- "JAVA"
- "MyBatis"
id: mybatis-plus
no_word_count: true
no_toc: false
categories: JAVA
---

## MyBatis-Plus

### 简介

MyBatis-Plus(简称 MP)是一个 MyBatis 的增强工具，在 MyBatis 的基础上只做增强不做改变，可以简化开发、提高效率。

### 依赖

```text
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-generator</artifactId>
    <version>3.5.2</version>
</dependency>
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>mybatis-plus-boot-starter</artifactId>
    <version>3.5.1</version>
</dependency>
<dependency>
    <groupId>org.apache.velocity</groupId>
    <artifactId>velocity-engine-core</artifactId>
    <version>2.3</version>
</dependency>
```

### 代码生成工具

```java
import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.generator.FastAutoGenerator;
import com.baomidou.mybatisplus.generator.config.TemplateType;
import com.baomidou.mybatisplus.generator.fill.Column;

public class CodeGenerator {

    public static void main(String[] args) {
        String pkgPath = System.getProperty("user.dir") + "/src/main/java";
        FastAutoGenerator.create("jdbc:mysql://<host>/<database>", "<username>", "<password>")
                .globalConfig(builder -> builder.outputDir(pkgPath).author("<author>")
                        .disableOpenDir())
                .packageConfig(builder -> builder.parent("<package>"))
                .templateConfig(builder -> builder.disable(TemplateType.XML))
                .strategyConfig((scanner, builder) -> builder.addInclude("<table-name>")
                        .controllerBuilder().enableRestStyle().enableHyphenStyle()
                        .entityBuilder().enableLombok().addTableFills(
                                new Column("create_time", FieldFill.INSERT)
                        ).build())
                .execute();
    }
}
```

### 参考资料

[官方文档](https://baomidou.com/pages/226c21/)

[样例代码](https://gitee.com/baomidou/mybatis-plus-generator-examples)