---
title: 打包插件
date: 2022-06-10 21:05:12
tags:
- "JAVA"
- "Maven"
- "Gradle"
id: maven-assemble
no_word_count: true
no_toc: false
categories: JAVA
---

## 打包插件

### 简介

在需要将带有额外包的程序部署在集群上的时候，可以通过使用下面的方式将外部包与代码进行合并打包。

> 注：如果是 Spring Boot 项目则可以直接使用 GraalVM Native Support 打包成可执行文件。

### Maven

样例如下：

```xml
<build>
    <pluginManagement>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
            </plugin>
        </plugins>
    </pluginManagement>
    <plugins>
        <plugin>
            <artifactId>maven-assembly-plugin</artifactId>
            <version>3.3.0</version>
            <configuration>
                <descriptorRefs>
                    <descriptorRef>jar-with-dependencies</descriptorRef>
                </descriptorRefs>
                <archive>
                    <manifest>
                        <mainClass>xxx.xxx.xxx</mainClass>
                    </manifest>
                </archive>
            </configuration>
            <executions>
                <execution>
                    <id>make-assembly</id>
                    <phase>package</phase>
                    <goals>
                        <goal>single</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

如果需要移除某些包则可以新增下面的配置项：

```xml
<dependencies>
    <dependency>
        <groupId>xxx</groupId>
        <artifactId>xxx</artifactId>
        <version>xxx</version>
        <scope>provided</scope>
    </dependency>
</dependencies>
```

### Gradle 

在 `build.gradle` 文件中新增如下内容即可：

```groovy
plugins {
    id 'com.github.johnrengelman.shadow' version '7.1.2'
    id 'java'
}
```

### 参考资料

[Apache Maven Assembly Plugin 官方文档](https://maven.apache.org/plugins/maven-assembly-plugin/usage.html)

[Gradle Shadow](https://imperceptiblethoughts.com/shadow/introduction/)
