---
title: Spring Data JPA
date: 2022-05-06 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring Data JPA"
id: jpa
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Data JPA

### 简介

Spring Data JPA 旨在通过减少实际需要的工作量来显着改进数据访问层的实现。

### 常见使用方式

#### 自动获取更新时间创建时间等内容

首先需要按照如下样例创建模型类

```java
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;

import javax.persistence.Entity;
import javax.persistence.Id;
import java.util.Date;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Test {

    @Id
    private String id;

    @CreatedBy
    private String createdBy;

    @LastModifiedBy
    private String lastModifiedBy;

    @CreatedDate
    private Date createdDate;

    @LastModifiedDate
    private Date updatedDate;

    @Transient
    private String cache;

}
```

创建如下的操作员获取类：

```java
import jakarta.validation.constraints.NotNull;
import org.springframework.data.domain.AuditorAware;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class AuditorConfig implements AuditorAware<String> {

    @NotNull
    @Override
    public Optional<String> getCurrentAuditor() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof Jwt) {
            return Optional.ofNullable(((Jwt) principal).getSubject());
        } else {
            return Optional.empty();
        }
    }

}
```

> 注：此样例为 SpringSecurity 启用 JWT 之后获取用户名的方式。

开启编辑审计功能(在启动类中加入下面的注解即可)

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class TestApplication {

    public static void main(String[] args) {
        SpringApplication.run(Test.class, args);
    }

}
```

#### 表名或列名大写

在配置中填入如下内容即可：

```yaml
spring:
  jpa:
    hibernate:
      naming:
        physical-strategy: org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
```

#### 自定义返回分页对象

```java
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.ArrayList;
import java.util.List;

class T {
}

public class Test {
    public void test() {
        long total = 1L;
        List<T> contentList = new ArrayList<>();
        // 注意此处的页码是从 0 开始的
        Pageable pageable = PageRequest.of(0, 10);
        Page<T> result = new PageImpl<>(contentList, pageable, total);
    }
}
```

#### 使用大写的表名和列名

新增如下配置即可：

```java
import org.hibernate.boot.model.naming.CamelCaseToUnderscoresNamingStrategy;
import org.hibernate.boot.model.naming.Identifier;
import org.hibernate.engine.jdbc.env.spi.JdbcEnvironment;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CustomNamingConf extends CamelCaseToUnderscoresNamingStrategy {

    @Override
    public Identifier toPhysicalCatalogName(Identifier logicalName, JdbcEnvironment context) {
        return logicalName;
    }

    @Override
    public Identifier toPhysicalSchemaName(Identifier logicalName, JdbcEnvironment context) {
        return logicalName;
    }

    @Override
    public Identifier toPhysicalTableName(Identifier logicalName, JdbcEnvironment context) {
        return logicalName;
    }

    @Override
    public Identifier toPhysicalSequenceName(Identifier logicalName, JdbcEnvironment context) {
        return logicalName;
    }

    @Override
    public Identifier toPhysicalColumnName(Identifier logicalName, JdbcEnvironment context) {
        return logicalName;
    }

    @Override
    protected boolean isCaseInsensitive(JdbcEnvironment jdbcEnvironment) {
        return false;
    }

}
```

#### 使用自定义的 SQL 文件

在初始化时可以采用自定义的 SQL 文件：

```yaml
spring:
  sql:
    init:
      mode: always
      schema-locations: schema.sql
      data-locations: data.sql
```

#### 使用 JPA 中的关系

使用如下模型类：

```java
@Entity
@NamedEntityGraph(name = "Item.characteristics",
        attributeNodes = @NamedAttributeNode("characteristics")
)
public class Item {

    @Id
    private Long id;
    private String name;
    
    @OneToMany(mappedBy = "item")
    private List<Characteristic> characteristics = new ArrayList<>();

    // getters and setters
}
```

```java
@Entity
public class Characteristic {

    @Id
    private Long id;
    private String type;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn
    private Item item;

    //Getters and Setters
}
```

然后在 Repository 中声明启用相关图即可：

```java
public interface ItemRepository extends JpaRepository<Item, Long> {

    @EntityGraph(value = "Item.characteristics")
    Item findByName(String name);
}
```

#### 动态构建查询


##### 基本查询

首先需要在 Repository 中额外引入 `JpaSpecificationExecutor`

```java
@Repository
public interface TestRepository extends JpaRepository<Test, String>, JpaSpecificationExecutor<Test> {
}
```

然后即可在查询中进行如下操作

```java
@Service
public class Test {
    @Resource
    private TestRepository testRepository;

    public void test() {
        testRepository.findAll((root, criteriaQuery, cb) -> {
            List<Predicate> predicate = new ArrayList<>();
            // 此处可以添加条件，需要注意的是所填写的列名要和模型对象名一致
            Path<String> testPath = root.get("test");
            predicate.add(cb.like(testPath, "test"));
            Predicate[] pre = new Predicate[predicate.size()];
            criteriaQuery.where(predicate.toArray(pre));
            return criteriaQuery.getRestriction();
        });
    }
}
```

##### 连表查询

如果需要联表查询则可使用如下的方式：

```java
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class Book {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;

}
```

```java
import jakarta.persistence.*;
import lombok.Data;

import java.util.List;

@Data
@Entity
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String firstName;

    private String lastName;

    @OneToMany(cascade = CascadeType.ALL)
    private List<Book> books;

}
```

```java
@Repository
public interface AuthorsRepository extends JpaRepository<Author, Long>, JpaSpecificationExecutor<Author> {
}
```

```java
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public TestService {
    public static Specification<Author> hasBookWithTitle(String bookTitle) {
        return (root, query, criteriaBuilder) -> {
            Join<Book, Author> authorsBook = root.join("books");
            return criteriaBuilder.equal(authorsBook.get("title"), bookTitle);
        };
    }
}
```

#### QueryDSL 

> 注：和 Specification 类似，但是对 GraphQL 更友好。且官网建议用 Maven，样例也没一个是 Gradle，所以此处暂时先用 Maven。

引入依赖：

```xml
<dependencies>
    <dependency>
        <groupId>com.querydsl</groupId>
        <artifactId>querydsl-jpa</artifactId>
        <version>${querydsl.version}</version>
    </dependency>
    <dependency>
        <groupId>com.querydsl</groupId>
        <artifactId>querydsl-apt</artifactId>
        <version>${querydsl.version}</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

安装插件：

```xml
<plugin>
    <groupId>com.mysema.maven</groupId>
    <artifactId>apt-maven-plugin</artifactId>
    <version>1.1.3</version>
    <executions>
        <execution>
            <goals>
                <goal>process</goal>
            </goals>
            <configuration>
                <outputDirectory>target/generated-sources/java</outputDirectory>
                <processor>com.querydsl.apt.jpa.JPAAnnotationProcessor</processor>
            </configuration>
        </execution>
    </executions>
</plugin>
```

编写模型，然后使用 `mvn compile` 即可在对应目录找到查询类。