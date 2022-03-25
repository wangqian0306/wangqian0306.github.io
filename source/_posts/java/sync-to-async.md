---
title: 异步与同步的转化
date: 2022-03-22 21:05:12
tags:
- "JAVA"
id: sync-and-async
no_word_count: true
no_toc: false
categories: JAVA
---

## 异步与同步的转化

### 简介

在实际的项目开发中经常会用到异步与同步的调用方式。这两种调用方式的区别如下：

- 同步调用：调用方在调用过程中，持续等待返回结果。
- 异步调用：调用方在调用过程中，不直接等待返回结果，而是执行其他任务，结果返回形式通常为回调函数。

本文会针对需要转化这两种请求方式的特殊需求进行初步分析。

### 异步转同步

在进行异步转同步调用的时候通常有如下方式

- wait 和 notify
- 条件锁
- Future 包
- CountDownLatch
- CyclicBarrier

#### 前置条件

- 新建异步调用类

```java
import java.util.Random;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class AsyncCall {

    private final Random random = new Random(System.currentTimeMillis());

    private final ExecutorService tp = Executors.newSingleThreadExecutor();

    // wait 和 notify
    // 条件锁
    // CountDownLatch
    // CyclicBarrier
    public void call(final BaseDemo demo) {
        new Thread(new Runnable() {
            public void run() {
                long res = random.nextInt(10);
                try {
                    Thread.sleep(res * 1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                demo.callback(res);
            }
        }).start();
    }

    // Future 包
    public Future<Long> futureCall() {
        return tp.submit(new Callable<Long>() {
            public Long call() throws Exception {
                long res = random.nextInt(10);
                try {
                    Thread.sleep(res * 1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                return res;
            }
        });
    }

    public void shutdown() {
        tp.shutdown();
    }

}
```

- 新建调用抽象类

```java
public abstract class BaseDemo {

    protected AsyncCall asyncCall = new AsyncCall();

    public abstract void callback(Long response);

    public void call() {
        System.out.println("发起调用");
        asyncCall.call(this);
        System.out.println("结束调用");
    }

}
```

#### wait 和 notify

```java
public class WaitNotifyDemo extends BaseDemo {

    private final Object lock = new Object();

    public void callback(Long response) {
        System.out.println("响应回调");
        System.out.println("返回等待时长: " + response);
        System.out.println("回调结束");
        synchronized (lock) {
            lock.notifyAll();
        }
    }

    public static void main(String[] args) {
        WaitNotifyDemo demo = new WaitNotifyDemo();
        demo.call();
        synchronized (demo.lock) {
            try {
                demo.lock.wait();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        System.out.println("主线程结束");
    }
}
```

#### 条件锁

```java
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

// 条件锁版样例代码
public class ConditionVariableDemo extends BaseDemo {

    private final Lock lock = new ReentrantLock();
    private final Condition con = lock.newCondition();

    @Override
    public void callback(Long response) {
        System.out.println("响应回调");
        System.out.println("返回等待时长: " + response);
        lock.lock();
        try {
            con.signal();
        } finally {
            lock.unlock();
        }
        System.out.println("回调结束");
    }

    public static void main(String[] args) {
        ConditionVariableDemo demo = new ConditionVariableDemo();
        demo.call();
        demo.lock.lock();
        try {
            demo.con.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } finally {
            demo.lock.unlock();
        }
        System.out.println("主线程结束");
    }

}
```

#### Future 包

```java
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

// Future 包版样例代码
public class FutureDemo {

    private static final AsyncCall asyncCall = new AsyncCall();

    public Future<Long> call() {
        Future<Long> future = asyncCall.futureCall();
        asyncCall.shutdown();
        return future;
    }

    public static void main(String[] args) {
        FutureDemo demo = new FutureDemo();
        System.out.println("发起调用");
        Future<Long> future = demo.call();
        System.out.println("结束调用");
        try {
            System.out.println("返回等待时长: " + future.get());
        } catch (InterruptedException | ExecutionException e) {
            e.printStackTrace();
        }
        System.out.println("主线程结束");
    }

}
```

#### CountDownLatch

```java
// CountDownLaunch 版样例代码
public class CountDownLaunchDemo extends BaseDemo {

    private final CountDownLatch countDownLatch = new CountDownLatch(1);

    @Override
    public void callback(Long response) {
        System.out.println("响应回调");
        System.out.println("返回等待时长: " + response);
        System.out.println("调用结束");
        countDownLatch.countDown();
    }

    public static void main(String[] args) {
        CountDownLaunchDemo demo = new CountDownLaunchDemo();
        demo.call();
        try {
            demo.countDownLatch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("主线程内容");
    }

}
```

#### CyclicBarrier

```java
import java.util.concurrent.BrokenBarrierException;
import java.util.concurrent.CyclicBarrier;

// CyclicBarrier 版样例代码
public class CyclicBarrierDemo extends BaseDemo {

    private final CyclicBarrier cyclicBarrier = new CyclicBarrier(2);

    @Override
    public void callback(Long response) {
        System.out.println("响应回调");
        System.out.println("返回等待时长: " + response);
        System.out.println("回调结束");

        try {
            cyclicBarrier.await();
        } catch (InterruptedException | BrokenBarrierException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        CyclicBarrierDemo demo = new CyclicBarrierDemo();
        demo.call();
        try {
            demo.cyclicBarrier.await();
        } catch (InterruptedException | BrokenBarrierException e) {
            e.printStackTrace();
        }
        System.out.println("主线程内容");
    }

}
```

### 同步转异步

使用多线程即可，具体使用方式参见线程池部分。

### 参考资料

[异步调用转同步](https://gitee.com/sunnymore/asyncToSync)
