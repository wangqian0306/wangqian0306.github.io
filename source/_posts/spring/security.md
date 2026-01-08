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
categories:
- "Spring"
---

## Spring Security

### 简介

Spring Security 是一款安全框架。

### 基本使用

引入依赖包：

- Developer Tools
    - Lombok
- Web
    - Spring Web
- Template Engines
    - Thymeleaf
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
spring.jpa.hibernate.ddl-auto=update
```

新建用户模型 `user/User.java` ：

```java
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.proxy.HibernateProxy;

import java.util.Objects;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@Table(name="T_USER")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;
    private String password;
    private String roles;

    public User(String username, String password, String roles) {
        this.username = username;
        this.password = password;
        this.roles = roles;
    }

    @Override
    public final boolean equals(Object o) {
        if (this == o) return true;
        if (o == null) return false;
        Class<?> oEffectiveClass = o instanceof HibernateProxy ? ((HibernateProxy) o).getHibernateLazyInitializer().getPersistentClass() : o.getClass();
        Class<?> thisEffectiveClass = this instanceof HibernateProxy ? ((HibernateProxy) this).getHibernateLazyInitializer().getPersistentClass() : this.getClass();
        if (thisEffectiveClass != oEffectiveClass) return false;
        User user = (User) o;
        return getId() != null && Objects.equals(getId(), user.getId());
    }

    @Override
    public final int hashCode() {
        return this instanceof HibernateProxy ? ((HibernateProxy) this).getHibernateLazyInitializer().getPersistentClass().hashCode() : getClass().hashCode();
    }

}
```

新建用户存储库 `user/UserRepository.java`：

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    Optional<User> findByUsername(String username);

}
```

新建用户初始化类：

```java
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.lang.Nullable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Component
public class SetupUserLoader implements ApplicationListener<ContextRefreshedEvent> {

    boolean alreadySetup = false;

    private final UserRepository userRepository;

    private final PasswordEncoder passwordEncoder;

    public SetupUserLoader(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void onApplicationEvent(@Nullable ContextRefreshedEvent event) {
        if (alreadySetup)
            return;
        createUserIfNotFound("admin", "admin", "ROLE_ADMIN,ROLE_USER");
        alreadySetup = true;
    }

    @Transactional
    public void createUserIfNotFound(String username, String password, String role) {
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            User user = new User();
            user.setUsername(username);
            user.setPassword(passwordEncoder.encode(password));
            user.setRoles(role);
            userRepository.save(user);
        }
    }

}
```

新建登录请求类 `auth/LoginRequest.java`：

```java
import lombok.Data;

@Data
public class LoginRequest {

    public String username;

    public String password;

}
```

新建用户细节类 `security/CustomUserDetail.java`

```java
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Arrays;
import java.util.Collection;

public class CustomUserDetail implements UserDetails {

    private final User user;

    public CustomUserDetail(User user) {
        this.user = user;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Arrays.stream(user
                        .getRoles()
                        .split(","))
                .map(SimpleGrantedAuthority::new)
                .toList();
    }

    @Override
    public String getPassword() {
        return user.getPassword();
    }

    @Override
    public String getUsername() {
        return user.getUsername();
    }

}
```

新建登录验证程序 `security/CustomUserDetailsService`：

```java
import jakarta.annotation.Resource;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Resource
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new UsernameNotFoundException(username);
        }
        return new CustomUserDetail(optional.get());
    }

}
```

### Session

新建登出处理类 `security/NoRedirectLogoutSuccessHandler.java` :

```java
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;

import java.io.IOException;

public class NoRedirectLogoutSuccessHandler implements LogoutSuccessHandler {

    @Override
    public void onLogoutSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) {
        response.setStatus(200);
    }

}
```

新建权限配置程序 `security/SecurityConfig.java` ：

