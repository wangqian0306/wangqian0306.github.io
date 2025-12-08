---
title: Spring AOP
date: 2024-12-04 21:32:58
tags:
- "Java"
- "Spring Boot"
id: spring-aop
no_word_count: true
no_toc: false
categories: 
- "Spring"
---

## Spring AOP

### 简介

面向方面编程(Aspect-oriented Programming,AOP)通过提供另一种思考程序结构的方式来补充面向对象编程 (Object-oriented Programming, OOP)。在 OOP 中，模块化的关键单元是类，而在 AOP 中，模块化的单元是切面。切面可以支持跨多个类型和对象的关注点进行通用的处理。

在 Spring 中，

### 概念和使用场景

在切面编程的时候有很多的专业名词，但是从使用上讲可以简单归类为以下几处：

1. 切面(Aspect)
2. 连接点(Join Point)
3. 通知(Advice)
4. 切入点(Pointcut)
5. 织入(Weaving)

> 注：此处内容简略，详细内容请参照官方文档。

在编码时可以简单的只考虑：

1. 切面
2. 切入点

#### Advice 类型和使用场景

切面编写时，首先需要明确要执行的业务逻辑，也就是通知(Advice)：

| Advice 类型              | 描述                      | 使用场景                    |
|------------------------|-------------------------|-------------------------|
| Before Advice          | 	在目标方法执行之前执行            | 	权限校验、日志记录、参数验证等        |
| After Advice           | 	在目标方法执行后（无论是否成功）执行     | 	清理资源、释放锁、后置操作等         |
| After Returning Advice | 	在目标方法正常返回后执行           | 	结果日志记录、统计等             |
| After Throwing Advice  | 	在目标方法抛出异常后执行           | 	异常日志记录、异常处理等           |
| Around Advice          | 	在目标方法执行前后都能执行，完全控制目标方法 | 	性能监控、事务管理、缓存处理、全局异常处理等 |

在选择 Advice 类型时可以使用如下的思路：

- 如果你只关心方法执行前后发生的事情，可以使用 Before 和 After。
- 如果你只关心方法的返回值或异常，使用 After Returning 或 After Throwing。
- 如果你需要对方法的执行过程进行全面控制，使用 Around Advice，它能在方法执行前后插入代码，并能改变方法的返回值或决定是否执行目标方法。

#### Pointcut Designator

业务逻辑编写完成后即可选择切点，也就是确认切面要执行的位置。可以将其指定为方法，类，注解等：

| Pointcut Designator | 	描述               | 	使用场景             |
|---------------------|-------------------|-------------------|
| execution()         | 	匹配方法执行时的连接点      | 	通常用于方法调用的切点，最常用  |
| within()            | 	匹配指定类或包中的方法      | 	用于限定类或包范围的切点     |
| this()              | 	匹配目标方法所在代理对象的类型  | 	适用于代理对象的类型匹配     |
| target()            | 	匹配目标方法所在目标对象的类型  | 	适用于目标对象类型的匹配     |
| args()              | 	匹配方法参数类型         | 	用于方法参数类型匹配       |
| @args()             | 	匹配方法参数上标注的注解类型   | 	用于基于方法参数的注解类型匹配  |
| @annotation()       | 	匹配标注了特定注解的方法     | 	用于基于注解的方法切点      |
| @within()           | 	匹配类或方法上标注特定注解的类  | 	用于类上注解的匹配        |
| @target()           | 	匹配目标对象上标注特定注解的方法 | 	用于目标对象本身带注解的方法匹配 |

### 示例

编写 `Convert.java` ：
```java
public interface Convert<PARAM> {

    OperateLog convert(PARAM param);

}
```

编写 `SaveOrder.java` ：

```java

public record SaveOrder (
        Long id
) {
}
```

编写 `UpdateOrder.java` ：

```java
public record UpdateOrder(
        Long orderId
) {
}
```

编写 `OperateLog.java` ：

```java
import lombok.Data;

@Data
public class OperateLog {

    private Long orderId;

    private String desc;

    private String result;

}
```

编写 `SaveLogConvert.java` ：

```java
public class SaveLogConvert implements Convert<SaveOrder> {
    @Override
    public OperateLog convert(SaveOrder saveOrder) {
        OperateLog operateLog = new OperateLog();
        operateLog.setOrderId(saveOrder.id());
        return operateLog;
    }
}
```

编写 `UpdateLogConvert.java` ：

```java
public class UpdateLogConvert implements Convert<UpdateOrder> {
    @Override
    public OperateLog convert(UpdateOrder updateOrder) {
        OperateLog operateLog = new OperateLog();
        operateLog.setOrderId(updateOrder.orderId());
        return operateLog;
    }
}
```

编写 `RecordOperate.java` ：

```java
import java.lang.annotation.*;

@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface RecordOperate {

    String desc() default "";

    Class<? extends Convert> convert();

}
```

编写 `OrderService.java` ：

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class OrderService {

    @RecordOperate(desc = "保存订单", convert = SaveLogConvert.class)
    public Boolean saveOrder(SaveOrder saveOrder) {
        log.info("saveOrder: {}", saveOrder);
        return true;
    }

    @RecordOperate(desc = "更新订单", convert = UpdateLogConvert.class)
    public Boolean updateOrder(UpdateOrder updateOrder) {
        log.info("updateOrder: {}", updateOrder);
        return true;
    }

}
```

编写 `StartUpRunner.java` ：

```java
import jakarta.annotation.Resource;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class StartUpRunner implements CommandLineRunner {

    @Resource
    private OrderService orderService;

    @Override
    public void run(String... args) throws Exception {
        orderService.saveOrder(new SaveOrder(123L));
        orderService.updateOrder(new UpdateOrder(123L));
    }

}
```

在入口添加如下注解：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@EnableAspectJAutoProxy
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
```

运行程序即可获得 AOP 产生的日志。

### 参考资料

[官方文档](https://docs.spring.io/spring-framework/reference/core/aop.html)

[【Java高级】你真的会切面编程么？技术专家实战演示！全是细节！](https://www.bilibili.com/video/BV1oD4y1W7Lh)

[【IT老齐140】非常实用！Spring AOP与自定义注解实现共性需求](https://www.bilibili.com/video/BV1VS4y127Lo)

[如何优雅地记录操作日志？](https://mp.weixin.qq.com/s/JC51S_bI02npm4CE5NEEow)
