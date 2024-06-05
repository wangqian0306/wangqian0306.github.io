---
title: Spring Authorization Server
date: 2023-06-30 21:32:58
tags:
- "Java"
- "Spring Boot"
- "OAuth"
- "OIDC"
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

##### OAuth

编辑如下配置类即可：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.server.authorization.settings.ClientSettings;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;

@Configuration
public class CustomOAuthConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails userDetails = User.withUsername("admin")
                .password(passwordEncoder().encode("admin"))
                .roles("USER")
                .build();
        return new InMemoryUserDetailsManager(userDetails);
    }

    @Bean
    public RegisteredClientRepository registeredClientRepository() {
        RegisteredClient registeredClient = RegisteredClient.withId("local")
                .clientId("oidc-client")
                .clientSecret("$xxxxx")
                .redirectUri("http://localhost:8080/test")
                .authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .postLogoutRedirectUri("http://localhost:8080/logout")
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .clientSettings(ClientSettings.builder().requireAuthorizationConsent(true).build())
                .build();
        return new InMemoryRegisteredClientRepository(registeredClient);
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
Authorization: Basic local secret
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=user.read
```

或者使用如下方式获取 OAuth Token：

访问如下地址并输入账号密码，点击同意授权：

[http://localhost:8080/oauth2/authorize?scope=openid+profile+email&response_type=code&client_id=local&redirect_uri=http://localhost:8080/test](http://localhost:8080/oauth2/authorize?scope=openid+profile+email&response_type=code&client_id=local&redirect_uri=http://localhost:8080/test)

之后可以从 URL 中获取到 `code`, 将其填写至下面的请求中即可获取 `Token` 。

```text
### GET TOKEN
POST http://localhost:8080/oauth2/token
Authorization: Basic local secret
Content-Type: application/x-www-form-urlencoded

grant_type = authorization_code &
client_id = local &
client_secret = secret &
code = xxxx &
redirect_uri = http://localhost:8080/test
```

##### Open ID Connect

编写如下 `application.yaml` 配置文件即可：

```yaml
logging:
  level:
    org.springframework.security.oauth2.server.authorization: DEBUG
    org.springframework.security: DEBUG

spring:
  application:
    name: auth-playground
  security:
    user:
      name: admin
      password: admin
    oauth2:
      authorizationserver:
        client:
          oidc-client:
            registration:
              client-id: "oidc-client"
              client-secret: "{noop}secret"
              client-authentication-methods:
                - "client_secret_basic"
              authorization-grant-types:
                - "authorization_code"
                - "refresh_token"
              redirect-uris:
                - "http://localhost:3000/auth/callback/oidc-client"
              post-logout-redirect-uris:
                - "http://localhost:8000/"
              scopes:
                - "openid"
                - "profile"
            require-authorization-consent: true
```

使用如下方式获取 Token：

访问如下地址并输入账号密码，点击同意授权：

[http://localhost:8080/oauth2/authorize?scope=openid+profile+email&response_type=code&client_id=local&redirect_uri=http://localhost:8080/test](http://localhost:8080/oauth2/authorize?scope=openid+profile+email&response_type=code&client_id=local&redirect_uri=http://localhost:8080/test)

之后可以从 URL 中获取到 `code`, 将其填写至下面的请求中即可获取 `Token` 。

```text
### GET TOKEN
POST http://localhost:8080/oauth2/token
Authorization: Basic oidc-client secret
Content-Type: application/x-www-form-urlencoded

grant_type = authorization_code &
client_id = oidc-client &
client_secret = secret &
code = xxxx &
redirect_uri = http://localhost:8080/test
```

又或者使用 [next-auth-example 项目](https://github.com/nextauthjs/next-auth-example) 进行试用。

##### 自定义 userinfo 

编辑 `OidcUserInfoService` ： 

```java
import org.springframework.security.oauth2.core.oidc.OidcUserInfo;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Map;

@Service
public class OidcUserInfoService {

    public OidcUserInfo loadUser(String username) {
        return new OidcUserInfo(createUser(username));
    }

    public Map<String, Object> createUser(String username) {
        return OidcUserInfo.builder()
                .subject(username)
                .name("First Last")
                .givenName("First")
                .familyName("Last")
                .middleName("Middle")
                .nickname("User")
                .preferredUsername(username)
                .profile("https://example.com/" + username)
                .picture("https://example.com/" + username + ".jpg")
                .website("https://example.com")
                .email(username + "@example.com")
                .emailVerified(true)
                .gender("female")
                .birthdate("1970-01-01")
                .zoneinfo("Europe/Paris")
                .locale("en-US")
                .phoneNumber("+1 (604) 555-1234;ext=5678")
                .phoneNumberVerified(false)
                .claim("address", Collections.singletonMap("formatted", "Champ de Mars\n5 Av. Anatole France\n75007 Paris\nFrance"))
                .updatedAt("1970-01-01T00:00:00Z")
                .build()
                .getClaims();
    }
}
```

新增配置类：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.oauth2.core.oidc.OidcUserInfo;
import org.springframework.security.oauth2.core.oidc.endpoint.OidcParameterNames;
import org.springframework.security.oauth2.server.authorization.token.JwtEncodingContext;
import org.springframework.security.oauth2.server.authorization.token.OAuth2TokenCustomizer;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public OAuth2TokenCustomizer<JwtEncodingContext> tokenCustomizer(
            OidcUserInfoService userInfoService) {
        return (context) -> {
            if (OidcParameterNames.ID_TOKEN.equals(context.getTokenType().getValue())) {
                OidcUserInfo userInfo = userInfoService.loadUser(
                        context.getPrincipal().getName());
                context.getClaims().claims(claims ->
                        claims.putAll(userInfo.getClaims()));
            }
        };
    }

}
```

> 注：在 scope 中新增 `email phone` 等 key 后就可以在 `/userinfo` 路由获取对应信息，或者将 `id_token` 放在 [JWT Debugger](https://jwt.io/) 中也可以解析这些内容。

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