```java
import jakarta.annotation.Resource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.logout.HeaderWriterLogoutHandler;
import org.springframework.security.web.header.writers.ClearSiteDataHeaderWriter;

import static jakarta.servlet.DispatcherType.ERROR;
import static jakarta.servlet.DispatcherType.FORWARD;
import static org.springframework.security.web.header.writers.ClearSiteDataHeaderWriter.Directive.ALL;


@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Resource
    private CustomUserDetailsService customUserDetailsService;

    private static final String ADMIN_ROLE_NAME = "ROLE_ADMIN";

    private static final String[] AUTH_WHITELIST = {
            // -- Swagger UI v3 (OpenAPI)
            "/v3/api-docs/**",
            "/swagger-ui/**",
            // other
            "/api/auth/login"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests((authorize) -> authorize
                        .dispatcherTypeMatchers(FORWARD, ERROR).permitAll()
                        .requestMatchers(AUTH_WHITELIST).permitAll()
                        .requestMatchers("/api/admin/**").hasAuthority(ADMIN_ROLE_NAME)
                        .anyRequest().authenticated()
                )
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(Customizer.withDefaults())
                .cors(AbstractHttpConfigurer::disable)
                .formLogin(Customizer.withDefaults())
                .logout((logout) -> logout
                        .logoutUrl("/api/auth/logout")
                        .addLogoutHandler(new HeaderWriterLogoutHandler(new ClearSiteDataHeaderWriter(ALL)))
                        .deleteCookies("JSESSIONID")
                        .logoutSuccessHandler(new NoRedirectLogoutSuccessHandler())
                );
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager() {
        DaoAuthenticationProvider daoAuthenticationProvider = new DaoAuthenticationProvider();
        daoAuthenticationProvider.setUserDetailsService(customUserDetailsService);
        daoAuthenticationProvider.setPasswordEncoder(passwordEncoder());
        return new ProviderManager(daoAuthenticationProvider);
    }

}
```

> 注：在调试权限部分内容时可以开启 Debug 开关 @EnableWebSecurity(debug = True) 或是打开如下开关 logging.level.springframework.security = TRACE 

新建用户验证服务 `auth/AuthService.java`：

```java
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.context.SecurityContextHolderStrategy;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Resource
    private AuthenticationManager authenticationManager;

    private final SecurityContextRepository securityContextRepository = new HttpSessionSecurityContextRepository();

    public void login(HttpServletRequest request,
                      HttpServletResponse response,
                      LoginRequest body
    ) throws AuthenticationException {
        UsernamePasswordAuthenticationToken token = UsernamePasswordAuthenticationToken.unauthenticated(body.getUsername(), body.getPassword());
        Authentication authentication = authenticationManager.authenticate(token);
        SecurityContextHolderStrategy securityContextHolderStrategy = SecurityContextHolder.getContextHolderStrategy();
        SecurityContext context = securityContextHolderStrategy.createEmptyContext();
        context.setAuthentication(authentication);
        securityContextHolderStrategy.setContext(context);
        securityContextRepository.saveContext(context, request, response);
    }

    public String getUsername() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof User user) {
            return user.getUsername();
        } else if (principal instanceof UserDetails userDetails) {
            return userDetails.getUsername();
        } else {
            throw new ReportBadException(ErrorEnum.PARAM_EXCEPTION);
        }
    }

}
```

新建登录控制器 `auth/AuthController.java`：

```java
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Resource
    private AuthService authService;

    @PostMapping("/login")
    public void login(@RequestBody LoginRequest loginRequest, HttpServletRequest request, HttpServletResponse response) {
        authService.login(request,response,loginRequest);
    }

    @GetMapping("/user")
    public String getUser() {
        return authService.getUsername();
    }

}
```

#### 使用方式

在 IDEA 中则可以使用如下方式进行请求：

```text
### Login
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin"
}

### Get User
GET http://localhost:8080/api/auth/user
Content-Type: application/json

### Logout
GET http://localhost:8080/api/auth/logout
Content-Type: application/json
```

#### 获取用户相关信息的基本方式
```java
@RestController
public class HelloController {

    @GetMapping("/hello")
    public String hello() {
        return "当前登录用户：" + SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
```

### JWT

新增如下配置：

```text
jwt.public.key=classpath:pub.key
jwt.private.key=classpath:pri.key
```

