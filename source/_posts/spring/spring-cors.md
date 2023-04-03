---
title: Spring CORS
date: 2023-03-27 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-cors
no_word_count: true
no_toc: false
categories: Spring
---

## Spring CORS

### 简介

解决跨域可以引入如下代码

### 配置

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.core.Ordered;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("*")
                .allowedHeaders("*")
                .exposedHeaders("Access-Control-Allow-Origin");
    }

    @Bean
    public FilterRegistrationBean<CorsFilter> corsFilterRegistrationBean() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        config.addAllowedOrigin("*");
        config.addAllowedMethod("*");
        config.addAllowedHeader("*");
        source.registerCorsConfiguration("/**", config);
        FilterRegistrationBean<CorsFilter> bean = new FilterRegistrationBean<>(new CorsFilter(source));
        bean.setOrder(Ordered.HIGHEST_PRECEDENCE);
        return bean;
    }
    
}
```

### 测试

使用如下命令即可：

```bash
curl -X 'GET' 'http://localhost:8080/test' -H 'accept: */*' -H 'origin:*' -v
```

若返回头中包含如下内容则证明配置成功：

```text
< Access-Control-Allow-Origin: *
```

> 注：在请求时必须加入 `origin` 头，否则不会返回 `Access-Control-Allow-Origin`
