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
categories: 
- Spring
---

## Spring Data JPA

### 简介

Spring Data JPA 旨在通过减少实际需要的工作量来显着改进数据访问层的实现。

### 常见使用方式

#### Repository 中的返回对象及分页与排序参数

在查询大量数据时，Spring 提供了多种的返回对象与输入参数，可以在不同情况下进行采用。

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User,Long> {
    
    // 较为适合 RESTful
    Page<User> findByLastname(String lastname, Pageable pageable);

    // 较为适合 GraphQL
    Slice<User> findByLastname(String lastname, Pageable pageable);

    Window<User> findTop10ByLastname(String lastname, ScrollPosition position, Sort sort);

    List<User> findByLastname(String lastname, Sort sort);

    List<User> findByLastname(String lastname, Pageable pageable);

}
```

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

enum TypeEnum {
    A,
    B
}

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@EntityListeners(AuditingEntityListener.class)
public class Test {

    @Id
    private String id;
    
    @Enumerated(EnumType.STRING)
    private TypeEnum type = TypeEnum.A;

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
public class TestService {
    public static Specification<Author> hasBookWithTitle(String bookTitle) {
        return (root, query, criteriaBuilder) -> {
            Join<Book, Author> authorsBook = root.join("books");
            return criteriaBuilder.equal(authorsBook.get("title"), bookTitle);
        };
    }
}
```

#### QueryDSL 

> 注：和 Specification 类似，但是对 GraphQL 更友好。

- Maven

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

编写模型，加上 `@Table` 与 `@Entity` 注解，然后使用 `mvn compile` 即可在对应目录找到查询类。

- Gradle

引入依赖：

```grovvy
dependencies {
    implementation("com.querydsl:querydsl-core:5.0.0")
    implementation("com.querydsl:querydsl-jpa:5.0.0:jakarta")
    annotationProcessor(
            "com.querydsl:querydsl-apt:5.0.0:jakarta",
            "jakarta.persistence:jakarta.persistence-api:3.1.0"
    )
}
```

编写模型，加上 `@Table` 与 `@Entity` 注解，然后使用 `./gradlew compileJava` 即可在对应目录找到查询类。

如果准备与 SpringDataJpa 一起使用则可以依照如下方式编写 Repository :

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.querydsl.QuerydslPredicateExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface AuthorRepository extends JpaRepository<Author, Long>, QuerydslPredicateExecutor<Author> {
}
```

然后按如下方式进行查询即可:

```java
import com.querydsl.core.types.Predicate;
import jakarta.annotation.Resource;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class TestController {

    @Resource
    private AuthorRepository authorRepository;

    @QueryMapping
    Iterable<Author> authors(@Argument String name) {
        if (name != null) {
            QAuthor author = QAuthor.author;
            Predicate predicate = author.name.eq(name);
            return authorRepository.findAll(predicate);
        } else {
            return authorRepository.findAll();
        }
    }
}
```

如果使用 QueryDSL 原始的查询方式则可以按照如下方式编写代码:

```java
import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.persistence.EntityManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QueryDSLConfig {
    @Bean
    public JPAQueryFactory jpaQueryFactory(EntityManager entityManager) {
        return new JPAQueryFactory(entityManager);
    }

}
```

```java
import com.querydsl.core.types.Predicate;
import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.annotation.Resource;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Controller
public class TestController {

    @Resource
    private JPAQueryFactory queryFactory;

    @QueryMapping
    Iterable<Author> queryAuthor(@Argument String name, @Argument String publisher) {
        QAuthor author = QAuthor.author;
        QBook book = QBook.book;
        return queryFactory.selectFrom(author).leftJoin(author.books, book).fetchJoin().where(author.name.like(name).and(book.publisher.eq(publisher))).fetch();
    }

}
```

分页和排序功能如下：

```java
import com.querydsl.core.types.Predicate;
import com.querydsl.core.types.dsl.PathBuilder;
import com.querydsl.jpa.JPAExpressions;
import com.querydsl.jpa.impl.JPAQuery;
import com.querydsl.jpa.impl.JPAQueryFactory;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.stereotype.Controller;

@Slf4j
@Controller
public class TestController {

    @Resource
    private JPAQueryFactory queryFactory;

    @QueryMapping
    Page<Author> pageAuthor(@Argument String name, @Argument String publisher) {
        Pageable pageable = PageRequest.of(0, 2);
        Sort sort = Sort.by(Sort.Direction.DESC, "id");
        QAuthor author = QAuthor.author;
        QBook book = QBook.book;
        List<Long> count = queryFactory.select(author.id.countDistinct()).from(author).leftJoin(book).on(book.author.id.eq(author.id)).where(author.name.like(name).and(book.publisher.eq(publisher))).fetch();
        PathBuilder<Author> authorPathBuilder = new PathBuilder<>(Author.class, author.getMetadata().getName());
        JPAQuery<Author> query = queryFactory.selectFrom(author).leftJoin(author.books, book).fetchJoin().where(author.name.like(name).and(book.publisher.eq(publisher)));
        sort.get().forEach(order -> query.orderBy(QueryDSLUtil.toOrderSpecifier(order, authorPathBuilder)));
        query.offset(pageable.getOffset());
        query.limit(pageable.getPageSize());
        return new PageImpl<>(query.fetch(), pageable, count.get(0));
    }
}
```

> 注：此处由于检索逻辑复杂，所以 QueryDSL 在内存中做了数据合并，并不能依照正常的方式完成数据分页，在使用时需要尤其注意。

#### 单元测试

在编写单元测试时需要加上 `@DataJpaTest` 注解，此注解会使用内存数据库进行测试，而不会产生多余的测试数据。 
样例如下：

```java
import org.springframework.boot.test.autoconfigure.data.jdbc.DataJdbcTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;

@DataJdbcTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
public class DataTest {
    
}
```

还可以在测试时指定独立的配置环境：

```java
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("dev")
public class DataTest {

}
```

或是直接使用测试容器：

```java
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@Testcontainers
public class DataTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16.0");
    
}
```

#### 使用样例数据查询(Query By Example,QBE)

QBE 适合以下场景：

- 过滤多个条件
- 加速原型(初版)开发
- 简单的基本内容检索
- 编译时搜索条件未知

不适合以下场景：

- 复杂比较(<,>,BETWEEN)
- OR 查询条件
- JOIN 查询条件
- 自定义 SQL

[样例项目](https://github.com/danvega/qbe)
