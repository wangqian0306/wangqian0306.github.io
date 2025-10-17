---
title: Spring Boot Graceful Shutdown
date: 2025-10-17 21:32:58
tags:
- "Java"
- "Spring Boot"
id: graceful-shutdown
no_word_count: true
no_toc: false
categories:
- "Spring"
---

## Spring Boot Graceful Shutdown

### 简介

Spring Boot Graceful Shutdown 是 Spring Boot 官方提供的一种优雅关闭 Spring Boot 应用的方式。

在自定义复杂逻辑的时候需要涉及到终止线程，比如数据库连接、定时任务等等时最好手动关闭自定义逻辑，避免数据异常。

### 实现方式

粗略分为以下四种，需要结合实际情况，选用合适的方式。

|                   机制                    |          触发时机          |      执行顺序       | 是否能控制启动/停止顺序 |       是否能异步        |          	常见用途           |
|:---------------------------------------:|:----------------------:|:---------------:|:------------:|:------------------:|:------------------------:|
|               @PreDestroy               |    Bean 销毁前（容器关闭时）     | 固定（按 Bean 依赖顺序） |     ❌ 否      |        ❌ 否         |          简单清理资源          |
|        DisposableBean.destroy()         |        Bean 销毁前        |    固定（按依赖顺序）    |     ❌ 否      |        ❌ 否         |   与 @PreDestroy 类似但更可控   |
| ApplicationListener<ContextClosedEvent> | Spring Context 关闭事件触发时 |    可手动控制执行逻辑    |   ⚙️ 可内部控制   |     	✅ 可以异步执行      |      多 Bean 统一关闭逻辑       |
|             SmartLifecycle              | Spring Context 启动/关闭阶段 | ✅ 按 phase 控制顺序  |    ✅ 完全可控    | ✅ 可异步（通过 callback） | 复杂系统组件（Quartz、线程池、消息消费者） |

#### PreDestroy

```java
@Component
public class TaskExecutorHolder {

    private final ExecutorService executor = Executors.newFixedThreadPool(8);

    public void execute(Runnable task) {
        executor.submit(task);
    }

    @PreDestroy
    public void shutdown() {
        System.out.println("Gracefully shutting down executor...");
        executor.shutdown();
    }
}
```

#### DisposableBean

```java
import org.springframework.beans.factory.DisposableBean;
import org.springframework.stereotype.Component;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Component
public class MyThreadPoolManager implements DisposableBean {

    private final ExecutorService executorService = Executors.newFixedThreadPool(10);

    public void submitTask(Runnable task) {
        executorService.submit(task);
    }

    @Override
    public void destroy() {
        System.out.println("Shutting down thread pool...");
        executorService.shutdown(); // 停止接收新任务，等待已提交任务执行完
        try {
            if (!executorService.awaitTermination(10, java.util.concurrent.TimeUnit.SECONDS)) {
                System.out.println("Forcing shutdown...");
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
        System.out.println("Thread pool shut down completed.");
    }
}
```

#### ApplicationListener<ContextClosedEvent>

```java
@Component
public class AppCloseListener implements ApplicationListener<ContextClosedEvent> {
    @Override
    public void onApplicationEvent(ContextClosedEvent event) {
        System.out.println("🧹 ContextClosedEvent: Application is shutting down...");
        // 可以关闭线程池、停止服务、通知外部系统等
    }
}
```

#### SmartLifecycle

```java
import org.springframework.context.SmartLifecycle;
import org.springframework.stereotype.Component;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

@Component
public class CustomLifecycleManager implements SmartLifecycle {

    private final ExecutorService executorService = Executors.newFixedThreadPool(10);
    private volatile boolean running = false;

    // 定义该组件的生命周期顺序，数值越小越早启动，越晚停止
    @Override
    public int getPhase() {
        return Integer.MAX_VALUE; // 希望最后停止，确保其他组件先关闭
    }

    @Override
    public void start() {
        running = true;
        System.out.println("CustomLifecycleManager is started...");
    }

    @Override
    public void stop() {
        running = false;
        System.out.println("CustomLifecycleManager is stopped...");
        executorService.shutdown();
        try {
            if (!executorService.awaitTermination(10, TimeUnit.SECONDS)) {
                System.out.println("CustomLifecycleManager is timeout...");
                executorService.shutdownNow();
            }
        } catch (InterruptedException e) {
            executorService.shutdownNow();
        }
        System.out.println("CustomLifecycleManager is stopped...");
    }

    @Override
    public boolean isRunning() {
        return running;
    }
}
```

> 注：此处实现的是 Lifecycle 的 stop 方法，而不是 SmartLifecycle 的 stop 方法

### 参考资料

[Graceful Shutdown](https://docs.spring.io/spring-boot/reference/web/graceful-shutdown.html)

[spring-如果优雅关闭java应用](https://www.bilibili.com/video/BV1gEZUYMEJg)