新建权限配置程序 `security/SecurityConfig.java`：

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
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
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
        http
                .authorizeHttpRequests((authorize) -> authorize
                        .dispatcherTypeMatchers(FORWARD, ERROR).permitAll()
                        .requestMatchers(AUTH_WHITELIST).permitAll()
                        .requestMatchers(AUTH_WHITELIST).permitAll()
                        .requestMatchers("/api/v1/admin/**").hasAuthority(ADMIN_ROLE_NAME)
                        .requestMatchers("/api/v1/admin").hasAuthority(ADMIN_ROLE_NAME)
                        .requestMatchers("/api/v1/notice").hasAnyAuthority(USER_ROLE_NAME, ADMIN_ROLE_NAME)
                        .anyRequest().authenticated()
                )
                .csrf((csrf) -> csrf.ignoringRequestMatchers("/token"))
                .httpBasic(Customizer.withDefaults())
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .decoder(jwtDecoder())
                        )
                )
                .sessionManagement((session) -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling((exceptions) -> exceptions.authenticationEntryPoint(new BearerTokenAuthenticationEntryPoint())
                        .accessDeniedHandler(new BearerTokenAccessDeniedHandler())
                ).cors(AbstractHttpConfigurer::disable);
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

新建登录返回类 `auth/LoginResponse.java`：

```java
import lombok.Data;

@Data
public class LoginResponse {
    private String token;
}
```

新建用户验证服务 `auth/AuthService.java`：

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
public class UserService {

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

    public LoginResponse login(LoginRequest loginRequest) {
        LoginResponse loginResponse = new LoginResponse();
        UserDetails userDetails = userDetailsService.loadUserByUsername(loginRequest.getUsername());
        if (passwordEncoder.matches(loginRequest.getPassword(), userDetails.getPassword())) {
            loginResponse.setToken(generateToken(userDetails));
        } else {
            throw new RuntimeException("Invalid password");
        }
        return loginResponse;
    }

    public User getUserByUsername(String username) {
        Optional<User> optionalUser = userRepository.findByUsername(username);
        if (optionalUser.isEmpty()){
            throw new RuntimeException("Not Found");
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

新建登录控制器 `auth/AuthController.java`：

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
@RequestMapping("/api/auth")
public class AuthController {

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
            throw new RuntimeException("Token error");
        }
    }

    @PostMapping("/login")
    @Operation(summary = "login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {
        return ResponseEntity.ok(userService.login(loginRequest));
    }

    @GetMapping("/roles")
    public ResponseEntity<List<String>> authorities() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        List<String> authorities = new ArrayList<>();
        for (GrantedAuthority authority : authentication.getAuthorities()) {
            authorities.add(authority.getAuthority());
        }
        return ResponseEntity.ok(authorities);
    }

}
```

#### 使用方式

```bash
curl --location --request POST 'localhost:8080/api/auth/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "username":"admin",
    "password":"admin"
}'
```

```bash
curl --request GET 'http://localhost:8080/api/auth' --header 'Authorization: Bearer <token>'
```

#### 在 Get 参数或 Form 中携带 token

首先需要参照如下样例修改配置类：

```java
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, MvcRequestMatcher.Builder mvc) throws Exception {
        DefaultBearerTokenResolver resolver = new DefaultBearerTokenResolver();
        resolver.setAllowUriQueryParameter(true);
        resolver.setAllowFormEncodedBodyParameter(true);
        http
                .authorizeHttpRequests((authorize) -> authorize
                        .dispatcherTypeMatchers(FORWARD, ERROR).permitAll()
                        .requestMatchers(antMatcher("/api/auth/login")).permitAll()
                        .anyRequest().authenticated()
                )
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(Customizer.withDefaults())
                .oauth2ResourceServer(oauth2 -> oauth2
                        .bearerTokenResolver(resolver)
                        .jwt(jwt -> jwt
                                .decoder(jwtDecoder())
                        )
                )
                .sessionManagement((session) -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling((exceptions) -> exceptions
                        .authenticationEntryPoint(new BearerTokenAuthenticationEntryPoint()));
        return http.build();
    }
}
```

然后即可在请求中添加 `access_token` 参数即可，GET 请求样例如下：

```bash
curl --request GET 'http://localhost:8080/api/user?access_token=<token>'
```

> 注：无需添加 `Bearer` 字段

#### OpenAPI 相关配置

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

### 与 Spring Data 集成

可以在依赖中添加 `org.springframework.security:spring-security-data` 来与 SpringData 集成，通过下面的查询直接返回用户所拥有的内容：

```java
@Repository
public interface MessageRepository extends PagingAndSortingRepository<Message,Long> {
    @Query("select m from Message m where m.to.id = ?#{ principal?.id }")
    Page<Message> findInbox(Pageable pageable);
}
```

### 自定义登录页

编写如下 `resources/templates/login.html` ：

```html
<!DOCTYPE html>
<html lang="zh" xmlns:th="https://www.thymeleaf.org">
<head>
    <title>Please Log In</title>
</head>
<body>
<h1>Here is Custom Login page. Please Log In: </h1>
<div th:if="${param.error}">
    Invalid username and password.</div>
