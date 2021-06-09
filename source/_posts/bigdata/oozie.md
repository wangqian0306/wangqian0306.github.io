---
title: Oozie 基础使用
date: 2020-07-02 22:43:13
tags: "Oozie"
id: oozie
no_word_count: true
no_toc: false
categories: 大数据
---

## 简介

Oozie 通常被用来提交和调度 Hadoop 集群中的任务。
在 CDH 集群中几乎所有的 Hue 操作都是由 Oozie 实现的。

## 安装和配置

服务可以直接添加，但是 Web UI 需要额外进行操作，样例如下：

### CDH

```bash
curl http://archive.cloudera.com/gplextras/misc/ext-2.2.zip -o ext-2.2.zip
unzip ext-2.2.zip -d /var/lib/oozie
chown -R oozie:oozie /var/lib/oozie/ext-2.2
```

[官方文档](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_oozie_console.html)

### HDP

```bash
curl http://archive.cloudera.com/gplextras/misc/ext-2.2.zip -o ext-2.2.zip
unzip ext-2.2.zip -d /usr/hdp/current/oozie-server/libext
chown -R oozie:hadoop /usr/hdp/current/oozie-server/libext
```

## 运行流程

Oozie 任务的创建需要两个部分一部分为配置文件，一部分为运行流程的XML。

在运行时需要配置如下变量：

|配置项|说明|样例|
|:---:|:---:|:---:|
|nameNode|HDFS NameNode 地址|hdfs://localhost:8020|
|jobTracker|Yarn ResourceManager 地址 |localhost:8032|
|queueName|任务位于的 Yarn 队列|default|
|oozie.wf.application.path|workflow.xml 文件所在的 HDFS 文件夹|hdfs://localhost:8020/demo|
|oozie.use.system.libpath|使用默认系统包|true|
|security_enabled|权限认证开关|False|
|user.name|任务所属用户|admin|

## Java Client

可以在项目中加入下面的依赖，来引入项目相关包

```xml
<dependency>
    <groupId>org.apache.oozie</groupId>
    <artifactId>oozie-client</artifactId>
    <version>5.1.0-cdh6.3.2</version>
    <exclusions>
        <exclusion>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-simple</artifactId>
        </exclusion>
        <exclusion>
            <groupId>ch.qos.logback</groupId>
            <artifactId>logback-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

> 注：如果需要与 SpringBoot 项目集成的话需要添加 exclusion。如果系统环境中不存在 slf4j 或者 log4j 的依赖问题可以直接省略。

```java
import org.apache.oozie.client.OozieClient;
import org.apache.oozie.client.OozieClientException;
import org.apache.oozie.client.WorkflowAction;
import org.apache.oozie.client.WorkflowJob;

public class OozieDemo {
    public static void main(String[] args) {
        OozieClient oc = new OozieClient("http://localhost:11000/oozie/");
        Properties conf = oc.createConfiguration();
        conf.setProperty("nameNode", "hdfs://localhost:8020");
        conf.setProperty("...", "...");
        String jobId;
        try {
            jobId = oc.run(conf, xmlString);
        } catch (Exception e) {
            System.out.println(e.toString());
            System.exit(1);
        }
        System.out.println(jobId);
    }
}
```

## XML 文件样例

- Shell 任务样例
```xml
<workflow-app name="shell-demo" xmlns="uri:oozie:workflow:0.5">
    <start to="shell-0001"/>
    <kill name="Kill">
        <message>Action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <action name="shell-0001">
        <shell xmlns="uri:oozie:shell-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <exec>wqecho.sh</exec>
            <file>/wq/wqecho.sh#wqecho.sh</file>
            <argument>test</argument>
              <capture-output/>
        </shell>
        <ok to="End"/>
        <error to="Kill"/>
    </action>
    <end name="End"/>
</workflow-app>
```

- Sqoop 任务样例
```xml
<workflow-app name="spark-demo" xmlns="uri:oozie:workflow:0.5">
    <start to="spark2-0002"/>
    <kill name="Kill">
        <message>Action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <action name="spark2-0002">
        <spark xmlns="uri:oozie:spark-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <master>yarn</master>
            <mode>client</mode>
            <name>BatchSpark2</name>
            <jar>demo.py</jar>
            <file>/wq/demo.py#demo.py</file>
        </spark>
        <ok to="End"/>
        <error to="Kill"/>
    </action>
    <end name="End"/>
</workflow-app>
```

- Sqoop 任务样例
```xml
<workflow-app name="sqoop-demo" xmlns="uri:oozie:workflow:0.5">
    <start to="sqoop-0003"/>
    <kill name="Kill">
        <message>Action failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
    </kill>
    <action name="sqoop-0003">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <command>import --connect jdbc:mysql://localhost:3306/mysql --username mariadb --password mariadb --table user --target-dir /tmp/demo -m 1</command>
        </sqoop>
        <ok to="End"/>
        <error to="Kill"/>
    </action>
    <end name="End"/>
</workflow-app>
```
