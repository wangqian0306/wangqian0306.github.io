---
title: Spring Security
date: 2021-10-27 21:32:58
tags:
- "Java"
- "Spring Boot"
- "Spring Security"
- "JWT"
id: spring-security
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Security

### 简介

Spring Security 是一款安全框架。

### 初步使用

引入依赖包：

- Developer Tools
    - Lombok
- Web
    - Spring Web
- Security
    - Spring Security
    - OAuth2 Resource Server
- SQL
    - Spring Data JPA / MyBatis Framework
    - MySQL Driver / ...

书写配置文件：

```text
spring.datasource.url=${MYSQL_URI:jdbc:mysql://xxx.xxx.xxx:xxxx/xxx}
spring.datasource.username=${JDBC_USERNAME:xxx}
spring.datasource.password=${JDBC_PASSWORD:xxx}
spring.datasource.driver-class-name=${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
jwt.public.key=classpath:pub.key
jwt.private.key=classpath:pri.key
spring.jpa.hibernate.ddl-auto=update
```

新建用户/权限相关模型：

```java
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.hibernate.Hibernate;

import java.util.Collection;
import java.util.Objects;

@Getter
@Setter
@RequiredArgsConstructor
@NamedEntityGraph(
        name = "user.roles",
        attributeNodes = @NamedAttributeNode("roles")
)
@Entity
@Table(name = "T_USER")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique=true)
    private String username;

    private String email;

    private String phone;

    @JsonIgnore
    private String password;

    @Transient
    private String rawPass;

    private Boolean enabled;

    @JsonIgnore
    private Boolean tokenExpired;

    @JsonIgnore
    @ManyToMany
    @JoinTable(
            name = "T_USER_ROLE_REL",
            joinColumns = @JoinColumn(
                    name = "USER_ID", referencedColumnName = "id"),
            inverseJoinColumns = @JoinColumn(
                    name = "ROLE_ID", referencedColumnName = "id"))
    private Collection<Role> roles;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        User that = (User) o;
        return id != null && Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

}
```

```java
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import com.fasterxml.jackson.annotation.JsonIgnore;

import java.util.Collection;

@Slf4j
@Setter
@Getter
@Entity
@Table(name = "T_ROLE")
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    private String name;

    @JsonIgnore
    @ManyToMany(mappedBy = "roles")
    private Collection<User> users;

}
```

新建用户/权限相关存储库：

```java
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    @EntityGraph(value = "user.roles", type = EntityGraph.EntityGraphType.FETCH)
    Optional<User> findByUsername(String username);

}
```

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {

    Role findByName(String name);

}
```

新建权限配置程序：

```java
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.oauth2.server.resource.OAuth2ResourceServerConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.data.repository.query.SecurityEvaluationContextExtension;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.web.access.BearerTokenAccessDeniedHandler;
import org.springframework.security.web.SecurityFilterChain;