<div th:if="${param.logout}">
    You have been logged out.</div>
<form th:action="@{/login}" method="post">
    <div>
        <label>
            <input type="text" name="username" placeholder="Username"/>
        </label>
    </div>
    <div>
        <label>
            <input type="password" name="password" placeholder="Password"/>
        </label>
    </div>
    <input type="submit" value="Log in" />
</form>
</body>
</html>
```

编写 `security/SecurityConfig.java` 配置文件：

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests((authorize) -> authorize.anyRequest().authenticated())
                .formLogin(form -> form.loginPage("/login").permitAll());
        return http.build();
    }
}
```

编写 `auth/LoginController.java` ：

```java
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class LoginController {

    @GetMapping("/login")
    public String login() {
        return "login";
    }

}
```

> 注：此处如果单个页面样式上需要使用 Tailwind CSS 可以参照参考资料样例。

### 单元测试

在测试中可以使用如下方式指定测试用户：

```java
@RunWith(SpringRunner.class)
@SpringBootTest
@AutoConfigureMockMvc
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockUser(username = "user", roles = "USER")
    public void testGetUser() throws Exception {
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.username").value("user"));
    }
}
```

### 方法鉴权

除了在接口层面上做安全之外，还可以在方法层面上进行补充和完善，确保数据安全。

开启下面的注解后即可使用方法鉴权：

```java
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@EnableMethodSecurity
```

在通过 Spring 调用相应需要鉴权的方法时就会触发安全检查，抛出相应异常。

### MFA

Spring Security 7 支持了原生的多方式认证逻辑，比方说验证码登录就可以采用如下配置：

配置文件 `SecurityConfig.java`

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.ott.OneTimeTokenService;
import org.springframework.security.config.annotation.authorization.EnableMultiFactorAuthentication;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.authority.FactorGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

import java.time.Duration;

import static org.springframework.security.config.Customizer.withDefaults;

@Configuration
@EnableWebSecurity
@EnableMultiFactorAuthentication(authorities = {
        FactorGrantedAuthority.PASSWORD_AUTHORITY,
        FactorGrantedAuthority.OTT_AUTHORITY
})
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) {
        return http
                .authorizeHttpRequests((authorize) -> authorize
                        .requestMatchers("/", "/ott/sent").permitAll()
                        .requestMatchers("/admin/**").hasRole("ADMIN")
                )
                .formLogin(withDefaults())
                .oneTimeTokenLogin(withDefaults())
                .build();
    }

    @Bean
    UserDetailsService userDetailsService() {
        var user = User.withUsername("user")
                .password("{noop}password")
                .roles("USER")
                .build();
        var admin = User.withUsername("admin")
                .password("{noop}password")
                .roles("ADMIN","USER")
                .build();

        return new InMemoryUserDetailsManager(user, admin);
    }

    @Bean
    public OneTimeTokenService oneTimeTokenService() {
        PinOneTimeTokenService service = new PinOneTimeTokenService();
        service.setTokenExpiresIn(Duration.ofMinutes(3));
        return service;
    }

}
```

测试路由文件 `HomeController.java`

```java
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {

    @GetMapping("/")
    public String home() {
        return "Hello World!";
    }

    @GetMapping("/admin")
    public String admin() {
        return "Admin Page";
    }

    @GetMapping("/ott/sent")
    String ottSent() {
        return "OneTimeToken Sent";
    }

}
```

发送验证码服务 `OttSuccessHandler.java`

```java
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.ott.OneTimeToken;
import org.springframework.security.web.authentication.ott.OneTimeTokenGenerationSuccessHandler;
import org.springframework.security.web.authentication.ott.RedirectOneTimeTokenGenerationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;

@Component
public class OttSuccessHandler implements OneTimeTokenGenerationSuccessHandler {

    private static final Logger log = LoggerFactory.getLogger(OttSuccessHandler.class);

