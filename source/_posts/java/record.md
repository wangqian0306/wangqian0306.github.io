---
title: record
date: 2022-06-27 21:32:58
tags:
- "Java"
id: record
no_word_count: true
no_toc: false
categories: JAVA
---

## Record 

### 简介

在 Java 16 中有一个新的 record 关键字用于生成 record 类。

### 简单使用

```java
public final class Range {
    private final int start;
    private final int end;

    public Range(int start, int end) {
        // 参数检查
        this.start = start;
        this.end = end;
    }

    public int start() {
        return start;
    }

    public int end() {
        return end;
    }

    @Override
    public boolean equals(Object obj) {
        if (obj == this) {
            return true;
        }
        if (obj == null || obj.getClass() != this.getClass()) {
            return false;
        }
        var that = (Range) obj;
        return this.start == that.start &&
                this.end == that.end;
    }

    @Override
    public int hashCode() {
        return Objects.hash(start, end);
    }

    @Override
    public String toString() {
        return "Range[" +
                "start=" + start + ", " +
                "end=" + end + ']';
    }

}
```

等同于

```java
public record Range(int start, int end) {
    public Range{
        // 参数检查
    }
}```