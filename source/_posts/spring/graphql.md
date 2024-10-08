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

编写 `src/main/resources/graphql/schema.graphqls` 配置文件：

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

### 数据分页

GraphQL 本身包含自己的 [分页请求模型与方式](https://graphql.org/learn/pagination/)，在项目中可以使用如下方式实现。

修改 Repository：

```java
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.ScrollPosition;
import org.springframework.data.domain.Window;
import org.springframework.data.repository.ListCrudRepository;
import org.springframework.graphql.data.GraphQlRepository;

@GraphQlRepository
public interface AuthorRepository extends ListCrudRepository<Author, Long> {

    Window<Author> findBy(ScrollPosition position, Limit limit);

}
```

> 注：此处可以额外添加查询参数和排序等内容。

修改请求类：

```java
import jakarta.annotation.Resource;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.ScrollPosition;
import org.springframework.data.domain.Window;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.query.ScrollSubrange;
import org.springframework.stereotype.Controller;

@Controller
public class TestController {

    @Resource
    private AuthorRepository authorRepository;

    @QueryMapping
    Window<Author> authors(ScrollSubrange subrange) {
        ScrollPosition scrollPosition = subrange.position().orElse(ScrollPosition.offset());
        Limit limit = Limit.of(subrange.count().orElse(1));
        return authorRepository.findBy(scrollPosition, limit);
    }

}
```

修改 graphql 配置文件：

```text
type Query {
    authors(first: Int,last: Int,before: String,after: String): AuthorConnection
}

type Author {
    id: ID!
    name: String!
}
```

在 graphiql 页面中即可使用如下查询：

```text
query{
  authors {
    edges{
      node {
        id
        name
      }
    }
    pageInfo {
      hasPreviousPage
      hasNextPage
      startCursor
      endCursor
    }
  }
}
```

### 嵌套查询

在 GraphQL 中还可以嵌套查询逻辑，样例如下：

```java
import jakarta.annotation.Resource;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SchemaMapping;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class TestController {

    @Resource
    private AuthorRepository authorRepository;

    @Resource
    private BookRepository bookRepository;

    @QueryMapping
    List<Author> authors() {
        return authorRepository.findAll();
    }

    @SchemaMapping
    List<Book> books(Author author,@Argument String publisher) {
        return bookRepository.findAllByAuthorIdAndPublisherLike(author.getId(), publisher);
    }

}
```

`src/main/resources/graphql/schema.graphqls` 配置文件：

```text
type Query {
    authors: [Author]
}

type Author {
    id: ID!
    name: String!
    books(publisher:String): [Book]
}

type Book {
    id: ID!
    title: String!
    publisher: String
}
```

### WebSocket 

首先需要切换 Web 至 WebFlux，样例如下：

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-graphql'
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test'
    testImplementation 'org.springframework.graphql:spring-graphql-test'
}
```

编写 Controller：

```java
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.graphql.data.method.annotation.SubscriptionMapping;
import org.springframework.stereotype.Controller;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.time.Instant;
import java.util.function.Supplier;
import java.util.stream.Stream;

@Controller
public class SampleController {

    @QueryMapping
    public String greeting() {
        return "Hello world!";
    }

    @SubscriptionMapping
    public Flux<String> greetings() {
        return Flux.fromStream(Stream.generate(new Supplier<String>() {
            @Override
            public String get() {
                return "Hello " + Instant.now() + "!";
            }
        })).delayElements(Duration.ofSeconds(1)).take(5);
    }

}
```

编写 `src/main/resources/graphql/schema.graphqls` 配置文件：

```text
type Query {
    greeting: String
}
type Subscription {
    greetings: String
}
```

编写 `application.yaml` 配置文件：

```yaml
server:
  port: 8080
spring:
  application:
    name: gql
  graphql:
    graphiql:
        enabled: true
    websocket:
      path: /graphql
```

启动程序，然后访问 `http://localhost:8080/graphiql` 即可看到调试控制台，输入如下内容即可完成测试。

```text
subscription {
  greetings
}
```

还可以按照如下样例编写单元测试

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.graphql.GraphQlTest;
import org.springframework.graphql.test.tester.GraphQlTester;
import reactor.core.publisher.Flux;
import reactor.test.StepVerifier;

