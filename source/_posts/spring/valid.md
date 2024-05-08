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

|        注解        |         简介          |
|:----------------:|:-------------------:|
|      @Null       |      验证元素必须为空       |
|     @NotNull     |      验证元素必须不为空      |
|    @NotBlank     |  验证元素必须不为空且至少有一个字符  |
|     @NotNull     |      验证元素必须不为空      |
|    @NotEmpty     |  验证元素必须不为空且至少有一个元素  |
|       @Min       | 验证元素必须是数字且必须小于等于指定值 |
|       @Max       | 验证元素必须是数字且必须大于等于指定值 |
|      @Past       |  被注解的元索必须是一个过去的时间   |
|  @PastOrPresent  | 被注解的元索必须是一个过去或当前的时间 |
|     @Future      |   验证元素必须是一个将来的时间    |
| @FutureOrPresent |  验证元素必须是一个将来或当前的时间  |
|     @Pattern     |  验证元素必须符合给定的正则表达式   |
|   @AssertTure    |     验证元素必须为ture     |
|   @AssertFalse   |    验证元素必须为false     |
|   @DecimalMax    |     验证小数元素最大数值      |
|   @DecimalMin    |     验证小数元素最小数值      |
|     @Digits      |     验证元素整数和小数位数     |
|    @Negative     |      验证元素必须是负数      |
| @NegativeOrZero  |    验证元素必须是负数或 0     |
|    @Positive     |      验证元素必须是正数      |
| @PositiveOrZero  |    验证元素必须是正数或 0     |
|      @Email      |   验证元素必须是email地址    |

额外功能注解清单：

|        注解         |             简介              |
|:-----------------:|:---------------------------:|
|      @Length      |        验证元素必须在指定的范围内        |
|     @NotEmpty     |           验证元素是必须           |
|      @Range       | 验证元素可以是数字或者是数字的字符串必须在指定的范围内 |
|       @URL        |        验证元素必须是一个URL         |
| @CreditCardNumber |      验证元素必须是一个合规的信用卡号       |
|   @DurationMax    |          验证元素最大的周期          |
|   @DurationMin    |          验证元素最小的周期          |
|       @EAN        |        验证元素为 EAN 条形码        |
|       @ISBN       |        验证元素为 ISBN 书号        |
|  @UniqueElements  |         验证元素是否是唯一的          |
|       @UUID       |         验证元素为 UUID          |

样例代码：

```java
import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

@Data
public class DemoRole {

    @NotNull
    @NotBlank
    private String role;

}
```

```java
import lombok.Data;
import org.hibernate.validator.constraints.Length;

import javax.validation.Valid;
import javax.validation.constraints.*;
import java.util.Date;
import java.util.List;

@Data
public class DemoUser {

    @NotNull(groups = {Update.class})
    private String code;

    @NotNull(groups = {Insert.class})
    @Length(min = 2, max = 10)
    private String name;

    @NotBlank(message = "手机号码不能为空", groups = {Insert.class})
    @NotNull(message = "手机号不能为空", groups = {Insert.class})
    @Length(min = 11, max = 11, message = "手机号只能为11位")
    private String phone;

    @Email(groups = {Insert.class})
    private String email;

    @Past(groups = {Insert.class})
    @NotNull(groups = {Insert.class})
    private Date birth;

    @Valid
    @Size(min = 1, groups = {Insert.class})
    @NotNull(groups = {Insert.class})
    private List<DemoRole> roleList;

    public interface Insert {
    }

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

自定义校验注解：

```java
import javax.validation.Constraint;
import java.lang.annotation.Documented;
import java.lang.annotation.Retention;
import java.lang.annotation.Target;
import javax.validation.Payload;

import static java.lang.annotation.ElementType.*;
import static java.lang.annotation.RetentionPolicy.RUNTIME;

@Target({METHOD,FIELD,ANNOTATION_TYPE,CONSTRUCTOR,PARAMETER})
@Retention(RUNTIME)
@Documented
@Constraint(validatedBy={CustomIdValidator.class})
public @interface CustomId {

    String message() default "CustomId not valid";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

}
```

```java
import javax.validation.ConstraintValidator;
import javax.validation.ConstraintValidatorContext;

public class CustomIdValidator implements ConstraintValidator<CustomId, String> {

    @Override
    public void initialize(CustomId constraintAnnotation) {
        ConstraintValidator.super.initialize(constraintAnnotation);
    }

    @Override
    public boolean isValid(String value, ConstraintValidatorContext context) {
        // valid function
        return false;
    }

}
```

在 Controller 中校验：

```java
import com.example.demo.request.DemoUser;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.annotation.Resource;
import javax.validation.ConstraintViolation;
import javax.validation.ConstraintViolationException;
import javax.validation.Validator;
import java.util.Set;

@Slf4j
@RestController
@RequestMapping("/demo")
public class DemoController {

    @Resource
    private Validator validator;

    @PutMapping
    public DemoUser update(@RequestBody DemoUser demoUser) {
        Set<ConstraintViolation<DemoUser>> validate = validator.validate(demoUser, DemoUser.Insert.class);
        if (validate.isEmpty()) {
            // argument is valid
            return demoUser;
        } else {
            throw new ConstraintViolationException(validate);
        }
    }
}
```

> 注：此种方式不太适合原版异常的抛出形式。

### 参考资料

[官方文档](https://spring.io/guides/gs/validating-form-input/)

[hibernate validation 验证注解](https://docs.jboss.org/hibernate/validator/8.0/reference/en-US/html_single/#section-builtin-constraints)

[SpringBoot 实现各种参数校验](https://juejin.cn/post/7080419992386142215)

[Differences in @Valid and @Validated Annotations in Spring](https://www.baeldung.com/spring-valid-vs-validated)