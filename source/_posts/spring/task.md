---
title: Spring 定时任务
date: 2022-06-22 21:32:58
tags:
- "Java"
- "Spring Boot"
id: task
no_word_count: true
no_toc: false
categories: Spring
---

## Spring 定时任务

### 简介

Spring 对于定时任务的支持有以下方式：

- 可以使用 `spring-boot-starter-quartz` 快速对接 Quartz
- 自带的 `@Scheduled` 注解配置调度任务

### `@Secheduled` 注解

使用 `@Secheduled` 注解应当遵循下面的两个简单的规则：

- 该方法的返回类型为 `void` (如果有返回值则将被忽略)
- 该方法应当没有任何入参

在使用时需要在入口类中启用调度器

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class TestApplication {

    public static void main(String[] args) {
        SpringApplication.run(Test.class, args);
    }

}
```

在需要定时运行的方法上可以使用如下注解：

```java
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class Test {

    // 此方法为固定延时，以任务运行结束的时间点为间隔
    @Scheduled(fixedDelayString = "${fixedDelay.in.milliseconds}")
    void runByDelay() {
        System.out.println("runByDelay At：" + System.currentTimeMillis());
    }

    // 此方法为固定延时，以任务运行的开始时间为间隔
    @Scheduled(fixedRateString = "${fixedRate.in.milliseconds}")
    void runByRate() {
        System.out.println("runByRate At：" + System.currentTimeMillis());
    }

    // 此方法以 cron 表达式作为运行条件
    @Scheduled(cron = "${cron.expression}")
    void runByCorn() {
        System.out.println("runByCorn At：" + System.currentTimeMillis());
    }

}
```

> 注: 如果任务需要异步执行，则需要引入 `@Async` 注解。

如果有多个任务可能涉及到同时运行还需要在配置文件中写入线程池设置：

```properties
spring.task.scheduling.pool.size=5
```

### Quartz

首先需要引入下面的依赖包：

Maven

```xml

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-quartz</artifactId>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <scope>runtime</scope>
    </dependency>
</dependencies>
```

Gradle

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-quartz'
    runtimeOnly 'mysql:mysql-connector-java'
}
```

> 注: Quartz 需要依赖于存储后端

编写配置项如下：

Yaml

```yaml
spring:
  datasource:
    driver-class-name: ${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
    url: ${MYSQL_URI:jdbc:mysql://xxx.xxx.xxx.xxx:xxxx/xxxx}
    username: ${MYSQL_USERNAME:xxxx}
    password: ${MYSQL_PASSWORD:xxxx}
  quartz:
    job-store-type: jdbc
    jdbc:
      initialize-schema: always
```

Properties

```properties
spring.datasource.driver-class-name=${JDBC_DRIVER:com.mysql.cj.jdbc.Driver}
spring.datasource.url=${MYSQL_URI:jdbc:mysql://xxx.xxx.xxx.xxx:xxxx/xxxx}
spring.datasource.username=${MYSQL_USERNAME:xxxx}
spring.datasource.password=${MYSQL_PASSWORD:xxxx}
spring.quartz.job-store-type=${QUARTZ_STORE_TYPE:jdbc}
spring.quartz.jdbc.initialize-schema=${QUARTZ_INIT_SCHEMA:always}
```

编写定时任务如下：

```java
import lombok.extern.slf4j.Slf4j;
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.springframework.scheduling.quartz.QuartzJobBean;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class SampleJob extends QuartzJobBean {

    @Override
    protected void executeInternal(JobExecutionContext context) throws JobExecutionException {
        log.info(context.toString());
        log.error("execute :" + System.currentTimeMillis());
    }

}
```

编写定时任务配置如下：

```java
import org.quartz.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class QuartzConf {

    @Bean
    public JobDetail jobDetail() {
        return JobBuilder.newJob().ofType(SampleJob.class)
                .storeDurably()
                .withIdentity("Qrtz_Job_Detail")
                .withDescription("Invoke Sample Job service...")
                .build();
    }

    @Bean
    public Trigger trigger(JobDetail job) {
        return TriggerBuilder.newTrigger().forJob(job)
                .withIdentity("Qrtz_Trigger")
                .withDescription("Sample trigger")
                .withSchedule(CronScheduleBuilder.cronSchedule("0/10 * * * * ? "))
                .build();
    }

}
```

如需动态编辑任务，则可以依照如下代码：

```java
import org.quartz.*;
import org.springframework.http.HttpEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.annotation.Resource;

@RestController
@RequestMapping("/quartz")
public class DemoController {

    @Resource
    Scheduler scheduler;

    @GetMapping
    public HttpEntity<String> get() throws SchedulerException {
        JobDetail job = JobBuilder.newJob().ofType(SampleJob.class)
                .storeDurably()
                .withIdentity("Qrtz_Job_Detail")
                .withDescription("Invoke Sample Job service...")
                .build();
        Trigger trigger = TriggerBuilder.newTrigger().forJob(job)
                .withIdentity("Qrtz_Trigger")
                .withDescription("Sample trigger")
                .withSchedule(CronScheduleBuilder.cronSchedule("0/10 * * * * ? "))
                .build();
        scheduler.scheduleJob(job, trigger);
        scheduler.start();
        return new HttpEntity<>("success");
    }

}
```

### 参考资料

[Quartz 官网](https://www.quartz-scheduler.org/)

[Quartz Scheduler](https://docs.spring.io/spring-boot/docs/current/reference/html/io.html)

[Spring 中的 @Scheduled 注解](https://www.baeldung.com/spring-scheduled-tasks)

[Spring 定时任务参考代码](https://github.com/eugenp/tutorials/tree/master/spring-scheduling)

[Spring Quartz 参考代码](https://github.com/eugenp/tutorials/tree/master/spring-quartz)

[Spring 定时任务多线程配置](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.task-execution-and-scheduling)