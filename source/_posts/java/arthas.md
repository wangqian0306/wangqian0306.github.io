---
title: Arthas
date: 2023-07-24 21:05:12
tags:
- "JAVA"
- "Arthas"
id: arthas
no_word_count: true
no_toc: false
categories: JAVA
---

## Arthas

### 简介

Arthas 是 Alibaba 开源的 Java 诊断工具，可以用来诊断 Java 应用的各种问题，比如内存泄漏、方法耗时、热部署、线程堆栈、监控方法调用、监控 Spring Bean 等等。

### 安装

访问 [官方项目发行版](https://github.com/alibaba/arthas/releases) 页面即可找到最新版软件的压缩包，下载并解压即可。

> 注: 解压后的软件即可直接使用 `java -jar arthas-boot.jar` 启动 arthas。

然后运行下面的命令即可完成安装:

```bash
./insta[gradle](gradle)ll-local.sh
```

使用如下命令即可启动 arthas:

```bash
./as.sh
```

### 基本使用

首先需要选择监听的 Java 进程，然后就可以根据需求进行监测了

从大类上来说基本指令有以下几种:

- jvm 相关
  - dashboard - 当前系统的实时数据面板
  - getstatic - 查看类的静态属性
  - heapdump - dump java heap, 类似 jmap 命令的 heap dump 功能
  - jvm - 查看当前 JVM 的信息
  - logger - 查看和修改 logger
  - mbean - 查看 Mbean 的信息
  - memory - 查看 JVM 的内存信息
  - ognl - 执行 ognl 表达式
  - perfcounter - 查看当前 JVM 的 Perf Counter 信息
  - sysenv - 查看 JVM 的环境变量
  - sysprop - 查看和修改 JVM 的系统属性
  - thread - 查看当前 JVM 的线程堆栈信息
  - vmoption - 查看和修改 JVM 里诊断相关的 option
  - vmtool - 从 jvm 里查询对象，执行 forceGc
- class/classloader 相关
  - classloader - 查看 classloader 的继承树，urls，类加载信息，使用 classloader 去 getResource
  - dump - dump 已加载类的 byte code 到特定目录
  - jad - 反编译指定已加载类的源码
  - mc - 内存编译器，内存编译.java文件为.class文件
  - redefine - 加载外部的.class文件，redefine 到 JVM 里
  - retransform - 加载外部的.class文件，retransform 到 JVM 里
  - sc - 查看 JVM 已加载的类信息
  - sm - 查看已加载类的方法信息
- monitor/watch/trace 相关
  - monitor - 方法执行监控
  - stack - 输出当前方法被调用的调用路径
  - trace - 方法内部调用路径，并输出方法路径上的每个节点上耗时
  - tt - 方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测
  - watch - 方法执行数据观测
- profiler/火焰图
  - profiler - 使用async-profiler对应用采样，生成火焰图
  - jfr - 动态开启关闭 JFR 记录

目前常用的命令如下

#### dashboard

可以使用 dashboard 命令查看服务线程，内存，JVM 相关信息。

#### jad

可以使用 jad 命令反编译源码

```bash
jad <package>.<class>
```

#### watch 

可以使用 watch 命令监测程序返回值(returnObj)，抛出异常(target)和入参(params)

```bash
watch <package>.<class> <function> returnObj -x 4
```

#### trace

可以使用 trace 命令检索方法调用路径，统计调用链路上的性能开销

```bash
trace <package>.<class> <function>
```

#### stack

可以使用 stack 命令输出当前方法被调用的调用路径

```bash
stack <package>.<class> <function>
```

#### tt

可以使用 tt 命令记录下当时方法调用的所有入参和返回值、抛出的异常

- 开始记录

```bash
tt -t <package>.<class> <function>
```

- 查看当前记录清单

```bash
tt -l
```

- 根据 ID 获取记录内容

```bash
tt -i <index>
```

- 重新调用进行测试

```bash
tt -i <index> -p
```

#### profiler

profiler 命令支持生成应用热点的火焰图

- 启动 profiler 开启数据收集

```bash
profiler start
```

- 获取当前已采集的样本数量

```bash
profiler getSamples
```

- 生成结果

```bash
profiler stop --format html
```

> 注：profiler 只支持 Linux 和 Mac 系统。

### web 控制台

在链接到 java 进程之后就可以访问 [http://127.0.0.1:8563/](http://127.0.0.1:8563/) 进入控制台。

> 注：默认监听地址为 127.0.0.1 不建议修改可能有安全风险，如果想要使用可以指定 `--target-ip` 参数指定监听地址。


### 参考资料

[官方项目](https://github.com/alibaba/arthas)

[官方文档](https://arthas.aliyun.com/doc/quick-start.html)
