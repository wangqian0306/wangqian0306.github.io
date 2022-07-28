---
title: Java 序列化工具
date: 2022-06-27 21:32:58
tags:
- "Java"
- "Kryo"
- "Avro"
id: serialization
no_word_count: true
no_toc: false
categories: JAVA
---

## Java 序列化工具

### 简介

序列化 (Serialization)是将对象的状态信息转换为可以存储或传输的形式的过程。Java 本身提供了 `Serializable` 类，通过继承此类可以方便的将数据进行序列化。

除此之外可以使用如下提到的第三方框架。

### Kryo

Kryo 是一个快速高效的 Java 二进制对象图序列化框架。该项目的目标是高速、小尺寸和易于使用的 API。该项目在需要持久化对象的任何时候都很有用，无论是构建文件、存储至数据库还是通过网络传输对象。

Kryo 还可以执行自动深浅复制/克隆。这是从对象到对象的直接复制，而不是从对象到字节到对象的直接复制。

#### 简单使用

首先需要引入依赖包：

```xml

<dependency>
    <groupId>com.esotericsoftware</groupId>
    <artifactId>kryo</artifactId>
    <version>5.3.0</version>
</dependency>
```

然后可以参照此样例完成代码编写：

```java
import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.Input;
import com.esotericsoftware.kryo.io.Output;

import java.io.*;

public class HelloKryo {
    static public void main(String[] args) throws Exception {
        Kryo kryo = new Kryo();
        kryo.register(SomeClass.class);

        SomeClass object = new SomeClass();
        object.value = "Hello Kryo!";

        Output output = new Output(new FileOutputStream("file.bin"));
        kryo.writeObject(output, object);
        output.close();

        Input input = new Input(new FileInputStream("file.bin"));
        SomeClass object2 = kryo.readObject(input, SomeClass.class);
        input.close();
    }

    static public class SomeClass {
        String value;
    }
}
```

### Avro

Apache Avro 是一个数据序列化系统。

Avro 提供：

- 丰富的数据结构。
- 一种紧凑、快速的二进制数据格式。
- 一个容器文件，用于存储持久数据。
- 远程过程调用 (RPC)。
- 与动态语言的简单集成。代码生成不需要读取或写入数据文件，也不需要使用或实现 RPC 协议。代码生成作为一种可选的优化，只为静态类型语言实现。

#### 简单使用

首先需要引入依赖包：

```xml
<dependency>
    <groupId>org.apache.avro</groupId>
    <artifactId>avro</artifactId>
    <version>1.11.0</version>
</dependency>
```

```xml
<plugins>
    <plugin>
        <groupId>org.apache.avro</groupId>
        <artifactId>avro-maven-plugin</artifactId>
        <version>1.11.0</version>
        <executions>
            <execution>
                <phase>generate-sources</phase>
                <goals>
                    <goal>schema</goal>
                </goals>
                <configuration>
                    <sourceDirectory>${project.basedir}/src/main/avro/</sourceDirectory>
                    <outputDirectory>${project.basedir}/src/main/java/</outputDirectory>
                </configuration>
            </execution>
        </executions>
    </plugin>
    <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <configuration>
            <source>1.8</source>
            <target>1.8</target>
        </configuration>
    </plugin>
</plugins>
```

Avro 在序列化时是需要提前定义结构：

```text
{"namespace": "example.avro",
  "type": "record",
  "name": "User",
  "fields": [
    {"name": "name", "type": "string"},
    {"name": "favorite_number",  "type": ["int", "null"]},
    {"name": "favorite_color", "type": ["string", "null"]}
  ]
}
```

然后根据所指定的结构编译 Java 文件，将目标文件放在代码中：

```bash
java -jar /path/to/avro-tools-1.11.0.jar compile schema <schema file> <destination>
```

编写样例代码

```java
public class Test {
    public static void main(String[] args) {
        User user1 = new User();
        user1.setName("Alyssa");
        user1.setFavoriteNumber(256);

        User user2 = new User("Ben", 7, "red");

        User user3 = User.newBuilder()
                .setName("Charlie")
                .setFavoriteColor("blue")
                .setFavoriteNumber(null)
                .build();

        DatumWriter<User> userDatumWriter = new SpecificDatumWriter<User>(User.class);
        DataFileWriter<User> dataFileWriter = new DataFileWriter<User>(userDatumWriter);
        dataFileWriter.create(user1.getSchema(), new File("users.avro"));
        dataFileWriter.append(user1);
        dataFileWriter.append(user2);
        dataFileWriter.append(user3);
        dataFileWriter.close();

        DatumReader<User> userDatumReader = new SpecificDatumReader<User>(User.class);
        DataFileReader<User> dataFileReader = new DataFileReader<User>(file, userDatumReader);
        User user = null;
        while (dataFileReader.hasNext()) {
            user = dataFileReader.next(user);
            System.out.println(user);
        }
    }
}
```

### 参考资料

[Kryo](https://github.com/EsotericSoftware/kryo)

[Avro](https://avro.apache.org/)
