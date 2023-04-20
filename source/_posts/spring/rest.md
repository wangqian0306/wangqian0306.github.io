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

```yaml
spring:
  data:
    rest:
      base-path: /api
  datasource:
    url: ${MYSQL_URI:jdbc:mysql://xxx.xxx.xxx.xxx:3306/xxx}
    driver-class-name: ${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
    username: ${MYSQL_USERNAME:xxxx}
    password: ${MYSQL_PASSWORD:xxxx}
  jpa:
    hibernate:
      ddl-auto: update
```

编写实体类

```java
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.Hibernate;

import java.util.Objects;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@Table(name = "USER")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    private String name;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        User user = (User) o;
        return id != null && Objects.equals(id, user.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

}
```

编写 Repository 

```java
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;

@RepositoryRestResource(collectionResourceRel = "user", path = "user")
public interface UserRepository extends JpaSpecificationExecutor<User>, CrudRepository<User, Long> {

    List<User> findByNameLike(@Param("name") String name, Pageable pageable);

}
```

运行项目

```http request
### info
GET http://localhost:8080/api

### list
GET http://localhost:8080/api/user

### insert
POST http://localhost:8080/api/user
Content-Type: application/json

{
  "name": "demo"
}

### update
POST http://localhost:8080/api/user
Content-Type: application/json

{
  "id": 1,
  "name" :"update"
}

### delete
DELETE http://localhost:8080/api/user/1

### search interface list
GET http://localhost:8080/api/user/search

### searchByName
GET http://localhost:8080/api/user/search/findByName?name=demo
```

使用关联表：

> 注：设顶或更新关联字段为 URL 即可，例如 `/{id}`。但是如果输入 id 不存在则会跳过该字段，不会报错。如需报错需要设置改字段为必填。

```java
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity(name = "Phone")
public class Phone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String number;

    @ManyToOne(optional = false)
    @JoinColumn(name = "person_id", nullable = false, foreignKey = @ForeignKey(name = "PERSON_ID_FK"))
    private Person person;

}
```

### 参考资料

[官方文档](https://docs.spring.io/spring-data/rest/docs/current/reference/html/)

[Accessing JPA Data with REST](https://spring.io/guides/gs/accessing-data-rest/)
