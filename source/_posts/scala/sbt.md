---
title: sbt 工具
date: 2022-07-08 22:43:13
tags:
- "Scala"
- "sbt"
id: sbt
no_word_count: true
no_toc: false
categories: Scala
---

## sbt 工具

### 简介

sbt 是 Scala 的包管理工具。 

### 使用及配置

可以使用 IDEA 工具轻松的创建由 sbt 管理的 Scala 项目，此处不在对环境安装和配置进行赘述。

配置依赖项

```text
name := "<name>"
version := "<version>"
scalaVersion := "<scalaVersion>"
//使用阿里云的仓库
resolvers+="aliyun Maven Repository"at"http://maven.aliyun.com/nexus/content/groups/public"
libraryDependencies += <groupID> % <artifactID> % <revision>
```

> 注：也可以使用 `organization %% moduleName % version` 的方式引入依赖包，这样一来 sbt 则会将项目 Scala 的二进制版本添加到引入中。

### 打包 fat jar 

在创建项目之后，整体的目录结构如下：

```text
project-root
 |----build.sbt
 |----src
 |----project
	  |----plugins.sbt
	  |----build.properties
```

如需打包 fatjar 则需要在 `plugins.sbt` 中写入如下内容：

```text
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.15.0")
```

然后运行 `sbt assembly` 即可

如果需要移除某些依赖则在 `build.sbt` 文件中采用如下写法：

```text
libraryDependencies += "org.apache.spark" %% "spark-core" % sparkVersion % "provided"
```

如需剔除了 Scala 相关依赖和指定主类则需要在 `build.sbt` 文件中进行如下配置：

```text
lazy val root = (project in file("."))
  .settings(
    assemblyPackageScala / assembleArtifact := false,
    assembly / mainClass := Some("<groupID>.<artifactID>.<mainClass>"),
    assembly / assemblyJarName := "<jarName>.jar",
  )
```

### 在 Spark 项目中使用

需要在 `build.sbt` 文件中进行如下配置，修改合并策略：

```bash
ThisBuild / assemblyMergeStrategy := {
  case PathList("org","aopalliance", xs @ _*) => MergeStrategy.last
  case PathList("javax", "inject", xs @ _*) => MergeStrategy.last
  case PathList("javax", "servlet", xs @ _*) => MergeStrategy.last
  case PathList("javax", "activation", xs @ _*) => MergeStrategy.last
  case PathList("org", "apache", xs @ _*) => MergeStrategy.last
  case PathList("com", "google", xs @ _*) => MergeStrategy.last
  case PathList("com", "esotericsoftware", xs @ _*) => MergeStrategy.last
  case PathList("com", "codahale", xs @ _*) => MergeStrategy.last
  case PathList("com", "yammer", xs @ _*) => MergeStrategy.last
  case "about.html" => MergeStrategy.rename
  case "META-INF/ECLIPSEF.RSA" => MergeStrategy.last
  case "META-INF/mailcap" => MergeStrategy.last
  case "META-INF/mimetypes.default" => MergeStrategy.last
  case "plugin.properties" => MergeStrategy.last
  case "log4j.properties" => MergeStrategy.last
  case x =>
    val oldStrategy = (ThisBuild / assemblyMergeStrategy).value
    oldStrategy(x)
}
```

### 参考资料

[官方文档](https://www.scala-sbt.org/1.x/docs/index.html)

[sbt-assembly 插件源码及文档](https://github.com/sbt/sbt-assembly)
