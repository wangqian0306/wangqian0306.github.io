---
title: Spring Security
date: 2021-10-27 21:32:58
tags:
- "Java"
- "Spring Boot"
id: caching
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Security

### 简介

Spring Security 是一款安全框架。本文会使用

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
spring.datasource.url=${MYSQL_URI:jdbc:mysql://192.168.2.77:3306/health_test}
spring.datasource.username=${JDBC_USERNAME:root}
spring.datasource.password=${JDBC_PASSWORD:Rb123456!}
spring.datasource.driver-class-name=${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
spring.jpa.hibernate.naming.physical-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
jwt.public.key=classpath:pub.key
jwt.private.key=classpath:pri.key
spring.jpa.hibernate.ddl-auto=update
```

新建用户/权限相关模型：

```java
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import com.fasterxml.jackson.annotation.JsonIgnore;

import javax.persistence.*;
import java.util.Collection;

@Slf4j
@Setter
@Getter
@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "T_USER")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    
    private String firstName;
    
    private String lastName;
    
    private String email;
    
    private String mobile;

    @JsonIgnore
    private String password;
    
    private Boolean enabled;
    
    private Boolean tokenExpired;

    @JsonIgnore
    @ManyToMany
    @JoinTable(
            name = "users_roles",
            joinColumns = @JoinColumn(
                    name = "user_id", referencedColumnName = "id"),
            inverseJoinColumns = @JoinColumn(
                    name = "role_id", referencedColumnName = "id"))
    private Collection<Role> roles;

    public Boolean isEnabled() {
        return this.enabled;
    }

}
```

```java
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import com.fasterxml.jackson.annotation.JsonIgnore;

import javax.persistence.*;
import java.util.Collection;

@Slf4j
@Setter
@Getter
@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "T_ROLE")
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    
    private String name;

    @JsonIgnore
    @ManyToMany(mappedBy = "roles")
    private Collection<User> users;

    @JsonIgnore
    @ManyToMany
    @JoinTable(
            name = "roles_privileges",
            joinColumns = @JoinColumn(
                    name = "role_id", referencedColumnName = "id"),
            inverseJoinColumns = @JoinColumn(
                    name = "privilege_id", referencedColumnName = "id"))
    private Collection<Privilege> privileges;

}
```

```java
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import com.fasterxml.jackson.annotation.JsonIgnore;

import javax.persistence.*;
import java.util.Collection;

@Slf4j
@Setter
@Getter
@Entity
@EntityListeners(AuditingEntityListener.class)
@Table(name = "T_PRIVILEGE")
public class Privilege {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;

    private String name;

    @JsonIgnore
    @ManyToMany(mappedBy = "privileges")
    private Collection<Role> roles;

}
```

新建用户/权限相关存储库：

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    User findByEmail(String email);
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

```java
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PrivilegeRepository extends JpaRepository<Privilege, Long> {
    Privilege findByName(String name);
}
```

新建权限配置程序：

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.config.annotation.web.configurers.oauth2.server.resource.OAuth2ResourceServerConfigurer;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

import java.security.interfaces.RSAPublicKey;

/**
 * Security configuration for the main application.
 *
 * @author Josh Cummings
 */
@Configuration
public class RestConfig extends WebSecurityConfigurerAdapter {

    @Value("${jwt.public.key}")
    RSAPublicKey key;

    private static final String[] AUTH_WHITELIST = {
            // -- Swagger UI v2
            "/v2/api-docs",
            "/swagger-resources",
            "/swagger-resources/**",
            "/configuration/ui",
            "/configuration/security",
            "/swagger-ui.html",
            "/webjars/**",
            // -- Swagger UI v3 (OpenAPI)
            "/v3/api-docs/**",
            "/swagger-ui/**",
            // other
            "/login"
    };

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .httpBasic(Customizer.withDefaults())
                .oauth2ResourceServer(OAuth2ResourceServerConfigurer::jwt)
                .authorizeRequests()
                .antMatchers(AUTH_WHITELIST).permitAll()
                .anyRequest().authenticated();
    }

    @Bean
    JwtDecoder jwtDecoder() {
        return NimbusJwtDecoder.withPublicKey(this.key).build();
    }

    @Bean
    public PasswordEncoder encoder() {
        return new BCryptPasswordEncoder(11);
    }

    @Bean("authenticationManager")
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
      return super.authenticationManagerBean();
    }
}
```

新建用户初始化程序：

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;

@Component
public class SetupDataLoader implements ApplicationListener<ContextRefreshedEvent> {