    private final OneTimeTokenGenerationSuccessHandler redirectHandler = new RedirectOneTimeTokenGenerationSuccessHandler("/ott/sent");

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, OneTimeToken oneTimeToken) throws IOException, ServletException {
        String magicLink = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/login/ott")
                .queryParam("token", oneTimeToken.getTokenValue())
                .toUriString();

        // Email, SMS, custom implementation, etc.
        System.out.println("Magic Link: " + magicLink);
        this.redirectHandler.handle(request, response, oneTimeToken);
    }

}
```

验证码生成逻辑：

```java
import org.jspecify.annotations.Nullable;
import org.springframework.security.authentication.ott.*;
import org.springframework.util.Assert;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class PinOneTimeTokenService implements OneTimeTokenService {


    /*
     * The collision risk is higher with 5-digit PINs (100,000 possible values) compared to UUIDs.
     * For production with high traffic, you might want to add collision detection or use a database-backed implementation
     */
    private static final int PIN_LENGTH = 5;
    private static final int MAX_PIN_VALUE = 100_000;

    private final Map<String, OneTimeToken> oneTimeTokenByToken = new ConcurrentHashMap<>();
    private final SecureRandom secureRandom = new SecureRandom();

    private Clock clock = Clock.systemUTC();
    // Consider setting a shorter expiration time for these PINs (typically 5-10 minutes for SMS codes) since they're more susceptible to brute force than UUIDs
    private Duration tokenExpiresIn = Duration.ofMinutes(5);

    @Override
    public OneTimeToken generate(GenerateOneTimeTokenRequest request) {
        String token = generatePin();
        Instant expiresAt = this.clock.instant().plus(this.tokenExpiresIn);
        OneTimeToken ott = new DefaultOneTimeToken(token, request.getUsername(), expiresAt);
        this.oneTimeTokenByToken.put(token, ott);
        cleanExpiredTokensIfNeeded();
        return ott;
    }

    @Override
    public @Nullable OneTimeToken consume(OneTimeTokenAuthenticationToken authenticationToken) {
        OneTimeToken ott = this.oneTimeTokenByToken.remove(authenticationToken.getTokenValue());
        if (ott == null || isExpired(ott)) {
            return null;
        }
        return ott;
    }

    public void setTokenExpiresIn(Duration tokenExpiresIn) {
        Assert.notNull(tokenExpiresIn, "tokenExpiresIn cannot be null");
        Assert.isTrue(!tokenExpiresIn.isNegative() && !tokenExpiresIn.isZero(),
                "tokenExpiresIn must be positive");
        this.tokenExpiresIn = tokenExpiresIn;
    }

    private String generatePin() {
        int pin = secureRandom.nextInt(MAX_PIN_VALUE);
        return String.format("%0" + PIN_LENGTH + "d", pin);
    }

    private void cleanExpiredTokensIfNeeded() {
        if (this.oneTimeTokenByToken.size() < 100) {
            return;
        }
        for (Map.Entry<String, OneTimeToken> entry : this.oneTimeTokenByToken.entrySet()) {
            if (isExpired(entry.getValue())) {
                this.oneTimeTokenByToken.remove(entry.getKey());
            }
        }
    }

    private boolean isExpired(OneTimeToken ott) {
        return this.clock.instant().isAfter(ott.getExpiresAt());
    }

    public void setClock(Clock clock) {
        Assert.notNull(clock, "clock cannot be null");
        this.clock = clock;
    }

}
```

> 注：现在阶段的代码需要在访问 admin 路由时确认两种认证都存在才能操作，如果需要单种责任可以试试权限部分识别 `FACTOR_OTT` 或 `FACTOR_PASSWORD`

### 参考资料

[Spring Security 例程](https://github.com/spring-projects/spring-security-samples)

[baeldung 教程](https://www.baeldung.com/security-spring)

[RSA 密钥生成](http://www.metools.info/code/c80.html)

[spring-boot-3-jwt-security](https://github.com/ali-bouali/spring-boot-3-jwt-security)

[spring-boot-tailwind](https://github.com/danvega/spring-boot-tailwind)

[Spring Tips: Spring Security method security with special guest Rob Winch](https://www.youtube.com/watch?v=JYZHp5eqS2I)

[method-security 样例项目](https://github.com/rwinch/method-security)

[Let’s Explore Spring Security 6.4 (SpringOne 2024)](https://www.youtube.com/watch?v=9eoi1TViceM)

[Bootiful Spring Boot 3.4: Spring Security](https://spring.io/blog/2024/11/24/bootiful-34-security)

[spring-security-64](https://github.com/rwinch/spring-security-64)

[Testing with CSRF Protection](https://docs.spring.io/spring-security/reference/servlet/test/mockmvc/csrf.html)

[Spring Security 7 Adds Multi-Factor Authentication (MFA)](https://www.youtube.com/watch?v=KmNAqlaKwjw)