import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Value("${jwt.public.key}")
    RSAPublicKey publicKey;

    @Value("${jwt.private.key}")
    RSAPrivateKey privateKey;

    private static final String ADMIN_ROLE_NAME = "ROLE_ADMIN";

    private static final String USER_ROLE_NAME = "ROLE_USER";

    private static final String[] AUTH_WHITELIST = {
            // -- Swagger UI v3 (OpenAPI)
            "/v3/api-docs/**",
            "/swagger-ui/**",
            // other
            "/api/v1/user/login"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .cors().disable()
                .formLogin().disable()
                .httpBasic().disable()
                .httpBasic(Customizer.withDefaults())
                .authorizeHttpRequests()
                .requestMatchers(AUTH_WHITELIST).permitAll()
                .requestMatchers("/api/v1/admin/**").hasAuthority(ADMIN_ROLE_NAME)
                .requestMatchers("/api/v1/admin").hasAuthority(ADMIN_ROLE_NAME)
                .requestMatchers("/api/v1/notice").hasAnyAuthority(USER_ROLE_NAME, ADMIN_ROLE_NAME)
                .anyRequest().authenticated()
                .and()
                .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .oauth2ResourceServer(OAuth2ResourceServerConfigurer::jwt)
                .exceptionHandling()
                .authenticationEntryPoint(new BearerTokenAuthenticationEntryPoint())
                .accessDeniedHandler(new BearerTokenAccessDeniedHandler());
        return http.build();
    }

    @Bean
    public SecurityEvaluationContextExtension securityEvaluationContextExtension() {
        return new SecurityEvaluationContextExtension();
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

新建登录验证程序：

```java
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Slf4j
@Service
public class CustomUserDetailService implements UserDetailsService {

    @Resource
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new UsernameNotFoundException(username);
        }
        return new CustomUserPrincipal(optional.get());
    }

}
```

新建登录请求和返回类：

```java
import lombok.Data;

@Data
public class LoginRequest {
    private String username;
    private String password;
}
```

```java
import lombok.Data;

@Data
public class LoginResponse {
    private String token;
}
```

新建用户验证服务：

```java
public interface UserService {

    LoginResponse login(LoginRequest loginRequest);

    User getUserByUsername(String username);

}
```

```java
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
public class UserServiceImpl implements UserService {

    @Value("${jwt.expiry:36000}")
    Long expiry;

    @Resource
    private JwtEncoder jwtEncoder;

    @Resource
    private UserDetailsService userDetailsService;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Resource
    private UserRepository userRepository;

    @Override
    public LoginResponse login(LoginRequest loginRequest) {
        LoginResponse loginResponse = new LoginResponse();
        UserDetails userDetails = userDetailsService.loadUserByUsername(loginRequest.getUsername());
        if (passwordEncoder.matches(loginRequest.getPassword(), userDetails.getPassword())) {
            loginResponse.setToken(generateToken(userDetails));
        } else {
            throw new ReportBadException(ErrorEnum.PASSWORD_MISMATCH);
        }
        return loginResponse;
    }

    @Override
    public User getUserByUsername(String username) {
        Optional<User> optionalUser = userRepository.findByUsername(username);
        if (optionalUser.isEmpty()){
            throw new ReportBadException(ErrorEnum.NOT_FOUND_EXCEPTION);
        }
        return optionalUser.get();
    }

    private String generateToken(UserDetails userDetails) {
        Instant now = Instant.now();
        String scope = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(" "));
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("self")
                .issuedAt(now)
                .expiresAt(now.plusSeconds(expiry))
                .subject(userDetails.getUsername())
                .claim("scope", scope)
                .build();
        return this.jwtEncoder.encode(JwtEncoderParameters.from(claims)).getTokenValue();
    }

}
```

新建登录控制器：

```java
import io.swagger.v3.oas.annotations.Operation;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    @Resource
    private UserService userService;

    @GetMapping
    @Operation(summary = "get current user")
    public ResponseEntity<User> user() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof Jwt) {
            String username = ((Jwt) principal).getSubject();
            return ResponseEntity.ok(userService.getUserByUsername(username));
        } else {
            throw new ReportBadException(ErrorEnum.TOKEN_EXCEPTION);
        }
    }

    @PostMapping("/login")
    @Operation(summary = "login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {
        return ResponseEntity.ok(userService.login(loginRequest));
    }

}
```

### 使用方式

```bash
curl --location --request POST 'localhost:8080/api/v1/user/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "username":"admin",
    "password":"admin"
}'
```

```bash
curl --request GET 'http://localhost:8080/api/v1/user' --header 'Authorization: Bearer <token>'
```

### 获取用户相关信息的基本方式
```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "当前登录用户：" + SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
```

### OpenAPI 相关配置

可以加入如下配置，可以在 OpenAPI 中自动携带 JWT Token。

```java
import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenAPIConf {

    @Bean
    public OpenAPI customizeOpenAPI() {
        String securitySchemeName = "bearerAuth";
        return new OpenAPI()
                .addSecurityItem(new SecurityRequirement()
                        .addList(securitySchemeName))
                .components(new Components()
                        .addSecuritySchemes(securitySchemeName, new SecurityScheme()
                                .name(securitySchemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .description(
                                        "Provide the JWT token. JWT token can be obtained from the Login API. For testing, use the credentials <strong>john/password</strong>")
                                .bearerFormat("JWT")));
    }
}
```

### 参考资料

[Spring Security 例程](https://github.com/spring-projects/spring-security-samples)

[baeldung 教程](https://www.baeldung.com/security-spring)

[RSA 密钥生成](http://www.metools.info/code/c80.html)