    boolean alreadySetup = false;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PrivilegeRepository privilegeRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (alreadySetup)
          return;
        Privilege readPrivilege = createPrivilegeIfNotFound("READ_PRIVILEGE");
        Privilege writePrivilege = createPrivilegeIfNotFound("WRITE_PRIVILEGE");
        List<Privilege> adminPrivileges = Arrays.asList(readPrivilege, writePrivilege);
        createRoleIfNotFound("ROLE_ADMIN", adminPrivileges);
        createRoleIfNotFound("ROLE_USER", List.of(readPrivilege));
        Role adminRole = roleRepository.findByName("ROLE_ADMIN");
        createUserIfNotFound(adminRole);
        alreadySetup = true;
    }

    @Transactional
    Privilege createPrivilegeIfNotFound(String name) {

        Privilege privilege = privilegeRepository.findByName(name);
        if (privilege == null) {
            privilege = new Privilege();
            privilege.setName(name);
            privilegeRepository.save(privilege);
        }
        return privilege;
    }

    @Transactional
    Role createRoleIfNotFound(String name, Collection<Privilege> privileges) {
        Role role = roleRepository.findByName(name);
        if (role == null) {
            role = new Role();
            role.setName(name);
            role.setPrivileges(privileges);
            roleRepository.save(role);
        }
        return role;
    }

    @Transactional
    void createUserIfNotFound(Role adminRole) {
      Optional<User> optional = userRepository.findByEmailOrPhoneOrName("admin");
      if (optional.isEmpty()) {
        User user = new User();
        user.setName("admin");
        user.setPhone("12312341234");
        user.setPassword(passwordEncoder.encode("rbfish123.."));
        user.setEmail("admin@admin.com");
        user.setRoles(List.of(adminRole));
        user.setEnabled(true);
        userRepository.save(user);
      }
    }
}
```

新建登录验证程序：

```java
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import javax.transaction.Transactional;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class MyUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    private final RoleRepository roleRepository;
  
    public MyUserDetailsService(UserRepository userRepository, RoleRepository roleRepository) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String text) throws UsernameNotFoundException {
        Optional<User> optional = userRepository.findByEmailOrPhoneOrName(text);
        if (optional.isEmpty()) {
            return new org.springframework.security.core.userdetails.User(
                  " ", " ", true, true, true,
                  true, getAuthorities(List.of(roleRepository.findByName("ROLE_USER"))));
        }
        User user = optional.get();
        return new org.springframework.security.core.userdetails.User(
                user.getEmail(), user.getPassword(), user.isEnabled(), true,
                true, true, getAuthorities(user.getRoles()));
    }

    private Collection<? extends GrantedAuthority> getAuthorities(Collection<Role> roles) {
        return getGrantedAuthorities(getPrivileges(roles));
    }

    private List<String> getPrivileges(Collection<Role> roles) {
        List<String> privileges = new ArrayList<>();
        List<Privilege> collection = new ArrayList<>();
        for (Role role : roles) {
            privileges.add(role.getName());
            collection.addAll(role.getPrivileges());
        }
        for (Privilege item : collection) {
            privileges.add(item.getName());
        }
        return privileges;
    }

    private List<GrantedAuthority> getGrantedAuthorities(List<String> privileges) {
        List<GrantedAuthority> authorities = new ArrayList<>();
        for (String privilege : privileges) {
            authorities.add(new SimpleGrantedAuthority(privilege));
        }
        return authorities;
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
    private User user;
}
```

新建登录控制器：

```java
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.interfaces.RSAPrivateKey;
import java.time.Instant;
import java.util.Date;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/login")
public class LoginController {

    @Value("${jwt.private.key}")
    RSAPrivateKey key;

    @Value("${jwt.expiry:36000}")
    Long expiry;

    private final AuthenticationManager authManager;
    private final UserRepository userRepository;

    public LoginController(AuthenticationManager authManager, UserRepository userRepository) {
        this.authManager = authManager;
        this.userRepository = userRepository;
    }

    @PostMapping
    public HttpEntity<LoginResponse> login(@RequestBody LoginRequest loginRequest) {
        LoginResponse loginResponse = new LoginResponse();
        UsernamePasswordAuthenticationToken authReq = new UsernamePasswordAuthenticationToken(loginRequest.getUsername(), loginRequest.getPassword());
        Authentication authentication = authManager.authenticate(authReq);
        SecurityContext sc = SecurityContextHolder.getContext();
        sc.setAuthentication(authentication);
        log.error(authentication.toString());
        Instant now = Instant.now();
        String scope = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(" "));
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .issuer("self")
                .issueTime(new Date(now.toEpochMilli()))
                .expirationTime(new Date(now.plusSeconds(expiry).toEpochMilli()))
                .subject(authentication.getName())
                .claim("scope", scope)
                .build();
        JWSHeader header = new JWSHeader.Builder(JWSAlgorithm.RS256).build();
        SignedJWT jwt = new SignedJWT(header, claims);
        loginResponse.setToken(sign(jwt).serialize());
        Optional<User> optional = userRepository.findByEmailOrPhoneOrName(loginRequest.getUsername());
        optional.ifPresent(loginResponse::setUser);
        return new HttpEntity<>(loginResponse);
    }

    SignedJWT sign(SignedJWT jwt) {
        try {
            jwt.sign(new RSASSASigner(this.key));
            return jwt;
        } catch (Exception ex) {
            throw new IllegalArgumentException(ex);
        }
    }
}

```

新建查看用户名控制器：

```java
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/hello")
public class HelloController {
    @GetMapping
    public String hello(Authentication authentication) {
        return "Hello, " + authentication.getName() + "!";
    }
}
```

### 使用方式

```bash
curl -XPOST -u test@test.com:test "http://localhost:8080/token"
```

```bash
curl --request GET 'http://localhost:8080/api/v1/hello' --header 'Authorization: Bearer <token>'
```

### 参考资料

[Spring Security 例程](https://github.com/spring-projects/spring-security-samples0)

[baeldung 教程](https://www.baeldung.com/security-spring)