@GraphQlTest(SampleController.class)
public class WebFluxWebSocketSampleTests {

    @Autowired
    private GraphQlTester graphQlTester;

    @Test
    void greetingMono() {
        this.graphQlTester.document("{greeting}")
                .execute()
                .path("greeting")
                .entity(String.class)
                .isEqualTo("Hello world!");
    }

    @Test
    void subscriptionWithResponse() {
        Flux<GraphQlTester.Response> result = this.graphQlTester.document("subscription { greetings }")
                .executeSubscription()
                .toFlux();

        StepVerifier.create(result)
                .consumeNextWith(response -> response.path("greetings").hasValue())
                .consumeNextWith(response -> response.path("greetings").hasValue())
                .consumeNextWith(response -> response.path("greetings").hasValue())
                .expectNextCount(2)
                .verifyComplete();
    }

}
```

在页面中可以按照如下样例编写读取程序 `src/main/resources/static/index.html`：

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>GraphQL over WebSocket</title>
    <script type="text/javascript" src="https://unpkg.com/graphql-ws/umd/graphql-ws.js"></script>
</head>
<body>
<p>Check the console for subscription messages.</p>
<script type="text/javascript">
  const client = graphqlWs.createClient({
    url: 'ws://localhost:8080/graphql',
  });

  // query
  (async () => {
    const result = await new Promise((resolve, reject) => {
      let result;
      client.subscribe(
        {
          query: '{ greeting }',
        },
        {
          next: (data) => (result = data),
          error: reject,
          complete: () => resolve(result),
        },
      );
    });

    console.log("Query result: " + result);
  })();

  // subscription
  (async () => {
    const onNext = (data) => {
      console.log("Subscription data:", data);
    };

    await new Promise((resolve, reject) => {
      client.subscribe(
        {
          query: 'subscription { greetings }',
        },
        {
          next: onNext,
          error: reject,
          complete: resolve,
        },
      );
    });
  })();

</script>
</body>
</html>
```

### RSocket

首先需要切换 Web 至 WebFlux，并引入 RSocket 样例如下：

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-graphql'
    implementation 'org.springframework.boot:spring-boot-starter-rsocket'
    implementation 'org.springframework.boot:spring-boot-starter-webflux'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'io.projectreactor:reactor-test'
    testImplementation 'org.springframework.graphql:spring-graphql-test'
}
```

编写 Record 类：

```java
public record Message(String name, String content) {
}
```

编写 Controller：

```java
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.stereotype.Controller;
import reactor.core.publisher.Flux;

import java.time.Duration;
import java.time.Instant;
import java.util.function.Supplier;
import java.util.stream.Stream;

@Controller
public class SampleController {

    @MessageMapping("graphql")
    public String greeting() {
        return "Hello world!";
    }

    @MessageMapping("graphql")
    public Flux<String> greetings() {
        return Flux.fromStream(Stream.generate(new Supplier<String>() {
            @Override
            public String get() {
                return "Hello " + Instant.now() + "!";
            }
        })).delayElements(Duration.ofSeconds(1)).take(5);
    }

}
```

编写 `src/main/resources/graphql/schema.graphqls` 配置文件：

```text
type Query {
    greeting: String
}
type Subscription {
    greetings: String
}
```

编写 `src/main/resources/application.yaml` 配置文件

```yaml
server:
  port: 8080
spring:
  rsocket:
    server:
      port: 7000
      mapping-path: /rsocket
      transport: websocket
```

参照 RSocket 文档使用如下命令即可完成测试：

```bash
java -jar rsc.jar --request --route=graphql --dataMimeType="application/graphql+json" --data '{"query": "query {\n  greeting\n}"}' --debug ws://localhost:7000/rsocket
java -jar rsc.jar --stream --route=graphql --dataMimeType="application/graphql+json" --data='{"subscription": "subscription { greetings { greeting } }"}' --debug ws://localhost:7000/rsocket
```

或者使用 RSocket Requests In HTTP Client：

```text
### query
GRAPHQL rsocketws://localhost:8080/rsocket/graphql

query {greeting}

### sub
GRAPHQL rsocketws://localhost:8080/rsocket/graphql

