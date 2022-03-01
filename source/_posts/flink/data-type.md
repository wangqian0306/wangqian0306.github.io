---
title: Flink 数据类型和序列化
date: 2022-02-28 22:26:13
tags:
- "Flink"
id: flink_data_type
no_word_count: true
no_toc: false
categories: Flink
---

## Flink 数据类型和序列化

### 简介

Flink 处于对执行性能的考量对可以在 DataStream 中的元素类型进行了一些限制。目前支持的类型如下：

1. Java Tuples and Scala Case Classes
2. Java POJOs
3. Primitive Types 原始数据类型及包装类
4. Regular Classes 即大多数的 Java 和 Scala 类，限制适用于包含无法序列化的字段的类，这样的类通常使用序列化框架 Kryo 进行序列化/反序列化。
5. Values 即 ByteValue, ShortValue, IntValue, LongValue, FloatValue, DoubleValue, StringValue, CharValue, BooleanValue
6. Hadoop Writables 实现了 org.apache.hadoop.Writable 接口的类
7. Special Types Scala 中的 Either, Option 和 Try 以及 Java 中的 Either

### POJO 常见使用方式

在使用 KeyBy 处理 POJO 类的时候需要重写 hashCode 方法，具体样例如下：

```java
public class Color {
    private String name;

    Color(String name) {
        this.name = name;
    }

    public String getName() {
        return this.name;
    }
    
    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return this.name;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((name == null) ? 0 : name.hashCode());
        return result;
    }

}
```

### 常见问题

- 注册子类型：在程序声明中只包含了父类型，但是在使用中需要使用子类，此时注册子类可以让 Flink 提高性能。(为子类调用 `.registerType(clazz)` 方法)
- 注册自定义序列化器：Flink 使用 Kryo 作为默认序列化器。如果需要使用其他序列化方式则需要进行独立配置。([第三方序列化工具](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/serialization/third_party_serializers/))
- 新增类型提示：在 Java 程序中返回类型不确定时需要指定返回类型。
- 手动创建 TypeInformation：在 Flink 无法推断数据类型时需要配置此项。

### 参考资料

[官方文档](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/dev/datastream/fault-tolerance/serialization/types_serialization/)