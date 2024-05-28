---
title: Spring Authorization Server
date: 2023-06-30 21:32:58
tags:
- "Java"
- "Spring Boot"
- "OAuth"
id: authorization-server
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Authorization Server

### 简介

Spring Authorization Server 是一个框架，提供 OAuth 2.1 和 OpenID Connect 1.0 规范以及其他相关规范的实现。

通常与 Spring Authorization Server 一起使用的组件还有 OAuth2 Resource Server (负责保护受保护的资源，并验证访问令牌以确保客户端和用户有权访问这些资源。) 和 OAuth2 Client (负责代表用户请求所需资源)

### 使用方式

#### Spring Boot CLI

使用如下命令安装 CLI ：

```bash
sdk install springboot
```

然后使用如下命令即可生成密码：

```bash
spring encodepassword secret
```

> 注：此处保存生成的密码即可。

#### OAuth2 Authorization Server

在创建项目时引入 `OAuth2 Authorization Server` 依赖即可，样例如下：

```grovvy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-oauth2-authorization-server'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-web'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    runtimeOnly 'com.h2database:h2'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testImplementation 'org.springframework.security:spring-security-test'
}
```

然后编辑如下配置类即可：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;

@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public RegisteredClientRepository registeredClientRepository() {
        RegisteredClient registeredClient = RegisteredClient.withId("local")
                .clientId("local")
                .clientSecret("$xxxx")
                .redirectUri("http://localhost:8080/test")
                .authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .scope("openid")
                .scope("profile")
                .scope("email")
                .build();
        return new InMemoryRegisteredClientRepository(registeredClient);
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails userDetails = User.withUsername("admin")
                .password(passwordEncoder().encode("admin"))
                .roles("USER","openid","profile","email")
                .build();
        return new InMemoryUserDetailsManager(userDetails);
    }

}
```

> 注：此处可以使用之前生成的密码替换 client-secret，不要带上 `{bcrypt}`。


启动程序然后使用如下命令即可获得 Token:

```bash
http -f POST :8080/oauth2/token grant_type=client_credentials scope='user.read' -a client:secret
```

> 注：如果没有 httpie 工具则可以使用 IDEA 自带的 Http 工具。

```http
POST http://localhost:8080/oauth2/token
Authorization: Basic client secret
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=user.read
```

#### OAuth2 Resource Server

在创建项目时引入 `OAuth2 Resource Server` 依赖即可，样例如下：

```grovvy
dependencies {
	implementation 'org.springframework.boot:spring-boot-starter-oauth2-resource-server'
	implementation 'org.springframework.boot:spring-boot-starter-web'
	testImplementation 'org.springframework.boot:spring-boot-starter-test'
}
```

然后编写如下 Contorller 即可：

```java
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping
public class TestController {

    @GetMapping
    public ResponseEntity<String> user() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof Jwt) {
            String username = ((Jwt) principal).getSubject();
            return ResponseEntity.ok(username);
        } else {
            throw new RuntimeException("Token error");
        }
    }

}
```

然后编写如下配置项：

```yaml
server:
  port: 8081
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8080
```

启动服务，然后使用之前获取到的 Token 令牌访问即可：

> 注: 默认 Token 的有效期是 5 分钟，建议重新生成一个再访问。

```http
### GET USER
GET http://localhost:8081/
Authorization: Bearer {token}
```

#### OAuth2 Client

在创建项目时引入 `OAuth2 Client` 和 `Spring Cloud Gateway` 依赖即可，样例如下：

```grovvy
dependencies {
	implementation 'org.springframework.boot:spring-boot-starter-oauth2-client'
	implementation 'org.springframework.boot:spring-boot-starter-webflux'
	implementation 'org.springframework.cloud:spring-cloud-starter-gateway'
	testImplementation 'org.springframework.boot:spring-boot-starter-test'
	testImplementation 'io.projectreactor:reactor-test'
}
```

按照如下代码修改主类：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.GatewayFilterSpec;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class AuthclientApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthclientApplication.class, args);
    }

    @Bean
    RouteLocator gateway(RouteLocatorBuilder rlb) {
        return rlb
                .routes()
                .route(rs -> rs
                        .path("/")
                        .filters(GatewayFilterSpec::tokenRelay)
                        .uri("http://localhost:8081"))
                .build();
    }
}
```

然后编写配置文件如下即可：

```yaml
server:
  port: 8082
spring:
  security:
    oauth2:
      client:
        registration:
          spring:
            provider: spring
            client-id: client
            client-secret: secret
            authorization-grant-type: authorization_code
            client-authentication-method: client_secret_basic
            redirect-uri: "{baseUrl}/login/oauth2/code/{registrationId}"
            scope: user.read,openid
        provider:
          spring:
            issuer-uri: http://localhost:8080
```

测试方式：

访问如下地址，按照页面提示输入用户名和密码登录即可：

[http://127.0.0.1:8082](http://127.0.0.1:8082)

> 注：访问后会自动跳转到 OAuth2 Authorization Server 登录，并将使用 Session 存储用户信息。然后 Spring Cloud Gateway 通过读取 Session 生成 Token 并将请求转发到 OAuth2 Resource Server 中。

### 参考资料

[官方文档](https://docs.spring.io/spring-authorization-server/docs/current/reference/html/getting-started.html)

[官方博客](https://spring.io/blog/2023/05/24/spring-authorization-server-is-on-spring-initializr)

[视频教程](https://www.youtube.com/watch?v=7zm3mxaAFWk)

[样例源码](https://github.com/coffee-software-show/authorization-server-in-boot-31)