subscription { greetings }
```

### IDEA 插件

在 IDEA 插件中可以找到 GraphQL 插件，此插件可以完成一些代码提示和运行测试的功能。

在安装完成后可以编写如下配置文件 `graphql.config.yaml`：

```yaml
schema: schema.graphqls
documents: '**/*.graphql'
exclude: 'src/**/__tests__/**'
include: src/**
extensions:
  endpoints:
    default:
      url: http://localhost:8080/graphql
      headers:
        Authorization: Bearer ${TOKEN}
```

### 单元测试

可以编写如下样例进行单元测试：

```java
import jakarta.annotation.Resource;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.graphql.tester.AutoConfigureGraphQlTester;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.graphql.test.tester.GraphQlTester;
import org.springframework.security.test.context.support.WithMockUser;

@Import({AuthorRepository.class})
@DataJpaTest
@AutoConfigureGraphQlTester
@AutoConfigureMockMvc
class TestControllerTest {

    @Resource
    private GraphQlTester graphQlTester;

    @Test
    @WithMockUser(username = "test", roles = "USER")
    void testFindAll() {
        // language=GraphQL
        String document = """
                query {
                  authors {
                    id
                    name
                  }
                }
                """;
        graphQlTester.document(document).execute().path("authors").entityList(Author.class).hasSize(2);
    }

}
```

### 与 Spring Security 集成

> 注：此处样例默认使用 JWT ，如需详细代码请参照 Spring Security 文档。需要值得注意的是，在配置完成后 graphqil 就不能正常使用了，我尝试将相应链接进行开放但还是在发送请求时遇到了 js 相关的问题，且 graphiql 无法访问 IntrospectionQuery 也就没有了代码提示等功能，但是 Postman 是可以正常工作的。 

```java
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.web.access.BearerTokenAccessDeniedHandler;
import org.springframework.security.web.SecurityFilterChain;

import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;

import static jakarta.servlet.DispatcherType.ERROR;
import static jakarta.servlet.DispatcherType.FORWARD;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity(securedEnabled = true)
public class SecurityConfig {

    @Value("${jwt.public.key}")
    RSAPublicKey publicKey;

    @Value("${jwt.private.key}")
    RSAPrivateKey privateKey;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests((authorize) -> authorize
                        .dispatcherTypeMatchers(FORWARD, ERROR).permitAll()
                        .anyRequest().authenticated()
                )
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement((session) -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .decoder(jwtDecoder())
                        )
                )
                .exceptionHandling((exceptions) -> exceptions.authenticationEntryPoint(new BearerTokenAuthenticationEntryPoint())
                        .accessDeniedHandler(new BearerTokenAccessDeniedHandler())
                );
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withPublicKey(this.publicKey).build();
    }

    @Bean
    JwtEncoder jwtEncoder() {
        JWK jwk = new RSAKey.Builder(this.publicKey).privateKey(this.privateKey).build();
        return new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(jwk)));
    }

}
```

然后在方法上添加如下注解：

```java
import jakarta.annotation.Resource;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class TestController {

    @Resource
    private AuthorRepository authorRepository;

    @Resource
    private UserServiceImpl userService;

    @Secured("SCOPE_ROLE_USER")
    @QueryMapping
    List<Author> authors() {
        return authorRepository.findAll();
    }

    @PreAuthorize("permitAll()")
    @QueryMapping
    String login(@Argument String username, @Argument String password) {
        return userService.login(username, password);
    }

}
```


### 参考资料

[Does Your API Need A REST? Check Out GraphQL](https://www.youtube.com/watch?v=tMPC-u891XA)

[GraphQL 样例程序](https://github.com/danvega/graphql-store)

[Introduction to Spring GraphQL with Spring Boot](https://www.youtube.com/watch?v=atA2OovQBic)

[Spring Fro GraphQL 官方文档](https://docs.spring.io/spring-graphql/docs/current/reference/html/)

[GraphQL 官方文档](https://graphql.org/learn/)

[官方 WebSocket 例程](https://github.com/spring-projects/spring-graphql/tree/1.0.x/samples/webflux-websocket)

[GrpahQL 的网关- Fedration](https://docs.spring.io/spring-graphql/reference/federation.html)

[Apollo Federation 文档](https://www.apollographql.com/docs/federation/)
