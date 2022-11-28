---
title: Spring Validation
date: 2022-11-28 21:32:58
tags:
- "Java"
- "Spring Boot"
id: valid
no_word_count: true
no_toc: false
categories: Spring
---

## Spring Validation

### 简介

Spring 框架官方提供的参数检验方式，通过对 hibernate validation 的二次封装而实现的。

### 使用方式

引入依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

基本功能注解清单：

|      注解      |          简介           |
|:------------:|:---------------------:|
|    @Null     |      被注解的元索必须为空       |
|   @notNull   |      被注解的元素必须不为空      |
|     @Min     | 被注解的元素必须是数字且必须小于等于指定值 |
|     @Max     | 被注解的元素必须是数字且必须大于等于指定值 |
|    @Past     |   被注解的元索必须是一个过去的日期    |
|   @Future    |   被注解的元素必须是一个将来的日期    |
|   @Pattern   |  被注解的元素必须符合给定的正则表达式   |
| @AssertTure  |     被注解的元素必须为ture     |
| @AssertFalse |    被注解的元素必须为false     |

额外功能注解清单：

|    注解     |              简介               |
|:---------:|:-----------------------------:|
|  @Email   |       被注解的元素必须是email地址        |
|  @Length  |        被注解的元素必须在指定的范围内        |
| @NotEmpty |           被注解的元素是必须           |
|  @Range   | 被注解的元素可以是数字或者是数字的字符串必须在指定的范围内 |
|   @URL    |        被注解的元素必须是一个URL         |

样例代码：

```java
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.Hibernate;
import org.hibernate.validator.constraints.Length;

import javax.persistence.*;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Past;
import java.util.Date;
import java.util.Objects;

@Getter
@Setter
@ToString
@RequiredArgsConstructor
@Entity
@Table(name = "demo", schema = "demo")
public class Demo {

    @NotNull(groups = {Update.class})
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Id
    @Column
    private String code;

    @NotNull(groups = {Insert.class})
    @Length(min = 2, max = 10)
    @Column
    private String name;

    @NotBlank(message = "手机号码不能为空", groups = {Insert.class})
    @NotNull(message = "手机号不能为空", groups = {Insert.class})
    @Length(min = 11, max = 11, message = "手机号只能为11位")
    @Column
    private String phone;

    @Email
    @Column
    private String email;

    @Past(groups = {Insert.class})
    @NotNull
    @Column
    private Date birth;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || Hibernate.getClass(this) != Hibernate.getClass(o)) return false;
        Demo demo = (Demo) o;
        return code != null && Objects.equals(code, demo.code);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }

    public interface Insert {
    }

    /**
     * 更新的时候校验分组
     */
    public interface Update {
    }

}
```

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/demo")
public class DemoController {

    @PutMapping
    public DemoUser insert(@RequestBody @Validated(DemoUser.Insert.class) DemoUser demoUser) {
        return demoUser;
    }

    @PostMapping
    public DemoUser update(@RequestBody @Validated(DemoUser.Update.class) DemoUser demoUser) {
        return demoUser;
    }

}
```

### 参考资料

[官方文档](https://spring.io/guides/gs/validating-form-input/)

[hibernate validation 验证注解](https://docs.jboss.org/hibernate/validator/8.0/reference/en-US/html_single/#section-builtin-constraints)

[SpringBoot 实现各种参数校验](https://juejin.cn/post/7080419992386142215)

[Differences in @Valid and @Validated Annotations in Spring](https://www.baeldung.com/spring-valid-vs-validated)