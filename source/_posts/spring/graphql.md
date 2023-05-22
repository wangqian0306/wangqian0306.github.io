---
title: Spring for GraphQL
date: 2023-05-22 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring Data JPA"
id: graphql
no_word_count: true
no_toc: false
categories: Spring
---

## Spring for GraphQL

### 简介

GraphQL 是用于 API 的查询语言，也是一个服务器端的运行时，被用来执行指定类型的查询。

> 注：经过和 JPA 结合，它可以做到仅仅返回用户查询的字段，并不会做额外的查询，而且可以在单次查询中调用多个接口。

### 基础使用

引入如下依赖：

- Lombok
- Spring Web
- Spring Data JPA 
- 数据库(本文使用 MySQL)

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-graphql'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    runtimeOnly 'com.mysql:mysql-connector-j'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework:spring-webflux'
    testImplementation 'org.springframework.graphql:spring-graphql-test'
}
```

编写如下模型类：

```java
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.Hibernate;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@AllArgsConstructor
@Entity
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @OneToMany(mappedBy = "author", cascade = CascadeType.ALL)
    @ToString.Exclude
    private List<Book> books = new ArrayList<>();

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        Author author = (Author) o;
        return getId() != null && Objects.equals(getId(), author.getId());
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

}
```

```java
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.Hibernate;

import java.util.Objects;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@AllArgsConstructor
@Entity
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

    private String publisher;

    @ManyToOne(fetch = FetchType.LAZY)
    @ToString.Exclude
    private Author author;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        Book book = (Book) o;
        return getId() != null && Objects.equals(getId(), book.getId());
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

}
```

编写如下 Repository ：

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AuthorRepository extends JpaRepository<Author,Long> {
}
```

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BookRepository extends JpaRepository<Book, Long> {
}
```

在主类中插入测试数据：

```java
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
public class GqlApplication {

    public static void main(String[] args) {
        SpringApplication.run(GqlApplication.class, args);
    }

    @Bean
    ApplicationRunner applicationRunner(AuthorRepository authorRepository, BookRepository bookRepository) {
        return args -> {
            Author josh = authorRepository.save(new Author(null, "Josh", new ArrayList<>()));
            Author mark = authorRepository.save(new Author(null, "Mark", new ArrayList<>()));
            bookRepository.saveAll(List.of(
                    new Book(null, "Java 11", "Tom", josh),
                    new Book(null, "Java 12", "Jerry", mark),
                    new Book(null, "Java 13", "Spike", josh)
            ));
        };
    }
}
```

编写 Controller :

```java
import jakarta.annotation.Resource;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class TestController {

    @Resource
    private AuthorRepository authorRepository;

    @QueryMapping
    List<Author> authors() {
        return authorRepository.findAll();
    }

}
```

编写 `resources/graphql/schema.graphqls` 配置文件：

```text
type Query {
    authors: [Author]
}

type Author {
    id: ID!
    name: String!
    books: [Book]
}

type Book {
    id: ID!
    title: String!
    publisher: String
}
```

编写 `application.yaml` 配置文件：

```yaml
server:
  port: 8080
spring:
  application:
    name: gql
  datasource:
    driver-class-name: ${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
    url: ${MYSQL_URI:jdbc:mysql://xxx.xxx.xxx.xxx:3306/xxx}
    username: ${MYSQL_USERNAME:xxxx}
    password: ${MYSQL_PASSWORD:xxxx}
  jackson:
    time-zone: Asia/Shanghai
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: create-drop
  graphql:
    graphiql:
      enabled: true
```

启动程序，然后访问 `http://localhost:8080/graphiql` 即可看到调试控制台，输入如下内容即可完成测试。

```text
query {
  authors {
    id
    name
    books {
    	id
      title
    }
  }
}
```

### 参考资料

[Introduction to Spring GraphQL with Spring Boot](https://www.youtube.com/watch?v=atA2OovQBic)

[官方文档](https://docs.spring.io/spring-graphql/docs/current/reference/html/)
