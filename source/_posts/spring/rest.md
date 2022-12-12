---
title: Spring Data Rest
date: 2022-12-12 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-data-rest
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Data Rest

### 简介

Spring Data Rest 可以轻松地在 Spring Data 存储库之上构建 REST Web 服务。

### 使用方式

引入依赖包：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-rest</artifactId>
</dependency>
```

或

```groovy
dependencies {
  compile("org.springframework.boot:spring-boot-starter-data-rest")
}
```

配置入口

```properties
spring.data.rest.basePath=/api
```

编写实体类

```java
@Setter
@Getter
@Entity
public class WebsiteUser {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private long id;

    private String name;
    private String email;
}
```

编写 Repository 

```java
@RepositoryRestResource(collectionResourceRel = "users", path = "users")
public interface UserRepository extends PagingAndSortingRepository<WebsiteUser, Long> {
    List<WebsiteUser> findByName(@Param("name") String name);
}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-data/rest/docs/current/reference/html/)
