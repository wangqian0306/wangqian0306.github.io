---
title: JAVA 当中的零拷贝技术
date: 2021-07-22 21:39:12
tags: "JAVA"
id: zero_copy
no_word_count: true
no_toc: false
categories: JAVA
---

## JAVA 当中的零拷贝技术

### 简介

在 Kafka 中使用 Linux 操作系统的 `sendFile()` 方法利用零拷贝技术来优化了程序性能，所以此处对这个知识点进行整理。

### 原理

零拷贝(Zero-copy) 技术是指计算机执行操作时，CPU 不需要先将数据从某处内存复制到另一个特定区域。 这种技术通常用于通过网络传输文件时节省 CPU 周期和内存带宽。

例如在文件复制的业务场景中，程序的执行逻辑如下图所示：

![图 1: 复制文件流程](https://i.loli.net/2021/07/22/pDS4Q7wcbljoxir.png)

1. 读取文件至内核缓冲区中。
2. 将内核缓冲区的数据复制到程序中。
3. 将程序缓冲的内容复制入写入缓存中。
4. 将写入缓存写入磁盘。

数据流经过了总共 4 个步骤。而使用零拷贝技术的流程如下：

1. 读取文件至内核缓冲区中。
2. 使用描述符将内核缓冲区中的读入缓存指定到写入缓存中
3. 将内核缓冲区中的写入缓存数据写入文件。

### 实现方式

复制文件的样例如下，可以使用 `FileChannel` 类的 `transferTo()` 和 `transferFrom()` 方法实现零拷贝：

```java
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;

public class Test {
    public static void transferToDemo(String from, String to) throws IOException {
        FileChannel fromChannel = new RandomAccessFile(from, "rw").getChannel();
        FileChannel toChannel = new RandomAccessFile(to, "rw").getChannel();
        long position = 0;
        long count = fromChannel.size();
        fromChannel.transferTo(position, count, toChannel);
        fromChannel.close();
        toChannel.close();
    }
}
```
