---
title: MyBatis
date: 2024-12-25 21:32:58
tags:
- "Java"
- "Spring Boot"
id: mybatis
no_word_count: true
no_toc: false
categories:
- "Spring"
---

## MyBatis

### 简介

MyBatis 是一款为了让服务更好使用关系型数据库的框架。

### 使用方式

至少引入如下依赖：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.mybatis.spring.boot:mybatis-spring-boot-starter:3.0.4'
    compileOnly 'org.projectlombok:lombok'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.mybatis.spring.boot:mybatis-spring-boot-starter-test:3.0.4'
    runtimeOnly 'com.mysql:mysql-connector-j'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

然后编写如下配置 `application.yaml` ：

```yaml
spring:
  datasource:
    url: jdbc:mysql://xxx.xxx.xxx.xxx:3306/sakila
    username: xxxx
    password: xxxx
    driver-class-name: com.mysql.cj.jdbc.Driver
mybatis:
  configuration:
    map-underscore-to-camel-case: true
```

> 注：此处为了便捷选了 MySQL 提供的示例数据库 [sakila](https://dev.mysql.com/doc/index-other.html) 。

之后编写如下代码 `Actor.java` ：

```java
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

@Data
public class Actor implements Serializable {

    private Integer actorId;

    private String firstName;

    private String lastName;

    private LocalDateTime lastUpdate;

}
```

然后编写 `ActorMapper.java` :

```java
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ActorMapper {

    @Select("SELECT * FROM actor")
    List<Actor> findAll();

}
```

之后修改主类即可：

```java
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application implements CommandLineRunner {

    private final ActorMapper actorMapper;

    public Application(ActorMapper actorMapper) {
        this.actorMapper = actorMapper;
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        System.out.println(this.actorMapper.findAll());
    }

}
```

### 其他插件

#### MyBatis Generator

从 Maven 上直接下载 mybatis-generator-core 的 jar 包和数据库驱动包，然后将其放置在同一目录下。

之后结合实际场景修改配置文件即可，样例如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE generatorConfiguration
  PUBLIC "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
  "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">

<generatorConfiguration>
  <classPathEntry location="mysql-connector-j-9.1.0.jar" />

  <context id="DB2Tables" targetRuntime="MyBatis3">
    <jdbcConnection driverClass="com.mysql.cj.jdbc.Driver"
        connectionURL="jdbc:mysql://xxx.xxx.xxx.xxx:3306/sakila?useSSL=false"
        userId="xxxx"
        password="xxxx">
    </jdbcConnection>

    <javaTypeResolver >
      <property name="forceBigDecimals" value="false" />
    </javaTypeResolver>

    <javaModelGenerator targetPackage="test.model" targetProject=".">
      <property name="enableSubPackages" value="true" />
      <property name="trimStrings" value="true" />
    </javaModelGenerator>

    <sqlMapGenerator targetPackage="test.xml"  targetProject=".">
      <property name="enableSubPackages" value="true" />
    </sqlMapGenerator>

    <javaClientGenerator type="XMLMAPPER" targetPackage="test.dao"  targetProject=".">
      <property name="enableSubPackages" value="true" />
    </javaClientGenerator>

    <table schema="sakila" tableName="actor" domainObjectName="Actor"/>

  </context>
</generatorConfiguration>
```

### 参考资料

[Java & Databases: An Overview of Libraries & APIs](https://www.marcobehler.com/guides/java-databases)

[官方网站](https://mybatis.org/mybatis-3/)

[官方项目](https://github.com/mybatis/mybatis-3)

[示例代码](https://github.com/mybatis/spring-boot-starter/tree/master/mybatis-spring-boot-samples)

[MyBatis Generator](https://mybatis.org/generator/)
